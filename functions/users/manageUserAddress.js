"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.firestore();
const maxSavedAddresses = 3;
const maxLabelLength = 40;
const maxTagLength = 120;
const maxAddressLength = 500;

function invalid(message) {
  throw new functions.https.HttpsError("invalid-argument", message);
}

function readAddressFields(data) {
  const labelType = String(data.label_type || "").trim().toLowerCase();
  const suppliedLabel = typeof data.label === "string" ? data.label.trim() : "";
  let label;
  if (labelType === "home") {
    if (suppliedLabel !== "Home") invalid("The Home label is invalid.");
    label = "Home";
  } else if (labelType === "work") {
    if (suppliedLabel !== "Work") invalid("The Work label is invalid.");
    label = "Work";
  } else if (labelType === "other") {
    label = suppliedLabel;
    if (!label || label.length > maxLabelLength) {
      invalid(`Enter an address label of up to ${maxLabelLength} characters.`);
    }
  } else {
    invalid("Choose Home, Work, or Other for the address label.");
  }

  const addressLine =
    typeof data.address_line === "string" ? data.address_line.trim() : "";
  const tag = typeof data.tag === "string" ? data.tag.trim() : "";
  if (!addressLine || addressLine.length > maxAddressLength) {
    invalid(`Enter a delivery address of up to ${maxAddressLength} characters.`);
  }
  if (tag.length > maxTagLength) {
    invalid(`The building or area must be at most ${maxTagLength} characters.`);
  }

  return {
    label,
    label_type: labelType,
    tag,
    address_line: addressLine,
  };
}

function readAddressId(data) {
  const id = typeof data.address_id === "string" ? data.address_id.trim() : "";
  if (!id || id.includes("/")) invalid("The address ID is invalid.");
  return id;
}

exports.manageUserAddress = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Sign in to manage saved addresses."
      );
    }

    if (!data || typeof data !== "object" || Array.isArray(data)) {
      invalid("The address request is invalid.");
    }

    const uid = context.auth.uid;
    const userRef = db.collection("users").doc(uid);
    const addressesRef = userRef.collection("addresses");
    const action = data.action;

    if (action === "add") {
      const fields = readAddressFields(data);
      const addressRef = addressesRef.doc();
      await db.runTransaction(async (transaction) => {
        const addressesSnapshot = await transaction.get(addressesRef);
        await transaction.get(userRef);
        if (addressesSnapshot.size >= maxSavedAddresses) {
          throw new functions.https.HttpsError(
            "resource-exhausted",
            `You can save up to ${maxSavedAddresses} addresses.`
          );
        }
        transaction.set(addressRef, {
          ...fields,
          image: "",
          badge: "",
          is_default: false,
        });
        transaction.set(
          userRef,
          { saved_address_count: addressesSnapshot.size + 1 },
          { merge: true }
        );
      });
      return { id: addressRef.id };
    }

    if (action === "update") {
      const id = readAddressId(data);
      const fields = readAddressFields(data);
      const addressRef = addressesRef.doc(id);
      await db.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(addressRef);
        if (!snapshot.exists) {
          throw new functions.https.HttpsError(
            "not-found",
            "The saved address no longer exists."
          );
        }
        transaction.update(addressRef, fields);
      });
      return { success: true };
    }

    if (action === "updateAddressLine") {
      const id = readAddressId(data);
      const addressLine =
        typeof data.address_line === "string" ? data.address_line.trim() : "";
      if (!addressLine || addressLine.length > maxAddressLength) {
        invalid(
          `Enter a delivery address of up to ${maxAddressLength} characters.`
        );
      }
      const addressRef = addressesRef.doc(id);
      await db.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(addressRef);
        if (!snapshot.exists) {
          throw new functions.https.HttpsError(
            "not-found",
            "The saved address no longer exists."
          );
        }
        transaction.update(addressRef, { address_line: addressLine });
      });
      return { success: true };
    }

    if (action === "setDefault") {
      const id = readAddressId(data);
      const addressRef = addressesRef.doc(id);
      await db.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(addressRef);
        if (!snapshot.exists) {
          throw new functions.https.HttpsError(
            "not-found",
            "The selected address no longer exists."
          );
        }
        transaction.set(
          userRef,
          { default_address_id: id },
          { merge: true }
        );
      });
      return { success: true };
    }

    if (action === "delete") {
      const id = readAddressId(data);
      const addressRef = addressesRef.doc(id);
      await db.runTransaction(async (transaction) => {
        const addressesSnapshot = await transaction.get(addressesRef);
        const addressSnapshot = await transaction.get(addressRef);
        const userSnapshot = await transaction.get(userRef);
        if (!addressSnapshot.exists) return;

        const userUpdate = {
          saved_address_count: Math.max(addressesSnapshot.size - 1, 0),
        };
        if (userSnapshot.data()?.default_address_id === id) {
          userUpdate.default_address_id = admin.firestore.FieldValue.delete();
        }
        transaction.delete(addressRef);
        transaction.set(userRef, userUpdate, { merge: true });
      });
      return { success: true };
    }

    invalid("The requested address operation is not supported.");
  });
