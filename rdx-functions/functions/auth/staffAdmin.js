/**
 * staffAdmin.js — Provision and manage restaurant roles
 *
 * Callables:
 *   bootstrapAdmin  — promote allowlisted email to admin
 *   // listStaffUsers  — list admin/staff (user management screen — disabled)
 *   // setUserRole     — change claim on an existing Auth user (user management screen — disabled)
 *   // createStaffUser — create Auth user + set role in one step (user management screen — disabled)
 */

"use strict";

const { randomUUID } = require("crypto");
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

function isBootstrapEmail(email) {
  return bootstrapEmails().has(String(email || "").trim().toLowerCase());
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
 * Promotes the signed-in user only when their email is on the server-side
 * ADMIN_BOOTSTRAP_EMAILS allowlist.
 */
const bootstrapAdmin = functions
  .region("us-central1")
  .https.onCall(async (_data, context) => {
    const uid = requireAuth(context);
    const allowedEmails = bootstrapEmails();
    if (allowedEmails.size === 0) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Admin bootstrap is not configured. Set ADMIN_BOOTSTRAP_EMAILS in the Functions environment."
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

// --- User management screen callables (disabled) ---

// /**
//  * MINIMAL version — only checks admin role and returns empty list.
//  * Use this to confirm the callable itself works.
//  * data: { pageToken?: string, limit?: number }
//  */
// const listStaffUsers = functions
//   .region("us-central1")
//   .https.onCall(async (data, context) => {
//     const requestId = randomUUID();
//     let stage = "admin_authorization";
//
//     logger.info("listStaffUsers started", {
//       requestId,
//       handlerVersion: "minimal-debug-v1",
//     });
//
//     try {
//       requireAdmin(context);
//       logger.info("listStaffUsers admin authorization succeeded", {
//         requestId,
//       });
//
//       stage = "response";
//       const response = {
//         users: [],
//         nextPageToken: null,
//       };
//       logger.info("listStaffUsers returning response", {
//         requestId,
//         userCount: response.users.length,
//       });
//       return response;
//     } catch (error) {
//       const errorCode =
//         error instanceof functions.https.HttpsError ? error.code : "internal";
//       logger.error("listStaffUsers failed", {
//         requestId,
//         stage,
//         errorCode,
//         errorName: error?.name || "Error",
//         errorMessage:
//           typeof error?.message === "string"
//             ? error.message.slice(0, 200)
//             : undefined,
//       });
//
//       if (error instanceof functions.https.HttpsError) {
//         throw error;
//       }
//
//       throw new functions.https.HttpsError(
//         "internal",
//         "Unable to list staff users.",
//         { requestId }
//       );
//     }
//   });

// /**
//  * data: { uid: string, role: "admin" | "staff" }
//  */
// const setUserRole = functions
//   .region("us-central1")
//   .https.onCall(async (data, context) => {
//     const { uid: callerUid } = requireAdmin(context);
//
//     const uid = String(data.uid || "").trim();
//     const role = String(data.role || "")
//       .trim()
//       .toLowerCase();
//
//     if (!uid) {
//       throw new functions.https.HttpsError(
//         "invalid-argument",
//         "uid is required."
//       );
//     }
//     if (role !== "admin" && role !== "staff") {
//       throw new functions.https.HttpsError(
//         "invalid-argument",
//         'role must be "admin" or "staff".'
//       );
//     }
//
//     if (uid === callerUid && role !== "admin") {
//       throw new functions.https.HttpsError(
//         "failed-precondition",
//         "You cannot remove your own admin role."
//       );
//     }
//
//     const target = await admin.auth().getUser(uid);
//     if (role === "admin" && !isBootstrapEmail(target.email)) {
//       throw new functions.https.HttpsError(
//         "permission-denied",
//         "Only allowlisted email accounts can be admins."
//       );
//     }
//     if (
//       target.customClaims?.role === "admin" &&
//       role === "staff" &&
//       !(await hasOtherAdmin(uid))
//     ) {
//       throw new functions.https.HttpsError(
//         "failed-precondition",
//         "At least one admin account must remain."
//       );
//     }
//
//     await admin.auth().setCustomUserClaims(uid, {
//       ...(target.customClaims || {}),
//       role,
//     });
//
//     await db
//       .collection("staff_profiles")
//       .doc(uid)
//       .set(
//         {
//           role,
//           updated_at: admin.firestore.FieldValue.serverTimestamp(),
//           updated_by: callerUid,
//         },
//         { merge: true }
//       );
//
//     return { ok: true, uid, role };
//   });

// /**
//  * data: {
//  *   email: string,
//  *   password: string,
//  *   displayName?: string,
//  *   role?: "admin" | "staff"
//  * }
//  */
// const createStaffUser = functions
//   .region("us-central1")
//   .https.onCall(async (data, context) => {
//     const { uid: callerUid } = requireAdmin(context);
//
//     const email = String(data.email || "")
//       .trim()
//       .toLowerCase();
//     const password = String(data.password || "");
//     const displayName = String(data.displayName || "").trim();
//     const role = String(data.role || "staff")
//       .trim()
//       .toLowerCase();
//
//     if (!email || password.length < 6) {
//       throw new functions.https.HttpsError(
//         "invalid-argument",
//         "Valid email and password (min 6 characters) are required."
//       );
//     }
//     if (role !== "admin" && role !== "staff") {
//       throw new functions.https.HttpsError(
//         "invalid-argument",
//         'role must be "admin" or "staff".'
//       );
//     }
//     if (role === "admin" && !isBootstrapEmail(email)) {
//       throw new functions.https.HttpsError(
//         "permission-denied",
//         "Only allowlisted email accounts can be admins."
//       );
//     }
//
//     const userRecord = await admin.auth().createUser({
//       email,
//       password,
//       displayName: displayName || undefined,
//       emailVerified: false,
//       disabled: false,
//     });
//
//     await admin.auth().setCustomUserClaims(userRecord.uid, { role });
//
//     await db
//       .collection("staff_profiles")
//       .doc(userRecord.uid)
//       .set({
//         email,
//         display_name: displayName || null,
//         role,
//         created_at: admin.firestore.FieldValue.serverTimestamp(),
//         created_by: callerUid,
//       });
//
//     return {
//       ok: true,
//       uid: userRecord.uid,
//       email,
//       role,
//     };
//   });

module.exports = {
  bootstrapAdmin,
  // listStaffUsers,   // user management screen — disabled
  // setUserRole,      // user management screen — disabled
  // createStaffUser,  // user management screen — disabled
};
