"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp({ projectId: "rdx-referral-test" });
}

const { meetsQualificationConditions } = require("./referrals")._private;

test("referral conditions support paid-only, delivered-only, and combined rules", () => {
  const paidPendingOrder = {
    payment_status: "paid",
    status: "preparing",
  };
  const paidDeliveredOrder = {
    payment_status: "paid",
    status: "delivered",
  };

  assert.equal(
    meetsQualificationConditions(paidPendingOrder, ["paid"]),
    true
  );
  assert.equal(
    meetsQualificationConditions(paidPendingOrder, ["paid", "delivered"]),
    false
  );
  assert.equal(
    meetsQualificationConditions(paidDeliveredOrder, ["paid", "delivered"]),
    true
  );
  assert.equal(
    meetsQualificationConditions(
      { ...paidDeliveredOrder, payment_status: "unpaid" },
      ["delivered"]
    ),
    true
  );
});
