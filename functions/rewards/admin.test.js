"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp({ projectId: "rdx-admin-test" });
}

const {
  DEFAULT_CONFIG,
  mapLedger,
  mapReferral,
  mapRedemption,
  normalizeConfiguration,
  validPageSize,
} = require("./admin")._private;
const { computeEarnPoints } = require("./earnOnDelivery");

function document(id, data) {
  return {
    id,
    data: () => data,
  };
}

test("default reward configuration matches the callable response contract", () => {
  assert.deepEqual(normalizeConfiguration(DEFAULT_CONFIG), DEFAULT_CONFIG);
});

test("configuration validation rejects invalid rates and date ranges", () => {
  assert.throws(
    () => normalizeConfiguration({
      ...DEFAULT_CONFIG,
      earning: { ...DEFAULT_CONFIG.earning, percentageBps: 10001 },
    }),
    (error) => error.code === "invalid-argument"
  );
  assert.throws(
    () => normalizeConfiguration({
      ...DEFAULT_CONFIG,
      earning: {
        ...DEFAULT_CONFIG.earning,
        itemRules: [
          {
            menuItemId: "burger",
            mode: "percentage",
            percentageBps: 10001,
            pointsPerRupee: 1,
          },
        ],
      },
    }),
    (error) => error.code === "invalid-argument"
  );
  assert.throws(
    () => normalizeConfiguration({
      ...DEFAULT_CONFIG,
      referrals: {
        ...DEFAULT_CONFIG.referrals,
        qualificationConditions: [],
      },
    }),
    (error) => error.code === "invalid-argument"
  );
  assert.throws(
    () => normalizeConfiguration({
      ...DEFAULT_CONFIG,
      referrals: {
        ...DEFAULT_CONFIG.referrals,
        validFrom: "2026-11-02T00:00:00.000Z",
        validUntil: "2026-11-01T00:00:00.000Z",
      },
    }),
    (error) => error.code === "invalid-argument"
  );
});

test("ledger records use the client transaction types and signed redemption points", () => {
  const earned = mapLedger(document("earn_order", {
    type: "earn",
    user_id: "user-1",
    points: 15,
    created_at: new Date("2026-11-01T00:00:00.000Z"),
  }));
  const redeemed = mapLedger(document("redeem_order", {
    type: "redeem",
    user_id: "user-1",
    order_id: "order-1",
    points: 5,
    created_at: new Date("2026-11-01T00:00:00.000Z"),
  }));

  assert.equal(earned.type, "earned");
  assert.equal(earned.points, 15);
  assert.equal(redeemed.type, "redeemed");
  assert.equal(redeemed.points, -5);
  assert.equal(redeemed.orderId, "order-1");
});

test("referral and redemption records match the Flutter model fields", () => {
  const referral = mapReferral(document("user-2", {
    referrer_uid: "user-1",
    referred_uid: "user-2",
    code: "ABC123",
    status: "rewarded",
    reward_status: "rewarded",
    referrer_reward_points: 10,
    referred_reward_points: 5,
    order_id: "order-2",
    created_at: new Date("2026-11-01T00:00:00.000Z"),
  }));
  const redemption = mapRedemption(document("redeem_order-1", {
    user_id: "user-1",
    order_id: "order-1",
    points: 4,
    created_at: new Date("2026-11-01T00:00:00.000Z"),
  }));

  assert.equal(referral.status, "qualified");
  assert.equal(referral.pointsAwarded, 15);
  assert.equal(referral.qualifyingOrderId, "order-2");
  assert.equal(redemption.status, "completed");
  assert.equal(redemption.pointsUsed, 4);
  assert.equal(redemption.rewardName, "Order discount");
});

test("page limits are clamped to supported bounds", () => {
  assert.equal(validPageSize(25), 25);
  assert.equal(validPageSize(500), 100);
  assert.equal(validPageSize("invalid"), 25);
});

test("points are earned from the configured, discounted subtotal", () => {
  const earningConfig = {
    enabled: true,
    earning: {
      mode: "percentage",
      percentageBps: 100,
      minimumOrderValuePaise: 5000,
    },
  };
  assert.equal(
    computeEarnPoints(
      { item_total: 80, coupon_discount: 10, total: 100 },
      earningConfig
    ),
    1
  );
  assert.equal(
    computeEarnPoints(
      { item_total: 40, coupon_discount: 0 },
      earningConfig
    ),
    0
  );
  assert.equal(
    computeEarnPoints(
      { item_total: 100, coupon_discount: 0 },
      { ...earningConfig, enabled: false }
    ),
    0
  );
});

test("item overrides replace the global rate only for configured menu items", () => {
  const earningConfig = {
    enabled: true,
    earning: {
      mode: "percentage",
      percentageBps: 100,
      minimumOrderValuePaise: 0,
      itemRules: [
        {
          menuItemId: "burger",
          mode: "fixedRate",
          percentageBps: 0,
          pointsPerRupee: 1,
        },
      ],
    },
  };
  assert.equal(
    computeEarnPoints(
      {
        item_total: 200,
        coupon_discount: 50,
        items: [
          { product_id: "burger", price: 100, quantity: 1 },
          { product_id: "fries", price: 100, quantity: 1 },
        ],
      },
      earningConfig
    ),
    76
  );
});

test("item earning uses server-calculated discount scope from new orders", () => {
  const earningConfig = {
    enabled: true,
    earning: {
      mode: "percentage",
      percentageBps: 100,
      minimumOrderValuePaise: 0,
      itemRules: [
        {
          menuItemId: "burger",
          mode: "fixedRate",
          percentageBps: 0,
          pointsPerRupee: 1,
        },
      ],
    },
  };
  assert.equal(
    computeEarnPoints(
      {
        item_total: 200,
        coupon_discount: 50,
        items: [
          {
            product_id: "burger",
            price: 100,
            quantity: 1,
            reward_eligible_subtotal: 50,
          },
          {
            product_id: "fries",
            price: 100,
            quantity: 1,
            reward_eligible_subtotal: 100,
          },
        ],
      },
      earningConfig
    ),
    51
  );
});
