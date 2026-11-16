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
  getPriceForSize,
  orderRequestDocumentId,
  planCartConsumption,
  validateIdempotencyKey,
} = require("./createUserOrder")._private;
const { getExtraScope, isExtraProduct } = require("./extraItems");

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

test("order prices use the selected server-defined size and reject unknown sizes", () => {
  const product = {
    name: "Momo",
    price: 90,
    sizes: [
      { name: "Half", price: 60 },
      { name: "Full", price: 100 },
    ],
  };

  assert.equal(getPriceForSize(product, "Full"), 100);
  assert.throws(() => getPriceForSize(product, "Large"), {
    code: "invalid-argument",
  });
  assert.throws(() => getPriceForSize({ name: "Sauce", price: 20 }, "Large"), {
    code: "invalid-argument",
  });
});

test("item-level extras take precedence over subcategory and category extras", () => {
  const baseProduct = {
    name: "House momo",
    primary_category_id: "momo",
    sub_category_id: "steamed",
    served_with: ["item-sauce"],
  };
  const category = {
    served_with: ["category-sauce"],
    subcategories: [
      { id: "steamed", served_with: ["subcategory-sauce"] },
    ],
  };

  assert.equal(
    getExtraScope({
      baseProduct,
      extraProduct: { id: "item-sauce", name: "Item sauce" },
      category,
    }),
    "item"
  );
  assert.equal(
    getExtraScope({
      baseProduct,
      extraProduct: { id: "subcategory-sauce", name: "Subcategory sauce" },
      category,
    }),
    null
  );
});

test("subcategory extras take precedence over category extras", () => {
  const baseProduct = {
    sub_category_id: "steamed",
  };
  const category = {
    served_with: ["category-sauce"],
    subcategories: [
      { id: "steamed", served_with: ["subcategory-sauce"] },
    ],
  };

  assert.equal(
    getExtraScope({
      baseProduct,
      extraProduct: { id: "subcategory-sauce" },
      category,
    }),
    "subcategory"
  );
  assert.equal(
    getExtraScope({
      baseProduct,
      extraProduct: { id: "category-sauce" },
      category,
    }),
    null
  );
});

test("category extras apply when no narrower extra mapping exists", () => {
  assert.equal(
    getExtraScope({
      baseProduct: {},
      extraProduct: { id: "category-sauce" },
      category: { served_with: ["category-sauce"] },
    }),
    "category"
  );
  assert.equal(isExtraProduct({ is_extra: true }), true);
  assert.equal(isExtraProduct({ is_extra: false }), false);
});

test("cart line consumption distinguishes extras linked to different items", () => {
  assert.deepEqual(
    planCartConsumption(
      [
        {
          id: "sauce-for-momo",
          data: {
            product_id: "sauce",
            quantity: 1,
            extra_for_product_id: "momo",
          },
        },
        {
          id: "sauce-for-noodles",
          data: {
            product_id: "sauce",
            quantity: 1,
            extra_for_product_id: "noodles",
          },
        },
      ],
      [
        {
          product_id: "sauce",
          quantity: 1,
          extra_for_product_id: "noodles",
        },
      ]
    ),
    [{ documentId: "sauce-for-noodles", remainingQuantity: 0 }]
  );
});
