"use strict";

module.exports = {
  /** Feature switch */
  enabled: true,

  /**
   * Earning tiers based on discounted item subtotal (server value at delivery).
   */
  earn: {
    /** Below this total → 0 points */
    minOrderTotal: 0,
    /**
     * Bands: { minTotal, maxTotalInclusive | null, minPts, maxPts }
     * maxTotal null means no upper bound.
     */
    bands: [
      { minTotal: 0, maxTotal: 499.99, minPts: 1, maxPts: 4 },
      { minTotal: 500, maxTotal: null, minPts: 5, maxPts: 9 },
    ],
  },

  /**
   * Redemption (checkout).
   * 1 point = pointsToRupee INR off the item subtotal (after coupon).
   */
  redeem: {
    pointsToRupee: 1,
    /** Minimum points user can spend in one order */
    minPoints: 1,
    /**
     * Hard cap: user may spend at most this many points on a single order,
     * regardless of wallet balance or order size.
     */
    maxPointsPerOrder: 100,
  },
};
