"use strict";

const admin = require("firebase-admin");

const db = admin.firestore();
const configRef = db.collection("settings").doc("rewards");

async function readStoredRewardConfiguration() {
  const snapshot = await configRef.get();
  if (!snapshot.exists) return null;
  const configuration = snapshot.data()?.config;
  return configuration && typeof configuration === "object"
    ? configuration
    : null;
}

module.exports = { readStoredRewardConfiguration };
