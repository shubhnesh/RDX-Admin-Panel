"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {
  awardReferralForDeliveredOrder,
} = require("../referrals/referrals");
const {
  awardPointsForDeliveredOrder,
} = require("../rewards/earnOnDelivery");
const { requireRestaurantUser } = require("../auth/roles");

const db = admin.firestore();

const validTransitions = {
  pending: ["preparing", "cancelled"],
  preparing: ["ready", "cancelled"],
  ready: ["delivered", "cancelled"],
};

exports.updateOrderStatus = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const { uid } = requireRestaurantUser(context);

    const orderId = String((data && data.order_id) || "").trim();
    const newStatus = String((data && data.new_status) || "")
      .trim()
      .toLowerCase();

    functions.logger.info("updateOrderStatus HIT", {
      orderId,
      newStatus,
      uid,
    });

    if (!orderId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "order_id is required."
      );
    }
    if (!["preparing", "ready", "delivered", "cancelled"].includes(newStatus)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid new_status."
      );
    }

    const orderRef = db.collection("orders").doc(orderId);

    // 2) Read + validate OUTSIDE a transaction (avoids HttpsError → internal)
    const snap = await orderRef.get();
    if (!snap.exists) {
      throw new functions.https.HttpsError("not-found", "Order not found.");
    }

    const order = snap.data() || {};
    const currentStatus = String(order.status || "")
      .trim()
      .toLowerCase();
    const paymentStatus = String(order.payment_status || "unpaid")
      .trim()
      .toLowerCase();
    let rewardPointsAwarded = 0;

    if (currentStatus === newStatus) {
      if (newStatus === "delivered") {
        const rewardResult = await awardPointsForDeliveredOrder(
          orderId,
          order,
          uid
        );
        rewardPointsAwarded = rewardResult.points;
        await awardReferralForDeliveredOrder(orderId, order);
      }
      return {
        ok: true,
        order_id: orderId,
        status: newStatus,
        reward_points_earned: rewardPointsAwarded,
      };
    }

    const allowed = validTransitions[currentStatus];
    if (!allowed || !allowed.includes(newStatus)) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        `Cannot change order status from ${currentStatus || "(empty)"} to ${newStatus}.`
      );
    }

    if (newStatus === "delivered" && paymentStatus !== "paid") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Payment must be completed before an order can be delivered."
      );
    }

    // 3) Simple update (no transaction)
    await orderRef.update({
      status: newStatus,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      status_updated_by: uid,
    });

    if (newStatus === "delivered") {
      const deliveredOrder = {
        ...order,
        status: newStatus,
      };
      const rewardResult = await awardPointsForDeliveredOrder(
        orderId,
        deliveredOrder,
        uid
      );
      rewardPointsAwarded = rewardResult.points;
      await awardReferralForDeliveredOrder(orderId, deliveredOrder);
    }

    functions.logger.info("updateOrderStatus SUCCESS", { orderId, newStatus });

    return {
      ok: true,
      order_id: orderId,
      status: newStatus,
      reward_points_earned: rewardPointsAwarded,
    };
  });