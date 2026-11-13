/**
 * createUserOrder.js — Secure order placement for the customer app.
 *
 * SECURITY RULES (non-negotiable):
 * 1. Client NEVER sends prices, discounts, taxes, delivery fees, or totals.
 * 2. All product prices are read from Firestore (menu_items).
 * 3. Coupon / offer validation + discount calculation happens ONLY here.
 * 4. Usage limits are enforced inside a Firestore transaction (atomic).
 * 5. Order document is written only by this function (Admin SDK).
 *
 * Coupon conditions verified:
 * - Code exists and matches (case-insensitive)
 * - status === "active"
 * - now is within [start_date, end_date]
 * - usage_count < usage_limit (when limit is set)
 * - applicable category / subcategory / item scope matches cart items
 * - eligible subtotal >= min_order_value (when set)
 * - Discount type/value/max_discount applied server-side only
 *
 * Same rules apply to offers (including item / subcategory scoping).
 */

"use strict";

const crypto = require("node:crypto");
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const rewardConfig = require("../rewards/config");
const { readStoredRewardConfiguration } = require("../rewards/configuration");
const { computeEarnPoints } = require("../rewards/earnOnDelivery");
const { generateOrderId } = require("./orderId");

// Admin is initialized in the main index entrypoint.
const db = admin.firestore();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function parseTimeToMinutes(timeStr) {
  if (!timeStr || typeof timeStr !== "string") return null;
  const [h, m] = timeStr.split(":").map(Number);
  if (isNaN(h) || isNaN(m)) return null;
  return h * 60 + m;
}

function isLateNight(now, startStr, endStr) {
  const start = parseTimeToMinutes(startStr);
  const end = parseTimeToMinutes(endStr);
  if (start === null || end === null) return false;
  const current = now.getHours() * 60 + now.getMinutes();
  if (start > end) {
    // Overnight window (e.g. 22:00 → 06:00)
    return current >= start || current < end;
  }
  return current >= start && current < end;
}

function getPriceForSize(product, sizeName) {
  if (!sizeName || !Array.isArray(product.sizes) || product.sizes.length === 0) {
    return Number(product.price) || 0;
  }
  const found = product.sizes.find(
    (s) => s.name && s.name.toString().trim() === sizeName.toString().trim()
  );
  return found ? Number(found.price) || 0 : Number(product.price) || 0;
}

/**
 * Pure discount calculator. Never trusts client values.
 * @returns {number} Discount amount clamped to [0, eligibleAmount]
 */
function calculateDiscount(discountType, discountValue, maxDiscount, eligibleAmount) {
  if (eligibleAmount <= 0) return 0;

  let discount = 0;
  const type = (discountType || "flat").toString().toLowerCase();

  if (type === "percentage" || type.includes("percent")) {
    discount = (eligibleAmount * Number(discountValue)) / 100;
    if (maxDiscount != null && maxDiscount !== "") {
      discount = Math.min(discount, Number(maxDiscount));
    }
  } else {
    discount = Number(discountValue) || 0;
  }

  // Never discount more than the eligible amount, never go negative
  return Math.min(Math.max(discount, 0), eligibleAmount);
}

function toDate(value) {
  if (!value) return null;
  if (value.toDate && typeof value.toDate === "function") return value.toDate();
  if (value instanceof Date) return value;
  const parsed = Date.parse(value);
  return isNaN(parsed) ? null : new Date(parsed);
}

function allocateRewardSubtotals(
  orderItems,
  couponDiscount,
  discountEligibleProductIds = null
) {
  const discountEligibleSubtotal = orderItems.reduce(
    (sum, item) =>
      discountEligibleProductIds == null ||
          discountEligibleProductIds.has(item.product_id)
        ? sum + item.price * item.quantity
        : sum,
    0
  );
  return orderItems.map((item) => {
    const lineSubtotal = item.price * item.quantity;
    const discountEligible =
      discountEligibleProductIds == null ||
      discountEligibleProductIds.has(item.product_id);
    const allocatedDiscount =
      discountEligible && discountEligibleSubtotal > 0
        ? couponDiscount * lineSubtotal / discountEligibleSubtotal
        : 0;
    return {
      ...item,
      reward_eligible_subtotal: Math.max(0, lineSubtotal - allocatedDiscount),
    };
  });
}

function planCartConsumption(cartDocuments, orderItems) {
  const lineKey = (productId, size) =>
    `${String(productId || "").trim()}\u0000${String(size || "").trim()}`;
  const orderedQuantities = new Map();
  for (const item of orderItems) {
    const key = lineKey(item.product_id, item.size);
    const quantity = Math.max(0, Math.floor(Number(item.quantity) || 0));
    if (key.startsWith("\u0000") || quantity === 0) continue;
    orderedQuantities.set(key, (orderedQuantities.get(key) || 0) + quantity);
  }

  const consumption = [];
  for (const document of cartDocuments) {
    const cartItem =
      typeof document.data === "function"
        ? document.data() || {}
        : document.data || {};
    const productId =
      cartItem.product_id || (cartItem.product && cartItem.product.id);
    const key = lineKey(
      productId,
      cartItem.selected_size || cartItem.size
    );
    const orderedQuantity = orderedQuantities.get(key) || 0;
    if (orderedQuantity === 0) continue;

    const cartQuantity = Math.max(
      0,
      Math.floor(Number(cartItem.quantity) || 0)
    );
    consumption.push({
      documentId: document.id,
      remainingQuantity: Math.max(0, cartQuantity - orderedQuantity),
    });
    orderedQuantities.delete(key);
  }

  return consumption;
}

function canonicalize(value) {
  if (Array.isArray(value)) return value.map(canonicalize);
  if (value && typeof value === "object") {
    return Object.keys(value)
      .sort()
      .reduce((result, key) => {
        if (value[key] !== undefined) result[key] = canonicalize(value[key]);
        return result;
      }, {});
  }
  return value;
}

function createOrderRequestHash(data) {
  const request = { ...(data || {}) };
  delete request.idempotency_key;
  return crypto
    .createHash("sha256")
    .update(JSON.stringify(canonicalize(request)))
    .digest("hex");
}

function validateIdempotencyKey(value) {
  if (
    typeof value !== "string" ||
    !/^[A-Za-z0-9._:-]{16,128}$/.test(value.trim())
  ) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "A valid idempotency key is required to place an order."
    );
  }
  return value.trim();
}

function getIdempotencyKey(value) {
  if (value === undefined) {
    return crypto.randomBytes(24).toString("hex");
  }
  return validateIdempotencyKey(value);
}

function orderRequestDocumentId(uid, key) {
  return crypto
    .createHash("sha256")
    .update(`${uid}:${key}`)
    .digest("hex");
}

function toOrderResponse(orderId, order) {
  const createdAt =
    order.created_at && typeof order.created_at.toDate === "function"
      ? order.created_at.toDate()
      : order.created_at instanceof Date
        ? order.created_at
        : new Date(order.created_at || Date.now());
  return {
    id: orderId,
    customer_id: order.customer_id,
    customer_name: order.customer_name || "",
    customer_phone: order.customer_phone || "",
    delivery_address: order.delivery_address || "",
    delivery_sub_address: order.delivery_sub_address || "",
    status: order.status || "pending",
    order_type: order.order_type || "delivery",
    order_source: order.order_source || "app",
    payment_method: order.payment_method || null,
    payment_status: order.payment_status || "unpaid",
    items: Array.isArray(order.items) ? order.items : [],
    item_total: Number(order.item_total) || 0,
    coupon_discount: Number(order.coupon_discount) || 0,
    coupon_code: order.coupon_code || null,
    offer_id: order.offer_id || null,
    reward_points_used: Number(order.reward_points_used) || 0,
    reward_discount: Number(order.reward_discount) || 0,
    reward_points_earned: Number(order.reward_points_earned) || 0,
    reward_points_refunded: Number(order.reward_points_refunded) || 0,
    reward_points_reversed: Number(order.reward_points_reversed) || 0,
    delivery_fee: Number(order.delivery_fee) || 0,
    taxes: Number(order.taxes) || 0,
    gst_percent: Number(order.gst_percent) || 0,
    late_night_fee: Number(order.late_night_fee) || 0,
    long_distance_fee: Number(order.long_distance_fee) || 0,
    total: Number(order.total) || 0,
    created_at: createdAt.toISOString(),
  };
}

async function findExistingOrderForRequest(requestRef, uid, requestHash) {
  const requestSnapshot = await requestRef.get();
  if (!requestSnapshot.exists) return null;

  const request = requestSnapshot.data() || {};
  if (request.user_id !== uid || request.payload_hash !== requestHash) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "This order request key has already been used with different details."
    );
  }

  const orderId = String(request.order_id || "");
  if (!orderId) {
    throw new functions.https.HttpsError(
      "internal",
      "The saved order request is incomplete."
    );
  }
  const orderSnapshot = await db.collection("orders").doc(orderId).get();
  if (!orderSnapshot.exists || orderSnapshot.get("customer_id") !== uid) {
    throw new functions.https.HttpsError(
      "internal",
      "The saved order could not be found."
    );
  }
  return toOrderResponse(orderId, orderSnapshot.data() || {});
}

// ---------------------------------------------------------------------------
// Main callable
// ---------------------------------------------------------------------------

// APP: USER APP — customer checkout order creation.
exports.createUserOrder = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    // 1. Auth required
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in to place an order."
      );
    }

    const uid = context.auth.uid;
    const idempotencyKey = getIdempotencyKey((data || {}).idempotency_key);
    if (!Object.prototype.hasOwnProperty.call(data || {}, "idempotency_key")) {
      functions.logger.warn(
        "createUserOrder called without a client idempotency key.",
        { uid }
      );
    }
    const requestHash = createOrderRequestHash(data);
    const idempotencyRef = db
      .collection("order_idempotency")
      .doc(orderRequestDocumentId(uid, idempotencyKey));
    const existingOrder = await findExistingOrderForRequest(
      idempotencyRef,
      uid,
      requestHash
    );
    if (existingOrder) return existingOrder;

    // Redemption limits and earning bands use the existing server policy;
    // the stored reward configuration can disable rewards.
    const storedRewardConfiguration =
      await readStoredRewardConfiguration();
    const activeRewardConfig = {
      enabled:
        storedRewardConfiguration == null
          ? rewardConfig.enabled !== false
          : storedRewardConfiguration.enabled === true,
      redeem: {
        pointsToRupee: Number(rewardConfig.redeem?.pointsToRupee) || 1,
        minPoints: Number(rewardConfig.redeem?.minPoints) || 1,
        maxPointsPerOrder:
          Number(rewardConfig.redeem?.maxPointsPerOrder) || 100,
      },
    };
    const {
      items = [],
      coupon_code = null,
      offer_id = null,
      reward_points_to_use = 0,
      delivery_address = "",
      delivery_sub_address = "",
      payment_method = "",
      customer_name = "",
      customer_phone = "",
    } = data || {};

    const requestedRewardPoints = Math.max(
      0,
      Math.floor(Number(reward_points_to_use) || 0)
    );

    // Reject any client attempt to push prices / totals
    const forbiddenKeys = [
      "item_total",
      "coupon_discount",
      "discount",
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
    ];
    for (const key of forbiddenKeys) {
      if (Object.prototype.hasOwnProperty.call(data || {}, key)) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          `Client is not allowed to send "${key}". All prices are calculated server-side.`
        );
      }
    }

    if (!Array.isArray(items) || items.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Order must contain at least one item."
      );
    }

    // 2. Fee settings (server-owned)
    const feesSnap = await db.collection("settings").doc("fees").get();
    const fees = feesSnap.exists ? feesSnap.data() : {};

    // GST is ALWAYS applied (no toggle).
    const gstPercent = Number(fees.gst_percent) || 0;
    const deliveryFeeBase = Number(fees.delivery_fee) || 0;
    const lateNightFeeValue = Number(fees.late_night_fee) || 0;
    const lateNightStart = fees.late_night_start || "22:00";
    const lateNightEnd = fees.late_night_end || "06:00";
    const freeDeliveryAbove = Number(fees.free_delivery_above) || 0;
    const longDistanceFeeValue = Number(fees.long_distance_fee) || 0;

    // Master switch + individual toggles for non-GST fees.
    let masterFeesOn = fees.fees_enabled !== false;
    let lateNightDeliveryOn = fees.late_night_delivery !== false;
    let longDistanceDeliveryOn = fees.long_distance_delivery !== false;
    if (fees.fees_enabled === undefined) {
      for (const id of ["restaurant", "config", "main", "general"]) {
        const s = await db.collection("settings").doc(id).get();
        if (s.exists) {
          const d = s.data() || {};
          if (d.fees_enabled !== undefined) masterFeesOn = d.fees_enabled !== false;
          if (d.late_night_delivery !== undefined) {
            lateNightDeliveryOn = d.late_night_delivery !== false;
          }
          if (d.long_distance_delivery !== undefined) {
            longDistanceDeliveryOn = d.long_distance_delivery !== false;
          }
          break;
        }
      }
    }

    // Customer app: long distance only when client sends the flag (amount still server-owned).
    const applyLongDistanceFee = !!(data && data.apply_long_distance_fee);

    // 3. Build order lines with authoritative server prices
    let itemTotal = 0;
    const orderItems = [];
    const productCategories = new Map();

    for (const line of items) {
      const productId = (line.product_id || line.menu_item_id || "")
        .toString()
        .trim();
      const quantity = Number(line.quantity) || 0;
      const size = line.size || line.selected_size || null;
      const notes = (line.notes || "").toString().trim() || null;

      if (!productId || quantity <= 0) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Every item must have a valid product_id and quantity > 0."
        );
      }

      const productSnap = await db.collection("menu_items").doc(productId).get();
      if (!productSnap.exists) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          `Product ${productId} not found.`
        );
      }

      const product = productSnap.data() || {};
      productCategories.set(productId, {
        id: (
          product.primary_category_id ||
          product.primaryCategoryId ||
          ""
        )
          .toString()
          .trim(),
        name: (product.category || "").toString().trim(),
      });

      // Support both field names used across admin / legacy data
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
        product_id: productId, // required for item-scoped offers
        name: product.name || "",
        quantity,
        price: unitPrice, // server price only
        image: product.image || product.image_url || "",
        size: size || null,
        notes,
        spice_level: line.spice_level || line.spiceLevel || null,
        add_ons: Array.isArray(line.add_ons || line.addOns)
          ? line.add_ons || line.addOns
          : [],
        // for subcategory-scoped offers
        sub_category_id: (
          product.sub_category_id ||
          product.subCategoryId ||
          ""
        )
          .toString()
          .trim(),
        sub_category: (
          product.sub_category ||
          product.subCategory ||
          product.subcategory ||
          ""
        )
          .toString()
          .trim(),
      });
    }

    // 4. Discount — Coupon OR Offer, never both. Fully server-validated.
    let couponDiscount = 0;
    let appliedCouponCode = null;
    let appliedOfferId = null;
    let couponRef = null;
    let offerRef = null;
    let discountEligibleProductIds = null;

    const now = new Date();

    // ---- Coupon path ----
    if (coupon_code && typeof coupon_code === "string" && coupon_code.trim()) {
      const code = coupon_code.trim().toUpperCase();

      const couponQuery = await db
        .collection("coupons")
        .where("code", "==", code)
        .limit(1)
        .get();

      if (couponQuery.empty) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Invalid or expired coupon code."
        );
      }

      const couponDoc = couponQuery.docs[0];
      const coupon = couponDoc.data() || {};
      couponRef = couponDoc.ref;

      // Status
      const status = (coupon.status || "active").toString().toLowerCase();
      if (status !== "active") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This coupon is not active."
        );
      }

      // Date window
      const start = toDate(coupon.start_date || coupon.startDate);
      const end = toDate(coupon.end_date || coupon.endDate);
      if (start && now < start) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This coupon is not active yet."
        );
      }
      if (end && now > end) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This coupon has expired."
        );
      }

      // Global usage limit (checked again inside transaction)
      const usageLimit =
        coupon.usage_limit != null
          ? Number(coupon.usage_limit)
          : coupon.usageLimit != null
            ? Number(coupon.usageLimit)
            : null;
      const usageCount =
        Number(coupon.usage_count ?? coupon.usageCount ?? 0) || 0;

      if (usageLimit != null && usageLimit > 0 && usageCount >= usageLimit) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This coupon has reached its usage limit."
        );
      }

      const categoryValues = [
        coupon.applicable_categories,
        coupon.applicableCategories,
        coupon.applicable_category_ids,
        coupon.applicableCategoryIds,
        coupon.applicable_category_id,
        coupon.applicableCategoryId,
        coupon.applicable_category,
        coupon.applicableCategory,
        coupon.category_id,
        coupon.categoryId,
      ].flatMap((value) =>
        Array.isArray(value) ? value : value == null ? [] : [value]
      );
      const categoryScopes = [
        ...new Set(
          categoryValues.flatMap((category) => {
            if (typeof category === "string") {
              return [category.trim()].filter(Boolean);
            }
            if (category && typeof category === "object") {
              return [
                category.id ||
                  category.category_id ||
                  category.categoryId ||
                  category.value,
                category.name || category.category_name,
              ]
                .filter((scope) => typeof scope === "string")
                .map((scope) => scope.trim())
                .filter(Boolean);
            }
            return [];
          })
        ),
      ];
      const applicableSubCategoryId = (
        coupon.applicable_sub_category_id ||
        coupon.applicableSubCategoryId ||
        ""
      )
        .toString()
        .trim();
      const applicableItemId = (
        coupon.applicable_item_id ||
        coupon.applicableItemId ||
        ""
      )
        .toString()
        .trim();

      const eligibleItems = orderItems.filter((item) => {
          if (
            categoryScopes.length > 0 &&
            !categoryScopes.some((scope) => {
              const category = productCategories.get(item.product_id);
              return category?.id === scope ||
                category?.name.toLowerCase() === scope.toLowerCase();
            })
          ) {
            return false;
          }
          if (
            applicableSubCategoryId &&
            item.sub_category_id !== applicableSubCategoryId &&
            item.sub_category.toLowerCase() !==
              applicableSubCategoryId.toLowerCase()
          ) {
            return false;
          }
          if (applicableItemId && item.product_id !== applicableItemId) {
            return false;
          }
          return true;
        });
      discountEligibleProductIds = new Set(
        eligibleItems.map((item) => item.product_id)
      );
      const eligibleSubtotal = eligibleItems.reduce(
        (sum, item) => sum + item.price * item.quantity,
        0
      );

      if (
        (categoryScopes.length > 0 ||
          applicableSubCategoryId ||
          applicableItemId) &&
        eligibleSubtotal <= 0
      ) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This coupon does not apply to any items in your cart."
        );
      }

      // Minimum order value is checked against the eligible subtotal.
      const minOrder =
        Number(coupon.min_order_value ?? coupon.minOrderValue ?? 0) || 0;
      if (eligibleSubtotal < minOrder) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          `Minimum order value for this coupon is ₹${minOrder}.`
        );
      }

      // Discount calculation (server only)
      const discountType = (
        coupon.discount_type ||
        coupon.discountType ||
        "flat"
      )
        .toString()
        .toLowerCase();
      const discountValue = Number(
        coupon.discount_value ?? coupon.discountValue ?? 0
      );
      const maxDiscount =
        coupon.max_discount != null
          ? Number(coupon.max_discount)
          : coupon.maxDiscount != null
            ? Number(coupon.maxDiscount)
            : null;

      couponDiscount = calculateDiscount(
        discountType,
        discountValue,
        maxDiscount,
        eligibleSubtotal
      );
      appliedCouponCode = code;
    }

    // ---- Offer path (only when no coupon was applied) ----
    else if (offer_id && typeof offer_id === "string" && offer_id.trim()) {
      const offerId = offer_id.trim();
      const offerSnap = await db.collection("offers").doc(offerId).get();

      if (!offerSnap.exists) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Offer not found."
        );
      }

      const offer = offerSnap.data() || {};
      offerRef = offerSnap.ref;

      const status = (offer.status || "active").toString().toLowerCase();
      if (status !== "active") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This offer is not active."
        );
      }

      const start = toDate(offer.start_date || offer.startDate);
      const end = toDate(offer.end_date || offer.endDate);
      if (start && now < start) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This offer is not active yet."
        );
      }
      if (end && now > end) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This offer has expired."
        );
      }

      // Usage limit on offers
      const offerUsageLimit =
        offer.usage_limit != null
          ? Number(offer.usage_limit)
          : offer.usageLimit != null
            ? Number(offer.usageLimit)
            : null;
      const offerUsageCount =
        Number(offer.usage_count ?? offer.usageCount ?? 0) || 0;
      if (
        offerUsageLimit != null &&
        offerUsageLimit > 0 &&
        offerUsageCount >= offerUsageLimit
      ) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This offer has reached its usage limit."
        );
      }

      // Eligible subtotal (item / subcategory scoped)
      let eligibleItems = orderItems;

      const applicableItemId = (
        offer.applicable_item_id ||
        offer.applicableItemId ||
        ""
      )
        .toString()
        .trim();
      const applicableSubCategoryId = (
        offer.applicable_sub_category_id ||
        offer.applicableSubCategoryId ||
        ""
      )
        .toString()
        .trim();

      if (applicableItemId) {
        eligibleItems = orderItems.filter(
          (item) => (item.product_id || "") === applicableItemId
        );
      } else if (applicableSubCategoryId) {
        const scope = applicableSubCategoryId.toLowerCase();
        eligibleItems = orderItems.filter((item) => {
            const id = (item.sub_category_id || "").toString().trim();
            const name = (item.sub_category || "").toString().trim().toLowerCase();
            return id === applicableSubCategoryId || name === scope;
          });
      }
      discountEligibleProductIds = new Set(
        eligibleItems.map((item) => item.product_id)
      );
      const eligibleSubtotal = eligibleItems.reduce(
        (sum, item) => sum + item.price * item.quantity,
        0
      );

      if (
        (applicableItemId || applicableSubCategoryId) &&
        eligibleSubtotal <= 0
      ) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This offer does not apply to any items in your cart."
        );
      }

      const minOrder =
        Number(offer.min_order_value ?? offer.minOrderValue ?? 0) || 0;
      // Min order is checked against the eligible scope when scoped
      if (eligibleSubtotal < minOrder) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          `Minimum order value for this offer is ₹${minOrder}.`
        );
      }

      const discountType = (
        offer.discount_type ||
        offer.discountType ||
        "flat"
      )
        .toString()
        .toLowerCase();
      const discountValue = Number(
        offer.discount_value ?? offer.discountValue ?? 0
      );
      const maxDiscount =
        offer.max_discount != null
          ? Number(offer.max_discount)
          : offer.maxDiscount != null
            ? Number(offer.maxDiscount)
            : null;

      couponDiscount = calculateDiscount(
        discountType,
        discountValue,
        maxDiscount,
        eligibleSubtotal
      );
      appliedOfferId = offerId;
    }

    // 5. Fees (server-owned — amounts only from settings/fees)
    // GST always applies.
    // Late-night: settings toggle + time window.
    // Long-distance: client flag only (optional at checkout).
    // Delivery fee: always for delivery orders (customer app is delivery).
    const isLate = isLateNight(now, lateNightStart, lateNightEnd);
    const lateNightFee =
      lateNightDeliveryOn && isLate ? lateNightFeeValue : 0;
    const longDistanceFee = applyLongDistanceFee
      ? longDistanceFeeValue
      : 0;

    let finalDeliveryFee = deliveryFeeBase;
    if (freeDeliveryAbove > 0 && itemTotal >= freeDeliveryAbove) {
      finalDeliveryFee = 0;
    }

    const afterCoupon = Math.max(itemTotal - couponDiscount, 0);
    const orderItemsWithRewardSubtotals = allocateRewardSubtotals(
      orderItems,
      couponDiscount,
      discountEligibleProductIds
    );
    const potentialRewardPointsEarned = activeRewardConfig.enabled
      ? computeEarnPoints({
        item_total: itemTotal,
        coupon_discount: couponDiscount,
      })
      : 0;

    // 6. Atomic write: order, cart consumption, reward ledger, wallet,
    // coupon/offer usage, and request idempotency record.
    let orderRef;
    const walletRef = db.collection("reward_wallets").doc(uid);
    const cartCollection = db.collection("users").doc(uid).collection("cart");

    const baseOrderFields = {
      customer_id: uid,
      customer_name: (customer_name || "Customer").toString().trim(),
      customer_phone: (customer_phone || "").toString().trim(),
      delivery_address: (delivery_address || "").toString().trim(),
      delivery_sub_address: (delivery_sub_address || "").toString().trim(),
      status: "pending",
      order_type: "delivery",
      order_source: "app",
      payment_method: (payment_method || "").toString().toLowerCase() || null,
      payment_status: "unpaid",
      items: orderItemsWithRewardSubtotals,
      item_total: itemTotal,
      coupon_discount: couponDiscount,
      coupon_code: appliedCouponCode,
      offer_id: appliedOfferId,
      reward_points_refunded: 0,
      reward_points_reversed: 0,
      delivery_fee: finalDeliveryFee,
      late_night_fee: lateNightFee,
      long_distance_fee: longDistanceFee,
      gst_percent: gstPercent,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    const commitOrderTransaction = () =>
      db.runTransaction(async (transaction) => {
        const requestSnapshot = await transaction.get(idempotencyRef);
        if (requestSnapshot.exists) {
          const request = requestSnapshot.data() || {};
          if (
            request.user_id !== uid ||
            request.payload_hash !== requestHash
          ) {
            throw new functions.https.HttpsError(
              "failed-precondition",
              "This order request key has already been used with different details."
            );
          }
          const savedOrderId = String(request.order_id || "");
          const savedOrderSnapshot = savedOrderId
            ? await transaction.get(
              db.collection("orders").doc(savedOrderId)
            )
            : null;
          if (
            !savedOrderSnapshot ||
            !savedOrderSnapshot.exists ||
            savedOrderSnapshot.get("customer_id") !== uid
          ) {
            throw new functions.https.HttpsError(
              "internal",
              "The saved order could not be found."
            );
          }
          return {
            orderId: savedOrderId,
            response: toOrderResponse(
              savedOrderId,
              savedOrderSnapshot.data() || {}
            ),
          };
        }

        const existingOrder = await transaction.get(orderRef);
        if (existingOrder.exists) {
          const collisionError = new Error("Generated order ID already exists.");
          collisionError.code = "ORDER_ID_COLLISION";
          throw collisionError;
        }

        const walletSnapshot =
          activeRewardConfig.enabled &&
          (requestedRewardPoints > 0 || potentialRewardPointsEarned > 0)
            ? await transaction.get(walletRef)
            : null;
        const couponSnapshot = couponRef
          ? await transaction.get(couponRef)
          : null;
        const offerSnapshot = offerRef
          ? await transaction.get(offerRef)
          : null;
        const cartSnapshot = await transaction.get(cartCollection);
        const cartConsumption = planCartConsumption(
          cartSnapshot.docs,
          orderItems
        );

        // All reads are complete before the transaction writes begin.
        if (couponRef) {
          if (!couponSnapshot.exists) {
            throw new functions.https.HttpsError(
              "failed-precondition",
              "Coupon no longer exists."
            );
          }
          const coupon = couponSnapshot.data() || {};
          const usageLimit =
            coupon.usage_limit != null
              ? Number(coupon.usage_limit)
              : coupon.usageLimit != null
                ? Number(coupon.usageLimit)
                : null;
          const usageCount =
            Number(coupon.usage_count ?? coupon.usageCount ?? 0) || 0;
          if (usageLimit != null && usageLimit > 0 && usageCount >= usageLimit) {
            throw new functions.https.HttpsError(
              "failed-precondition",
              "This coupon has reached its usage limit."
            );
          }
          if ((coupon.status || "active").toString().toLowerCase() !== "active") {
            throw new functions.https.HttpsError(
              "failed-precondition",
              "This coupon is no longer active."
            );
          }
        }

        if (offerRef) {
          if (!offerSnapshot.exists) {
            throw new functions.https.HttpsError(
              "failed-precondition",
              "Offer no longer exists."
            );
          }
          const offer = offerSnapshot.data() || {};
          const usageLimit =
            offer.usage_limit != null
              ? Number(offer.usage_limit)
              : offer.usageLimit != null
                ? Number(offer.usageLimit)
                : null;
          const usageCount =
            Number(offer.usage_count ?? offer.usageCount ?? 0) || 0;
          if (usageLimit != null && usageLimit > 0 && usageCount >= usageLimit) {
            throw new functions.https.HttpsError(
              "failed-precondition",
              "This offer has reached its usage limit."
            );
          }
          if ((offer.status || "active").toString().toLowerCase() !== "active") {
            throw new functions.https.HttpsError(
              "failed-precondition",
              "This offer is no longer active."
            );
          }
        }

        const wallet = walletSnapshot && walletSnapshot.exists
          ? walletSnapshot.data() || {}
          : {};
        const rawBalance = Number(wallet.balance);
        const balance = Number.isFinite(rawBalance) ? Math.trunc(rawBalance) : 0;
        let rewardPointsUsed = 0;
        let rewardDiscount = 0;
        if (requestedRewardPoints > 0 && activeRewardConfig.enabled) {
          const rate =
            Number(activeRewardConfig.redeem.pointsToRupee) || 1;
          const minPts = Number(activeRewardConfig.redeem.minPoints) || 1;
          const maxPerOrder =
            Number(activeRewardConfig.redeem.maxPointsPerOrder) || 100;
          const maxBySubtotal = Math.floor(afterCoupon / rate);
          let allowed = Math.min(
            requestedRewardPoints,
            Math.max(0, balance),
            maxPerOrder,
            maxBySubtotal
          );
          if (allowed > 0 && allowed < minPts) allowed = 0;
          rewardPointsUsed = Math.max(0, allowed);
          rewardDiscount = rewardPointsUsed * rate;
        }

        const rewardPointsEarned = rewardPointsUsed > 0
          ? 0
          : potentialRewardPointsEarned;
        const taxableAmount = Math.max(afterCoupon - rewardDiscount, 0);
        const taxes = (taxableAmount * gstPercent) / 100;
        const total =
          taxableAmount +
          taxes +
          finalDeliveryFee +
          lateNightFee +
          longDistanceFee;
        const newBalance =
          balance - rewardPointsUsed + rewardPointsEarned;
        const now = admin.firestore.FieldValue.serverTimestamp();

        for (const item of cartConsumption) {
          const cartItemRef = cartCollection.doc(item.documentId);
          if (item.remainingQuantity === 0) {
            transaction.delete(cartItemRef);
          } else {
            transaction.update(cartItemRef, {
              quantity: item.remainingQuantity,
              updated_at: now,
            });
          }
        }

        if (couponRef) {
          const coupon = couponSnapshot.data() || {};
          const usageCount =
            Number(coupon.usage_count ?? coupon.usageCount ?? 0) || 0;
          transaction.update(couponRef, { usage_count: usageCount + 1 });
        }
        if (offerRef) {
          const offer = offerSnapshot.data() || {};
          const usageCount =
            Number(offer.usage_count ?? offer.usageCount ?? 0) || 0;
          transaction.update(offerRef, { usage_count: usageCount + 1 });
        }

        if (rewardPointsUsed > 0 || rewardPointsEarned > 0) {
          transaction.set(
            walletRef,
            {
              user_id: uid,
              balance: newBalance,
              total_earned:
                (Number(wallet.total_earned) || 0) + rewardPointsEarned,
              total_redeemed:
                (Number(wallet.total_redeemed) || 0) + rewardPointsUsed,
              updated_at: now,
            },
            { merge: true }
          );
        }

        if (rewardPointsUsed > 0) {
          transaction.create(
            db.collection("reward_ledger").doc(`redeem_${orderRef.id}`),
            {
              type: "redeem",
              order_id: orderRef.id,
              user_id: uid,
              points: rewardPointsUsed,
              discount_inr: rewardDiscount,
              balance_after: newBalance,
              created_at: now,
            }
          );
        }
        if (rewardPointsEarned > 0) {
          transaction.create(
            db.collection("reward_ledger").doc(`earn_${orderRef.id}`),
            {
              type: "earn",
              order_id: orderRef.id,
              user_id: uid,
              points: rewardPointsEarned,
              order_total: Math.max(itemTotal - couponDiscount, 0),
              balance_after: newBalance,
              awarded_by: "order_placement",
              order_source: "app",
              created_at: now,
            }
          );
        }

        transaction.create(orderRef, {
          ...baseOrderFields,
          taxes,
          total,
          reward_points_used: rewardPointsUsed,
          reward_discount: rewardDiscount,
          reward_points_earned: rewardPointsEarned,
          reward_awarded_at: rewardPointsEarned > 0 ? now : null,
        });
        transaction.create(idempotencyRef, {
          user_id: uid,
          payload_hash: requestHash,
          order_id: orderRef.id,
          created_at: now,
        });
        return { orderId: orderRef.id };
      });

    let committedOrderId;
    for (let attempt = 0; attempt < 5; attempt++) {
      orderRef = db.collection("orders").doc(generateOrderId());

      try {
        const result = await commitOrderTransaction();
        if (result.response) return result.response;
        committedOrderId = result.orderId;
        break;
      } catch (error) {
        const isIdCollision =
          error.code === "ORDER_ID_COLLISION" ||
          error.code === 6 ||
          error.code === "already-exists";
        if (!isIdCollision || attempt === 4) throw error;
      }
    }

    const savedOrder = await db.collection("orders").doc(committedOrderId).get();
    return toOrderResponse(committedOrderId, savedOrder.data() || {});
  });

exports._private = {
  allocateRewardSubtotals,
  planCartConsumption,
  createOrderRequestHash,
  orderRequestDocumentId,
  getIdempotencyKey,
  validateIdempotencyKey,
};
