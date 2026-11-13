/**
 * manageRestaurantSettings — admin-only restaurant profile and hours updates.
 */

"use strict";

const functions = require("firebase-functions");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const { requireAdmin } = require("../auth/roles");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const settingsRef = db.collection("settings").doc("restaurant");
const profileFields = [
  "restaurant_name",
  "description",
  "address",
  "phone",
  "email",
];
const toggleFields = new Set([
  "auto_accept_orders",
  "require_manager_approval_for_refunds",
  "keep_pricing_consistent",
  "late_night_delivery",
  "long_distance_delivery",
]);

function requiredText(value, field, maxLength) {
  if (typeof value !== "string" || value.trim().length === 0 ||
      value.trim().length > maxLength) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} must contain between 1 and ${maxLength} characters.`
    );
  }
  return value.trim();
}

function optionalText(value, field, maxLength) {
  if (typeof value !== "string" || value.trim().length > maxLength) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} must be no more than ${maxLength} characters.`
    );
  }
  return value.trim();
}

function normalizeHours(value, label) {
  if (!value || typeof value !== "object") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${label} hours are required.`
    );
  }
  const open = requiredText(value.open, `${label} opening time`, 20);
  const close = requiredText(value.close, `${label} closing time`, 20);
  const timePattern = /^(0?[1-9]|1[0-2]):[0-5]\d\s?(AM|PM)$/i;
  if (!timePattern.test(open) || !timePattern.test(close) ||
      typeof value.is_open !== "boolean") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${label} hours must include valid 12-hour opening/closing times and an is_open flag.`
    );
  }
  return { open, close, is_open: value.is_open };
}

// APP: ADMIN APP — restaurant profile, operating hours, and settings.
const manageRestaurantSettings = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const { uid } = requireAdmin(context);
    const action = String(data?.action || "");
    logger.info("Restaurant settings request started", { uid, action });

    try {
      if (action === "updateProfile") {
        const profile = data.profile || {};
        const updates = {
          restaurant_name: requiredText(
            profile.restaurant_name,
            "Restaurant name",
            120
          ),
          description: optionalText(profile.description || "", "Description", 1000),
          address: optionalText(profile.address || "", "Address", 500),
          phone: optionalText(profile.phone || "", "Phone", 40),
          email: optionalText(profile.email || "", "Email", 254),
        };
        await settingsRef.set({
          ...updates,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_by: uid,
        }, { merge: true });
        logger.info("Restaurant profile updated", { uid, fields: Object.keys(updates) });
        return { ok: true };
      }

      if (action === "updateOperatingHours") {
        const hours = data.hours || {};
        const updates = {
          weekdays: normalizeHours(hours.weekdays, "Weekdays"),
          weekends: normalizeHours(hours.weekends, "Weekends"),
        };
        await settingsRef.set({
          ...updates,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_by: uid,
        }, { merge: true });
        logger.info("Restaurant operating hours updated", { uid });
        return { ok: true };
      }

      if (action === "updateToggle") {
        const field = String(data.field || "");
        if (!toggleFields.has(field) || typeof data.value !== "boolean") {
          throw new functions.https.HttpsError(
            "invalid-argument",
            "A supported toggle field and boolean value are required."
          );
        }
        await settingsRef.set({
          [field]: data.value,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_by: uid,
        }, { merge: true });
        logger.info("Restaurant settings toggle updated", {
          uid,
          field,
          value: data.value,
        });
        return { ok: true };
      }

      throw new functions.https.HttpsError(
        "invalid-argument",
        "Unsupported restaurant settings action."
      );
    } catch (error) {
      logger.error("Restaurant settings request failed", {
        uid,
        action,
        error_code: error.code || null,
        error_message: error.message || String(error),
      });
      throw error;
    }
  });

module.exports = { manageRestaurantSettings };
