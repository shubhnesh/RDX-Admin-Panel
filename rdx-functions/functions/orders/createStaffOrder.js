/**
 * createStaffOrder — POS / walk-in orders (Admin + Staff).
 *
 * SECURITY (non-negotiable):
 * 1. Client NEVER sends prices, taxes, fee amounts, or totals.
 * 2. All product prices are read from Firestore (menu_items).
 * 3. GST is ALWAYS applied from settings/fees.
 * 4. Delivery / late-night / long-distance fees are controlled ONLY by
 *    settings/fees (fees_enabled master switch + per-fee toggles).
 * 5. Client may only send apply_long_distance_fee: true|false, and it is
 *    honoured only if the server toggle long_distance_delivery is ON.
 * 6. Order document is written only by this function (Admin SDK).
 */

"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { requireRestaurantUser } = require("../auth/roles");
const { generateOrderId } = require("./orderId");

const db = admin.firestore();

const MAX_LINES = 50;
const MAX_QTY = 99;
const MAX_ADDONS = 10;

const round2 = (n) => Math.round((n + Number.EPSILON) * 100) / 100;

function bad(message) {
  return new functions.https.HttpsError("invalid-argument", message);
}

function parseTimeToMinutes(timeStr) {
  if (!timeStr || typeof timeStr !== "string") return null;
  const [h, m] = timeStr.split(":").map(Number);
  if (Number.isNaN(h) || Number.isNaN(m)) return null;
  return h * 60 + m;
}

/** Minutes since midnight in IST (UTC+5:30). Cloud Functions run in UTC. */
function istMinutes(date) {
  const ist = new Date(date.getTime() + (5 * 60 + 30) * 60 * 1000);
  return ist.getUTCHours() * 60 + ist.getUTCMinutes();
}

/** Late-night window check in IST (supports overnight, e.g. 22:00–06:00). */
function isLateNight(now, startStr, endStr) {
  const start = parseTimeToMinutes(startStr);
  const end = parseTimeToMinutes(endStr);
  if (start === null || end === null) return false;
  const current = istMinutes(now);
  if (start > end) {
    return current >= start || current < end;
  }
  return current >= start && current < end;
}

/** Strict: unknown size or missing/zero price is rejected, never free. */
function getPriceForSize(product, sizeName) {
  const hasSizes = Array.isArray(product.sizes) && product.sizes.length > 0;
  let price;
  if (!sizeName || !hasSizes) {
    if (sizeName && !hasSizes) throw bad("This item has no sizes.");
    price = Number(product.price);
  } else {
    const found = product.sizes.find(
      (s) =>
        s.name && s.name.toString().trim() === sizeName.toString().trim()
    );
    if (!found) throw bad(`Unknown size "${sizeName}".`);
    price = Number(found.price);
  }
  if (!Number.isFinite(price) || price <= 0) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      `${product.name || "Item"} has no valid price.`
    );
  }
  return price;
}

/** Add-ons are stored as names only; the server never trusts client prices. */
function sanitizeAddOns(raw) {
  if (raw == null) return [];
  if (!Array.isArray(raw) || raw.length > MAX_ADDONS) {
    throw bad(`add_ons must be an array of at most ${MAX_ADDONS}.`);
  }
  return raw
    .map((a) => {
      const name =
        typeof a === "string" ? a : a && typeof a.name === "string" ? a.name : "";
      return { name: name.trim().slice(0, 40) };
    })
    .filter((a) => a.name);
}

// APP: ADMIN APP — restaurant staff/POS order creation.
exports.createStaffOrder = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const { uid } = requireRestaurantUser(context);

    // Reject any client attempt to push money fields
    const forbiddenKeys = [
      "item_total",
      "subtotal",
      "taxes",
      "tax",
      "gst",
      "gst_percent",
      "delivery_fee",
      "late_night_fee",
      "long_distance_fee",
      "total",
      "final_total",
      "price",
      "unit_price",
      "discount",
      "coupon_discount",
    ];
    for (const key of forbiddenKeys) {
      if (Object.prototype.hasOwnProperty.call(data || {}, key)) {
        throw bad(
          `Client is not allowed to send "${key}". All amounts are calculated server-side from settings/fees and menu_items.`
        );
      }
    }

    const {
      items = [],
      order_type = "dineIn",
      table_number = null,
      customer_name = "Walk-in",
      customer_phone = "",
      delivery_address = "",
      notes = null,
      coupon_code = null,
      payment_method = null,
      apply_long_distance_fee = false,
    } = data || {};

    if (!Array.isArray(items) || items.length === 0) {
      throw bad("Order must contain at least one item.");
    }
    if (items.length > MAX_LINES) {
      throw bad(`An order can have at most ${MAX_LINES} items.`);
    }

    const type = String(order_type).trim();
    if (!["dineIn", "takeaway", "delivery"].includes(type)) {
      throw bad("order_type must be dineIn, takeaway, or delivery.");
    }

    // ── Fees: ONE source of truth — settings/fees ─────────────────────────
    const feesSnap = await db.collection("settings").doc("fees").get();
    const fees = feesSnap.exists ? feesSnap.data() || {} : {};

    const gstPercent = Math.min(100, Math.max(0, Number(fees.gst_percent) || 0));
    const lateNightFeeValue = Math.max(0, Number(fees.late_night_fee) || 0);
    const lateNightStart = (fees.late_night_start || "22:00").toString();
    const lateNightEnd = (fees.late_night_end || "06:00").toString();
    const longDistanceFeeValue = Math.max(
      0,
      Number(fees.long_distance_fee) || 0
    );
    const deliveryFeeBase = Math.max(0, Number(fees.delivery_fee) || 0);
    const freeDeliveryAbove = Math.max(
      0,
      Number(fees.free_delivery_above) || 0
    );

    // Master switch gates delivery / late-night / long-distance. GST never.
    const feesOn = fees.fees_enabled !== false;
    const lateNightOn = fees.late_night_delivery === true;
    const longDistanceOn = fees.long_distance_delivery === true;

    // ── Line items: server prices from menu_items ─────────────────────────
    let itemTotal = 0;
    const orderItems = [];

    for (const line of items) {
      if (!line || typeof line !== "object") {
        throw bad("Invalid item.");
      }
      const productId = (line.product_id || line.menu_item_id || "")
        .toString()
        .trim();
      const quantity = line.quantity;
      const size = line.size || line.selected_size || null;

      if (
        !productId ||
        productId.includes("/") ||
        !Number.isInteger(quantity) ||
        quantity < 1 ||
        quantity > MAX_QTY
      ) {
        throw bad(
          `Every item must have a valid product_id and an integer quantity from 1 to ${MAX_QTY}.`
        );
      }
      if (size != null && typeof size !== "string") {
        throw bad("size must be a string.");
      }

      const productSnap = await db
        .collection("menu_items")
        .doc(productId)
        .get();
      if (!productSnap.exists) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          `Product ${productId} not found.`
        );
      }

      const product = productSnap.data() || {};
      const available =
        product.is_available !== false && product.available !== false;
      if (!available) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          `${product.name || "Item"} is currently unavailable.`
        );
      }

      const unitPrice = getPriceForSize(product, size);
      itemTotal += unitPrice * quantity;

      orderItems.push({
        product_id: productId,
        name: product.name || "",
        quantity,
        price: unitPrice,
        size: size || null,
        notes: (line.notes || "").toString().trim().slice(0, 200) || null,
        spice_level: line.spice_level || line.spiceLevel || null,
        add_ons: sanitizeAddOns(line.add_ons || line.addOns),
      });
    }
    itemTotal = round2(itemTotal);

    // ── Apply fees (server clock + settings only) ─────────────────────────
    const now = new Date();
    const isDelivery = type === "delivery";

    const taxes = round2((itemTotal * gstPercent) / 100);

    const freeDelivery = freeDeliveryAbove > 0 && itemTotal >= freeDeliveryAbove;
    const deliveryFee =
      feesOn && isDelivery && !freeDelivery ? round2(deliveryFeeBase) : 0;

    const lateNightFee =
      feesOn &&
      isDelivery &&
      lateNightOn &&
      isLateNight(now, lateNightStart, lateNightEnd)
        ? round2(lateNightFeeValue)
        : 0;

    // Staff may request the fee, but only if the admin toggle is ON.
    const longDistanceFee =
      feesOn &&
      isDelivery &&
      longDistanceOn &&
      apply_long_distance_fee === true
        ? round2(longDistanceFeeValue)
        : 0;

    const total = round2(
      itemTotal + taxes + deliveryFee + lateNightFee + longDistanceFee
    );

    const method = payment_method
      ? String(payment_method).toLowerCase().trim()
      : null;
    if (method && !["cash", "upi", "card"].includes(method)) {
      throw bad("payment_method must be cash, upi, or card.");
    }

    const base = {
      customer_id: null,
      customer_name:
        String(customer_name || "Walk-in").trim().slice(0, 60) || "Walk-in",
      customer_phone: String(customer_phone || "").trim().slice(0, 20),
      delivery_address: isDelivery
        ? String(delivery_address || "").trim().slice(0, 300)
        : "",
      status: "pending",
      order_type: type,
      order_source: "staff",
      table_number:
        type === "dineIn" && table_number
          ? String(table_number).trim().slice(0, 20)
          : null,
      payment_method: method,
      payment_status: method ? "paid" : "unpaid",
      items: orderItems,
      item_total: itemTotal,
      taxes,
      gst_percent: gstPercent,
      delivery_fee: deliveryFee,
      late_night_fee: lateNightFee,
      long_distance_fee: longDistanceFee,
      total,
      notes: notes ? String(notes).trim().slice(0, 500) : null,
      coupon_code: coupon_code
        ? String(coupon_code).trim().toUpperCase().slice(0, 100)
        : null,
      created_by: uid,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    let orderRef;
    for (let attempt = 0; attempt < 5; attempt++) {
      orderRef = db.collection("orders").doc(generateOrderId());
      try {
        await orderRef.create(base);
        break;
      } catch (e) {
        const collision = e.code === 6 || e.code === "already-exists";
        if (!collision || attempt === 4) throw e;
      }
    }

    return {
      id: orderRef.id,
      customer_name: base.customer_name,
      customer_phone: base.customer_phone,
      delivery_address: base.delivery_address,
      status: base.status,
      order_type: base.order_type,
      order_source: base.order_source,
      table_number: base.table_number,
      payment_method: base.payment_method,
      payment_status: base.payment_status,
      items: orderItems,
      item_total: itemTotal,
      taxes,
      gst_percent: gstPercent,
      delivery_fee: deliveryFee,
      late_night_fee: lateNightFee,
      long_distance_fee: longDistanceFee,
      total,
      notes: base.notes,
      created_at: now.toISOString(),
      updated_at: now.toISOString(),
    };
  });
