/**
 * Award reward points for delivered + paid app orders.
 *
 * SECURITY / FAIR USE:
 * - Only runs from trusted code (updateOrderStatus CF, settleOrder, or
 *   processOrderRewards Firestore trigger).
 * - Idempotent: ledger doc id = earn_{orderId} → never double-award.
 * - Points computed only from server order totals (never client input).
 * - Only order_source === "app" orders earn points.
 * - Re-reads the order status transactionally and requires delivered + paid.
 * - Wallet + ledger updated in one transaction.
 * - Earning uses admin-configured price bands on discounted item subtotal
 *   (after coupon, before tax/fees). Up to 5 bands; each band is either a
 *   fixed point amount or a random range (inclusive).
 */

"use strict";

const admin = require("firebase-admin");
const config = require("./config");
const { readStoredRewardConfiguration } = require("./configuration");

const db = admin.firestore();

/**
 * Random integer in [min, max] inclusive (server entropy).
 */
function randomInt(min, max) {
  const lo = Math.ceil(min);
  const hi = Math.floor(max);
  if (hi < lo) return lo;
  return lo + Math.floor(Math.random() * (hi - lo + 1));
}

/**
 * Discounted item subtotal used for earning (coupon already applied).
 * Never trusts client-supplied totals. Excludes tax, delivery, and fees.
 */
function eligibleOrderTotal(order) {
  if (!order || typeof order !== "object") return 0;
  const itemTotal = Number(order.item_total ?? order.total) || 0;
  const couponDiscount = Math.max(0, Number(order.coupon_discount) || 0);
  const rewardDiscount = Math.max(0, Number(order.reward_discount) || 0);
  return Math.max(0, itemTotal - couponDiscount - rewardDiscount);
}

/**
 * Normalize bands from stored admin config or legacy static config.
 * Returns array of { minTotal, maxTotal|null, pointsMode, minPts, maxPts, fixedPts }.
 */
function resolveBands(earningConfiguration) {
  const earning =
    earningConfiguration && typeof earningConfiguration === "object"
      ? earningConfiguration.earning || earningConfiguration
      : null;

  if (earning && Array.isArray(earning.bands) && earning.bands.length > 0) {
    return earning.bands
      .map((band) => {
        if (!band || typeof band !== "object") return null;
        const minTotal = Math.max(0, Number(band.minTotal) || 0);
        const maxRaw = band.maxTotal;
        const maxTotal =
          maxRaw == null || maxRaw === ""
            ? null
            : Math.max(minTotal, Number(maxRaw) || minTotal);
        const pointsMode =
          String(band.pointsMode || "").toLowerCase() === "fixed"
            ? "fixed"
            : "range";
        const fixedPts = Math.max(0, Math.floor(Number(band.fixedPts) || 0));
        const minPts = Math.max(0, Math.floor(Number(band.minPts) || 0));
        const maxPts = Math.max(
          minPts,
          Math.floor(Number(band.maxPts) || minPts)
        );
        return {
          minTotal,
          maxTotal,
          pointsMode,
          minPts,
          maxPts,
          fixedPts,
        };
      })
      .filter(Boolean)
      .slice(0, 5);
  }

  // Legacy static bands from config.js (earn.bands)
  const legacy = Array.isArray(config.earn?.bands) ? config.earn.bands : [];
  return legacy
    .map((band) => {
      const minTotal = Math.max(0, Number(band.minTotal) || 0);
      const maxRaw = band.maxTotal;
      const maxTotal =
        maxRaw == null || maxRaw === ""
          ? null
          : Math.max(minTotal, Number(maxRaw) || minTotal);
      const minPts = Math.max(0, Math.floor(Number(band.minPts) || 0));
      const maxPts = Math.max(minPts, Math.floor(Number(band.maxPts) || minPts));
      return {
        minTotal,
        maxTotal,
        pointsMode: minPts === maxPts ? "fixed" : "range",
        minPts,
        maxPts,
        fixedPts: minPts,
      };
    })
    .slice(0, 5);
}

/**
 * Points for a matching band.
 */
function pointsForBand(band) {
  if (!band) return 0;
  if (band.pointsMode === "fixed") {
    return Math.max(0, Math.floor(Number(band.fixedPts) || 0));
  }
  const minPts = Math.max(0, Math.floor(Number(band.minPts) || 0));
  const maxPts = Math.max(minPts, Math.floor(Number(band.maxPts) || minPts));
  return randomInt(minPts, maxPts);
}

/**
 * Calculate points from admin price bands (or legacy static bands).
 * Order amount = discounted item subtotal (excludes tax / delivery / fees).
 */
function computeEarnPoints(orderOrTotal, earningConfiguration) {
  const configured =
    earningConfiguration && typeof earningConfiguration === "object";
  if (configured && earningConfiguration.enabled === false) return 0;
  if (!configured && !config.enabled) return 0;

  if (
    typeof orderOrTotal === "object" &&
    orderOrTotal &&
    Number(orderOrTotal.reward_points_used) > 0
  ) {
    // Orders that redeemed points do not earn on the same order (existing policy).
    return 0;
  }

  const total =
    typeof orderOrTotal === "object" && orderOrTotal
      ? eligibleOrderTotal(orderOrTotal)
      : Math.max(0, Number(orderOrTotal) || 0);

  if (configured) {
    const earning = earningConfiguration.earning || {};
    const minimumOrderValuePaise = Math.max(
      0,
      Number(earning.minimumOrderValuePaise) || 0
    );
    if (total * 100 < minimumOrderValuePaise) return 0;
  } else {
    const minOrderTotal = Number(config.earn?.minOrderTotal) || 0;
    if (total < minOrderTotal) return 0;
  }

  const bands = resolveBands(earningConfiguration);
  for (const band of bands) {
    if (total < band.minTotal) continue;
    if (band.maxTotal != null && total > band.maxTotal) continue;
    return pointsForBand(band);
  }

  return 0;
}

/**
 * Award points for a delivered app order. Safe to call multiple times.
 *
 * @param {string} orderId
 * @param {object} orderData - Firestore order document data (unused; re-read in tx)
 * @param {string} [awardedBy] - staff uid or "system"
 * @returns {Promise<{ awarded: boolean, points: number, reason?: string, balance?: number }>}
 */
async function awardPointsForDeliveredOrder(
  orderId,
  orderData,
  awardedBy = "system"
) {
  if (!orderId) {
    return { awarded: false, points: 0, reason: "invalid_order" };
  }

  let storedConfiguration = null;
  try {
    storedConfiguration = await readStoredRewardConfiguration();
  } catch (_) {
    storedConfiguration = null;
  }

  const rewardsEnabled =
    storedConfiguration == null
      ? config.enabled !== false
      : storedConfiguration.enabled === true;

  if (!rewardsEnabled) {
    return { awarded: false, points: 0, reason: "rewards_disabled" };
  }

  const ledgerId = `earn_${orderId}`;
  const ledgerRef = db.collection("reward_ledger").doc(ledgerId);
  const orderRef = db.collection("orders").doc(orderId);

  const result = await db.runTransaction(async (tx) => {
    const orderSnapshot = await tx.get(orderRef);
    if (!orderSnapshot.exists) {
      return { awarded: false, points: 0, reason: "invalid_order" };
    }

    const order = orderSnapshot.data() || {};
    const status = String(order.status || "").trim().toLowerCase();
    const paymentStatus = String(order.payment_status || "")
      .trim()
      .toLowerCase();
    if (status !== "delivered" || paymentStatus !== "paid") {
      return { awarded: false, points: 0, reason: "order_not_eligible" };
    }

    const source = String(order.order_source || "").trim().toLowerCase();
    if (source !== "app") {
      return { awarded: false, points: 0, reason: "not_app_order" };
    }

    if (Number(order.reward_points_used) > 0) {
      return { awarded: false, points: 0, reason: "reward_points_used" };
    }

    const customerId = String(order.customer_id || order.user_id || "").trim();
    if (!customerId) {
      return { awarded: false, points: 0, reason: "no_customer" };
    }

    const ledgerSnap = await tx.get(ledgerRef);

    // Idempotency: already awarded for this order
    if (ledgerSnap.exists) {
      const existing = ledgerSnap.data() || {};
      return {
        awarded: false,
        points: Number(existing.points) || 0,
        reason: "already_awarded",
      };
    }

    const points = computeEarnPoints(order, storedConfiguration);
    if (points <= 0) {
      return { awarded: false, points: 0, reason: "below_threshold" };
    }

    const walletRef = db.collection("reward_wallets").doc(customerId);
    const walletSnap = await tx.get(walletRef);
    const wallet = walletSnap.exists ? walletSnap.data() || {} : {};
    const prevBalance = Number(wallet.balance) || 0;
    const prevEarned = Number(wallet.total_earned) || 0;
    const newBalance = prevBalance + points;

    tx.set(ledgerRef, {
      type: "earn",
      order_id: orderId,
      user_id: customerId,
      points,
      order_total: eligibleOrderTotal(order),
      balance_after: newBalance,
      awarded_by: awardedBy,
      order_source: "app",
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.set(
      walletRef,
      {
        user_id: customerId,
        balance: newBalance,
        total_earned: prevEarned + points,
        total_redeemed: Number(wallet.total_redeemed) || 0,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // Mark order so clients / admin can show "you earned X points"
    tx.update(orderRef, {
      reward_points_earned: points,
      reward_awarded_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      awarded: true,
      points,
      balance: newBalance,
      reason: "ok",
    };
  });

  return result;
}

module.exports = {
  awardPointsForDeliveredOrder,
  computeEarnPoints,
  eligibleOrderTotal,
  randomInt,
  resolveBands,
  pointsForBand,
};
