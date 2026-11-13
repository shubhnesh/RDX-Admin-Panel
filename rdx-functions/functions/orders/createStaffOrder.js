/**
 * createStaffOrder — POS / walk-in orders (Admin + Staff).
 *
 * SECURITY (non-negotiable):
 * 1. Client NEVER sends prices, taxes, fee amounts, or totals.
 * 2. All product prices are read from Firestore (menu_items).
 * 3. GST is ALWAYS applied from settings/fees (no client toggle can disable it).
 * 4. Delivery / late-night / long-distance fees are applied only when the
 *    corresponding server-side toggles are ON (and for delivery orders).
 * 5. Client may only send apply_long_distance_fee: true|false (flag).
 * 6. Order document is written only by this function (Admin SDK).
 */

"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { requireRestaurantUser } = require("../auth/roles");
const { generateOrderId } = require("./orderId");

const db = admin.firestore();

function parseTimeToMinutes(timeStr) {
  if (!timeStr || typeof timeStr !== "string") return null;
  const [h, m] = timeStr.split(":").map(Number);
  if (Number.isNaN(h) || Number.isNaN(m)) return null;
  return h * 60 + m;
}

/** Server-side late-night window check (supports overnight, e.g. 22:00–06:00). */
function isLateNight(now, startStr, endStr) {
  const start = parseTimeToMinutes(startStr);
  const end = parseTimeToMinutes(endStr);
  if (start === null || end === null) return false;
  const current = now.getHours() * 60 + now.getMinutes();
  if (start > end) {
    return current >= start || current < end;
  }
  return current >= start && current < end;
}

function getPriceForSize(product, sizeName) {
  if (!sizeName || !Array.isArray(product.sizes) || product.sizes.length === 0) {
    return Number(product.price) || 0;
  }
  const found = product.sizes.find(
    (s) =>
      s.name &&
      s.name.toString().trim() === sizeName.toString().trim()
  );
  return found ? Number(found.price) || 0 : Number(product.price) || 0;
}

/**
 * Load operational toggles that control whether non-GST fees apply.
 * Tries common document ids used by the admin app; defaults to enabled
 * when the document is missing so existing restaurants keep working.
 */
async function loadFeeToggles() {
  const candidates = ["restaurant", "config", "main", "general"];
  for (const id of candidates) {
    const snap = await db.collection("settings").doc(id).get();
    if (snap.exists) {
      const d = snap.data() || {};
      return {
        feesEnabled: d.fees_enabled !== false && d.order_fees_enabled !== false,
        lateNightDelivery: d.late_night_delivery !== false,
        longDistanceDelivery: d.long_distance_delivery !== false,
      };
    }
  }
  // Also check the fees document itself for enable flags.
  const feesSnap = await db.collection("settings").doc("fees").get();
  if (feesSnap.exists) {
    const d = feesSnap.data() || {};
    return {
      feesEnabled: d.fees_enabled !== false,
      lateNightDelivery: d.late_night_delivery !== false,
      longDistanceDelivery: d.long_distance_delivery !== false,
    };
  }
  return {
    feesEnabled: true,
    lateNightDelivery: true,
    longDistanceDelivery: true,
  };
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
        throw new functions.https.HttpsError(
          "invalid-argument",
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
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Order must contain at least one item."
      );
    }

    const type = String(order_type).trim();
    if (!["dineIn", "takeaway", "delivery"].includes(type)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "order_type must be dineIn, takeaway, or delivery."
      );
    }

    // ── Fees: amounts ONLY from settings/fees ─────────────────────────────
    const feesSnap = await db.collection("settings").doc("fees").get();
    const fees = feesSnap.exists ? feesSnap.data() || {} : {};

    // GST is always active (no toggle).
    const gstPercent = Math.max(0, Number(fees.gst_percent) || 0);
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

    // ── Toggles: control whether non-GST fees are applied ─────────────────
    // fees_enabled (or order_fees_enabled) is the master switch for
    // delivery / late-night / long-distance. GST is never gated by it.
    const toggles = await loadFeeToggles();
    // Prefer explicit fees_enabled on the fees document when present.
    const masterFeesOn =
      fees.fees_enabled === true ||
      (fees.fees_enabled !== false && toggles.feesEnabled);

    // ── Line items: server prices from menu_items ─────────────────────────
    let itemTotal = 0;
    const orderItems = [];

    for (const line of items) {
      const productId = (line.product_id || line.menu_item_id || "")
        .toString()
        .trim();
      const quantity = Number(line.quantity) || 0;
      const size = line.size || line.selected_size || null;

      if (!productId || quantity <= 0) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Every item must have a valid product_id and quantity > 0."
        );
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
      const lineTotal = unitPrice * quantity;
      itemTotal += lineTotal;

      orderItems.push({
        product_id: productId,
        name: product.name || "",
        quantity,
        price: unitPrice,
        size: size || null,
        notes: (line.notes || "").toString().trim() || null,
        spice_level: line.spice_level || line.spiceLevel || null,
        add_ons: Array.isArray(line.add_ons || line.addOns)
          ? line.add_ons || line.addOns
          : [],
      });
    }

    // ── Apply fees (server clock + settings + toggles only) ───────────────
    const now = new Date();
    const isDelivery = type === "delivery";

    // GST always calculated from item total.
    const taxes = (itemTotal * gstPercent) / 100;

    // Delivery fee for delivery orders (amount from settings/fees only).
    let deliveryFee = 0;
    if (isDelivery) {
      deliveryFee = deliveryFeeBase;
      if (freeDeliveryAbove > 0 && itemTotal >= freeDeliveryAbove) {
        deliveryFee = 0;
      }
    }

    // Late-night: delivery + settings toggle ON + inside late-night window.
    // (Late Night toggle is the switch — no master fees_enabled gate.)
    const lateNightFee =
      isDelivery &&
      toggles.lateNightDelivery &&
      isLateNight(now, lateNightStart, lateNightEnd)
        ? lateNightFeeValue
        : 0;

    // Long-distance: delivery + staff enabled optional checkout toggle.
    // Amount always from settings/fees; never from client.
    const longDistanceFee =
      isDelivery && apply_long_distance_fee === true
        ? longDistanceFeeValue
        : 0;

    const total =
      itemTotal + taxes + deliveryFee + lateNightFee + longDistanceFee;

    const method = payment_method
      ? String(payment_method).toLowerCase().trim()
      : null;
    if (method && !["cash", "upi", "card"].includes(method)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "payment_method must be cash, upi, or card."
      );
    }

    const base = {
      customer_id: null,
      customer_name:
        String(customer_name || "Walk-in").trim() || "Walk-in",
      customer_phone: String(customer_phone || "").trim(),
      delivery_address: isDelivery
        ? String(delivery_address || "").trim()
        : "",
      status: "pending",
      order_type: type,
      order_source: "staff",
      table_number:
        type === "dineIn" && table_number
          ? String(table_number).trim()
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
      notes: notes ? String(notes).trim() : null,
      coupon_code: coupon_code
        ? String(coupon_code).trim().toUpperCase()
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
