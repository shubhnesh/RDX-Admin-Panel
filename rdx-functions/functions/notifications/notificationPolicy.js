"use strict";

const CUSTOMER_TOPIC = "all_customers";

const MENU_FIELDS = [
  "name",
  "description",
  "image",
  "image_url",
  "price",
  "sizes",
  "is_available",
  "available",
  "show_on_mobile_app",
  "is_featured",
  "featured_item",
];

const COUPON_FIELDS = [
  "code",
  "description",
  "discount_type",
  "discount_value",
  "min_order_value",
  "usage_limit",
  "start_date",
  "end_date",
  "status",
  "applicable_categories",
  "applicable_sub_categories",
  "applicable_sub_category_id",
  "applicable_item_id",
  "image_url",
];

const OFFER_FIELDS = [
  "title",
  "description",
  "discount_type",
  "discount_value",
  "min_order_value",
  "usage_limit",
  "start_date",
  "end_date",
  "status",
  "image_url",
  "auto_apply",
  "show_on_home",
  "home_priority",
  "applicable_sub_category_id",
  "applicable_item_id",
];

function isMenuItemVisible(data = {}) {
  const isAvailable = data.is_available ?? data.available;
  const showOnMobile = data.show_on_mobile_app ?? data.showOnMobileApp;
  return isAvailable !== false && showOnMobile !== false;
}

function toDate(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value.toDate === "function") return value.toDate();
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function isPromotionActive(data = {}, now = new Date()) {
  const status = String(data.status || "").trim().toLowerCase();
  if (status === "scheduled" || status === "expired") return false;

  const startDate = toDate(data.start_date);
  const endDate = toDate(data.end_date);
  return (!startDate || startDate <= now) && (!endDate || endDate > now);
}

function normalize(value) {
  if (value && typeof value.toMillis === "function") {
    return value.toMillis();
  }
  if (value instanceof Date) return value.getTime();
  if (Array.isArray(value)) return value.map(normalize);
  if (value && typeof value === "object") {
    return Object.keys(value)
      .sort()
      .reduce((result, key) => {
        result[key] = normalize(value[key]);
        return result;
      }, {});
  }
  return value;
}

function hasMeaningfulChange(before = {}, after = {}, fields) {
  return fields.some(
    (field) =>
      JSON.stringify(normalize(before[field])) !==
      JSON.stringify(normalize(after[field]))
  );
}

function createFcmMessage({ notificationId, title, message, category }) {
  return {
    topic: CUSTOMER_TOPIC,
    notification: { title, body: message },
    data: {
      notification_id: notificationId,
      category,
    },
    apns: {
      payload: {
        aps: { sound: "default" },
      },
    },
  };
}

module.exports = {
  COUPON_FIELDS,
  CUSTOMER_TOPIC,
  MENU_FIELDS,
  OFFER_FIELDS,
  createFcmMessage,
  hasMeaningfulChange,
  isMenuItemVisible,
  isPromotionActive,
};
