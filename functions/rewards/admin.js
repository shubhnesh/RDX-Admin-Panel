"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { requireAdmin } = require("../auth/roles");
const {
  awardPointsForDeliveredOrder,
} = require("./earnOnDelivery");
const {
  awardReferralForDeliveredOrder,
} = require("../referrals/referrals");

const db = admin.firestore();
const configRef = db.collection("settings").doc("rewards");
const MAX_PAGE_SIZE = 100;
const SCAN_BATCH_SIZE = 100;
const MAX_SCAN_BATCHES = 5;

const DEFAULT_CONFIG = {
  enabled: true,
  earning: {
    mode: "percentage",
    percentageBps: 100,
    pointsPerRupee: 1,
    eligibleSubtotalBasis: "afterDiscountBeforeTax",
    minimumOrderValuePaise: 5000,
    itemRules: [],
  },
  redemption: {
    pointsPerRupee: 1,
    minimumPoints: 1,
    maximumOrderPercentage: 20,
  },
  pointsValidityDays: null,
  referrals: {
    enabled: true,
    referrerRewardPoints: 50,
    newUserRewardPoints: 50,
    qualifyingOrderMinimumValuePaise: 0,
    maximumRewardsPerCampaign: null,
    validFrom: null,
    validUntil: null,
    qualificationConditions: ["paid", "delivered"],
  },
};

function fail(code, message) {
  throw new functions.https.HttpsError(code, message);
}

function asObject(value, label) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    fail("invalid-argument", `${label} must be an object.`);
  }
  return value;
}

function requiredInteger(value, label, min = 0, max = 1000000000) {
  if (!Number.isSafeInteger(value) || value < min || value > max) {
    fail("invalid-argument", `${label} must be an integer from ${min} to ${max}.`);
  }
  return value;
}

function optionalInteger(value, label, min = 1, max = 1000000000) {
  if (value == null) return null;
  return requiredInteger(value, label, min, max);
}

function optionalDate(value, label) {
  if (value == null || value === "") return null;
  if (typeof value !== "string" || !Number.isFinite(Date.parse(value))) {
    fail("invalid-argument", `${label} must be a valid date or null.`);
  }
  return new Date(value).toISOString();
}

function normalizeItemRules(value) {
  if (value == null) return [];
  if (!Array.isArray(value) || value.length > 500) {
    fail(
      "invalid-argument",
      "config.earning.itemRules must be a list of at most 500 rules."
    );
  }
  const seen = new Set();
  return value.map((rule, index) => {
    asObject(rule, `config.earning.itemRules[${index}]`);
    const menuItemId = typeof rule.menuItemId === "string"
      ? rule.menuItemId.trim()
      : "";
    if (!menuItemId || menuItemId.length > 150 || seen.has(menuItemId)) {
      fail(
        "invalid-argument",
        `config.earning.itemRules[${index}].menuItemId must be unique and non-empty.`
      );
    }
    if (!["percentage", "fixedRate"].includes(rule.mode)) {
      fail(
        "invalid-argument",
        `config.earning.itemRules[${index}].mode is not supported.`
      );
    }
    seen.add(menuItemId);
    return {
      menuItemId,
      mode: rule.mode,
      percentageBps: requiredInteger(
        rule.percentageBps,
        `config.earning.itemRules[${index}].percentageBps`,
        0,
        10000
      ),
      pointsPerRupee: requiredInteger(
        rule.pointsPerRupee,
        `config.earning.itemRules[${index}].pointsPerRupee`
      ),
    };
  });
}

function normalizeConfiguration(value) {
  const config = asObject(value, "config");
  const earning = asObject(config.earning, "config.earning");
  const redemption = asObject(config.redemption, "config.redemption");
  const referrals = asObject(config.referrals, "config.referrals");
  if (typeof config.enabled !== "boolean") {
    fail("invalid-argument", "config.enabled must be a boolean.");
  }
  if (!["percentage", "fixedRate"].includes(earning.mode)) {
    fail("invalid-argument", "config.earning.mode is not supported.");
  }
  if (earning.eligibleSubtotalBasis !== "afterDiscountBeforeTax") {
    fail(
      "invalid-argument",
      "config.earning.eligibleSubtotalBasis must be afterDiscountBeforeTax."
    );
  }
  if (typeof referrals.enabled !== "boolean") {
    fail("invalid-argument", "config.referrals.enabled must be a boolean.");
  }
  if (
    !Array.isArray(referrals.qualificationConditions) ||
    referrals.qualificationConditions.length === 0 ||
    referrals.qualificationConditions.some(
      (condition) => !["paid", "delivered"].includes(condition)
    )
  ) {
    fail(
      "invalid-argument",
      "config.referrals.qualificationConditions must include paid, delivered, or both."
    );
  }

  const validFrom = optionalDate(referrals.validFrom, "referrals.validFrom");
  const validUntil = optionalDate(referrals.validUntil, "referrals.validUntil");
  if (
    validFrom &&
    validUntil &&
    Date.parse(validUntil) <= Date.parse(validFrom)
  ) {
    fail("invalid-argument", "Referral end date must be after its start date.");
  }

  return {
    enabled: config.enabled,
    earning: {
      mode: earning.mode,
      percentageBps: requiredInteger(
        earning.percentageBps,
        "earning.percentageBps",
        0,
        10000
      ),
      pointsPerRupee: requiredInteger(
        earning.pointsPerRupee,
        "earning.pointsPerRupee"
      ),
      eligibleSubtotalBasis: earning.eligibleSubtotalBasis,
      minimumOrderValuePaise: requiredInteger(
        earning.minimumOrderValuePaise,
        "earning.minimumOrderValuePaise"
      ),
      itemRules: normalizeItemRules(earning.itemRules),
    },
    redemption: {
      pointsPerRupee: requiredInteger(
        redemption.pointsPerRupee,
        "redemption.pointsPerRupee",
        1
      ),
      minimumPoints: requiredInteger(
        redemption.minimumPoints,
        "redemption.minimumPoints"
      ),
      maximumOrderPercentage: requiredInteger(
        redemption.maximumOrderPercentage,
        "redemption.maximumOrderPercentage",
        0,
        100
      ),
    },
    pointsValidityDays: optionalInteger(
      config.pointsValidityDays,
      "pointsValidityDays"
    ),
    referrals: {
      enabled: referrals.enabled,
      referrerRewardPoints: requiredInteger(
        referrals.referrerRewardPoints,
        "referrals.referrerRewardPoints"
      ),
      newUserRewardPoints: requiredInteger(
        referrals.newUserRewardPoints,
        "referrals.newUserRewardPoints"
      ),
      qualifyingOrderMinimumValuePaise: requiredInteger(
        referrals.qualifyingOrderMinimumValuePaise,
        "referrals.qualifyingOrderMinimumValuePaise"
      ),
      maximumRewardsPerCampaign: optionalInteger(
        referrals.maximumRewardsPerCampaign,
        "referrals.maximumRewardsPerCampaign"
      ),
      validFrom,
      validUntil,
      qualificationConditions: [
        ...new Set(
          referrals.qualificationConditions
        ),
      ],
    },
  };
}

function dateToIso(value) {
  if (value && typeof value.toDate === "function") {
    return value.toDate().toISOString();
  }
  if (value instanceof Date) return value.toISOString();
  if (typeof value === "string") return value;
  return null;
}

async function getConfig() {
  const snapshot = await configRef.get();
  if (!snapshot.exists) return { version: 1, config: DEFAULT_CONFIG };
  const data = snapshot.data() || {};
  return {
    version: Number.isSafeInteger(data.version) ? data.version : 1,
    config: data.config || DEFAULT_CONFIG,
  };
}

function validateRequestId(value) {
  if (typeof value !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(value)) {
    fail("invalid-argument", "requestId is required.");
  }
  return value;
}

function validPageSize(value) {
  const size = Number(value);
  return Number.isInteger(size)
    ? Math.max(1, Math.min(size, MAX_PAGE_SIZE))
    : 25;
}

function mapLedger(snapshot) {
  const data = snapshot.data() || {};
  const rawType = String(data.type || "");
  const type = {
    earn: "earned",
    redeem: "redeemed",
    referral: "referral_bonus",
    refund: "refunded",
    earn_reversal: "reversed",
  }[rawType] || rawType;
  const signedPoints = ["redeemed", "reversed"].includes(type)
    ? -Math.abs(Number(data.points) || 0)
    : Math.abs(Number(data.points) || 0);
  return {
    transactionId: snapshot.id,
    userId: String(data.user_id || ""),
    points: signedPoints,
    type,
    createdAt: dateToIso(data.created_at),
    orderId: data.order_id == null ? null : String(data.order_id),
    referralId: data.referral_id == null ? null : String(data.referral_id),
    description:
      String(data.description || "") ||
      ({
        earned: "Points earned from a qualifying order",
        redeemed: "Points redeemed at checkout",
        referral_bonus: "Referral bonus",
        refunded: "Points refunded for a cancelled order",
        reversed: "Points reversed for a cancelled order",
      }[type] || ""),
    status: data.status == null ? null : String(data.status),
  };
}

function mapReferral(snapshot) {
  const data = snapshot.data() || {};
  return {
    referralId: snapshot.id,
    referrerId: String(data.referrer_uid || ""),
    referredUserId: String(data.referred_uid || snapshot.id),
    referralCode: String(data.code || ""),
    status:
      data.status === "rewarded" || data.reward_status === "rewarded"
        ? "qualified"
        : String(data.status || data.reward_status || "pending"),
    createdAt: dateToIso(data.created_at),
    qualifyingOrderId:
      data.order_id == null ? null : String(data.order_id),
    pointsAwarded:
      data.reward_status === "rewarded" || data.status === "rewarded"
        ? (Number(data.referrer_reward_points) || 0) +
          (Number(data.referred_reward_points) || 0)
        : 0,
  };
}

function mapRedemption(snapshot) {
  const data = snapshot.data() || {};
  return {
    redemptionId: snapshot.id,
    userId: String(data.user_id || ""),
    rewardId: "points",
    rewardName: "Order discount",
    pointsUsed: Math.abs(Number(data.points) || 0),
    status: "completed",
    createdAt: dateToIso(data.created_at),
    orderId: data.order_id == null ? null : String(data.order_id),
  };
}

function matchesSearch(values, search) {
  if (!search) return true;
  const normalized = search.toLowerCase();
  return values.some((value) =>
    String(value || "").toLowerCase().includes(normalized)
  );
}

async function fetchPage(collectionName, data, map, filter) {
  const filters = data.filters && typeof data.filters === "object"
    ? data.filters
    : {};
  const search =
    typeof filters.search === "string" ? filters.search.trim() : "";
  const limit = validPageSize(data.limit);
  const cursor =
    typeof data.cursor === "string" ? data.cursor.trim() : "";
  let cursorSnapshot = null;
  if (cursor) {
    cursorSnapshot = await db.collection(collectionName).doc(cursor).get();
    if (!cursorSnapshot.exists) {
      fail("invalid-argument", "The page cursor is invalid.");
    }
  }

  let query = db.collection(collectionName).orderBy("created_at", "desc");
  if (cursorSnapshot) query = query.startAfter(cursorSnapshot);

  const items = [];
  let lastScanned = null;
  let lastReturned = null;
  let nextCursor = null;
  let hasMore = false;
  for (let batchIndex = 0; batchIndex < MAX_SCAN_BATCHES; batchIndex += 1) {
    const snapshot = await query.limit(SCAN_BATCH_SIZE).get();
    if (snapshot.empty) break;
    for (const document of snapshot.docs) {
      lastScanned = document;
      const item = map(document);
      if ((!filter || filter(item, filters, document)) &&
          matchesSearch(Object.values(item), search)) {
        if (items.length === limit) {
          hasMore = true;
          nextCursor = lastReturned?.id || null;
          break;
        }
        items.push(item);
        lastReturned = document;
      }
    }
    if (items.length === limit) break;
    if (snapshot.size < SCAN_BATCH_SIZE) break;
    query = query.startAfter(snapshot.docs[snapshot.docs.length - 1]);
    if (batchIndex === MAX_SCAN_BATCHES - 1) {
      hasMore = true;
      nextCursor = lastScanned?.id || null;
    }
  }

  return {
    items,
    nextPageToken: hasMore ? nextCursor : null,
  };
}

function adminCallable(handler) {
  return functions
    .region("us-central1")
    .https.onCall(async (data, context) => {
      requireAdmin(context);
      return handler(data || {}, context);
    });
}

exports.getRewardConfiguration = adminCallable(async () => getConfig());

exports.updateRewardConfiguration = adminCallable(async (data, context) => {
  const configuration = normalizeConfiguration(data.config);
  const requestId = validateRequestId(data.requestId);
  const result = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(configRef);
    const version =
      snapshot.exists && Number.isSafeInteger(snapshot.data().version)
        ? snapshot.data().version + 1
        : 2;
    transaction.set(configRef, {
      version,
      config: configuration,
      ...(Number.isSafeInteger(snapshot.data()?.referral_rewards_issued)
        ? {
            referral_rewards_issued:
              snapshot.data().referral_rewards_issued,
          }
        : {}),
      request_id: requestId,
      updated_by: context.auth.uid,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { version };
  });
  return { ok: true, version: result.version };
});

exports.createFoodReward = adminCallable(async (data) => {
  validateRequestId(data.requestId);
  const reward = asObject(data.reward, "reward");
  const menuItemId =
    typeof reward.menuItemId === "string" ? reward.menuItemId.trim() : "";
  if (!menuItemId) fail("invalid-argument", "reward.menuItemId is required.");
  const pointsCost = requiredInteger(reward.pointsCost, "reward.pointsCost", 1);
  const menuSnapshot = await db.collection("menu_items").doc(menuItemId).get();
  if (!menuSnapshot.exists) {
    fail("not-found", "The selected menu item no longer exists.");
  }
  const menuName = String(menuSnapshot.data().name || menuItemId).trim();
  const document = db.collection("reward_catalog").doc();
  await document.create({
    menuItemId,
    name: menuName,
    pointsCost,
    available: reward.available !== false,
    stockLimit: optionalInteger(reward.stockLimit, "reward.stockLimit"),
    validFrom: optionalDate(reward.validFrom, "reward.validFrom"),
    validUntil: optionalDate(reward.validUntil, "reward.validUntil"),
    usageCount: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { ok: true, rewardId: document.id };
});

exports.updateFoodReward = adminCallable(async (data) => {
  validateRequestId(data.requestId);
  const rewardId =
    typeof data.rewardId === "string" ? data.rewardId.trim() : "";
  if (!rewardId) fail("invalid-argument", "rewardId is required.");
  const patch = asObject(data.patch, "patch");
  const menuItemId =
    typeof patch.menuItemId === "string" ? patch.menuItemId.trim() : "";
  if (!menuItemId) fail("invalid-argument", "patch.menuItemId is required.");
  const pointsCost = requiredInteger(patch.pointsCost, "patch.pointsCost", 1);
  const menuSnapshot = await db.collection("menu_items").doc(menuItemId).get();
  if (!menuSnapshot.exists) {
    fail("not-found", "The selected menu item no longer exists.");
  }
  await db.collection("reward_catalog").doc(rewardId).update({
    menuItemId,
    name: String(menuSnapshot.data().name || menuItemId).trim(),
    pointsCost,
    available: patch.available === true,
    stockLimit: optionalInteger(patch.stockLimit, "patch.stockLimit"),
    validFrom: optionalDate(patch.validFrom, "patch.validFrom"),
    validUntil: optionalDate(patch.validUntil, "patch.validUntil"),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { ok: true };
});

exports.disableReward = adminCallable(async (data) => {
  validateRequestId(data.requestId);
  const rewardId =
    typeof data.rewardId === "string" ? data.rewardId.trim() : "";
  if (!rewardId) fail("invalid-argument", "rewardId is required.");
  const rewardRef = db.collection("reward_catalog").doc(rewardId);
  const snapshot = await rewardRef.get();
  if (!snapshot.exists) fail("not-found", "Reward not found.");
  await rewardRef.update({
    available: false,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { ok: true };
});

exports.reconcileOrderRewards = adminCallable(async (data, context) => {
  const orderId =
    typeof data.orderId === "string" ? data.orderId.trim() : "";
  if (!orderId) fail("invalid-argument", "orderId is required.");
  const orderSnapshot = await db.collection("orders").doc(orderId).get();
  if (!orderSnapshot.exists) fail("not-found", "Order not found.");
  const order = orderSnapshot.data() || {};
  const result = await awardPointsForDeliveredOrder(
    orderId,
    order,
    context.auth.uid
  );
  await awardReferralForDeliveredOrder(orderId, order);
  return {
    ok: true,
    reward_points_earned: result.points,
    reason: result.reason || "ok",
  };
});

exports.fetchRewardAnalytics = adminCallable(async () => {
  const ledger = db.collection("reward_ledger");
  const wallets = db.collection("reward_wallets");
  const [issued, redeemed, refunded, referralRewards, liability, activeCampaigns,
    usersWithBalances, successfulReferrals] = await Promise.all([
    ledger
      .where("type", "in", ["earn", "referral", "earn_reversal"])
      .aggregate({
        points: admin.firestore.AggregateField.sum("points"),
      })
      .get(),
    ledger
      .where("type", "==", "redeem")
      .aggregate({
        points: admin.firestore.AggregateField.sum("points"),
        count: admin.firestore.AggregateField.count(),
      })
      .get(),
    ledger
      .where("type", "==", "refund")
      .aggregate({
        points: admin.firestore.AggregateField.sum("points"),
      })
      .get(),
    ledger
      .where("type", "==", "referral")
      .aggregate({
        points: admin.firestore.AggregateField.sum("points"),
      })
      .get(),
    wallets
      .where("balance", ">", 0)
      .aggregate({
        balance: admin.firestore.AggregateField.sum("balance"),
      })
      .get(),
    db.collection("reward_catalog")
      .where("available", "==", true)
      .count()
      .get(),
    wallets.where("balance", ">", 0).count().get(),
    db.collection("referrals")
      .where("reward_status", "==", "rewarded")
      .count()
      .get(),
  ]);
  const redeemedData = redeemed.data();
  const refundedPoints = Math.abs(refunded.data().points || 0);

  return {
    totalPointsIssued: Math.max(0, issued.data().points || 0),
    totalPointsRedeemed: Math.max(
      0,
      Math.abs(redeemedData.points || 0) - refundedPoints
    ),
    outstandingPointsLiability: liability.data().balance || 0,
    activeRewardCampaigns: activeCampaigns.data().count,
    usersWithBalances: usersWithBalances.data().count,
    totalReferralRewardsIssued: referralRewards.data().points || 0,
    successfulReferrals: successfulReferrals.data().count,
    totalRedemptions: redeemedData.count,
  };
});

exports.fetchRewardTransactions = adminCallable((data) =>
  fetchPage(
    "reward_ledger",
    data,
    mapLedger,
    (item, filters) =>
      !filters.type || item.type === String(filters.type)
  )
);

exports.fetchReferralRecords = adminCallable((data) =>
  fetchPage(
    "referrals",
    data,
    mapReferral,
    (item, filters) =>
      !filters.status || item.status === String(filters.status)
  )
);

exports.fetchRedemptionRecords = adminCallable((data) =>
  fetchPage(
    "reward_ledger",
    data,
    mapRedemption,
    (item, filters, document) =>
      (!filters.status || item.status === String(filters.status)) &&
      document.data()?.type === "redeem"
  )
);

exports._private = {
  DEFAULT_CONFIG,
  mapLedger,
  mapReferral,
  mapRedemption,
  normalizeConfiguration,
  normalizeItemRules,
  validPageSize,
};
