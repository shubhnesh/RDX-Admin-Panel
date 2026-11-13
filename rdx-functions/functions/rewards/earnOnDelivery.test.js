"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp({ projectId: "rdx-reward-earning-test" });
}

const { computeEarnPoints } = require("./earnOnDelivery");

const earningConfiguration = {
  enabled: true,
  earning: {
    mode: "fixedRate",
    pointsPerRupee: 1,
  },
};

test("orders using reward points do not earn order reward points", () => {
  assert.equal(
    computeEarnPoints(
      { item_total: 100, reward_points_used: 1 },
      earningConfiguration
    ),
    0
  );
});

test("orders with no reward points used remain eligible to earn points", () => {
  assert.equal(
    computeEarnPoints(
      { item_total: 100, reward_points_used: 0 },
      earningConfiguration
    ),
    100
  );
});
