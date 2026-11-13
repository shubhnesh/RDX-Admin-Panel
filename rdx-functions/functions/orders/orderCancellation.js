"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");

function calculateCancellationBalances({
  balance,
  totalEarned,
  totalRedeemed,
  earnedPoints,
  redeemedPoints,
  reversalExists,
  refundExists,
}) {
  const shouldReverse = earnedPoints > 0 && !reversalExists;
  const shouldRefund = redeemedPoints > 0 && !refundExists;
  return {
    shouldReverse,
    shouldRefund,
    // Future reward credits repay points already spent from this cancelled order.
    newBalance:
      balance +
      (shouldRefund ? redeemedPoints : 0) -
      (shouldReverse ? earnedPoints : 0),
    totalEarned: Math.max(
      0,
      totalEarned - (shouldReverse ? earnedPoints : 0)
    ),
    totalRedeemed: Math.max(
      0,
      totalRedeemed - (shouldRefund ? redeemedPoints : 0)
    ),
  };
}

async function applyOrderCancellation(
  transaction,
  orderRef,
  orderSnapshot,
  cancelledBy,
  reason
) {
  if (!orderSnapshot.exists) {
    throw new functions.https.HttpsError("not-found", "Order not found.");
  }

  const order = orderSnapshot.data() || {};
  const currentStatus = String(order.status || "").trim().toLowerCase();
  if (
    currentStatus !== "cancelled" &&
    !["pending", "preparing", "ready"].includes(currentStatus)
  ) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "This order can no longer be cancelled."
    );
  }

  const orderId = orderRef.id;
  const userId = String(order.customer_id || order.user_id || "").trim();
  if (!userId) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "The order has no customer wallet."
    );
  }

  const ledger = admin.firestore().collection("reward_ledger");
  const earningRef = ledger.doc(`earn_${orderId}`);
  const redemptionRef = ledger.doc(`redeem_${orderId}`);
  const reversalRef = ledger.doc(`earn_reversal_${orderId}`);
  const refundRef = ledger.doc(`refund_${orderId}`);
  const walletRef = admin.firestore().collection("reward_wallets").doc(userId);
  const [earningSnapshot, redemptionSnapshot, reversalSnapshot, refundSnapshot] =
    await Promise.all([
      transaction.get(earningRef),
      transaction.get(redemptionRef),
      transaction.get(reversalRef),
      transaction.get(refundRef),
    ]);

  const earnedPoints = earningSnapshot.exists &&
      earningSnapshot.get("type") === "earn"
    ? Math.max(0, Math.floor(Number(earningSnapshot.get("points")) || 0))
    : 0;
  const redeemedPoints = redemptionSnapshot.exists &&
      redemptionSnapshot.get("type") === "redeem"
    ? Math.max(0, Math.floor(Number(redemptionSnapshot.get("points")) || 0))
    : 0;
  const shouldReverse = earnedPoints > 0 && !reversalSnapshot.exists;
  const shouldRefund = redeemedPoints > 0 && !refundSnapshot.exists;
  const walletSnapshot = await transaction.get(walletRef);
  const wallet = walletSnapshot && walletSnapshot.exists
    ? walletSnapshot.data() || {}
    : {};
  const rawBalance = Number(wallet.balance);
  const balance = Number.isFinite(rawBalance) ? Math.trunc(rawBalance) : 0;
  const adjustments = calculateCancellationBalances({
    balance,
    totalEarned: Number(wallet.total_earned) || 0,
    totalRedeemed: Number(wallet.total_redeemed) || 0,
    earnedPoints,
    redeemedPoints,
    reversalExists: reversalSnapshot.exists,
    refundExists: refundSnapshot.exists,
  });
  const newBalance = adjustments.newBalance;
  const now = admin.firestore.FieldValue.serverTimestamp();

  if (shouldReverse || shouldRefund) {
    transaction.set(
      walletRef,
      {
        user_id: userId,
        balance: newBalance,
        total_earned: adjustments.totalEarned,
        total_redeemed: adjustments.totalRedeemed,
        updated_at: now,
      },
      { merge: true }
    );
  }

  if (shouldReverse) {
    transaction.create(reversalRef, {
      type: "earn_reversal",
      order_id: orderId,
      user_id: userId,
      points: -earnedPoints,
      balance_after: newBalance,
      reverses_ledger_id: earningRef.id,
      created_at: now,
    });
  }
  if (shouldRefund) {
    transaction.create(refundRef, {
      type: "refund",
      order_id: orderId,
      user_id: userId,
      points: redeemedPoints,
      balance_after: newBalance,
      refunds_ledger_id: redemptionRef.id,
      created_at: now,
    });
  }

  const rewardPointsReversed = shouldReverse
    ? earnedPoints
    : reversalSnapshot.exists
      ? Math.abs(Number(reversalSnapshot.get("points")) || 0)
      : 0;
  const rewardPointsRefunded = shouldRefund
    ? redeemedPoints
    : refundSnapshot.exists
      ? Number(refundSnapshot.get("points")) || 0
      : 0;
  const orderUpdates = {};
  if (currentStatus !== "cancelled") {
    Object.assign(orderUpdates, {
      status: "cancelled",
      updated_at: now,
      cancelled_at: now,
      cancelled_by: cancelledBy,
    });
    if (typeof reason === "string" && reason.trim()) {
      orderUpdates.cancellation_reason = reason.trim().slice(0, 500);
    }
  }
  if (
    Number(order.reward_points_reversed) !== rewardPointsReversed ||
    Number(order.reward_points_refunded) !== rewardPointsRefunded ||
    (rewardPointsReversed > 0 && Number(order.reward_points_earned) !== 0)
  ) {
    Object.assign(orderUpdates, {
      reward_points_earned: rewardPointsReversed > 0
        ? 0
        : Number(order.reward_points_earned) || 0,
      reward_points_reversed: rewardPointsReversed,
      reward_points_refunded: rewardPointsRefunded,
    });
  }
  if (Object.keys(orderUpdates).length > 0) {
    transaction.update(orderRef, orderUpdates);
  }

  return {
    status: "cancelled",
    reward_points_earned:
      rewardPointsReversed > 0
        ? 0
        : Number(order.reward_points_earned) || 0,
    reward_points_refunded: rewardPointsRefunded,
    reward_points_reversed: rewardPointsReversed,
    balance: newBalance,
  };
}

module.exports = {
  applyOrderCancellation,
  calculateCancellationBalances,
};
