"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {
  isMenuItemVisible,
  isPromotionActive,
  notificationDocumentId,
  buildAdminOrderNotification,
  isAdminInitiatedOrderStatusChange,
  isAdminInitiatedPaymentChange,
} = require("./notificationPolicy");
const { ADMIN_TOPIC } = require("./notificationPolicy");
const {
  createAndDeliverNotification,
} = require("./pushNotifications");
const { requireAuth } = require("../auth/roles");

const db = admin.firestore();
const REGION = "us-central1";

function eventDocumentId(category, eventId) {
  return notificationDocumentId(category, eventId);
}

function publishEvent(
  category,
  eventId,
  title,
  message,
  sourceId,
  { customer = true, admin = false } = {}
) {
  const deliveries = [];
  if (customer) {
    deliveries.push(createAndDeliverNotification({
      eventId: eventDocumentId(category, eventId),
      title,
      message,
      category,
      sourceId,
      audience: "allApp",
    }));
  }
  if (admin) {
    deliveries.push(createAndDeliverNotification({
      eventId: eventDocumentId(`${category}_admin`, eventId),
      title,
      message,
      category,
      sourceId,
      audience: "admin",
      topic: ADMIN_TOPIC,
    }));
  }
  return Promise.all(deliveries);
}

function orderAmount(order) {
  const amount = Number(order.total);
  return Number.isFinite(amount) && amount > 0
    ? ` Total: Rs. ${amount.toFixed(2)}.`
    : "";
}

function statusLabel(status) {
  const value = String(status || "").trim().toLowerCase();
  return value ? value.charAt(0).toUpperCase() + value.slice(1) : "Updated";
}

function itemName(data, fallback = "A menu item") {
  const name = String(data.name || "").trim();
  return name || fallback;
}

exports.notifyMenuItemCreated = functions
  .region(REGION)
  .firestore.document("menu_items/{itemId}")
  .onCreate(async (snapshot, context) => {
    const item = snapshot.data() || {};
    if (!isMenuItemVisible(item)) return null;

    return publishEvent(
      "menu",
      context.eventId,
      "New menu item",
      `Now available: ${itemName(item)}.`,
      context.params.itemId
    );
  });

function ignoreDocumentUpdates(collection) {
  return functions
    .region(REGION)
    .firestore.document(`${collection}/{documentId}`)
    .onUpdate(async () => null);
}

// Keep these exported names so deployments replace stale senders in place.
exports.notifyMenuItemUpdated = ignoreDocumentUpdates("menu_items");

function registerPromotionCreatedEvent(collection, category, titleFor) {
  const created = functions
    .region(REGION)
    .firestore.document(`${collection}/{documentId}`)
    .onCreate(async (snapshot, context) => {
      const promotion = snapshot.data() || {};
      if (!isPromotionActive(promotion)) return null;
      const title = titleFor(promotion);
      return publishEvent(
        category,
        context.eventId,
        title,
        `${titleFor(promotion, true)} is now available.`,
        context.params.documentId
      );
    });

  return created;
}

exports.notifyCouponCreated = registerPromotionCreatedEvent(
  "coupons",
  "coupon",
  (coupon, body = false) => {
    const code = String(coupon.code || "").trim();
    return body ? (code ? `Coupon ${code}` : "A new coupon") : "New coupon";
  }
);

exports.notifyCouponUpdated = ignoreDocumentUpdates("coupons");

exports.notifyOfferCreated = registerPromotionCreatedEvent(
  "offers",
  "offer",
  (offer, body = false) => {
    const title = String(offer.title || "").trim();
    return body ? (title || "A new offer") : "New offer";
  }
);

exports.notifyOfferUpdated = ignoreDocumentUpdates("offers");

exports.notifyAppOrderCreated = functions
  .region(REGION)
  .firestore.document("orders/{orderId}")
  .onCreate(async (snapshot, context) => {
    const order = snapshot.data() || {};
    if (
      String(order.order_source || "").toLowerCase() !== "app" ||
      !String(order.customer_id || "").trim()
    ) {
      return null;
    }

    const orderId = context.params.orderId;
    const notification = buildAdminOrderNotification(orderId, order);
    return createAndDeliverNotification({
      eventId: notification.id,
      title: notification.data.title,
      message: notification.data.message,
      category: notification.data.category,
      sourceId: notification.data.source_id,
      audience: notification.data.audience,
      topic: ADMIN_TOPIC,
    });
  });

exports.notifyAppOrderStatusChanged = functions
  .region(REGION)
  .firestore.document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    if (
      !String(after.customer_id || "").trim() ||
      String(before.status || "").toLowerCase() ===
        String(after.status || "").toLowerCase()
    ) {
      return null;
    }

    const status = statusLabel(after.status);
    const orderId = context.params.orderId;
    return publishEvent(
      "order",
      context.eventId,
      `Order ${status}`,
      `Order ${orderId} is now ${String(after.status || "updated").toLowerCase()}.`,
      orderId,
      {
        customer: true,
        admin: !isAdminInitiatedOrderStatusChange(after),
      }
    );
  });

exports.notifyOrderPaymentChanged = functions
  .region(REGION)
  .firestore.document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    const beforePaid = String(before.payment_status || "").toLowerCase() === "paid";
    const afterPaid = String(after.payment_status || "").toLowerCase() === "paid";
    if (beforePaid === afterPaid || !afterPaid) return null;

    const orderId = context.params.orderId;
    const method = String(after.payment_method || "the selected payment method")
      .trim();
    return publishEvent(
      "payment",
      context.eventId,
      "Payment completed",
      `Payment received for order ${orderId} via ${method}.${orderAmount(after)}`,
      orderId,
      {
        customer: true,
        admin: !isAdminInitiatedPaymentChange(after),
      }
    );
  });

exports.notifyOrderRefundChanged = functions
  .region(REGION)
  .firestore.document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    const wasCancelled =
      String(before.status || "").toLowerCase() === "cancelled";
    const isCancelled =
      String(after.status || "").toLowerCase() === "cancelled";
    if (wasCancelled || !isCancelled) return null;

    const refundedPoints =
      Math.max(0, Math.floor(Number(after.reward_points_refunded) || 0));
    const paid = String(after.payment_status || "").toLowerCase() === "paid";
    if (!paid && refundedPoints <= 0) return null;

    const orderId = context.params.orderId;
    const detail = paid
      ? `The paid amount for order ${orderId} is eligible for refund processing.`
      : `${refundedPoints} reward points were refunded for order ${orderId}.`;
    return publishEvent(
      "refund",
      context.eventId,
      "Refund update",
      detail,
      orderId,
      { customer: true, admin: true }
    );
  });

exports.notifySupportRequestCreated = functions
  .region(REGION)
  .firestore.document("support_requests/{requestId}")
  .onCreate(async (snapshot, context) => {
    const request = snapshot.data() || {};
    const subject = String(request.subject || "Support request").trim();
    const category = String(request.category || "general").trim();
    return publishEvent(
      "support",
      context.eventId,
      "New support request",
      `${category}: ${subject}`,
      context.params.requestId,
      { customer: false, admin: true }
    );
  });

exports.submitSupportRequest = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    const { uid } = requireAuth(context);
    const subject = String((data && data.subject) || "").trim();
    const message = String((data && data.message) || "").trim();
    const category = String((data && data.category) || "").trim();

    if (!subject || !message || !category) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Subject, message, and category are required."
      );
    }
    if (
      Buffer.byteLength(subject, "utf8") > 500 ||
      Buffer.byteLength(message, "utf8") > 5000 ||
      Buffer.byteLength(category, "utf8") > 100
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The support request contains a field that is too long."
      );
    }

    const requestRef = db.collection("support_requests").doc();
    await requestRef.create({
      user_id: uid,
      subject,
      message,
      category,
      status: "open",
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { id: requestRef.id };
  });

async function activateDuePromotions(collection) {
  const now = admin.firestore.Timestamp.now();
  const snapshot = await db.collection(collection)
    .where("status", "==", "scheduled")
    .where("start_date", "<=", now)
    .where("end_date", ">", now)
    .limit(100)
    .get();

  if (snapshot.empty) return;
  const batch = db.batch();
  for (const document of snapshot.docs) {
    batch.update(document.ref, {
      status: "active",
      activated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
}

exports.activateScheduledPromotions = functions
  .region(REGION)
  .pubsub.schedule("every 1 minutes")
  .onRun(async () => {
    await Promise.all([
      activateDuePromotions("coupons"),
      activateDuePromotions("offers"),
    ]);
    return null;
  });
