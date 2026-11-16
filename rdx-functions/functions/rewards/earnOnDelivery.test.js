"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp({ projectId: "rdx-reward-earning-test" });
}

const { computeEarnPoints } = require("./earnOnDelivery");

const bandConfiguration = {
  enabled: true,
  earning: {
    mode: "bands",
    minimumOrderValuePaise: 0,
    bands: [
      {
        minTotal: 0,
        maxTotal: 99.99,
        pointsMode: "fixed",
        minPts: 2,
        maxPts: 2,
        fixedPts: 2,
      },
      {
        minTotal: 100,
        maxTotal: null,
        pointsMode: "range",
        minPts: 5,
        maxPts: 5,
        fixedPts: 5,
      },
    ],
  },
};

test("orders using reward points do not earn order reward points", () => {
  assert.equal(
    computeEarnPoints(
      { item_total: 150, reward_points_used: 1 },
      bandConfiguration
    ),
    0
  );
});

test("orders with no reward points used remain eligible to earn points", () => {
  assert.equal(
    computeEarnPoints(
      { item_total: 150, reward_points_used: 0 },
      bandConfiguration
    ),
    5
  );
});

test("fixed band awards exact points for matching price range", () => {
  assert.equal(
    computeEarnPoints({ item_total: 50 }, bandConfiguration),
    2
  );
});

test("open-ended upper band matches high totals", () => {
  assert.equal(
    computeEarnPoints({ item_total: 5000 }, bandConfiguration),
    5
  );
});
