"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.firestore();

function toDate(value) {
  if (!value) return null;
  if (value.toDate && typeof value.toDate === "function") return value.toDate();
  if (value instanceof Date) return value;
  const parsed = Date.parse(value);
  return Number.isNaN(parsed) ? null : new Date(parsed);
}

function readPrice(product, sizeName) {
  if (!sizeName || !Array.isArray(product.sizes) || product.sizes.length === 0) {
    return Number(product.price) || 0;
  }
  const selectedSize = product.sizes.find(
    (size) => size.name &&
      size.name.toString().trim() === sizeName.toString().trim()
  );
  return selectedSize ? Number(selectedSize.price) || 0 : Number(product.price) || 0;
}

function calculateDiscount(offer, eligibleSubtotal) {
  if (eligibleSubtotal <= 0) return 0;
  const type = String(
    offer.discount_type || offer.discountType || "flat"
  ).toLowerCase();
  const value = Number(offer.discount_value ?? offer.discountValue ?? 0);
  const maxDiscount = offer.max_discount ?? offer.maxDiscount;
  if (!Number.isFinite(value) || value < 0) return 0;

  let discount = type.includes("percent")
    ? eligibleSubtotal * value / 100
    : value;
  if (
    type.includes("percent") &&
    maxDiscount != null &&
    maxDiscount !== ""
  ) {
    const cap = Number(maxDiscount);
    if (!Number.isFinite(cap) || cap < 0) return 0;
    discount = Math.min(discount, cap);
  }
  return Math.min(Math.max(discount, 0), eligibleSubtotal);
}

function formatAmount(amount) {
  const rounded = Math.round((amount + Number.EPSILON) * 100) / 100;
  return Number.isInteger(rounded) ? String(rounded) : rounded.toFixed(2);
}

function formatDiscount(offer) {
  const type = String(
    offer.discount_type || offer.discountType || "flat"
  ).toLowerCase();
  const value = Number(offer.discount_value ?? offer.discountValue ?? 0);
  if (!Number.isFinite(value) || value <= 0) return "";
  const formatted = formatAmount(value);
  return type.includes("percent")
    ? `${formatted}% OFF`
    : `₹${formatted} OFF`;
}

function progressForOffer(offer, lines, now) {
  const status = String(offer.status || "active").toLowerCase();
  if (status !== "active") return null;

  const start = toDate(offer.start_date || offer.startDate);
  const end = toDate(offer.end_date || offer.endDate);
  if ((start && now < start) || (end && now > end)) return null;

  const usageLimit = Number(offer.usage_limit ?? offer.usageLimit ?? 0);
  const usageCount = Number(offer.usage_count ?? offer.usageCount ?? 0);
  if (usageLimit > 0 && usageCount >= usageLimit) return null;

  const applicableItemId = String(
    offer.applicable_item_id || offer.applicableItemId || ""
  ).trim();
  const applicableSubCategoryId = String(
    offer.applicable_sub_category_id ||
      offer.applicableSubCategoryId ||
      ""
  ).trim();
  const eligibleLines = lines.filter((line) => {
    if (applicableItemId) return line.productId === applicableItemId;
    if (applicableSubCategoryId) {
      return line.subCategoryId === applicableSubCategoryId ||
        line.subCategory.toLowerCase() ===
          applicableSubCategoryId.toLowerCase();
    }
    return true;
  });
  const eligibleSubtotal = eligibleLines.reduce(
    (sum, line) => sum + line.price * line.quantity,
    0
  );
  if (eligibleSubtotal <= 0) return null;

  const minimum = Number(offer.min_order_value ?? offer.minOrderValue ?? 0);
  const threshold = Number.isFinite(minimum) && minimum > 0 ? minimum : 0;
  const remaining = Math.max(threshold - eligibleSubtotal, 0);
  const progress = threshold <= 0
    ? 1
    : Math.min(eligibleSubtotal / threshold, 1);
  const estimateSubtotal = remaining > 0 ? threshold : eligibleSubtotal;
  const discount = calculateDiscount(offer, estimateSubtotal);
  const discountLabel = formatDiscount(offer);
  if (!discountLabel || discount <= 0) return null;

  return {
    title: String(offer.title || offer.name || discountLabel).trim(),
    discountLabel,
    discount,
    remaining,
    progress,
  };
}

exports.getCartOfferProgress = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Sign in to check cart offers."
      );
    }

    const requestedItems = data?.items;
    if (
      !Array.isArray(requestedItems) ||
      requestedItems.length === 0 ||
      requestedItems.length > 50
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The cart items are invalid."
      );
    }

    const lines = await Promise.all(requestedItems.map(async (item) => {
      const productId = typeof item?.product_id === "string"
        ? item.product_id.trim()
        : "";
      const quantity = item?.quantity;
      const size = item?.size;
      if (
        !productId ||
        productId.includes("/") ||
        !Number.isInteger(quantity) ||
        quantity < 1 ||
        quantity > 99 ||
        (size != null && typeof size !== "string")
      ) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "A cart item is invalid."
        );
      }

      const productSnapshot = await db
        .collection("menu_items")
        .doc(productId)
        .get();
      if (!productSnapshot.exists) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "A cart item is no longer available."
        );
      }
      const product = productSnapshot.data() || {};
      if (product.is_available === false || product.available === false) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "A cart item is no longer available."
        );
      }

      return {
        productId,
        quantity,
        price: readPrice(product, size),
        subCategoryId: String(
          product.sub_category_id || product.subCategoryId || ""
        ).trim(),
        subCategory: String(
          product.sub_category ||
            product.subCategory ||
            product.subcategory ||
            ""
        ).trim(),
      };
    }));

    const offerSnapshot = await db.collection("offers").get();
    const now = new Date();
    const eligibleOffers = offerSnapshot.docs
      .map((document) => progressForOffer(document.data() || {}, lines, now))
      .filter(Boolean);
    const unlockedOffers = eligibleOffers
      .filter((offer) => offer.remaining <= 0)
      .sort((a, b) => b.discount - a.discount);
    const upcomingOffers = eligibleOffers
      .filter((offer) => offer.remaining > 0)
      .sort((a, b) => a.remaining - b.remaining || b.discount - a.discount);

    const unlocked = unlockedOffers[0];
    const upcoming = upcomingOffers[0];
    if (!unlocked && !upcoming) return { available: false };

    const featuredOffer = unlocked || upcoming;
    const heading = unlocked
      ? `You unlocked ₹${formatAmount(unlocked.discount)} off`
      : `Unlock ${upcoming.discountLabel}`;
    const subtitle = upcoming
      ? `Add ₹${formatAmount(upcoming.remaining)} to unlock ${upcoming.discountLabel}`
      : "Your offer is ready to use";

    return {
      available: true,
      isUnlocked: Boolean(unlocked),
      heading,
      subtitle,
      progress: featuredOffer.progress,
    };
  });
