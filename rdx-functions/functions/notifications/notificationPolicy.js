"use strict";

const crypto = require("node:crypto");

const CUSTOMER_TOPIC = "all_customers";
const ADMIN_TOPIC = "all_admins";

function notificationDocumentId(category, eventId) {
  const hash = crypto.createHash("sha256").update(String(eventId)).digest("hex");
  return `auto_${category}_${hash}`;
}

function buildAdminOrderNotification(orderId, order = {}, createdAt = null) {
  const name = String(order.customer_name || "").trim() || "A customer";
  const amount = Number(order.total);
  const amountText = Number.isFinite(amount) && amount > 0
    ? ` Total: Rs. ${amount.toFixed(2)}.`
    : "";

  return {
    id: notificationDocumentId("order_admin", orderId),
    data: {
      title: "Order placed successfully",
      message: `${name} placed order ${orderId}.${amountText}`,
      category: "order",
      source_id: orderId,
      audience: "admin",
      created_at: createdAt,
      scheduled_at: null,
      sent_at: null,
      recipient_count: 0,
      scheduled: false,
      delivery_status: "pending",
      delivery_attempts: 0,
      source: "automatic",
    },
  };
}

function isAdminInitiatedOrderStatusChange(order = {}) {
  const status = String(order.status || "").trim().toLowerCase();
  if (status !== "cancelled") return true;

  const cancelledBy = String(order.cancelled_by || "").trim();
  const customerId = String(order.customer_id || "").trim();
  return cancelledBy !== "" &&
    customerId !== "" &&
    cancelledBy !== customerId;
}

function isAdminInitiatedPaymentChange(order = {}) {
  return String(order.settled_by || "").trim() !== "";
}

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

function createFcmMessage({
  notificationId,
  title,
  message,
  category,
  topic = CUSTOMER_TOPIC,
}) {
  return {
    topic,
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
  ADMIN_TOPIC,
  notificationDocumentId,
  buildAdminOrderNotification,
  isAdminInitiatedOrderStatusChange,
  isAdminInitiatedPaymentChange,
  createFcmMessage,
  isMenuItemVisible,
  isPromotionActive,
};
