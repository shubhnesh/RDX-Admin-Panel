/**
 * settleOrder.js — Mark order paid. NEVER accepts client totals or fees.
 */
"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { requireRestaurantUser } = require("../auth/roles");

const db = admin.firestore();

// APP: ADMIN APP — staff settles payment for a restaurant order.
exports.settleOrder = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const { uid } = requireRestaurantUser(context);

    const { order_id, payment_method, notes = null } = data || {};

    // Reject every client attempt to push money fields.
    const forbiddenKeys = [
      "final_total",
      "total",
      "taxes",
      "late_night_fee",
      "long_distance_fee",
      "delivery_fee",
      "apply_late_night_fee",
      "apply_long_distance_fee",
    ];
    for (const key of forbiddenKeys) {
      if (data != null && Object.prototype.hasOwnProperty.call(data, key)) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          `${key} is not allowed. Order total is set at create time and cannot be changed on settle.`
        );
      }
    }

    if (!order_id || typeof order_id !== "string" || order_id.trim() === "") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "order_id is required."
      );
    }

    const validPaymentMethods = ["cash", "upi", "card"];
    const method = (payment_method || "").toString().toLowerCase().trim();

    if (!validPaymentMethods.includes(method)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "payment_method must be one of: cash, upi, card."
      );
    }

    const orderRef = db.collection("orders").doc(order_id.trim());

    const result = await db.runTransaction(async (transaction) => {
      const snap = await transaction.get(orderRef);

      if (!snap.exists) {
        throw new functions.https.HttpsError("not-found", "Order not found.");
      }

      const order = snap.data();

      const status = String(order.status || "").trim().toLowerCase();
      if (!["pending", "preparing", "ready"].includes(status)) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This order can no longer be settled."
        );
      }

      if (order.payment_status === "paid") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This order is already marked as paid."
        );
      }

      const updateData = {
        payment_status: "paid",
        payment_method: method,
        settled_at: admin.firestore.FieldValue.serverTimestamp(),
        settled_by: uid,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      };

      if (notes && typeof notes === "string" && notes.trim()) {
        updateData.settlement_notes = notes.trim().slice(0, 500);
      }

      transaction.update(orderRef, updateData);

      return {
        id: order_id.trim(),
        ...order,
        ...updateData,
        total: order.total,
        settled_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      };
    });

    return result;
  });
