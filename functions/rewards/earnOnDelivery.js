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
 * Compute points from order total using server config only.
 */
function pointsForSubtotal(total, earning) {
  if (total <= 0) return 0;
  const rate = earning.mode === "fixedRate"
    ? Number(earning.pointsPerRupee) || 0
    : (Number(earning.percentageBps) || 0) / 10000;
  return rate > 0 ? Math.max(1, Math.floor(total * rate)) : 0;
}

function computeEarnPoints(orderTotal, storedConfiguration) {
  const order = typeof orderTotal === "object" && orderTotal
    ? orderTotal
    : null;
  const itemSubtotal = order
    ? Number(order.item_total ?? order.total) || 0
    : Number(orderTotal) || 0;
  const total = order
    ? Math.max(0, itemSubtotal - (Number(order.coupon_discount) || 0))
    : itemSubtotal;
  if (storedConfiguration) {
    if (storedConfiguration.enabled !== true) return 0;
    const earning = storedConfiguration.earning || {};
    const minimumOrderValue = Number(earning.minimumOrderValuePaise) || 0;
    if (total * 100 < minimumOrderValue) return 0;

    const itemRules = Array.isArray(earning.itemRules)
      ? earning.itemRules
      : [];
    if (!order || itemRules.length === 0 || !Array.isArray(order.items)) {
      return pointsForSubtotal(total, earning);
    }

    const lines = order.items
      .map((item) => ({
        menuItemId: String(item.product_id || item.menu_item_id || ""),
        subtotal: Math.max(0, Number(item.price) || 0) *
          Math.max(0, Number(item.quantity) || 0),
        rewardSubtotal: item.reward_eligible_subtotal,
      }))
      .filter((item) => item.menuItemId && item.subtotal > 0);
    const linesSubtotal = lines.reduce((sum, item) => sum + item.subtotal, 0);
    if (linesSubtotal <= 0) return pointsForSubtotal(total, earning);

    const hasRewardSubtotals = lines.every(
      (item) =>
        typeof item.rewardSubtotal === "number" &&
        Number.isFinite(item.rewardSubtotal) &&
        item.rewardSubtotal >= 0
    );
    const discount = Math.min(
      linesSubtotal,
      Math.max(0, Number(order.coupon_discount) || 0)
    );
    // Older orders get a proportional fallback; newer orders store server allocations.
    const discountRatio = hasRewardSubtotals ? 0 : discount / linesSubtotal;
    const rulesByItem = new Map(
      itemRules.map((rule) => [String(rule.menuItemId), rule])
    );
    const overriddenSubtotals = new Map();
    let defaultSubtotal = 0;
    for (const line of lines) {
      const netSubtotal = hasRewardSubtotals
        ? line.rewardSubtotal
        : line.subtotal * (1 - discountRatio);
      const rule = rulesByItem.get(line.menuItemId);
      if (!rule) {
        defaultSubtotal += netSubtotal;
      } else {
        overriddenSubtotals.set(
          line.menuItemId,
          (overriddenSubtotals.get(line.menuItemId) || 0) + netSubtotal
        );
      }
    }

    let points = pointsForSubtotal(defaultSubtotal, earning);
    for (const [menuItemId, subtotal] of overriddenSubtotals) {
      const rule = rulesByItem.get(menuItemId);
      points += pointsForSubtotal(subtotal, rule);
    }
    return points;
  }

  if (!config.enabled) return 0;
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
  const storedConfiguration = await readStoredRewardConfiguration();
  if (storedConfiguration
      ? storedConfiguration.enabled !== true
      : !config.enabled) {
    return { awarded: false, points: 0, reason: "rewards_disabled" };
  }

  if (!orderId || !orderData) {
    return { awarded: false, points: 0, reason: "invalid_order" };
  }

  const status = (orderData.status || "").toString().toLowerCase();
  if (
    status !== "delivered" ||
    (orderData.payment_status || "").toString().toLowerCase() !== "paid"
  ) {
    return { awarded: false, points: 0, reason: "order_not_eligible" };
  }

  // Only customer app orders earn (optional: allow staff-created too)
  const customerId = (orderData.customer_id || orderData.user_id || "")
    .toString()
    .trim();
  if (!customerId) {
    return { awarded: false, points: 0, reason: "no_customer" };
  }

  // Prefer already-computed server total
  const orderTotal = Number(orderData.item_total ?? orderData.total ?? 0) || 0;
  const itemRules = storedConfiguration?.earning?.itemRules || [];
  if (itemRules.length > 0) {
    const items = orderData.items;
    const hasOrderLines = Array.isArray(items) &&
      items.length > 0 &&
      items.every((item) =>
        Boolean(item.product_id || item.menu_item_id) &&
        Number.isFinite(Number(item.price)) &&
        Number.isFinite(Number(item.quantity)) &&
        Number(item.quantity) > 0
      );
    const hasDiscountAllocations = hasOrderLines &&
      items.every((item) =>
        typeof item.reward_eligible_subtotal === "number" &&
        Number.isFinite(item.reward_eligible_subtotal) &&
        item.reward_eligible_subtotal >= 0
      );
    if (
      !hasOrderLines ||
      ((Number(orderData.coupon_discount) || 0) > 0 &&
        !hasDiscountAllocations)
    ) {
      return {
        awarded: false,
        points: 0,
        reason: "item_allocation_unavailable",
      };
    }
  }
  const points = computeEarnPoints(orderData, storedConfiguration);
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
