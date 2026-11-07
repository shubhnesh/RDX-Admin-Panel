"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { getOrderStatusTransitionError } = require("./orderStatusTransitions");
const { requireRestaurantUser } = require("../auth/roles");

const db = admin.firestore();

/**
 * Advance or cancel an order.
 *
 * Allowed transitions (server-enforced):
 *   pending   → preparing | cancelled
 *   preparing → ready     | cancelled
 *   ready     → delivered | cancelled
 *
 * ready → delivered also requires payment_status === "paid".
 *
 * Only restaurant users (admin | staff) may call this.
 */
exports.updateOrderStatus = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    let uid;
    let orderId;
    let newStatus;

    try {
      ({ uid } = requireRestaurantUser(context));

      orderId = String((data && data.order_id) || "").trim();
      newStatus = String((data && data.new_status) || "")
        .trim()
        .toLowerCase();

      functions.logger.info("updateOrderStatus called", {
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

      if (!newStatus) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "new_status is required."
        );
      }

      const allowedTargets = ["preparing", "ready", "delivered", "cancelled"];
      if (!allowedTargets.includes(newStatus)) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          `new_status must be one of: ${allowedTargets.join(", ")}.`
        );
      }

      const orderRef = db.collection("orders").doc(orderId);

      // Validate + write inside a transaction so concurrent advances cannot
      // skip stages or double-apply the same transition.
      await db.runTransaction(async (transaction) => {
        const snap = await transaction.get(orderRef);
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

        const transitionError = getOrderStatusTransitionError(
          currentStatus,
          newStatus,
          paymentStatus
        );
        if (transitionError) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            transitionError
          );
        }

        // Idempotent: if already at the target status, succeed without rewrite.
        if (currentStatus === newStatus) {
          return;
        }

        transaction.update(orderRef, {
          status: newStatus,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
          status_updated_by: uid,
        });
      });

      functions.logger.info("updateOrderStatus success", {
        orderId,
        newStatus,
        uid,
      });

      return {
        ok: true,
        order_id: orderId,
        status: newStatus,
      };
    } catch (error) {
      functions.logger.error("updateOrderStatus failed", {
        orderId: orderId || null,
        newStatus: newStatus || null,
        uid: uid || null,
        errorName: error && error.name,
        errorCode: error && error.code,
        errorMessage: error && error.message,
        errorStack: error && error.stack,
      });

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        "Unable to update order status. Check Cloud Function logs for details."
      );
    }
  });