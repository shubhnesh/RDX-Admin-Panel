"use strict";

const crypto = require("crypto");
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const config = require("./config");
const { readStoredRewardConfiguration } = require("../rewards/configuration");

const db = admin.firestore();
const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

async function getReferralCampaign() {
  const stored = await readStoredRewardConfiguration();
  if (!stored) {
    return {
      ...config,
      enabled: config.enabled,
      referrerPoints: 10,
      referredPoints: 10,
      minimumOrderValuePaise: 0,
      maximumRewards: null,
      qualificationConditions: ["paid", "delivered"],
      validFrom: null,
      validUntil: null,
    };
  }
  const referrals = stored.referrals || {};
  return {
    enabled: stored.enabled === true && referrals.enabled === true,
    referrerPoints: Number(referrals.referrerRewardPoints) || 0,
    referredPoints: Number(referrals.newUserRewardPoints) || 0,
    minimumOrderValuePaise:
      Number(referrals.qualifyingOrderMinimumValuePaise) || 0,
    maximumRewards:
      referrals.maximumRewardsPerCampaign == null
        ? null
        : Number(referrals.maximumRewardsPerCampaign),
    qualificationConditions:
      Array.isArray(referrals.qualificationConditions) &&
      referrals.qualificationConditions.length > 0
        ? referrals.qualificationConditions
        : ["paid", "delivered"],
    validFrom: referrals.validFrom || null,
    validUntil: referrals.validUntil || null,
  };
}

function isCampaignActive(campaign, now = new Date()) {
  const time = now.getTime();
  return (
    campaign.enabled &&
    (!campaign.validFrom || time >= Date.parse(campaign.validFrom)) &&
    (!campaign.validUntil || time <= Date.parse(campaign.validUntil))
  );
}

function requireAuth(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Sign in to use referrals."
    );
  }
  return context.auth.uid;
}

function createCode() {
  const bytes = crypto.randomBytes(8);
  return Array.from(
    bytes,
    (byte) => CODE_ALPHABET[byte % CODE_ALPHABET.length]
  ).join("");
}

async function getOrCreateCode(uid) {
  const ownerRef = db.collection("referral_codes_by_user").doc(uid);
  return db.runTransaction(async (transaction) => {
    const ownerSnapshot = await transaction.get(ownerRef);
    if (ownerSnapshot.exists) {
      return String(ownerSnapshot.data().code);
    }

    for (let attempt = 0; attempt < 5; attempt += 1) {
      const code = createCode();
      const codeRef = db.collection("referral_codes").doc(code);
      const codeSnapshot = await transaction.get(codeRef);
      if (codeSnapshot.exists) continue;

      transaction.create(codeRef, {
        user_id: uid,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      transaction.create(ownerRef, {
        code,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      return code;
    }

    throw new functions.https.HttpsError(
      "resource-exhausted",
      "Could not create a referral code. Try again."
    );
  });
}

function hasEligibleDeliveredOrder(uid) {
  return db
    .collection("orders")
    .where("customer_id", "==", uid)
    .where("status", "==", "delivered")
    .where("payment_status", "==", "paid")
    .limit(1)
    .get()
    .then((snapshot) => !snapshot.empty);
}

function readDate(value) {
  if (!value) return null;
  if (typeof value.toDate === "function") return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  return value;
}

function meetsQualificationConditions(order, conditions) {
  return (
    (!conditions.includes("paid") ||
      String(order.payment_status || "").toLowerCase() === "paid") &&
    (!conditions.includes("delivered") ||
      String(order.status || "").toLowerCase() === "delivered")
  );
}

function toHistoryEntry(snapshot) {
  const data = snapshot.data() || {};
  return {
    referred_label: "Friend",
    status: String(data.status || "pending"),
    reward_status: String(data.reward_status || "pending"),
    reward_points: Number(data.referrer_reward_points) || 0,
    created_at: readDate(data.created_at),
    qualified_at: readDate(data.qualified_at),
    rewarded_at: readDate(data.rewarded_at),
  };
}

exports.getReferralOverview = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const uid = requireAuth(context);
    const campaign = await getReferralCampaign();
    const pageSize = Math.min(
      Math.max(Math.floor(Number(data && data.page_size) || 20), 1),
      50
    );
    const code = await getOrCreateCode(uid);
    const appliedRef = db.collection("referrals").doc(uid);
    const appliedSnapshot = await appliedRef.get();

    let historyQuery = db
      .collection("referrals")
      .where("referrer_uid", "==", uid)
      .orderBy("created_at", "desc");
    const cursor = typeof data?.cursor === "string" ? data.cursor.trim() : "";
    if (cursor) {
      const cursorSnapshot = await db.collection("referrals").doc(cursor).get();
      if (
        !cursorSnapshot.exists ||
        cursorSnapshot.data()?.referrer_uid !== uid
      ) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "The referral history cursor is invalid."
        );
      }
      historyQuery = historyQuery.startAfter(cursorSnapshot);
    }

    const [historySnapshot, hasQualifiedOrder] = await Promise.all([
      historyQuery.limit(pageSize + 1).get(),
      hasEligibleDeliveredOrder(uid),
    ]);
    const page = historySnapshot.docs.slice(0, pageSize);
    const applied = appliedSnapshot.exists ? appliedSnapshot.data() : null;
    const campaignActive = isCampaignActive(campaign);
    const canApply = campaignActive && !applied && !hasQualifiedOrder;
    let eligibilityReason = null;
    if (!campaignActive) {
      eligibilityReason = "campaign_unavailable";
    } else if (applied) {
      eligibilityReason = "already_referred";
    } else if (hasQualifiedOrder) {
      eligibilityReason = "account_ineligible";
    }

    return {
      enabled: campaignActive,
      referral_code: code,
      benefits: {
        referrer_points: Number(campaign.referrerPoints) || 0,
        referred_points: Number(campaign.referredPoints) || 0,
        description:
          `Your friend gets ${Number(campaign.referredPoints) || 0} points and ` +
          `you earn ${Number(campaign.referrerPoints) || 0} points after their ` +
          `first eligible order is ${campaign.qualificationConditions.join(" and ")}.`,
      },
      app_link: null,
      can_apply: canApply,
      eligibility_reason: eligibilityReason,
      applied_referral: applied
        ? {
            status: String(applied.status || "pending"),
            code: String(applied.code || ""),
            created_at: readDate(applied.created_at),
            qualified_at: readDate(applied.qualified_at),
            rewarded_at: readDate(applied.rewarded_at),
            reward_points: Number(applied.referred_reward_points) || 0,
          }
        : null,
      history: page.map(toHistoryEntry),
      next_cursor:
        historySnapshot.docs.length > pageSize
          ? page[page.length - 1].id
          : null,
    };
  });

exports.applyReferralCode = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const uid = requireAuth(context);
    const campaign = await getReferralCampaign();
    const code =
      typeof data?.code === "string" ? data.code.trim().toUpperCase() : "";
    if (!/^[A-Z0-9]{6,12}$/.test(code)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Enter a valid referral code.",
        { reason: "empty_code" }
      );
    }
    if (!isCampaignActive(campaign)) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "The referral campaign is not currently accepting codes.",
        { reason: "campaign_unavailable" }
      );
    }

    const codeRef = db.collection("referral_codes").doc(code);
    const referralRef = db.collection("referrals").doc(uid);
    const orderQuery = db
      .collection("orders")
      .where("customer_id", "==", uid)
      .where("status", "==", "delivered")
      .where("payment_status", "==", "paid")
      .limit(1);

    return db.runTransaction(async (transaction) => {
      const [codeSnapshot, referralSnapshot, ordersSnapshot] =
        await Promise.all([
          transaction.get(codeRef),
          transaction.get(referralRef),
          transaction.get(orderQuery),
        ]);
      if (referralSnapshot.exists) {
          return {
            ok: true,
            already_applied: true,
            status: String(referralSnapshot.data()?.status || "pending"),
          };
        }
      if (!codeSnapshot.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "We could not find that referral code.",
          { reason: "invalid_code" }
        );
      }
      const referrerUid = String(codeSnapshot.data()?.user_id || "");
      if (!referrerUid || referrerUid === uid) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "You cannot use your own referral code.",
          { reason: referrerUid === uid ? "self_referral" : "invalid_code" }
        );
      }
      if (!ordersSnapshot.empty) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This account is not eligible to apply a referral code.",
          { reason: "account_ineligible" }
        );
      }

      const referrerUserRef = db.collection("users").doc(referrerUid);
      const referrerUser = await transaction.get(referrerUserRef);
      if (!referrerUser.exists) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This referral code is not available.",
          { reason: "referrer_inactive" }
        );
      }

      transaction.create(referralRef, {
        referred_uid: uid,
        referrer_uid: referrerUid,
        code,
        status: "pending",
        reward_status: "pending",
        referrer_reward_points: Number(campaign.referrerPoints) || 0,
        referred_reward_points: Number(campaign.referredPoints) || 0,
        qualifying_order_minimum_value_paise:
          campaign.minimumOrderValuePaise || 0,
        qualification_conditions: campaign.qualificationConditions,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        qualified_at: null,
        rewarded_at: null,
      });
      return { ok: true, already_applied: false, status: "pending" };
    });
  });

async function awardReferralForDeliveredOrder(orderId, order) {
  const referredUid = String(order?.customer_id || order?.user_id || "").trim();
  if (!referredUid || !orderId || !order) {
    return { awarded: false, reason: "invalid_order" };
  }

  const campaign = await getReferralCampaign();
  if (!isCampaignActive(campaign)) {
    return { awarded: false, reason: "campaign_or_order_ineligible" };
  }

  let existingRewardedCount = null;
  if (campaign.maximumRewards != null) {
    const configSnapshot = await db.collection("settings").doc("rewards").get();
    const savedCount = configSnapshot.data()?.referral_rewards_issued;
    if (!Number.isSafeInteger(savedCount)) {
      const count = await db
        .collection("referrals")
        .where("reward_status", "==", "rewarded")
        .count()
        .get();
      existingRewardedCount = count.data().count;
    }
  }

  const referralRef = db.collection("referrals").doc(referredUid);
  return db.runTransaction(async (transaction) => {
    const [referralSnapshot, configurationSnapshot] = await Promise.all([
      transaction.get(referralRef),
      transaction.get(db.collection("settings").doc("rewards")),
    ]);
    if (!referralSnapshot.exists) {
      return { awarded: false, reason: "no_referral" };
    }
    const referral = referralSnapshot.data() || {};
    if (referral.reward_status === "rewarded") {
      return { awarded: false, reason: "already_rewarded" };
    }

    const conditions = Array.isArray(referral.qualification_conditions) &&
        referral.qualification_conditions.length > 0
      ? referral.qualification_conditions
      : campaign.qualificationConditions;
    if (!meetsQualificationConditions(order, conditions)) {
      return { awarded: false, reason: "order_not_eligible" };
    }
    const rawSubtotal = Number(order.item_total ?? order.total);
    if (!Number.isFinite(rawSubtotal)) {
      return { awarded: false, reason: "below_threshold" };
    }
    const orderSubtotal = Math.max(
      0,
      rawSubtotal - Math.max(0, Number(order.coupon_discount) || 0)
    );
    const minimumOrderValuePaise = referral
      .qualifying_order_minimum_value_paise == null
      ? campaign.minimumOrderValuePaise || 0
      : Number(referral.qualifying_order_minimum_value_paise);
    if (orderSubtotal * 100 < minimumOrderValuePaise) {
      return { awarded: false, reason: "below_threshold" };
    }

    const referrerUid = String(referral.referrer_uid || "");
    if (!referrerUid || referrerUid === referredUid) {
      return { awarded: false, reason: "invalid_referral" };
    }
    const referrerPoints = Math.max(
      0,
      Math.floor(Number(referral.referrer_reward_points) || 0)
    );
    const referredPoints = Math.max(
      0,
      Math.floor(Number(referral.referred_reward_points) || 0)
    );

    const referrerWalletRef = db.collection("reward_wallets").doc(referrerUid);
    const referredWalletRef = db.collection("reward_wallets").doc(referredUid);
    const referrerLedgerRef = db
      .collection("reward_ledger")
      .doc(`referral_referrer_${referredUid}`);
    const referredLedgerRef = db
      .collection("reward_ledger")
      .doc(`referral_referred_${referredUid}`);
    const [
      referrerWalletSnapshot,
      referredWalletSnapshot,
      referrerLedgerSnapshot,
      referredLedgerSnapshot,
    ] = await Promise.all([
      transaction.get(referrerWalletRef),
      transaction.get(referredWalletRef),
      transaction.get(referrerLedgerRef),
      transaction.get(referredLedgerRef),
    ]);

    if (referrerLedgerSnapshot.exists || referredLedgerSnapshot.exists) {
      return { awarded: false, reason: "ledger_already_exists" };
    }

    const configuration = configurationSnapshot.data() || {};
    const rewardsIssued = Number.isSafeInteger(
      configuration.referral_rewards_issued
    )
      ? configuration.referral_rewards_issued
      : existingRewardedCount || 0;
    const maximumRewards = campaign.maximumRewards;
    if (maximumRewards != null && rewardsIssued >= maximumRewards) {
      return { awarded: false, reason: "campaign_limit_reached" };
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    const referrerWallet = referrerWalletSnapshot.data() || {};
    const referredWallet = referredWalletSnapshot.data() || {};
    const referrerBalance = (Number(referrerWallet.balance) || 0) +
      referrerPoints;
    const referredBalance = (Number(referredWallet.balance) || 0) +
      referredPoints;

    transaction.set(
      referrerWalletRef,
      {
        user_id: referrerUid,
        balance: referrerBalance,
        total_earned: (Number(referrerWallet.total_earned) || 0) +
          referrerPoints,
        total_redeemed: Number(referrerWallet.total_redeemed) || 0,
        updated_at: now,
      },
      { merge: true }
    );
    transaction.set(
      referredWalletRef,
      {
        user_id: referredUid,
        balance: referredBalance,
        total_earned: (Number(referredWallet.total_earned) || 0) +
          referredPoints,
        total_redeemed: Number(referredWallet.total_redeemed) || 0,
        updated_at: now,
      },
      { merge: true }
    );
    transaction.create(referrerLedgerRef, {
      type: "referral",
      referral_id: referredUid,
      order_id: orderId,
      user_id: referrerUid,
      points: referrerPoints,
      balance_after: referrerBalance,
      created_at: now,
    });
    transaction.create(referredLedgerRef, {
      type: "referral",
      referral_id: referredUid,
      order_id: orderId,
      user_id: referredUid,
      points: referredPoints,
      balance_after: referredBalance,
      created_at: now,
    });
    transaction.update(referralRef, {
      status: "rewarded",
      reward_status: "rewarded",
      qualified_at: now,
      rewarded_at: now,
      order_id: orderId,
    });
    if (maximumRewards != null) {
      transaction.set(
        db.collection("settings").doc("rewards"),
        { referral_rewards_issued: rewardsIssued + 1 },
        { merge: true }
      );
    }
    return { awarded: true, referrerPoints, referredPoints };
  });
}

exports.awardReferralForDeliveredOrder = awardReferralForDeliveredOrder;
exports._private = { meetsQualificationConditions };
