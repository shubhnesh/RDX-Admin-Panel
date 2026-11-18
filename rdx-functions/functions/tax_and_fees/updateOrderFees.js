/**
 * updateOrderFees — admin-only fee configuration for order totals.
 *
 * Stored in Firestore: settings/fees
 * Only Cloud Functions (Admin SDK) write this document.
 * Clients may read for UI preview; order total math always uses server values.
 *
 * Client payload (SettingsService):
 *   { action: "updateFees", fees: { gst_percent, late_night_fee, ... } }
 *   { action: "setEnabled", enabled: boolean }
 *   { action: "setToggle", field: "late_night_delivery"|"long_distance_delivery", value: boolean }
 */

"use strict";

const functions = require("firebase-functions");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const { requireAdmin } = require("../auth/roles");

const db = admin.firestore();
const feesRef = db.collection("settings").doc("fees");

/** Sanity ceiling for any single monetary fee (₹). Adjust to your business. */
const MAX_FEE = 10000;

/** HH:MM or H:MM (24h). */
function isValidTime(value) {
  if (typeof value !== "string") return false;
  const m = value.trim().match(/^([01]?\d|2[0-3]):([0-5]\d)$/);
  return !!m;
}

/** Strict number: rejects null, "", booleans, NaN and Infinity. */
function toNumber(value, field) {
  const ok =
    (typeof value === "number" && Number.isFinite(value)) ||
    (typeof value === "string" &&
      value.trim() !== "" &&
      Number.isFinite(Number(value)));
  if (!ok) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} must be a valid number.`
    );
  }
  return Number(value);
}

/**
 * Validates and normalizes fee payload from the client.
 * All monetary values must be 0..MAX_FEE. GST 0–100.
 */
function normalizeFees(raw) {
  if (!raw || typeof raw !== "object") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "fees object is required."
    );
  }

  const gstPercent = toNumber(raw.gst_percent, "gst_percent");
  if (gstPercent < 0 || gstPercent > 100) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "gst_percent must be between 0 and 100."
    );
  }

  const lateNightFee = toNumber(raw.late_night_fee, "late_night_fee");
  const longDistanceFee = toNumber(raw.long_distance_fee, "long_distance_fee");
  const deliveryFee = toNumber(raw.delivery_fee, "delivery_fee");
  const freeDeliveryAbove = toNumber(
    raw.free_delivery_above ?? 0,
    "free_delivery_above"
  );

  for (const [name, value] of [
    ["late_night_fee", lateNightFee],
    ["long_distance_fee", longDistanceFee],
    ["delivery_fee", deliveryFee],
    ["free_delivery_above", freeDeliveryAbove],
  ]) {
    if (value < 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `${name} cannot be negative.`
      );
    }
    if (value > MAX_FEE) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        `${name} cannot exceed ${MAX_FEE}.`
      );
    }
  }

  const lateNightStart = String(raw.late_night_start || "22:00").trim();
  const lateNightEnd = String(raw.late_night_end || "06:00").trim();
  if (!isValidTime(lateNightStart) || !isValidTime(lateNightEnd)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      'late_night_start and late_night_end must be HH:MM (24-hour), e.g. "22:00".'
    );
  }

  const result = {
    gst_percent: gstPercent,
    late_night_fee: lateNightFee,
    late_night_start: lateNightStart,
    late_night_end: lateNightEnd,
    long_distance_fee: longDistanceFee,
    delivery_fee: deliveryFee,
    free_delivery_above: freeDeliveryAbove,
  };

  // Optional toggles when sent with amount updates
  if (typeof raw.late_night_delivery === "boolean") {
    result.late_night_delivery = raw.late_night_delivery;
  }
  if (typeof raw.long_distance_delivery === "boolean") {
    result.long_distance_delivery = raw.long_distance_delivery;
  }

  return result;
}

const TOGGLE_FIELDS = new Set([
  "late_night_delivery",
  "long_distance_delivery",
]);

// APP: ADMIN APP — restaurant order-fee configuration.
const updateOrderFees = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const { uid: callerUid } = requireAdmin(context);
    const action = String((data && data.action) || "").trim();

    if (action === "setEnabled") {
      // Strict boolean: "false" (string) must not become true.
      if (typeof (data && data.enabled) !== "boolean") {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "enabled must be a boolean."
        );
      }
      const enabled = data.enabled;
      await feesRef.set(
        {
          fees_enabled: enabled,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_by: callerUid,
        },
        { merge: true }
      );
      logger.info("updateOrderFees setEnabled", { enabled, by: callerUid });
      return { ok: true, fees_enabled: enabled };
    }

    if (action === "setToggle") {
      const field = String((data && data.field) || "").trim();
      if (!TOGGLE_FIELDS.has(field) || typeof (data && data.value) !== "boolean") {
        throw new functions.https.HttpsError(
          "invalid-argument",
          'field must be "late_night_delivery" or "long_distance_delivery" and value a boolean.'
        );
      }
      await feesRef.set(
        {
          [field]: data.value,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_by: callerUid,
        },
        { merge: true }
      );
      logger.info("updateOrderFees setToggle", {
        field,
        value: data.value,
        by: callerUid,
      });
      return { ok: true, [field]: data.value };
    }

    if (action === "updateFees") {
      const fees = normalizeFees(data && data.fees);
      await feesRef.set(
        {
          ...fees,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_by: callerUid,
        },
        { merge: true }
      );
      logger.info("updateOrderFees updateFees", {
        by: callerUid,
        keys: Object.keys(fees),
      });
      return { ok: true, fees };
    }

    throw new functions.https.HttpsError(
      "invalid-argument",
      'action must be "updateFees", "setEnabled", or "setToggle".'
    );
  });

module.exports = { updateOrderFees };
