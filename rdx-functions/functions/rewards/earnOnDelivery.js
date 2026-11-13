/**
 * Award legacy reward coins for delivered orders created before placement-time
 * earning was introduced.
 *
 * SECURITY / FAIR USE:
 * - Only runs from trusted code (updateOrderStatus CF, settleOrder, or
 *   processOrderRewards Firestore trigger).
 * - Idempotent: ledger doc id = earn_{orderId} → never double-award.
 * - Points computed only from server order totals (never client input).
 * - Only order_source === "app" orders earn points.
 * - Re-reads the order status transactionally and requires delivered + paid.
 * - Wallet + ledger updated in one transaction.
 * - Fixed random bands (see config.js):
 *     total < 500  → 1–4 points
 *     total ≥ 500  → 5–9 points
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
 * Discounted item subtotal used for earning (coupon already applied).
 * Never trusts client-supplied totals.
 */
function eligibleOrderTotal(order) {
  if (!order || typeof order !== "object") return 0;
  const itemTotal = Number(order.item_total ?? order.total) || 0;
  const couponDiscount = Math.max(0, Number(order.coupon_discount) || 0);
  return Math.max(0, itemTotal - couponDiscount);
}

/**
 * Calculate points from configured earning rules when supplied; legacy
 * delivered orders retain the original fixed-band policy.
 */
function computeEarnPoints(orderOrTotal, earningConfiguration) {
  const configured = earningConfiguration &&
    typeof earningConfiguration === "object";
  if (configured && earningConfiguration.enabled === false) return 0;
  if (!configured && !config.enabled) return 0;
  if (
    typeof orderOrTotal === "object" &&
    orderOrTotal &&
    Number(orderOrTotal.reward_points_used) > 0
  ) {
    return 0;
  }

  const total =
    typeof orderOrTotal === "object" && orderOrTotal
      ? eligibleOrderTotal(orderOrTotal)
      : Math.max(0, Number(orderOrTotal) || 0);

  if (configured) {
    const earning = earningConfiguration.earning || {};
    const minimumOrderValuePaise =
      Math.max(0, Number(earning.minimumOrderValuePaise) || 0);
    if (total * 100 < minimumOrderValuePaise) return 0;

    const percentageBps = Math.max(0, Number(earning.percentageBps) || 0);
    const pointsPerRupee = Math.max(
      0,
      Number(earning.pointsPerRupee ?? 1) || 0
    );
    const itemRules = new Map(
      (Array.isArray(earning.itemRules) ? earning.itemRules : [])
        .map((rule) => [String(rule.menuItemId || ""), rule])
        .filter(([id]) => id)
    );
    const order = typeof orderOrTotal === "object" && orderOrTotal
      ? orderOrTotal
      : null;
    const items = Array.isArray(order?.items) ? order.items : [];
    if (items.length === 0) {
      return Math.max(
        0,
        Math.round(
          calculateConfiguredItemPoints(
            total,
            earning.mode,
            percentageBps,
            pointsPerRupee
          )
        )
      );
    }

    const itemTotal = items.reduce(
      (sum, item) =>
        sum + Math.max(0, Number(item.price) || 0) *
          Math.max(0, Number(item.quantity) || 0),
      0
    );
    const unallocatedDiscount = Math.max(0, itemTotal - total);
    const rawPoints = items.reduce((sum, item) => {
      const lineTotal =
        Math.max(0, Number(item.price) || 0) *
        Math.max(0, Number(item.quantity) || 0);
      const eligibleSubtotal = Number.isFinite(
        Number(item.reward_eligible_subtotal)
      )
        ? Math.max(0, Number(item.reward_eligible_subtotal))
        : Math.max(
          0,
          lineTotal -
            (itemTotal > 0 ? unallocatedDiscount * lineTotal / itemTotal : 0)
        );
      const rule = itemRules.get(String(item.product_id || ""));
      return sum + calculateConfiguredItemPoints(
        eligibleSubtotal,
        rule?.mode || earning.mode,
        Number(rule?.percentageBps ?? percentageBps) || 0,
        Number(rule?.pointsPerRupee ?? pointsPerRupee) || 0
      );
    }, 0);
    return Math.max(0, Math.round(rawPoints));
  }

  const bands = Array.isArray(config.earn?.bands) ? config.earn.bands : [];
  const minOrderTotal = Number(config.earn?.minOrderTotal) || 0;
  if (total < minOrderTotal) return 0;

  for (const band of bands) {
    const minT = Number(band.minTotal) || 0;
    const maxT =
      band.maxTotal == null || band.maxTotal === ""
        ? null
        : Number(band.maxTotal);
    if (total < minT) continue;
    if (maxT != null && total > maxT) continue;

    const minPts = Math.max(0, Math.floor(Number(band.minPts) || 0));
    const maxPts = Math.max(minPts, Math.floor(Number(band.maxPts) || minPts));
    return randomInt(minPts, maxPts);
  }

  return 0;
}

function calculateConfiguredItemPoints(
  subtotal,
  mode,
  percentageBps,
  pointsPerRupee
) {
  if (mode === "fixedRate") return subtotal * pointsPerRupee;
  return subtotal * percentageBps / 10000 * pointsPerRupee;
}

/**
 * Award points for a legacy delivered app order. Safe to call multiple times.
 *
 * @param {string} orderId
 * @param {object} orderData - Firestore order document data
 * @param {string} [awardedBy] - staff uid or "system"
 * @returns {Promise<{ awarded: boolean, points: number, reason?: string, balance?: number }>}
 */
async function awardPointsForDeliveredOrder(
  orderId,
  orderData,
  awardedBy = "system"
) {
  if (!config.enabled) {
    return { awarded: false, points: 0, reason: "rewards_disabled" };
  }

  if (!orderId) {
    return { awarded: false, points: 0, reason: "invalid_order" };
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

    const points = computeEarnPoints(order);
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
};
