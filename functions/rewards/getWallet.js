/**
 * getRewardWallet — read current user's points balance (authenticated).
 * Optional preview: how many points can apply to a given cart total.
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
    const activeConfig = storedConfiguration
      ? {
          enabled: storedConfiguration.enabled === true,
          redeem: {
            pointsToRupee:
              1 /
              Math.max(
                1,
                Number(
                  storedConfiguration.redemption?.pointsPerRupee
                ) || 1
              ),
            minPoints:
              Number(
                storedConfiguration.redemption?.minimumPoints
              ) || 1,
            maxOrderPercent:
              Number(
                storedConfiguration.redemption?.maximumOrderPercentage
              ) || 0,
          },
        }
      : config;

    const balance = Math.max(0, Number(wallet.balance) || 0);
    const orderTotal = Math.max(0, Number(data && data.order_total) || 0);

    let maxRedeemable = 0;
    if (activeConfig.enabled && orderTotal > 0 && balance > 0) {
      const maxByPercent = Math.floor(
        (orderTotal * (Number(activeConfig.redeem.maxOrderPercent) || 0)) /
          100 /
          (Number(activeConfig.redeem.pointsToRupee) || 1)
      );
      maxRedeemable = Math.min(
        balance,
        maxByPercent,
        Math.floor(
          orderTotal / (Number(activeConfig.redeem.pointsToRupee) || 1)
        )
      );
      const minPts = Number(activeConfig.redeem.minPoints) || 1;
      if (maxRedeemable < minPts) maxRedeemable = 0;
    }

    return {
      enabled: !!activeConfig.enabled,
      balance,
      total_earned: Number(wallet.total_earned) || 0,
      total_redeemed: Number(wallet.total_redeemed) || 0,
      max_redeemable_for_order: maxRedeemable,
      points_to_rupee:
        Number(activeConfig.redeem.pointsToRupee) || 1,
      max_order_percent: Number(activeConfig.redeem.maxOrderPercent) || 0,
    };
  });
