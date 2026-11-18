"use strict";

const CUSTOMER_TOPIC = "all_customers";

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
  CUSTOMER_TOPIC,
  createFcmMessage,
  isMenuItemVisible,
  isPromotionActive,
};
