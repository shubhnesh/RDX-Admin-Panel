/**
 * Server-side reward (coins) configuration.
 * Change numbers here or move to Firestore settings/rewards later.
 *
 * Rules:
 * - Points only awarded when order status becomes "delivered".
 * - Cap is always <= 10 (fixed 10 when order total >= highThreshold).
 * - 1 point = 1 INR discount when redeeming (server-enforced).
 * - Client cannot write wallets or ledger.
 */

"use strict";

module.exports = {
  /** Feature switch */
  enabled: true,

  /**
   * Earning tiers based on order.total (server value at delivery time).
   * max points overall = 10.
   */
  earn: {
    /** Below this total → 0 points */
    minOrderTotal: 50,
    /** At/above this → always exactly fixedHighPoints */
    highThreshold: 1000,
    fixedHighPoints: 10,
    /**
     * Random bands for totals under highThreshold.
     * Each band: { minTotal, maxTotalInclusive, minPts, maxPts }
     * maxPts must be < 10 for bands below highThreshold.
     */
    bands: [
      { minTotal: 50, maxTotal: 199, minPts: 1, maxPts: 2 },
      { minTotal: 200, maxTotal: 499, minPts: 2, maxPts: 4 },
      { minTotal: 500, maxTotal: 999, minPts: 4, maxPts: 7 },
    ],
  },

  /**
   * Redemption (checkout).
   * 1 point = pointsToRupee INR off the item subtotal.
   */
  redeem: {
    pointsToRupee: 1,
    /** Minimum points user can spend in one order */
    minPoints: 1,
    /**
     * Max share of item_total that points can cover (0–100).
     * e.g. 20 → points discount cannot exceed 20% of item total.
     */
    maxOrderPercent: 20,
  },
};
