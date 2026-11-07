/**
 * Award reward coins when an order is marked delivered.
 *
 * SECURITY / FAIR USE:
 * - Only runs from trusted code (updateOrderStatus CF or Admin SDK).
 * - Idempotent: ledger doc id = earn_{orderId} → never double-award.
 * - Points computed only from server order.total (never client input).
 * - Wallet + ledger updated in one transaction.
 */

"use strict";

const admin = require("firebase-admin");
const config = require("./config");

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
 * Compute points from order total using server config only.
 */
function computeEarnPoints(orderTotal) {
  if (!config.enabled) return 0;

  const total = Number(orderTotal) || 0;
  const { minOrderTotal, highThreshold, fixedHighPoints, bands } = config.earn;

  if (total < minOrderTotal) return 0;
  if (total >= highThreshold) {
    return Math.min(10, Math.max(0, Number(fixedHighPoints) || 10));
  }

  for (const band of bands) {
    if (total >= band.minTotal && total <= band.maxTotal) {
      const pts = randomInt(band.minPts, band.maxPts);
      return Math.min(9, Math.max(0, pts)); // keep under 10 for non-high band
    }
  }

  return 0;
}

/**
 * Award points for a delivered order. Safe to call multiple times.
 *
 * @param {string} orderId
 * @param {object} orderData - Firestore order document data
 * @param {string} [awardedBy] - staff uid or "system"
 * @returns {Promise<{ awarded: boolean, points: number, reason?: string }>}
 */
async function awardPointsForDeliveredOrder(orderId, orderData, awardedBy = "system") {
  if (!config.enabled) {
    return { awarded: false, points: 0, reason: "rewards_disabled" };
  }

  if (!orderId || !orderData) {
    return { awarded: false, points: 0, reason: "invalid_order" };
  }

  const status = (orderData.status || "").toString().toLowerCase();
  if (status !== "delivered") {
    return { awarded: false, points: 0, reason: "not_delivered" };
  }

  // Only customer app orders earn (optional: allow staff-created too)
  const customerId = (orderData.customer_id || orderData.user_id || "")
    .toString()
    .trim();
  if (!customerId) {
    return { awarded: false, points: 0, reason: "no_customer" };
  }

  // Prefer already-computed server total
  const orderTotal = Number(orderData.total ?? orderData.item_total ?? 0) || 0;
  const points = computeEarnPoints(orderTotal);
  if (points <= 0) {
    return { awarded: false, points: 0, reason: "below_threshold" };
  }

  const ledgerId = `earn_${orderId}`;
  const ledgerRef = db.collection("reward_ledger").doc(ledgerId);
  const walletRef = db.collection("reward_wallets").doc(customerId);

  const result = await db.runTransaction(async (tx) => {
    const [ledgerSnap, walletSnap] = await Promise.all([
      tx.get(ledgerRef),
      tx.get(walletRef),
    ]);

    // Idempotency: already awarded for this order
    if (ledgerSnap.exists) {
      const existing = ledgerSnap.data() || {};
      return {
        awarded: false,
        points: Number(existing.points) || 0,
        reason: "already_awarded",
        balance: Number((walletSnap.data() || {}).balance) || 0,
      };
    }

    const wallet = walletSnap.exists ? walletSnap.data() || {} : {};
    const prevBalance = Number(wallet.balance) || 0;
    const prevEarned = Number(wallet.total_earned) || 0;
    const newBalance = prevBalance + points;

    tx.set(ledgerRef, {
      type: "earn",
      order_id: orderId,
      user_id: customerId,
      points,
      order_total: orderTotal,
      balance_after: newBalance,
      awarded_by: awardedBy,
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

    // Mark order so clients can show "you earned X points"
    const orderRef = db.collection("orders").doc(orderId);
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
};
