"use strict";

const functions = require("firebase-functions");
const {
  awardReferralForDeliveredOrder,
} = require("../referrals/referrals");
const {
  awardPointsForDeliveredOrder,
} = require("./earnOnDelivery");

exports.processOrderRewards = functions
  .region("us-central1")
  .firestore.document("orders/{orderId}")
  .onWrite(async (change, context) => {
    if (!change.after.exists) return null;

    const order = change.after.data() || {};
    const previousOrder = change.before.exists ? change.before.data() || {} : {};
    const qualificationFieldsChanged =
      !change.before.exists ||
      previousOrder.status !== order.status ||
      previousOrder.payment_status !== order.payment_status;
    if (!qualificationFieldsChanged) return null;

    const status = String(order.status || "").toLowerCase();
    const paymentStatus = String(order.payment_status || "").toLowerCase();
    if (status !== "delivered" && paymentStatus !== "paid") return null;

    if (status === "delivered" && paymentStatus === "paid") {
      await awardPointsForDeliveredOrder(context.params.orderId, order);
    }
    await awardReferralForDeliveredOrder(context.params.orderId, order);
    return null;
  });
