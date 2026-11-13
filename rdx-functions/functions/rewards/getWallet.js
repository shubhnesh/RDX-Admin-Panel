/**
 * getRewardWallet — read current user's points balance (authenticated).
 * Optional preview: how many points can apply to a given cart total.
 *
 * Policy (server-enforced):
 * - 1 point = ₹1 discount
 * - Max redeemable per order = 100 points (hard cap)
 * - Also limited by wallet balance and cart subtotal
 */

"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const config = require("./config");
const { readStoredRewardConfiguration } = require("./configuration");

const db = admin.firestore();

// APP: USER APP — customer reads their reward wallet and redemption preview.
exports.getRewardWallet = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in."
      );
    }

    const uid = context.auth.uid;
    const [snap, storedConfiguration] = await Promise.all([
      db.collection("reward_wallets").doc(uid).get(),
      readStoredRewardConfiguration(),
    ]);
    const wallet = snap.exists ? snap.data() || {} : {};

    // Fixed redemption policy; stored config may only disable rewards.
    const enabled =
      storedConfiguration == null
        ? config.enabled !== false
        : storedConfiguration.enabled === true;
    const pointsToRupee = Number(config.redeem?.pointsToRupee) || 1;
    const minPoints = Number(config.redeem?.minPoints) || 1;
    const maxPointsPerOrder =
      Number(config.redeem?.maxPointsPerOrder) || 100;

    const balance = Math.max(0, Number(wallet.balance) || 0);
    const orderTotal = Math.max(0, Number(data && data.order_total) || 0);

    let maxRedeemable = 0;
    if (enabled && orderTotal > 0 && balance > 0) {
      const maxBySubtotal = Math.floor(orderTotal / pointsToRupee);
      maxRedeemable = Math.min(balance, maxPointsPerOrder, maxBySubtotal);
      if (maxRedeemable < minPoints) maxRedeemable = 0;
    }

    return {
      enabled: !!enabled,
      balance,
      total_earned: Number(wallet.total_earned) || 0,
      total_redeemed: Number(wallet.total_redeemed) || 0,
      max_redeemable_for_order: maxRedeemable,
      points_to_rupee: pointsToRupee,
      max_points_per_order: maxPointsPerOrder,
      // Legacy field kept for older clients; percent no longer gates redemption.
      max_order_percent: 100,
    };
  });
