"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp({ projectId: "rdx-referral-test" });
}

const {
  canApplyReferralCode,
  isReferralOpportunityOpen,
  meetsQualificationConditions,
} = require("./referrals")._private;

function snapshot(exists, data = {}) {
  return { exists, data: () => data };
}

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

test("referral code application requires an open server opportunity", () => {
  const referral = snapshot(false);
  const openOpportunity = snapshot(true, { status: "open" });

  assert.equal(isReferralOpportunityOpen(openOpportunity), true);
  assert.equal(
    canApplyReferralCode({
      campaignActive: true,
      opportunitySnapshot: openOpportunity,
      referralSnapshot: referral,
      hasQualifiedOrder: false,
      hasOwnCode: false,
    }),
    true
  );
  assert.equal(
    canApplyReferralCode({
      campaignActive: true,
      opportunitySnapshot: snapshot(false),
      referralSnapshot: referral,
      hasQualifiedOrder: false,
      hasOwnCode: false,
    }),
    false
  );
  assert.equal(
    canApplyReferralCode({
      campaignActive: true,
      opportunitySnapshot: snapshot(true, { status: "skipped" }),
      referralSnapshot: referral,
      hasQualifiedOrder: false,
      hasOwnCode: false,
    }),
    false
  );
});

test("referral eligibility rejects repeat, qualified, and code-owning users", () => {
  const opportunity = snapshot(true, { status: "open" });
  const base = {
    campaignActive: true,
    opportunitySnapshot: opportunity,
    referralSnapshot: snapshot(false),
    hasQualifiedOrder: false,
    hasOwnCode: false,
  };

  assert.equal(canApplyReferralCode({ ...base, hasOwnCode: true }), false);
  assert.equal(
    canApplyReferralCode({
      ...base,
      referralSnapshot: snapshot(true, { status: "pending" }),
    }),
    false
  );
  assert.equal(canApplyReferralCode({ ...base, hasQualifiedOrder: true }), false);
});
