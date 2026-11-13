"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp({ projectId: "rdx-cancellation-test" });
}
const {
  applyOrderCancellation,
  calculateCancellationBalances,
} = require("./orderCancellation");

function snapshot(data) {
  return {
    exists: data != null,
    data: () => data,
    get: (field) => data && data[field],
  };
}

test("cancellation refunds redeemed points and preserves debt from spent earnings", () => {
  assert.deepEqual(
    calculateCancellationBalances({
      balance: 2,
      totalEarned: 10,
      totalRedeemed: 3,
      earnedPoints: 10,
      redeemedPoints: 3,
      reversalExists: false,
      refundExists: false,
    }),
    {
      shouldReverse: true,
      shouldRefund: true,
      newBalance: -5,
      totalEarned: 0,
      totalRedeemed: 0,
    }
  );
});

test("repeated cancellation compensation does not adjust the wallet twice", () => {
  assert.deepEqual(
    calculateCancellationBalances({
      balance: -5,
      totalEarned: 0,
      totalRedeemed: 0,
      earnedPoints: 10,
      redeemedPoints: 3,
      reversalExists: true,
      refundExists: true,
    }),
    {
      shouldReverse: false,
      shouldRefund: false,
      newBalance: -5,
      totalEarned: 0,
      totalRedeemed: 0,
    }
  );
});

test("cancellation transaction refunds and reverses the order ledger once", async () => {
  const orderId = "order-1";
  const orderRef = admin.firestore().collection("orders").doc(orderId);
  const documents = {
    [`reward_ledger/earn_${orderId}`]: { type: "earn", points: 10 },
    [`reward_ledger/redeem_${orderId}`]: { type: "redeem", points: 3 },
    "reward_wallets/user-1": {
      balance: 2,
      total_earned: 10,
      total_redeemed: 3,
    },
  };
  const writes = [];
  const transaction = {
    async get(reference) {
      return snapshot(documents[reference.path]);
    },
    create(reference, data) {
      writes.push({ kind: "create", path: reference.path, data });
    },
    set(reference, data) {
      writes.push({ kind: "set", path: reference.path, data });
    },
    update(reference, data) {
      writes.push({ kind: "update", path: reference.path, data });
    },
  };

  const result = await applyOrderCancellation(
    transaction,
    orderRef,
    snapshot({
      customer_id: "user-1",
      status: "pending",
      reward_points_earned: 10,
      reward_points_refunded: 0,
      reward_points_reversed: 0,
    }),
    "user-1",
    "Changed my mind"
  );

  assert.equal(result.reward_points_refunded, 3);
  assert.equal(result.reward_points_reversed, 10);
  assert.equal(result.balance, -5);
  assert.equal(
    writes.find((write) => write.path === "reward_wallets/user-1").data.balance,
    -5
  );
  assert.ok(writes.some((write) => write.path === `reward_ledger/refund_${orderId}`));
  assert.ok(writes.some((write) =>
    write.path === `reward_ledger/earn_reversal_${orderId}`
  ));
  assert.equal(
    writes.find((write) => write.kind === "update").data.status,
    "cancelled"
  );
});
