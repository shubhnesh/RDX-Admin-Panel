"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {
  awardPointsForDeliveredOrder,
} = require("../rewards/earnOnDelivery");
const { applyOrderCancellation } = require("./orderCancellation");
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
    const transition = await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(orderRef);
      if (!snapshot.exists) {
        throw new functions.https.HttpsError("not-found", "Order not found.");
      }

      const order = snapshot.data() || {};
      const currentStatus = String(order.status || "").trim().toLowerCase();
      const paymentStatus = String(order.payment_status || "unpaid")
        .trim()
        .toLowerCase();
      if (newStatus === "delivered" && paymentStatus !== "paid") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Payment must be completed before an order can be delivered."
        );
      }

      if (newStatus === "cancelled") {
        const cancellation = await applyOrderCancellation(
          transaction,
          orderRef,
          snapshot,
          uid,
          (data && data.reason) || ""
        );
        return {
          order: { ...order, status: "cancelled" },
          cancellation,
        };
      }

      if (currentStatus !== newStatus) {
        const allowed = validTransitions[currentStatus];
        if (!allowed || !allowed.includes(newStatus)) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            `Cannot change order status from ${currentStatus || "(empty)"} to ${newStatus}.`
          );
        }

        transaction.update(orderRef, {
          status: newStatus,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
          status_updated_by: uid,
        });
      }

      return {
        order: { ...order, status: newStatus },
        cancellation: null,
      };
    });

    let rewardPointsAwarded = 0;
    if (newStatus === "delivered") {
      const rewardResult = await awardPointsForDeliveredOrder(
        orderId,
        transition.order,
        uid
      );
      rewardPointsAwarded = rewardResult.points;
    }

    functions.logger.info("updateOrderStatus SUCCESS", { orderId, newStatus });

    return {
      ok: true,
      order_id: orderId,
      status: newStatus,
      reward_points_earned: rewardPointsAwarded,
      reward_points_refunded:
        transition.cancellation?.reward_points_refunded || 0,
      reward_points_reversed:
        transition.cancellation?.reward_points_reversed || 0,
    };
  });
