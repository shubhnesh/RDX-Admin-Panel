"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const { generateOrderId } = require("./orderId");

test("generates uppercase order IDs in the requested format", () => {
  const orderId = generateOrderId(new Date("2026-11-04T12:00:00.000Z"));

  assert.match(orderId, /^ORD-\d{6}-[A-Z0-9]{10}$/);
  assert.equal(orderId, orderId.toUpperCase());
  assert.equal(orderId.slice(0, 10), "ORD-261104");
});

test("uses the India calendar date at midnight boundaries", () => {
  const orderId = generateOrderId(new Date("2026-11-03T19:00:00.000Z"));

  assert.match(orderId, /^ORD-261104-[A-Z0-9]{10}$/);
});
