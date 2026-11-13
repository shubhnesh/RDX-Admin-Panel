"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { requireAuth } = require("../auth/roles");

const db = admin.firestore();
const filterTypes = new Set(["category", "regionality", "tag", "preparation"]);
const sortOrders = new Set(["none", "priceLowToHigh", "priceHighToLow"]);

function invalid(message) {
  throw new functions.https.HttpsError("invalid-argument", message);
}

function normalize(value) {
  return String(value || "").trim().toLowerCase();
}

function displayPrice(item) {
  if (Array.isArray(item.sizes) && item.sizes.length > 0) {
    const prices = item.sizes
      .map((size) =>
        size && size.price != null ? Number(size.price) : Number.NaN
      )
      .filter(Number.isFinite);
    if (prices.length > 0) return Math.min(...prices);
  }
  const price = item.price == null ? Number.NaN : Number(item.price);
  return Number.isFinite(price) ? price : 0;
}

function isAvailable(item) {
  return item.is_available !== false && item.available !== false;
}

function matchesFilter(item, filterType, filterValue, categoryIds) {
  if (!filterValue) return true;

  switch (filterType) {
    case "category": {
      const value = normalize(filterValue);
      return normalize(item.category) === value ||
        normalize(item.primary_category_id) === value ||
        categoryIds.has(normalize(item.primary_category_id));
    }
    case "regionality":
      return normalize(item.regionality) === normalize(filterValue);
    case "tag":
      return Array.isArray(item.tags) &&
        item.tags.some((tag) => normalize(tag) === normalize(filterValue));
    case "preparation":
      return normalize(item.preparation) === normalize(filterValue);
    default:
      return false;
  }
}

exports.filterMenuItems = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    requireAuth(context);

    if (!data || typeof data !== "object" || Array.isArray(data)) {
      invalid("The menu filter request is invalid.");
    }
    const allowedKeys = new Set(["filter_type", "filter_value", "sort_order"]);
    if (Object.keys(data).some((key) => !allowedKeys.has(key))) {
      invalid("The menu filter request contains unsupported fields.");
    }

    const filterType = data.filter_type;
    const sortOrder = data.sort_order;
    const filterValue = data.filter_value == null ? "" : data.filter_value;
    if (!filterTypes.has(filterType)) {
      invalid("Choose a valid menu filter.");
    }
    if (!sortOrders.has(sortOrder)) {
      invalid("Choose a valid menu sort order.");
    }
    if (typeof filterValue !== "string" || filterValue.trim().length > 100) {
      invalid("The menu filter value is invalid.");
    }

    const selectedValue = filterValue.trim();
    const categoryIds = new Set();
    if (filterType === "category" && selectedValue) {
      const categorySnapshot = await db.collection("menu_categories").get();
      for (const doc of categorySnapshot.docs) {
        if (normalize(doc.data().name) === normalize(selectedValue)) {
          categoryIds.add(normalize(doc.id));
        }
      }
    }

    const snapshot = await db.collection("menu_items").get();
    const items = snapshot.docs
      .map((doc) => ({ id: doc.id, ...doc.data() }))
      .filter((item) =>
        isAvailable(item) &&
        matchesFilter(item, filterType, selectedValue, categoryIds)
      );

    if (sortOrder === "priceLowToHigh") {
      items.sort((a, b) =>
        displayPrice(a) - displayPrice(b) ||
        normalize(a.name).localeCompare(normalize(b.name))
      );
    } else if (sortOrder === "priceHighToLow") {
      items.sort((a, b) =>
        displayPrice(b) - displayPrice(a) ||
        normalize(a.name).localeCompare(normalize(b.name))
      );
    } else {
      items.sort((a, b) =>
        (Number(a.sort_order) || 0) - (Number(b.sort_order) || 0) ||
        normalize(a.name).localeCompare(normalize(b.name))
      );
    }

    return { items: items.map((item) => item.id) };
  });
