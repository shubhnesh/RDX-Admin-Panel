/**
 * managedUsers.js — Restaurant app user provisioning (SERVER ONLY)
 *
 * Auth custom claim `role`:
 *   "admin" — full management
 *   "staff" — day-to-day worker role (NOT a group that includes admins)
 *
 * Claims are set exclusively via Firebase Admin SDK in this file.
 * The Flutter client never imports firebase-admin and cannot set claims.
 *
 * Callables (requireAdmin except bootstrapAdmin):
 *   bootstrapAdmin      — allowlisted first admin only (env ADMIN_BOOTSTRAP_EMAILS)
 *   listManagedUsers
 *   setUserRole
 *   createManagedUser
 *   disableManagedUser
 */

"use strict";

const functions = require("firebase-functions");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const { requireAdmin, requireAuth } = require("./roles");

const db = admin.firestore();

function bootstrapEmails() {
  return new Set(
    (process.env.ADMIN_BOOTSTRAP_EMAILS || "")
      .split(",")
      .map((email) => email.trim().toLowerCase())
      .filter(Boolean)
  );
}

async function hasOtherAdmin(excludedUid) {
  let pageToken;
  do {
    const page = await admin.auth().listUsers(1000, pageToken);
    if (
      page.users.some(
        (user) =>
          user.uid !== excludedUid && user.customClaims?.role === "admin"
      )
    ) {
      return true;
    }
    pageToken = page.pageToken;
  } while (pageToken);
  return false;
}

/**
 * Promote signed-in user only if email is on ADMIN_BOOTSTRAP_EMAILS
 * (Functions environment — not present in the app binary).
 */
// APP: ADMIN APP — allowlisted first-admin account bootstrap.
const bootstrapAdmin = functions
  .region("us-central1")
  .https.onCall(async (_data, context) => {
    const uid = requireAuth(context);
    const allowedEmails = bootstrapEmails();
    if (allowedEmails.size === 0) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Admin bootstrap is not configured."
      );
    }

    const email = String(context.auth.token.email || "")
      .trim()
      .toLowerCase();

    if (!email || !allowedEmails.has(email)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "This account is not authorized for admin setup."
      );
    }

    const user = await admin.auth().getUser(uid);
    if ((user.email || "").trim().toLowerCase() !== email) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "The signed-in account email could not be verified."
      );
    }

    await admin.auth().setCustomUserClaims(uid, {
      ...(user.customClaims || {}),
      role: "admin",
    });
    await db.collection("staff_profiles").doc(uid).set(
      {
        email,
        display_name: user.displayName || null,
        role: "admin",
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return { ok: true, uid, role: "admin" };
  });

/**
 * Lists Auth users that have role claim admin | staff.
 */
// APP: ADMIN APP — list provisioned admin and staff accounts.
const listManagedUsers = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    requireAdmin(context);

    const limit = Math.min(
      Math.max(Number((data && data.limit) || 100) || 100, 1),
      1000
    );
    const pageToken =
      data && data.pageToken ? String(data.pageToken) : undefined;

    const page = await admin.auth().listUsers(limit, pageToken);
    const users = [];

    for (const user of page.users) {
      const role = (user.customClaims && user.customClaims.role) || null;
      if (role !== "admin" && role !== "staff") continue;

      users.push({
        uid: user.uid,
        email: user.email || "",
        display_name: user.displayName || null,
        role,
        disabled: !!user.disabled,
        created_at:
          user.metadata && user.metadata.creationTime
            ? user.metadata.creationTime
            : null,
      });
    }

    return {
      users,
      nextPageToken: page.pageToken || null,
    };
  });

/**
 * data: { uid: string, role: "admin" | "staff" }
 */
// APP: ADMIN APP — change a managed user's admin/staff role.
const setUserRole = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const { uid: callerUid } = requireAdmin(context);

    const uid = String((data && data.uid) || "").trim();
    const role = String((data && data.role) || "")
      .trim()
      .toLowerCase();

    if (!uid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "uid is required."
      );
    }
    if (role !== "admin" && role !== "staff") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        'role must be "admin" or "staff".'
      );
    }

    if (uid === callerUid && role !== "admin") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "You cannot remove your own admin role."
      );
    }

    const target = await admin.auth().getUser(uid);
    if (
      target.customClaims?.role === "admin" &&
      role === "staff" &&
      !(await hasOtherAdmin(uid))
    ) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "At least one admin account must remain."
      );
    }

    await admin.auth().setCustomUserClaims(uid, {
      ...(target.customClaims || {}),
      role,
    });

    await db
      .collection("staff_profiles")
      .doc(uid)
      .set(
        {
          email: (target.email || "").toLowerCase() || null,
          display_name: target.displayName || null,
          role,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_by: callerUid,
        },
        { merge: true }
      );

    logger.info("setUserRole", { targetUid: uid, role, by: callerUid });
    return { ok: true, uid, role };
  });

/**
 * data: { uid, email, displayName, role: "admin"|"staff" }
 */
// APP: ADMIN APP — update a managed user's account details and role.
const updateManagedUser = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const { uid: callerUid } = requireAdmin(context);
    const uid = String((data && data.uid) || "").trim();
    const email = String((data && data.email) || "")
      .trim()
      .toLowerCase();
    const displayName = String((data && data.displayName) || "").trim();
    const role = String((data && data.role) || "")
      .trim()
      .toLowerCase();

    if (!uid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "uid is required."
      );
    }
    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid email address is required."
      );
    }
    if (displayName.length > 40) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Display name must be 40 characters or fewer."
      );
    }
    if (role !== "admin" && role !== "staff") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        'role must be "admin" or "staff".'
      );
    }
    if (uid === callerUid && role !== "admin") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "You cannot remove your own admin role."
      );
    }

    const target = await admin.auth().getUser(uid);
    if (
      target.customClaims?.role === "admin" &&
      role === "staff" &&
      !(await hasOtherAdmin(uid))
    ) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "At least one admin account must remain."
      );
    }

    const emailChanged = (target.email || "").toLowerCase() !== email;
    await admin.auth().updateUser(uid, {
      email,
      displayName: displayName || null,
      ...(emailChanged ? { emailVerified: false } : {}),
    });

    if (target.customClaims?.role !== role) {
      await admin.auth().setCustomUserClaims(uid, {
        ...(target.customClaims || {}),
        role,
      });
    }

    await db.collection("staff_profiles").doc(uid).set(
      {
        email,
        display_name: displayName || null,
        role,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_by: callerUid,
      },
      { merge: true }
    );

    logger.info("updateManagedUser", { targetUid: uid, role, by: callerUid });
    return { ok: true, uid, email, displayName, role };
  });

/**
 * data: { email, password, displayName?, role?: "admin"|"staff" }
 */
// APP: ADMIN APP — provision restaurant admin/staff accounts.
const createManagedUser = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const { uid: callerUid } = requireAdmin(context);

    const email = String((data && data.email) || "")
      .trim()
      .toLowerCase();
    const password = String((data && data.password) || "");
    const displayName = String((data && data.displayName) || "").trim();
    const role = String((data && data.role) || "staff")
      .trim()
      .toLowerCase();

    if (!email || password.length < 6) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Valid email and password (min 6 characters) are required."
      );
    }
    if (role !== "admin" && role !== "staff") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        'role must be "admin" or "staff".'
      );
    }

    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: displayName || undefined,
      emailVerified: false,
      disabled: false,
    });

    await admin.auth().setCustomUserClaims(userRecord.uid, { role });

    await db.collection("staff_profiles").doc(userRecord.uid).set({
      email,
      display_name: displayName || null,
      role,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      created_by: callerUid,
    });

    return {
      ok: true,
      uid: userRecord.uid,
      email,
      role,
    };
  });

/**
 * data: { uid: string }
 */
// APP: ADMIN APP — disable a managed restaurant account.
const disableManagedUser = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const { uid: callerUid } = requireAdmin(context);

    const uid = String((data && data.uid) || "").trim();
    if (!uid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "uid is required."
      );
    }
    if (uid === callerUid) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "You cannot disable your own account."
      );
    }

    const target = await admin.auth().getUser(uid);
    if (
      target.customClaims?.role === "admin" &&
      !(await hasOtherAdmin(uid))
    ) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "At least one admin account must remain."
      );
    }

    await admin.auth().updateUser(uid, { disabled: true });
    await db.collection("staff_profiles").doc(uid).set(
      {
        disabled: true,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_by: callerUid,
      },
      { merge: true }
    );

    return { ok: true, uid, disabled: true };
  });

module.exports = {
  bootstrapAdmin,
  listManagedUsers,
  setUserRole,
  updateManagedUser,
  createManagedUser,
  disableManagedUser,
};
