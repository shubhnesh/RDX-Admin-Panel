"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp({ projectId: "rdx-order-reward-test" });
}

const { allocateRewardSubtotals } = require("./createUserOrder")._private;

test("order discounts are allocated only to coupon-eligible menu items", () => {
  const items = [
    { product_id: "burger", price: 100, quantity: 1 },
    { product_id: "fries", price: 100, quantity: 1 },
  ];

  assert.deepEqual(
    allocateRewardSubtotals(items, 50, new Set(["burger"])).map(
      (item) => item.reward_eligible_subtotal
    ),
    [50, 100]
  );
});

test("order-wide discounts are allocated proportionally across menu items", () => {
  const items = [
    { product_id: "burger", price: 100, quantity: 1 },
    { product_id: "fries", price: 100, quantity: 1 },
  ];

  assert.deepEqual(
    allocateRewardSubtotals(items, 50).map(
      (item) => item.reward_eligible_subtotal
    ),
    [75, 75]
  );
});
