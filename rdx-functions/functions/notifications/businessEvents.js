"use strict";

const crypto = require("crypto");
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {
  isMenuItemVisible,
  isPromotionActive,
} = require("./notificationPolicy");
const {
  createAndDeliverNotification,
} = require("./pushNotifications");
const { requireAuth } = require("../auth/roles");

const db = admin.firestore();
const REGION = "us-central1";

function eventDocumentId(category, eventId) {
  const hash = crypto.createHash("sha256").update(eventId).digest("hex");
  return `auto_${category}_${hash}`;
}

function publishEvent(category, eventId, title, message, sourceId) {
  return createAndDeliverNotification({
    eventId: eventDocumentId(category, eventId),
    title,
    message,
    category,
    sourceId,
  });
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

    return publishEvent(
      "order",
      context.eventId,
      "New order activity",
      "A customer placed a new order.",
      context.params.orderId
    );
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

    return publishEvent(
      "order",
      context.eventId,
      "Order status updated",
      "An order status has changed.",
      context.params.orderId
    );
  });

exports.notifySupportRequestCreated = functions
  .region(REGION)
  .firestore.document("support_requests/{requestId}")
  .onCreate(async (_snapshot, context) =>
    publishEvent(
      "support",
      context.eventId,
      "Support activity",
      "A new support request has been submitted.",
      context.params.requestId
    )
  );

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
