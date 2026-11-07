/**
 * validateCoupon.js — Server-side coupon preview for the user app.
 *
 * Purpose:
 *   Give the checkout UI a trusted preview of whether a code is valid
 *   and what the discount would be for a given cart subtotal.
 *
 * Security:
 *   - This function does NOT create orders or increment usage.
 *   - Final enforcement still happens inside createUserOrder.
 *   - Client must still only send product_ids + quantities to placeOrder;
 *     it must never send the discount amount returned here as the final total.
 */

"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.firestore();

function toDate(value) {
  if (!value) return null;
  if (value.toDate && typeof value.toDate === "function") return value.toDate();
  if (value instanceof Date) return value;
  const parsed = Date.parse(value);
  return isNaN(parsed) ? null : new Date(parsed);
}

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
  return Math.min(Math.max(discount, 0), eligibleAmount);
}

function getPriceForSize(product, sizeName) {
  if (!sizeName || !Array.isArray(product.sizes) || product.sizes.length === 0) {
    return Number(product.price) || 0;
  }
  const found = product.sizes.find(
    (size) =>
      size.name &&
      size.name.toString().trim() === sizeName.toString().trim()
  );
  return found ? Number(found.price) || 0 : Number(product.price) || 0;
}

/**
 * data: {
 *   code: string,          // required
 *   order_total: number,   // legacy cart subtotal; item prices are resolved server-side when items are provided
 *   items: Array<{ product_id: string, quantity: number, size?: string }>
 * }
 *
 * Returns:
 * {
 *   valid: boolean,
 *   message?: string,
 *   code?: string,
 *   title?: string,
 *   discount_type?: string,
 *   discount_value?: number,
 *   max_discount?: number | null,
 *   min_order_value?: number | null,
 *   discount_amount?: number,   // calculated for the given order_total
 *   usage_remaining?: number | null,
 * }
 */
// APP: USER APP — coupon preview for customer checkout.
exports.validateCoupon = functions
  .region("us-central1")
  .https.onCall(async (data) => {
    // Coupon previews are public; order creation still requires authentication.
    const codeRaw = (data && data.code ? String(data.code) : "").trim();
    if (!codeRaw) {
      return { valid: false, message: "Enter a coupon code." };
    }
    if (codeRaw.length > 100) {
      return { valid: false, message: "Invalid coupon code." };
    }

    const code = codeRaw.toUpperCase();
    const orderTotal = Number(data.order_total);
    if (!Number.isFinite(orderTotal) || orderTotal < 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The order total is invalid."
      );
    }

    const couponQuery = await db
      .collection("coupons")
      .where("code", "==", code)
      .limit(1)
      .get();

    if (couponQuery.empty) {
      return { valid: false, message: "Invalid or expired coupon code." };
    }

    const couponDoc = couponQuery.docs[0];
    const coupon = couponDoc.data() || {};
    const now = new Date();

    // Status
    const status = (coupon.status || "active").toString().toLowerCase();
    if (status !== "active") {
      return { valid: false, message: "This coupon is not active." };
    }

    // Dates
    const start = toDate(coupon.start_date || coupon.startDate);
    const end = toDate(coupon.end_date || coupon.endDate);
    if (!start || !end) {
      return { valid: false, message: "This coupon is not active." };
    }
    if (start && now < start) {
      return { valid: false, message: "This coupon is not active yet." };
    }
    if (end && now > end) {
      return { valid: false, message: "This coupon has expired." };
    }

    // Usage limit
    const usageLimit =
      coupon.usage_limit != null
        ? Number(coupon.usage_limit)
        : coupon.usageLimit != null
          ? Number(coupon.usageLimit)
          : null;
    const usageCount =
      Number(coupon.usage_count ?? coupon.usageCount ?? 0) || 0;

    if (usageLimit != null && usageLimit > 0 && usageCount >= usageLimit) {
      return {
        valid: false,
        message: "This coupon has reached its usage limit.",
      };
    }

    const minOrder =
      Number(coupon.min_order_value ?? coupon.minOrderValue ?? 0) || 0;

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
    const hasItemScope =
      categoryScopes.length > 0 ||
      Boolean(applicableSubCategoryId) ||
      Boolean(applicableItemId);

    let eligibleAmount = orderTotal;
    if (Array.isArray(data.items)) {
      if (data.items.length === 0) {
        return { valid: false, message: "Your cart is empty." };
      }

      const cartItems = await Promise.all(
        data.items.map(async (line) => {
          const productId = (
            line && (line.product_id || line.menu_item_id)
              ? String(line.product_id || line.menu_item_id)
              : ""
          ).trim();
          const quantity = Number(line && line.quantity);
          if (!productId || !Number.isFinite(quantity) || quantity <= 0) {
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
              "An item in your cart is no longer available."
            );
          }

          const product = productSnap.data() || {};
          const categoryId = (
            product.primary_category_id ||
            product.primaryCategoryId ||
            ""
          )
            .toString()
            .trim();
          const categoryName = (product.category || "").toString().trim();
          const subCategoryId = (
            product.sub_category_id ||
            product.subCategoryId ||
            ""
          )
            .toString()
            .trim();
          const subCategory = (
            product.sub_category ||
            product.subCategory ||
            product.subcategory ||
            ""
          )
            .toString()
            .trim();
          const productPrice = getPriceForSize(
            product,
            line.size || line.selected_size
          );
          const matchesCategory =
            categoryScopes.length === 0 ||
            categoryScopes.some(
              (scope) =>
                categoryId === scope ||
                categoryName.toLowerCase() === scope.toLowerCase()
            );
          const matchesSubCategory =
            !applicableSubCategoryId ||
            subCategoryId === applicableSubCategoryId ||
            subCategory.toLowerCase() ===
              applicableSubCategoryId.toLowerCase();
          const matchesItem =
            !applicableItemId || productId === applicableItemId;

          return {
            subtotal: productPrice * quantity,
            eligible:
              matchesCategory && matchesSubCategory && matchesItem,
          };
        })
      );

      const cartSubtotal = cartItems.reduce(
        (sum, item) => sum + item.subtotal,
        0
      );
      eligibleAmount = cartItems
        .filter((item) => item.eligible)
        .reduce((sum, item) => sum + item.subtotal, 0);

      if (!Number.isFinite(cartSubtotal) || cartSubtotal <= 0) {
        return { valid: false, message: "Your cart is empty." };
      }
      if (hasItemScope && eligibleAmount <= 0) {
        return {
          valid: false,
          message: "This coupon does not apply to any items in your cart.",
        };
      }
    } else if (hasItemScope) {
      return {
        valid: false,
        message: "Add eligible items to your cart to use this coupon.",
      };
    }

    // Minimum order and preview discount use the same eligible subtotal as
    // createUserOrder. The final amount is still recalculated at checkout.
    if (eligibleAmount < minOrder) {
      return {
        valid: false,
        message: `Minimum order value for this coupon is ₹${minOrder}.`,
        min_order_value: minOrder,
      };
    }

    const discountAmount =
      eligibleAmount > 0
        ? calculateDiscount(
            discountType,
            discountValue,
            maxDiscount,
            eligibleAmount
          )
        : 0;

    const usageRemaining =
      usageLimit != null && usageLimit > 0
        ? Math.max(usageLimit - usageCount, 0)
        : null;

    return {
      valid: true,
      code,
      title: (coupon.title || coupon.name || code).toString(),
      discount_type: discountType.includes("percent") ? "percentage" : "flat",
      discount_value: discountValue,
      max_discount: maxDiscount,
      min_order_value: minOrder > 0 ? minOrder : null,
      applicable_categories: categoryScopes,
      applicable_sub_category_id: applicableSubCategoryId || null,
      applicable_item_id: applicableItemId || null,
      discount_amount: discountAmount,
      usage_remaining: usageRemaining,
      message: "Coupon is valid.",
    };
  });
