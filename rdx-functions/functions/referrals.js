"use strict";

/**
 * Referrals — server-authoritative, anti-abuse design
 *
 * Rules (non-negotiable):
 * 1. Each Auth uid may apply AT MOST ONE referral code, ever.
 *    Document path: referrals/{uid} — permanent lock on the referred user.
 * 2. A first-time user does NOT receive a shareable referral code until they
 *    complete the one-time "apply referral" opportunity (apply OR skip).
 * 3. Skipping or applying closes the opportunity forever for that uid.
 * 4. After the opportunity is closed, the server generates referral_codes/{code}
 *    bound to referral_codes_by_user/{uid}. Codes are never client-supplied.
 * 5. All mutations run in Cloud Functions with Admin SDK. Clients cannot write
 *    referral collections (Firestore rules deny client writes).
 * 6. Referral rewards are paid once the referred user completes onboarding
 *    and reaches the home screen.
 */

const crypto = require("crypto");
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const config = require("./config");
const { readStoredRewardConfiguration } = require("../rewards/configuration");

const db = admin.firestore();
const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const OPPORTUNITY_RECOVERY_WINDOW_MS = 24 * 60 * 60 * 1000;

async function getReferralCampaign() {
  const stored = await readStoredRewardConfiguration();
  if (!stored) {
    return {
      ...config,
      enabled: config.enabled,
      referrerPoints: 50,
      referredPoints: 50,
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

/**
 * Returns existing shareable code for uid, or null if none yet.
 * Does NOT create a code — generation only happens after opportunity closes.
 */
async function getExistingCode(uid) {
  const ownerRef = db.collection("referral_codes_by_user").doc(uid);
  const ownerSnapshot = await ownerRef.get();
  if (!ownerSnapshot.exists) return null;
  const code = String(ownerSnapshot.data()?.code || "").trim();
  return code || null;
}

async function createReferralOpportunity(uid) {
  const opportunityRef = db.collection("referral_opportunities").doc(uid);
  const referralRef = db.collection("referrals").doc(uid);
  const ownerRef = db.collection("referral_codes_by_user").doc(uid);

  return db.runTransaction(async (transaction) => {
    const [opportunitySnapshot, referralSnapshot, ownerSnapshot] =
      await Promise.all([
        transaction.get(opportunityRef),
        transaction.get(referralRef),
        transaction.get(ownerRef),
      ]);

    if (
      opportunitySnapshot.exists ||
      referralSnapshot.exists ||
      ownerSnapshot.exists
    ) {
      return false;
    }

    transaction.create(opportunityRef, {
      user_id: uid,
      status: "open",
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    return true;
  });
}

async function recoverRecentlyCreatedOpportunity(uid) {
  const opportunityRef = db.collection("referral_opportunities").doc(uid);
  const existing = await opportunityRef.get();
  if (existing.exists) return existing;

  const user = await admin.auth().getUser(uid);
  const createdAt = Date.parse(user.metadata?.creationTime || "");
  const age = Date.now() - createdAt;
  if (
    !Number.isFinite(createdAt) ||
    age < 0 ||
    age > OPPORTUNITY_RECOVERY_WINDOW_MS
  ) {
    return existing;
  }

  await createReferralOpportunity(uid);
  return opportunityRef.get();
}

/**
 * Creates a shareable referral code bound to uid.
 * Only call after the apply-opportunity is closed (applied or skipped).
 * Idempotent: if a code already exists, returns it.
 */
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

function isReferralOpportunityOpen(opportunitySnapshot) {
  return (
    opportunitySnapshot.exists &&
    String(opportunitySnapshot.data()?.status || "").toLowerCase() === "open"
  );
}

function canApplyReferralCode({
  campaignActive,
  opportunitySnapshot,
  referralSnapshot,
  hasQualifiedOrder,
  hasOwnCode,
}) {
  return (
    campaignActive &&
    isReferralOpportunityOpen(opportunitySnapshot) &&
    !referralSnapshot.exists &&
    !hasQualifiedOrder &&
    !hasOwnCode
  );
}

function isSkippedReferral(data) {
  return (
    data &&
    (String(data.status || "").toLowerCase() === "skipped" ||
      data.skipped === true ||
      !data.referrer_uid)
  );
}

// ---------------------------------------------------------------------------
// getReferralOverview
// ---------------------------------------------------------------------------

exports.getReferralOverview = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const uid = requireAuth(context);
    const campaign = await getReferralCampaign();
    const pageSize = Math.min(
      Math.max(Math.floor(Number(data && data.page_size) || 20), 1),
      50
    );

    const appliedRef = db.collection("referrals").doc(uid);
    const opportunityRef = db.collection("referral_opportunities").doc(uid);
    const [appliedSnapshot, initialOpportunitySnapshot] = await Promise.all([
      appliedRef.get(),
      opportunityRef.get(),
    ]);
    const opportunitySnapshot = initialOpportunitySnapshot.exists
      ? initialOpportunitySnapshot
      : await recoverRecentlyCreatedOpportunity(uid);
    const opportunityIsOpen = isReferralOpportunityOpen(opportunitySnapshot);
    const applied = appliedSnapshot.exists ? appliedSnapshot.data() : null;
    const skipped = isSkippedReferral(applied);

    // Generate a share code only after an explicit apply/skip record closes
    // the opportunity. Accounts without a server-created opportunity are
    // ineligible to apply and may only retain a code they already had.
    const opportunityWasClosed =
      appliedSnapshot.exists ||
      (opportunitySnapshot.exists && !opportunityIsOpen);
    const code = opportunityWasClosed
      ? await getOrCreateCode(uid)
      : await getExistingCode(uid);

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
    const campaignActive = isCampaignActive(campaign);
    const opportunityOpen =
      opportunityIsOpen && !appliedSnapshot.exists && !code;

    const canApply = canApplyReferralCode({
      campaignActive,
      opportunitySnapshot,
      referralSnapshot: appliedSnapshot,
      hasQualifiedOrder,
      hasOwnCode: Boolean(code),
    });

    let eligibilityReason = null;
    if (!campaignActive) {
      eligibilityReason = "campaign_unavailable";
    } else if (appliedSnapshot.exists && !skipped) {
      eligibilityReason = "already_referred";
    } else if (skipped || !opportunityOpen) {
      eligibilityReason = "opportunity_closed";
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
          `you earn ${Number(campaign.referrerPoints) || 0} points when they ` +
          "finish setup and reach the home screen.",
      },
      app_link: null,
      can_apply: canApply,
      eligibility_reason: eligibilityReason,
      opportunity_open: opportunityOpen,
      applied_referral:
        applied && !skipped
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

// ---------------------------------------------------------------------------
// applyReferralCode — permanent lock on referrals/{uid}
// ---------------------------------------------------------------------------

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
    const opportunityRef = db.collection("referral_opportunities").doc(uid);
    const ownerRef = db.collection("referral_codes_by_user").doc(uid);
    const orderQuery = db
      .collection("orders")
      .where("customer_id", "==", uid)
      .where("status", "==", "delivered")
      .where("payment_status", "==", "paid")
      .limit(1);

    const result = await db.runTransaction(async (transaction) => {
      const [
        codeSnapshot,
        referralSnapshot,
        ordersSnapshot,
        opportunitySnapshot,
        ownerSnapshot,
      ] = await Promise.all([
        transaction.get(codeRef),
        transaction.get(referralRef),
        transaction.get(orderQuery),
        transaction.get(opportunityRef),
        transaction.get(ownerRef),
      ]);

      // Permanent lock: any existing referrals/{uid} blocks apply forever.
      if (referralSnapshot.exists) {
        const existing = referralSnapshot.data() || {};
        if (isSkippedReferral(existing)) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "The referral code entry period for this account has expired.",
            { reason: "attribution_expired" }
          );
        }
        return {
          ok: true,
          already_applied: true,
          status: String(existing.status || "pending"),
        };
      }

      if (ownerSnapshot.exists) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This account is not eligible to apply a referral code.",
          { reason: "account_ineligible" }
        );
      }
      if (!isReferralOpportunityOpen(opportunitySnapshot)) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "The referral code entry period for this account has expired.",
          { reason: "attribution_expired" }
        );
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
      const referrerOwnerRef = db
        .collection("referral_codes_by_user")
        .doc(referrerUid);
      const reverseRef = db.collection("referrals").doc(referrerUid);
      const [referrerUser, referrerOwner, reverseSnap] = await Promise.all([
        transaction.get(referrerUserRef),
        transaction.get(referrerOwnerRef),
        transaction.get(reverseRef),
      ]);
      if (
        !referrerUser.exists ||
        !referrerOwner.exists ||
        String(referrerOwner.data()?.code || "").toUpperCase() !== code
      ) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This referral code is not available.",
          { reason: "referrer_inactive" }
        );
      }

      // Block circular referral: if the referrer was referred by this uid.
      if (
        reverseSnap.exists &&
        String(reverseSnap.data()?.referrer_uid || "") === uid
      ) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This referral would create a circular referral relationship.",
          { reason: "referral_cycle" }
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
      transaction.update(opportunityRef, {
        status: "applied",
        referral_code: code,
        closed_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      return { ok: true, already_applied: false, status: "pending" };
    });

    // After a successful apply, generate the user's own shareable code so they
    // can invite others. This runs outside the apply transaction intentionally.
    if (result.ok && !result.already_applied) {
      try {
        await getOrCreateCode(uid);
      } catch (error) {
        functions.logger.warn("Referral code generation after apply failed", {
          uid,
          error: error.message || String(error),
        });
      }
    }

    return result;
  });

// ---------------------------------------------------------------------------
// completeReferralOpportunity — skip / close without applying a code
// ---------------------------------------------------------------------------
//
// Call this when the user taps "Skip" or leaves the one-time apply screen.
// Writes referrals/{uid} with status "skipped" so the uid can never apply
// another code, then generates their shareable referral code.

exports.completeReferralOpportunity = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const uid = requireAuth(context);
    const referralRef = db.collection("referrals").doc(uid);
    const opportunityRef = db.collection("referral_opportunities").doc(uid);

    const closed = await db.runTransaction(async (transaction) => {
      const [snapshot, opportunitySnapshot] = await Promise.all([
        transaction.get(referralRef),
        transaction.get(opportunityRef),
      ]);
      if (snapshot.exists) {
        return {
          already_closed: true,
          status: String(snapshot.data()?.status || "pending"),
        };
      }

      // Also block if the account already placed a qualifying order or
      // already holds a shareable code (legacy).
      const [ordersSnapshot, ownerSnapshot] = await Promise.all([
        transaction.get(
          db
            .collection("orders")
            .where("customer_id", "==", uid)
            .where("status", "==", "delivered")
            .where("payment_status", "==", "paid")
            .limit(1)
        ),
        transaction.get(db.collection("referral_codes_by_user").doc(uid)),
      ]);

      // Still allow closing even with prior orders / existing code — the goal
      // is permanent lock. If they somehow open the screen late, skip still locks.
      transaction.create(referralRef, {
        referred_uid: uid,
        referrer_uid: null,
        code: null,
        status: "skipped",
        reward_status: "skipped",
        skipped: true,
        referrer_reward_points: 0,
        referred_reward_points: 0,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        qualified_at: null,
        rewarded_at: null,
        had_qualifying_order: !ordersSnapshot.empty,
        had_own_code: ownerSnapshot.exists,
      });
      transaction.set(
        opportunityRef,
        {
          user_id: uid,
          status: "skipped",
          closed_at: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      return { already_closed: false, status: "skipped" };
    });

    // Generate shareable code after opportunity is closed.
    let referralCode = null;
    try {
      referralCode = await getOrCreateCode(uid);
    } catch (error) {
      functions.logger.warn("Referral code generation after skip failed", {
        uid,
        error: error.message || String(error),
      });
    }

    return {
      ok: true,
      already_closed: closed.already_closed,
      status: closed.status,
      referral_code: referralCode,
    };
  });

exports.initializeReferralOpportunity = functions
  .region("us-central1")
  .auth.user()
  .onCreate(async (user) => {
    const uid = String(user?.uid || "").trim();
    if (!uid) {
      functions.logger.error("Auth user creation event has no uid");
      return null;
    }
    await createReferralOpportunity(uid);
    return null;
  });

// ---------------------------------------------------------------------------
// awardReferralOnHomeScreen
// ---------------------------------------------------------------------------

async function awardReferralOnHomeScreen(referredUid) {
  referredUid = String(referredUid || "").trim();
  if (!referredUid) return { awarded: false, reason: "invalid_user" };
  const campaign = await getReferralCampaign();

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
      return referral.reward_dialog_pending === true
        ? {
            awarded: true,
            referredPoints: Math.max(
              0,
              Math.floor(Number(referral.referred_reward_points) || 0)
            ),
          }
        : { awarded: false, reason: "already_rewarded" };
    }
    if (!canAwardReferral(referral)) {
      return { awarded: false, reason: "skipped_referral" };
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
    const referrerDialogRef = db
      .collection("referral_reward_dialogs")
      .doc(referrerUid)
      .collection("events")
      .doc(referredUid);
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
    const referrerBalance =
      (Number(referrerWallet.balance) || 0) + referrerPoints;
    const referredBalance =
      (Number(referredWallet.balance) || 0) + referredPoints;

    transaction.set(
      referrerWalletRef,
      {
        user_id: referrerUid,
        balance: referrerBalance,
        total_earned:
          (Number(referrerWallet.total_earned) || 0) + referrerPoints,
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
        total_earned:
          (Number(referredWallet.total_earned) || 0) + referredPoints,
        total_redeemed: Number(referredWallet.total_redeemed) || 0,
        updated_at: now,
      },
      { merge: true }
    );
    transaction.create(referrerLedgerRef, {
      type: "referral",
      referral_id: referredUid,
      user_id: referrerUid,
      points: referrerPoints,
      balance_after: referrerBalance,
      created_at: now,
    });
    transaction.create(referredLedgerRef, {
      type: "referral",
      referral_id: referredUid,
      user_id: referredUid,
      points: referredPoints,
      balance_after: referredBalance,
      created_at: now,
    });
    if (referrerPoints > 0) {
      transaction.set(referrerDialogRef, {
        referral_id: referredUid,
        points: referrerPoints,
        pending: true,
        created_at: now,
      });
    }
    transaction.update(referralRef, {
      status: "rewarded",
      reward_status: "rewarded",
      rewarded_at: now,
      reward_dialog_pending: referredPoints > 0,
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

function canAwardReferral(referral) {
  return Boolean(referral) &&
    !isSkippedReferral(referral) &&
    String(referral.reward_status || "").toLowerCase() !== "rewarded";
}

exports.acknowledgeReferralRewardDialog = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const uid = requireAuth(context);
    if (data && data.role === "referrer") {
      const referralId = String(data.referral_id || "").trim();
      if (!referralId) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "A referral id is required."
        );
      }

      const dialogRef = db
        .collection("referral_reward_dialogs")
        .doc(uid)
        .collection("events")
        .doc(referralId);
      await db.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(dialogRef);
        if (snapshot.exists && snapshot.data()?.pending === true) {
          transaction.update(dialogRef, {
            pending: false,
            acknowledged_at: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      });
      return { ok: true };
    }

    const referralRef = db.collection("referrals").doc(uid);
    await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(referralRef);
      if (!snapshot.exists) return;
      const referral = snapshot.data() || {};
      if (
        referral.reward_status === "rewarded" &&
        referral.reward_dialog_pending === true
      ) {
        transaction.update(referralRef, {
          reward_dialog_pending: false,
          reward_dialog_acknowledged_at:
            admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    });
    return { ok: true };
  });

exports.claimReferrerReferralRewardDialog = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const uid = requireAuth(context);
    const pending = await db
      .collection("referral_reward_dialogs")
      .doc(uid)
      .collection("events")
      .where("pending", "==", true)
      .limit(1)
      .get();
    if (pending.empty) {
      return { ok: true, awarded: false };
    }

    const document = pending.docs[0];
    const notification = document.data() || {};
    return {
      ok: true,
      awarded: true,
      referral_id: String(notification.referral_id || document.id),
      points: Math.max(0, Math.floor(Number(notification.points) || 0)),
    };
  });

exports.awardReferralOnHomeScreen = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const uid = requireAuth(context);
    const result = await awardReferralOnHomeScreen(uid);
    return {
      ok: true,
      awarded: result.awarded,
      referred_points: result.awarded ? result.referredPoints : 0,
    };
  });

exports._private = {
  canApplyReferralCode,
  isReferralOpportunityOpen,
  meetsQualificationConditions,
  isSkippedReferral,
  canAwardReferral,
};
