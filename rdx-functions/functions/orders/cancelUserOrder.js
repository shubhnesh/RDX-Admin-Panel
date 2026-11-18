"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { requireAuth } = require("../auth/roles");
const { applyOrderCancellation } = require("./orderCancellation");

const db = admin.firestore();

exports.cancelUserOrder = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const uid = requireAuth(context);
    const orderId = String((data && data.order_id) || "").trim();
    const reason =
      typeof (data && data.reason) === "string" ? data.reason : "";
    if (!orderId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "order_id is required."
      );
    }

    const orderRef = db.collection("orders").doc(orderId);
    return db.runTransaction(async (transaction) => {
      const orderSnapshot = await transaction.get(orderRef);
      if (!orderSnapshot.exists) {
        throw new functions.https.HttpsError("not-found", "Order not found.");
      }
      if (orderSnapshot.get("customer_id") !== uid) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "You can only cancel your own orders."
        );
      }

      return applyOrderCancellation(
        transaction,
        orderRef,
        orderSnapshot,
        uid,
        reason
      );
    });
  });
