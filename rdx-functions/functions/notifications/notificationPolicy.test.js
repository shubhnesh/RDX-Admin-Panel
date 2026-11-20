"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  CUSTOMER_TOPIC,
  ADMIN_TOPIC,
  notificationDocumentId,
  buildAdminOrderNotification,
  isAdminInitiatedOrderStatusChange,
  isAdminInitiatedPaymentChange,
  createFcmMessage,
  isMenuItemVisible,
  isPromotionActive,
} = require("./notificationPolicy");

test("FCM message targets the customer topic with string data values", () => {
  const message = createFcmMessage({
    notificationId: "notification-1",
    title: "New offer",
    message: "An offer is available.",
    category: "offer",
  });

  test("FCM message can target the admin topic", () => {
    const message = createFcmMessage({
      notificationId: "admin-1",
      title: "New support request",
      message: "Customer support: Order issue",
      category: "support",
      topic: ADMIN_TOPIC,
    });

    assert.equal(message.topic, ADMIN_TOPIC);
    assert.equal(message.data.category, "support");
  });

  assert.equal(message.topic, CUSTOMER_TOPIC);
  assert.deepEqual(message.notification, {
    title: "New offer",
    body: "An offer is available.",
  });
  assert.deepEqual(message.data, {
    notification_id: "notification-1",
    category: "offer",
  });
});

test("menu notifications require the item to be visible and available", () => {
  assert.equal(isMenuItemVisible({}), true);
  assert.equal(isMenuItemVisible({ is_available: false }), false);
  assert.equal(isMenuItemVisible({ show_on_mobile_app: false }), false);
});

test("promotions are sent only while their effective dates are active", () => {
  const now = new Date("2026-11-15T00:00:00Z");
  assert.equal(
    isPromotionActive({
      status: "active",
      start_date: new Date("2026-11-14T00:00:00Z"),
      end_date: new Date("2026-11-16T00:00:00Z"),
    }, now),
    true
  );
  assert.equal(
    isPromotionActive({
      status: "scheduled",
      start_date: new Date("2026-11-16T00:00:00Z"),
    }, now),
    false
  );
});

test("admin order notification has a stable ID and correct order details", () => {
  const notification = buildAdminOrderNotification("ORD-123", {
    customer_name: "Customer One",
    total: 250,
  });

  assert.equal(notification.id, notificationDocumentId("order_admin", "ORD-123"));
  assert.equal(notification.data.title, "Order placed successfully");
  assert.equal(
    notification.data.message,
    "Customer One placed order ORD-123. Total: Rs. 250.00."
  );
  assert.equal(notification.data.category, "order");
  assert.equal(notification.data.source_id, "ORD-123");
  assert.equal(notification.data.audience, "admin");
  assert.equal(notification.data.delivery_status, "pending");
});

test("admin order status changes do not route notifications back to admin", () => {
  assert.equal(
    isAdminInitiatedOrderStatusChange({
      customer_id: "customer-1",
      status: "ready",
      status_updated_by: "admin-1",
    }),
    true
  );
  assert.equal(
    isAdminInitiatedOrderStatusChange({
      customer_id: "customer-1",
      status: "cancelled",
      cancelled_by: "customer-1",
    }),
    false
  );
  assert.equal(
    isAdminInitiatedOrderStatusChange({
      customer_id: "customer-1",
      status: "cancelled",
      cancelled_by: "admin-1",
    }),
    true
  );
});

test("admin payment settlement does not notify the settling admin", () => {
  assert.equal(
    isAdminInitiatedPaymentChange({ settled_by: "admin-1" }),
    true
  );
  assert.equal(isAdminInitiatedPaymentChange({}), false);
});
