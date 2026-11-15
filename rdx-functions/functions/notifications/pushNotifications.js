"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { requireAdmin } = require("../auth/roles");
const { createFcmMessage } = require("./notificationPolicy");

const db = admin.firestore();
const MAX_DELIVERY_ATTEMPTS = 3;
const SENDING_LEASE_MS = 5 * 60 * 1000;

function cleanText(value) {
  return typeof value === "string" ? value.trim() : "";
}

function alreadyExists(error) {
  return error.code === 6 || error.code === "already-exists";
}

function isDue(data, now = Date.now()) {
  if (data.scheduled !== true) return true;
  const scheduledAt = data.scheduled_at;
  if (!scheduledAt) return false;
  const scheduledDate = typeof scheduledAt.toDate === "function"
    ? scheduledAt.toDate()
    : new Date(scheduledAt);
  return !Number.isNaN(scheduledDate.getTime()) &&
    scheduledDate.getTime() <= now;
}

async function deliverNotification(notificationRef) {
  const claim = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(notificationRef);
    if (!snapshot.exists) return null;

    const notification = snapshot.data() || {};
    if (notification.delivery_status === "sent" || !isDue(notification)) {
      return null;
    }

    const attempts = Number(notification.delivery_attempts) || 0;
    if (attempts >= MAX_DELIVERY_ATTEMPTS) return null;

    if (notification.delivery_status === "sending") {
      const startedAt = notification.delivery_started_at;
      const startedDate = startedAt && typeof startedAt.toDate === "function"
        ? startedAt.toDate()
        : null;
      if (
        startedDate &&
        Date.now() - startedDate.getTime() < SENDING_LEASE_MS
      ) {
        return null;
      }
    }

    const title = cleanText(notification.title);
    const message = cleanText(notification.message);
    if (!title || !message) {
      throw new Error("Notification title and message are required.");
    }

    transaction.update(notificationRef, {
      delivery_status: "sending",
      delivery_attempts: attempts + 1,
      delivery_started_at: admin.firestore.FieldValue.serverTimestamp(),
      delivery_error: admin.firestore.FieldValue.delete(),
    });

    return {
      notificationId: notificationRef.id,
      title,
      message,
      category: cleanText(notification.category) || "broadcast",
    };
  });

  if (!claim) return false;

  try {
    const messageId = await admin.messaging().send(
      createFcmMessage(claim)
    );
    await notificationRef.update({
      delivery_status: "sent",
      sent_at: admin.firestore.FieldValue.serverTimestamp(),
      fcm_message_id: messageId,
      delivery_error: admin.firestore.FieldValue.delete(),
    });
    return true;
  } catch (error) {
    await notificationRef.update({
      delivery_status: "failed",
      delivery_error: String(error.code || error.message || "send-failed")
        .slice(0, 200),
    });
    throw error;
  }
}

async function createAndDeliverNotification({
  eventId,
  title,
  message,
  category,
  sourceId,
}) {
  const notificationRef = db.collection("notifications").doc(eventId);
  try {
    await notificationRef.create({
      title,
      message,
      category,
      source_id: sourceId || null,
      audience: "allApp",
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      scheduled_at: null,
      sent_at: null,
      recipient_count: 0,
      scheduled: false,
      delivery_status: "pending",
      delivery_attempts: 0,
      source: "automatic",
    });
  } catch (error) {
    if (!alreadyExists(error)) throw error;
  }

  await deliverNotification(notificationRef);
}

exports.sendBroadcastNotification = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const { uid } = requireAdmin(context);
    const title = cleanText(data && data.title);
    const message = cleanText(data && data.message);

    if (!title || !message) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Both notification title and message are required."
      );
    }
    if (
      Buffer.byteLength(title, "utf8") > 1000 ||
      Buffer.byteLength(message, "utf8") > 3000
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The notification title or message is too long."
      );
    }

    const notificationRef = db.collection("notifications").doc();
    await notificationRef.create({
      title,
      message,
      category: "broadcast",
      audience: "allApp",
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      scheduled_at: null,
      sent_at: null,
      recipient_count: 0,
      scheduled: false,
      delivery_status: "pending",
      delivery_attempts: 0,
      source: "admin",
      created_by: uid,
    });

    try {
      await deliverNotification(notificationRef);
      return { id: notificationRef.id, delivery_status: "sent" };
    } catch (error) {
      functions.logger.error("Broadcast notification delivery failed.", {
        notificationId: notificationRef.id,
        errorCode: error.code || "unknown",
      });
      throw new functions.https.HttpsError(
        "internal",
        "The notification could not be sent."
      );
    }
  });

exports.processScheduledNotifications = functions
  .region("us-central1")
  .pubsub.schedule("every 1 minutes")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const due = await db.collection("notifications")
      .where("scheduled", "==", true)
      .where("sent_at", "==", null)
      .where("scheduled_at", "<=", now)
      .limit(100)
      .get();

    const retryStatuses = ["pending", "failed", "sending"];
    const retrySnapshots = await Promise.all(
      retryStatuses.map((status) =>
        db.collection("notifications")
          .where("delivery_status", "==", status)
          .limit(100)
          .get()
      )
    );

    const documents = new Map();
    for (const snapshot of [due, ...retrySnapshots]) {
      for (const doc of snapshot.docs) documents.set(doc.id, doc.ref);
    }

    await Promise.all(
      [...documents.values()].map(async (ref) => {
        try {
          await deliverNotification(ref);
        } catch (error) {
          functions.logger.error("Notification retry failed.", {
            notificationId: ref.id,
            errorCode: error.code || "unknown",
          });
        }
      })
    );

    return null;
  });

exports.createAndDeliverNotification = createAndDeliverNotification;
exports.deliverNotification = deliverNotification;
