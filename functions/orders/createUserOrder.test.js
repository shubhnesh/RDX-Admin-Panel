"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp({ projectId: "rdx-order-reward-test" });
}

const {
  allocateRewardSubtotals,
  createOrderRequestHash,
  getIdempotencyKey,
  orderRequestDocumentId,
  planCartConsumption,
  validateIdempotencyKey,
} = require("./createUserOrder")._private;

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

test("order placement consumes only ordered cart lines and quantities", () => {
  assert.deepEqual(
    planCartConsumption(
      [
        {
          id: "burger",
          data: { product_id: "burger", selected_size: null, quantity: 2 },
        },
        {
          id: "burger-large",
          data: {
            product_id: "burger",
            selected_size: "Large",
            quantity: 1,
          },
        },
        {
          id: "fries",
          data: { product_id: "fries", selected_size: null, quantity: 1 },
        },
      ],
      [
        { product_id: "burger", size: null, quantity: 1 },
        { product_id: "burger", size: "Large", quantity: 1 },
      ]
    ),
    [
      { documentId: "burger", remainingQuantity: 1 },
      { documentId: "burger-large", remainingQuantity: 0 },
    ]
  );
});

test("order request hashes ignore object key order but bind all order details", () => {
  assert.equal(
    createOrderRequestHash({
      items: [{ product_id: "burger", quantity: 1 }],
      delivery_address: "123 Main Street",
      idempotency_key: "request-key-12345678",
    }),
    createOrderRequestHash({
      delivery_address: "123 Main Street",
      items: [{ quantity: 1, product_id: "burger" }],
      idempotency_key: "another-retry-key",
    })
  );
  assert.notEqual(
    createOrderRequestHash({
      items: [{ product_id: "burger", quantity: 1 }],
    }),
    createOrderRequestHash({
      items: [{ product_id: "burger", quantity: 2 }],
    })
  );
});

test("request keys are validated and scoped to a user", () => {
  assert.equal(validateIdempotencyKey("request-key-12345678"), "request-key-12345678");
  assert.throws(() => validateIdempotencyKey("short"), {
    code: "invalid-argument",
  });
  assert.notEqual(
    orderRequestDocumentId("user-a", "request-key-12345678"),
    orderRequestDocumentId("user-b", "request-key-12345678")
  );
});

test("legacy clients receive a one-call idempotency key", () => {
  const key = getIdempotencyKey();
  assert.match(key, /^[a-f0-9]{48}$/);
});
