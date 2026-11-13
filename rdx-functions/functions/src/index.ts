import { randomBytes } from "node:crypto";
import { initializeApp } from "firebase-admin/app";
import {
  type DocumentReference,
  type DocumentSnapshot,
  FieldValue,
  Timestamp,
  getFirestore,
} from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

initializeApp();

const db = getFirestore();
const deliveryFee = 45;
const taxes = 76;
const orderAlphabet = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ";

interface CartEntry {
  product_id?: unknown;
  quantity?: unknown;
  size?: unknown;
  notes?: unknown;
}

interface PricedItem {
  productId: string;
  quantity: number;
  size: string | null;
  notes: string | null;
  name: string;
  image: string;
  price: number;
  subCategory: string;
  subCategoryId: string;
}

type DataMap = Record<string, unknown>;

function isRecord(value: unknown): value is DataMap {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function readString(data: DataMap, snake: string, camel?: string): string {
  const value = data[snake] ?? (camel ? data[camel] : undefined);
  return typeof value === "string" ? value.trim() : "";
}

function readNumber(data: DataMap, snake: string, camel?: string): number | null {
  const value = data[snake] ?? (camel ? data[camel] : undefined);
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function readDate(data: DataMap, snake: string, camel: string): Date | null {
  const value = data[snake] ?? data[camel];
  if (value instanceof Timestamp) return value.toDate();
  if (value instanceof Date) return value;
  if (typeof value === "string") {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  return null;
}

function validPromotion(data: DataMap, now: Date): boolean {
  const status = (readString(data, "status") || "active").toLowerCase();
  const start = readDate(data, "start_date", "startDate");
  const end = readDate(data, "end_date", "endDate");
  return status === "active" &&
    start !== null &&
    end !== null &&
    now >= start &&
    now <= end;
}

function calculateDiscount(
  data: DataMap,
  subtotal: number,
  minimum: number | null,
): number {
  if (subtotal <= 0 || (minimum !== null && subtotal < minimum)) return 0;

  const discountValue = readNumber(data, "discount_value", "discountValue");
  if (discountValue === null || discountValue < 0) {
    throw new HttpsError("failed-precondition", "Promotion data is invalid.");
  }

  const type =
    (readString(data, "discount_type", "discountType") || "flat").toLowerCase();
  const isPercentage = type.includes("percent");
  if (!isPercentage && type !== "flat") {
    throw new HttpsError("failed-precondition", "Promotion data is invalid.");
  }
  const maxDiscount = readNumber(data, "max_discount", "maxDiscount");
  if (maxDiscount !== null && maxDiscount < 0) {
    throw new HttpsError("failed-precondition", "Promotion data is invalid.");
  }
  let discount = isPercentage ? subtotal * discountValue / 100 : discountValue;

  if (isPercentage && maxDiscount !== null && maxDiscount >= 0) {
    discount = Math.min(discount, maxDiscount);
  }
  return Math.min(Math.max(discount, 0), subtotal);
}

function parseCart(items: unknown): CartEntry[] {
  if (!Array.isArray(items) || items.length === 0 || items.length > 50) {
    throw new HttpsError("invalid-argument", "The cart is invalid.");
  }

  return items.map((item) => {
    if (!isRecord(item)) {
      throw new HttpsError("invalid-argument", "A cart item is invalid.");
    }

    const productId = item.product_id;
    const quantity = item.quantity;
    const size = item.size;
    const notes = item.notes;
    if (
      typeof productId !== "string" ||
      productId.trim().length === 0 ||
      productId.length > 150 ||
      productId.includes("/") ||
      !Number.isInteger(quantity) ||
      (quantity as number) < 1 ||
      (quantity as number) > 99 ||
      (size !== undefined && size !== null && typeof size !== "string") ||
      (notes !== undefined && notes !== null && typeof notes !== "string")
    ) {
      throw new HttpsError("invalid-argument", "A cart item is invalid.");
    }
    return {
      ...item,
      product_id: productId.trim(),
      size: typeof size === "string" ? size.trim() : size,
    } as CartEntry;
  });
}

function getOrderId(now: Date): string {
  const day = now.getDate().toString().padStart(2, "0");
  const month = (now.getMonth() + 1).toString().padStart(2, "0");
  const year = (now.getFullYear() % 100).toString().padStart(2, "0");
  const bytes = randomBytes(8);
  const suffix = Array.from(bytes, (byte) =>
    orderAlphabet[byte % orderAlphabet.length]
  ).join("");
  return `ORD-${day}${month}${year}-${suffix}`;
}

function resolvePaymentMethod(value: unknown): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", "Select a payment method.");
  }
  const normalized = value.trim().toLowerCase();
  if (normalized.includes("cash")) return "cash";
  if (normalized.includes("card") || normalized.includes("credit")) return "card";
  if (normalized.includes("apple") || normalized.includes("online")) return "online";
  throw new HttpsError("invalid-argument", "The payment method is invalid.");
}

function readBoundedString(
  value: unknown,
  name: string,
  maximum: number,
  required = false,
): string {
  if (typeof value !== "string") {
    if (!required && (value === undefined || value === null)) return "";
    throw new HttpsError("invalid-argument", `${name} is invalid.`);
  }
  const result = value.trim();
  if ((required && result.length === 0) || result.length > maximum) {
    throw new HttpsError("invalid-argument", `${name} is invalid.`);
  }
  return result;
}

export const createUserOrder = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in to place an order.");
  }

  const body = isRecord(request.data) ? request.data : {};
  const cart = parseCart(body.items);
  const couponCode = readBoundedString(body.coupon_code, "Coupon code", 100)
    .toUpperCase();
  const offerId = readBoundedString(body.offer_id, "Offer", 150);
  if (offerId.includes("/")) {
    throw new HttpsError("invalid-argument", "The offer is invalid.");
  }
  if (couponCode && offerId) {
    throw new HttpsError(
      "invalid-argument",
      "Only one coupon or offer can be applied.",
    );
  }
  const address = readBoundedString(
    body.delivery_address,
    "Delivery address",
    500,
    true,
  );
  const subAddress = readBoundedString(
    body.delivery_sub_address,
    "Delivery address details",
    200,
  );
  const paymentMethod = resolvePaymentMethod(body.payment_method);
  const customerName = readBoundedString(body.customer_name, "Customer name", 100);
  const customerPhone = readBoundedString(body.customer_phone, "Phone number", 30);

  const customerId = request.auth.uid;
  const authName = typeof request.auth.token.name === "string"
    ? request.auth.token.name
    : "";
  const authPhone = typeof request.auth.token.phone_number === "string"
    ? request.auth.token.phone_number
    : "";
  let couponRef: DocumentReference | null = null;
  if (couponCode) {
    const coupons = await db.collection("coupons").get();
    const match = coupons.docs.find((doc) =>
      readString(doc.data(), "code").toUpperCase() === couponCode
    );
    if (!match) {
      throw new HttpsError("failed-precondition", "The coupon is not valid.");
    }
    couponRef = match.ref;
  }
  const offerRef = offerId ? db.collection("offers").doc(offerId) : null;
  const productRefs = cart.map((item) =>
    db.collection("menu_items").doc(item.product_id as string)
  );
  const orderId = getOrderId(new Date());
  const orderRef = db.collection("orders").doc(orderId);

  const orderData = await db.runTransaction(async (transaction) => {
    const productSnapshots: DocumentSnapshot[] = [];
    for (const productRef of productRefs) {
      productSnapshots.push(await transaction.get(productRef));
    }
    const couponSnapshot = couponRef ? await transaction.get(couponRef) : null;
    const offerSnapshot = offerRef ? await transaction.get(offerRef) : null;

    const pricedItems: PricedItem[] = cart.map((entry, index) => {
      const snapshot = productSnapshots[index];
      const product = snapshot.data();
      if (!snapshot.exists || !product) {
        throw new HttpsError("failed-precondition", "A menu item is unavailable.");
      }
      if (snapshot.id.includes("/")) {
        throw new HttpsError("invalid-argument", "A menu item is invalid.");
      }
      if (product.is_available === false || product.available === false) {
        throw new HttpsError("failed-precondition", "A menu item is unavailable.");
      }

      const selectedSize =
        typeof entry.size === "string" ? entry.size.trim() : "";
      const sizes = Array.isArray(product.sizes) ? product.sizes : [];
      let unitPrice: number | null = null;
      if (sizes.length > 0) {
        const selected = sizes.find((size: unknown) =>
          isRecord(size) &&
          typeof size.name === "string" &&
          size.name.trim() === selectedSize
        );
        if (selected && isRecord(selected)) {
          unitPrice = readNumber(selected, "price");
        }
      } else if (selectedSize.length === 0) {
        unitPrice = readNumber(product, "price");
      }

      if (unitPrice === null || unitPrice < 0) {
        throw new HttpsError(
          "failed-precondition",
          "A selected menu item size or price is no longer available.",
        );
      }

      return {
        productId: snapshot.id,
        quantity: entry.quantity as number,
        size: selectedSize || null,
        notes: typeof entry.notes === "string"
          ? entry.notes.trim().slice(0, 500)
          : null,
        name: readString(product, "name") || "Menu item",
        image: readString(product, "image") ||
          readString(product, "image_url") ||
          readString(product, "imageUrl"),
        price: unitPrice,
        subCategory: readString(product, "sub_category", "subCategory") ||
          readString(product, "subcategory"),
        subCategoryId: readString(product, "sub_category_id", "subCategoryId"),
      };
    });

    const now = new Date();
    const itemTotal = pricedItems.reduce(
      (sum, item) => sum + item.price * item.quantity,
      0,
    );
    if (!Number.isFinite(itemTotal)) {
      throw new HttpsError("failed-precondition", "The order total is invalid.");
    }
    let couponDiscount = 0;
    if (couponSnapshot) {
      const coupon = couponSnapshot.data();
      if (!couponSnapshot.exists || !coupon || !validPromotion(coupon, now)) {
        throw new HttpsError("failed-precondition", "The coupon is not valid.");
      }
      const code = readString(coupon, "code").toUpperCase();
      const usageCount = readNumber(coupon, "usage_count", "usageCount") ?? 0;
      const usageLimit = readNumber(coupon, "usage_limit", "usageLimit");
      if (
        code !== couponCode ||
        (usageLimit !== null && usageCount >= usageLimit)
      ) {
        throw new HttpsError("failed-precondition", "The coupon is not valid.");
      }
      const minimum = readNumber(coupon, "min_order_value", "minOrderValue");
      couponDiscount = calculateDiscount(coupon, itemTotal, minimum);
      if (couponDiscount <= 0) {
        throw new HttpsError(
          "failed-precondition",
          "The coupon requirements are not met.",
        );
      }
    }

    if (offerSnapshot) {
      const offer = offerSnapshot.data();
      if (!offerSnapshot.exists || !offer || !validPromotion(offer, now)) {
        throw new HttpsError("failed-precondition", "The offer is not valid.");
      }
      const usageCount = readNumber(offer, "usage_count", "usageCount") ?? 0;
      const usageLimit = readNumber(offer, "usage_limit", "usageLimit");
      if (usageLimit !== null && usageLimit > 0 && usageCount >= usageLimit) {
        throw new HttpsError("failed-precondition", "The offer is no longer available.");
      }

      const itemScope = readString(offer, "applicable_item_id", "applicableItemId");
      const subCategoryScope = readString(
        offer,
        "applicable_sub_category_id",
        "applicableSubCategoryId",
      );
      const eligibleItems = pricedItems.filter((item) => {
        if (itemScope) return item.productId === itemScope;
        if (subCategoryScope) {
          return item.subCategoryId === subCategoryScope ||
            item.subCategory.toLowerCase() === subCategoryScope.toLowerCase();
        }
        return true;
      });
      const eligibleSubtotal = eligibleItems.reduce(
        (sum, item) => sum + item.price * item.quantity,
        0,
      );
      const minimum = readNumber(offer, "min_order_value", "minOrderValue");
      couponDiscount = calculateDiscount(offer, eligibleSubtotal, minimum);
      if (couponDiscount <= 0) {
        throw new HttpsError(
          "failed-precondition",
          "The offer requirements are not met.",
        );
      }
    }

    const total = itemTotal - couponDiscount + deliveryFee + taxes;
    if (!Number.isFinite(total) || total < 0) {
      throw new HttpsError("failed-precondition", "The order total is invalid.");
    }
    const createdAt = new Date();
    const fullAddress = subAddress ? `${address}, ${subAddress}` : address;
    const data = {
      customer_name: customerName || authName || "Customer",
      customer_phone: customerPhone || authPhone,
      delivery_address: fullAddress,
      delivery_sub_address: subAddress,
      status: "pending",
      total,
      item_total: itemTotal,
      coupon_discount: couponDiscount,
      coupon_code: couponDiscount > 0 && couponCode ? couponCode : null,
      delivery_fee: deliveryFee,
      taxes,
      created_at: Timestamp.fromDate(createdAt),
      updated_at: FieldValue.serverTimestamp(),
      items: pricedItems.map((item) => ({
        product_id: item.productId,
        name: item.name,
        quantity: item.quantity,
        price: item.price,
        image: item.image,
        spice_level: null,
        add_ons: [],
        notes: item.notes,
        size: item.size,
      })),
      delivery_lat: null,
      delivery_lng: null,
      customer_id: customerId,
      notes: null,
      order_type: "delivery",
      table_number: null,
      payment_method: paymentMethod,
      payment_status: "unpaid",
      order_source: "app",
      order_number: orderId,
    };

    transaction.create(orderRef, data);
    if (couponSnapshot && couponRef) {
      const usageCount =
        readNumber(couponSnapshot.data() ?? {}, "usage_count", "usageCount") ?? 0;
      transaction.set(couponRef, { usage_count: usageCount + 1 }, { merge: true });
    } else if (offerSnapshot && offerRef) {
      const offer = offerSnapshot.data() ?? {};
      const usageCount = readNumber(offer, "usage_count", "usageCount") ?? 0;
      transaction.set(offerRef, { usage_count: usageCount + 1 }, { merge: true });
    }

    const serializedAt = createdAt.toISOString();
    return {
      ...data,
      id: orderId,
      created_at: serializedAt,
      updated_at: serializedAt,
    };
  });

  return orderData;
});
