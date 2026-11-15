"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  COUPON_FIELDS,
  CUSTOMER_TOPIC,
  createFcmMessage,
  hasMeaningfulChange,
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

test("promotion usage-count changes do not trigger customer pushes", () => {
  assert.equal(
    hasMeaningfulChange(
      { usage_count: 1, discount_value: 10 },
      { usage_count: 2, discount_value: 10 },
      COUPON_FIELDS
    ),
    false
  );
  assert.equal(
    hasMeaningfulChange(
      { discount_value: 10 },
      { discount_value: 15 },
      COUPON_FIELDS
    ),
    true
  );
});
