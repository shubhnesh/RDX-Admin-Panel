/**
 * roles.js — Auth & role guards for RDX Cloud Functions
 *
 * Custom claims (set only via Admin SDK):
 *   { role: "admin" | "staff" }
 */

"use strict";

const functions = require("firebase-functions");

/**
 * @param {functions.https.CallableContext} context
 * @returns {"admin"|"staff"|null}
 */
function getRole(context) {
  if (!context.auth || !context.auth.token) return null;
  const r = context.auth.token.role;
  if (r === "admin" || r === "staff") return r;
  return null;
}

function requireAuth(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be signed in."
    );
  }
  return context.auth.uid;
}

/**
 * Admin or staff — restaurant workers using the admin/POS app.
 */
function requireRestaurantUser(context) {
  requireAuth(context);
  const role = getRole(context);
  if (role !== "admin" && role !== "staff") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Restaurant access required. Your account has no admin/staff role."
    );
  }
  return { uid: context.auth.uid, role };
}

/**
 * Admin only — catalog, settings, rewards.
 * // (user provisioning / user management screen disabled)
 */
function requireAdmin(context) {
  requireAuth(context);
  const role = getRole(context);
  if (role !== "admin") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Admin access required."
    );
  }
  return { uid: context.auth.uid, role: "admin" };
}

module.exports = {
  getRole,
  requireAuth,
  requireRestaurantUser,
  requireAdmin,
};
