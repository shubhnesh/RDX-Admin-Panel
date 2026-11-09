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

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const rewardConfig = require("../rewards/config");
const { readStoredRewardConfiguration } = require("../rewards/configuration");
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
    const storedRewardConfiguration =
      await readStoredRewardConfiguration();
    const activeRewardConfig = storedRewardConfiguration
      ? {
          enabled: storedRewardConfiguration.enabled === true,
          redeem: {
            pointsToRupee:
              1 /
              Math.max(
                1,
                Number(
                  storedRewardConfiguration.redemption?.pointsPerRupee
                ) || 1
              ),
            minPoints:
              Number(
                storedRewardConfiguration.redemption?.minimumPoints
              ) || 1,
            maxOrderPercent:
              Number(
                storedRewardConfiguration.redemption?.maximumOrderPercentage
              ) || 0,
          },
        }
      : rewardConfig;
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

    // Reward points discount is finalized inside the transaction after reading wallet.
    let rewardPointsUsed = 0;
    let rewardDiscount = 0;

    const afterCoupon = Math.max(itemTotal - couponDiscount, 0);
    const orderItemsWithRewardSubtotals = allocateRewardSubtotals(
      orderItems,
      couponDiscount,
      discountEligibleProductIds
    );

    // 6. Atomic write: order + coupon/offer usage + wallet debit
    let orderRef;
    const walletRef = db.collection("reward_wallets").doc(uid);

    let taxes = 0;
    let total = 0;

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
      delivery_fee: finalDeliveryFee,
      late_night_fee: lateNightFee,
      long_distance_fee: longDistanceFee,
      gst_percent: gstPercent,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    const commitOrderTransaction = () => db.runTransaction(async (transaction) => {
      const existingOrder = await transaction.get(orderRef);
      if (existingOrder.exists) {
        const collisionError = new Error("Generated order ID already exists.");
        collisionError.code = "ORDER_ID_COLLISION";
        throw collisionError;
      }

      // --- Reward points redemption (server wallet only) ---
      if (requestedRewardPoints > 0 && activeRewardConfig.enabled) {
        const walletSnap = await transaction.get(walletRef);
        const wallet = walletSnap.exists ? walletSnap.data() || {} : {};
        const balance = Math.max(0, Number(wallet.balance) || 0);

        const maxByPercent = Math.floor(
          (afterCoupon *
            (Number(activeRewardConfig.redeem.maxOrderPercent) || 0)) /
            100 /
            (Number(activeRewardConfig.redeem.pointsToRupee) || 1)
        );
        const maxByBalance = balance;
        const minPts = Number(activeRewardConfig.redeem.minPoints) || 1;

        let allowed = Math.min(
          requestedRewardPoints,
          maxByBalance,
          maxByPercent,
          Math.floor(
            afterCoupon /
              (Number(activeRewardConfig.redeem.pointsToRupee) || 1)
          ) // cannot discount more than remaining subtotal
        );

        if (allowed > 0 && allowed < minPts) {
          allowed = 0;
        }

        rewardPointsUsed = Math.max(0, allowed);
        const rate =
          Number(activeRewardConfig.redeem.pointsToRupee) || 1;
        rewardDiscount = rewardPointsUsed * rate;

        if (rewardPointsUsed > 0) {
          const newBalance = balance - rewardPointsUsed;
          const totalRedeemed =
            (Number(wallet.total_redeemed) || 0) + rewardPointsUsed;

          transaction.set(
            walletRef,
            {
              user_id: uid,
              balance: newBalance,
              total_earned: Number(wallet.total_earned) || 0,
              total_redeemed: totalRedeemed,
              updated_at: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
          );

          const ledgerRef = db
            .collection("reward_ledger")
            .doc(`redeem_${orderRef.id}`);
          transaction.set(ledgerRef, {
            type: "redeem",
            order_id: orderRef.id,
            user_id: uid,
            points: rewardPointsUsed,
            discount_inr: rewardDiscount,
            balance_after: newBalance,
            created_at: admin.firestore.FieldValue.serverTimestamp(),
          });

        }
      }

      const taxableAmount = Math.max(afterCoupon - rewardDiscount, 0);
      taxes = (taxableAmount * gstPercent) / 100;
      total =
        taxableAmount +
        taxes +
        finalDeliveryFee +
        lateNightFee +
        longDistanceFee;

      // Re-check coupon usage limit inside the transaction (prevents race)
      if (couponRef) {
        const freshCoupon = await transaction.get(couponRef);
        if (!freshCoupon.exists) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Coupon no longer exists."
          );
        }
        const cdata = freshCoupon.data() || {};
        const usageLimit =
          cdata.usage_limit != null
            ? Number(cdata.usage_limit)
            : cdata.usageLimit != null
              ? Number(cdata.usageLimit)
              : null;
        const usageCount =
          Number(cdata.usage_count ?? cdata.usageCount ?? 0) || 0;

        if (usageLimit != null && usageLimit > 0 && usageCount >= usageLimit) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "This coupon has reached its usage limit."
          );
        }

        // Status + dates re-checked lightly (status is the most important)
        const status = (cdata.status || "active").toString().toLowerCase();
        if (status !== "active") {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "This coupon is no longer active."
          );
        }

        transaction.update(couponRef, {
          usage_count: usageCount + 1,
        });

      }

      // Same for offer
      if (offerRef) {
        const freshOffer = await transaction.get(offerRef);
        if (!freshOffer.exists) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Offer no longer exists."
          );
        }
        const odata = freshOffer.data() || {};
        const usageLimit =
          odata.usage_limit != null
            ? Number(odata.usage_limit)
            : odata.usageLimit != null
              ? Number(odata.usageLimit)
              : null;
        const usageCount =
          Number(odata.usage_count ?? odata.usageCount ?? 0) || 0;

        if (usageLimit != null && usageLimit > 0 && usageCount >= usageLimit) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "This offer has reached its usage limit."
          );
        }

        const status = (odata.status || "active").toString().toLowerCase();
        if (status !== "active") {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "This offer is no longer active."
          );
        }

        transaction.update(offerRef, {
          usage_count: usageCount + 1,
        });
      }

      transaction.create(orderRef, {
        ...baseOrderFields,
        taxes,
        total,
        reward_points_used: rewardPointsUsed,
        reward_discount: rewardDiscount,
      });
    });

    for (let attempt = 0; attempt < 5; attempt++) {
      orderRef = db.collection("orders").doc(generateOrderId());
      rewardPointsUsed = 0;
      rewardDiscount = 0;
      taxes = 0;
      total = 0;

      try {
        await commitOrderTransaction();
        break;
      } catch (error) {
        const isIdCollision =
          error.code === "ORDER_ID_COLLISION" ||
          error.code === 6 ||
          error.code === "already-exists";
        if (!isIdCollision || attempt === 4) throw error;
      }
    }

    // 7. Return clean order (no internal refs)
    return {
      id: orderRef.id,
      customer_id: uid,
      customer_name: baseOrderFields.customer_name,
      customer_phone: baseOrderFields.customer_phone,
      delivery_address: baseOrderFields.delivery_address,
      delivery_sub_address: baseOrderFields.delivery_sub_address,
      status: "pending",
      order_type: "delivery",
      order_source: "app",
      payment_method: baseOrderFields.payment_method,
      payment_status: "unpaid",
      items: orderItems,
      item_total: itemTotal,
      coupon_discount: couponDiscount,
      coupon_code: appliedCouponCode,
      offer_id: appliedOfferId,
      reward_points_used: rewardPointsUsed,
      reward_discount: rewardDiscount,
      delivery_fee: finalDeliveryFee,
      taxes: taxes,
      gst_percent: gstPercent,
      late_night_fee: lateNightFee,
      long_distance_fee: longDistanceFee,
      total: total,
      created_at: new Date().toISOString(),
    };
  });

exports._private = { allocateRewardSubtotals };
