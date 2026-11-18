/**
 * manageInventory — server-authoritative inventory reads and mutations.
 */

"use strict";

const functions = require("firebase-functions");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const { requireAdmin, requireRestaurantUser } = require("../auth/roles");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const DAY_MS = 24 * 60 * 60 * 1000;
const IST_OFFSET_MS = (5 * 60 + 30) * 60 * 1000;

function number(value, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function toDate(value) {
  if (!value) return null;
  if (typeof value.toDate === "function") return value.toDate();
  if (value instanceof Date) return value;
  if (typeof value === "string" || typeof value === "number") {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  return null;
}

function dateToIso(value) {
  return toDate(value)?.toISOString() || null;
}

function stockStatus(quantity, minimum) {
  if (quantity <= 0) return "out_of_stock";
  if (minimum > 0 && quantity < minimum * 0.25) return "critical";
  if (quantity < minimum) return "low_stock";
  return "in_stock";
}

function stockPercent(quantity, minimum, maximum) {
  if (maximum > 0) return Math.min((quantity / maximum) * 100, 100);
  if (minimum > 0) {
    return Math.min(Math.max(quantity / (minimum * 2), 0), 1.5) * 100;
  }
  return quantity > 0 ? 100 : 0;
}

function stockFillFraction(quantity, minimum, maximum) {
  return Math.min(Math.max(stockPercent(quantity, minimum, maximum) / 100, 0), 1);
}

function weightedAverageUnitCost(
  currentQuantity,
  currentTotalCost,
  addedQuantity,
  purchaseCost
) {
  const totalQuantity = currentQuantity + addedQuantity;
  return totalQuantity > 0
    ? (currentTotalCost + purchaseCost) / totalQuantity
    : 0;
}

function startOfIstDay(date = new Date()) {
  const shifted = new Date(date.getTime() + IST_OFFSET_MS);
  return new Date(Date.UTC(
    shifted.getUTCFullYear(),
    shifted.getUTCMonth(),
    shifted.getUTCDate()
  ) - IST_OFFSET_MS);
}

function resolvePeriod(period, now = new Date()) {
  if (period === "overall") return null;
  const today = startOfIstDay(now);
  if (period === "today") return { start: today, end: new Date(today.getTime() + DAY_MS) };
  if (period === "yesterday") {
    return { start: new Date(today.getTime() - DAY_MS), end: today };
  }

  const shifted = new Date(today.getTime() + IST_OFFSET_MS);
  if (period === "this_week") {
    const daysSinceMonday = (shifted.getUTCDay() + 6) % 7;
    const start = new Date(today.getTime() - daysSinceMonday * DAY_MS);
    return { start, end: new Date(start.getTime() + 7 * DAY_MS) };
  }
  if (period === "this_month") {
    const start = new Date(Date.UTC(
      shifted.getUTCFullYear(),
      shifted.getUTCMonth(),
      1
    ) - IST_OFFSET_MS);
    const end = new Date(Date.UTC(
      shifted.getUTCFullYear(),
      shifted.getUTCMonth() + 1,
      1
    ) - IST_OFFSET_MS);
    return { start, end };
  }
  throw new functions.https.HttpsError(
    "invalid-argument",
    "period must be overall, today, yesterday, this_week, or this_month."
  );
}

function inPeriod(value, window) {
  const date = toDate(value);
  return !!date && (!window || (date >= window.start && date < window.end));
}

function normalizeItem(doc, periodWindow) {
  const data = doc.data() || {};
  const quantity = number(data.quantity);
  const minimum =
    number(data.min_required) || number(data.low_stock_threshold);
  const maximum = number(data.max_capacity);
  const portionSize = number(data.portion_size);
  const unitCost = number(data.unit_cost);
  const lastAddedAt = toDate(data.last_added_at);
  const lastUsedAt = toDate(data.last_used_at);
  const createdAt = toDate(data.created_at || data.last_updated);
  const initialStockAt = toDate(data.initial_stock_at) || createdAt;
  const initialStockQty = data.initial_stock_qty == null
    ? null
    : number(data.initial_stock_qty);
  const totalAdded = number(
    data.total_added,
    number(data.last_added_qty)
  );
  const totalUsed = number(
    data.total_used,
    number(data.last_used_qty)
  );
  const addedInPeriod = inPeriod(lastAddedAt, periodWindow);
  const usedInPeriod = inPeriod(lastUsedAt, periodWindow);

  return {
    id: doc.id,
    name: String(data.name || doc.id),
    category: String(data.category || "Uncategorized"),
    quantity,
    min_required: minimum,
    max_capacity: maximum,
    unit: String(data.unit || "pcs"),
    portion_size: portionSize,
    portion_unit: portionSize > 0
      ? String(data.portion_unit || "")
      : null,
    unit_cost: unitCost,
    total_cost: number(data.total_cost, quantity * unitCost),
    created_at: dateToIso(createdAt),
    updated_at: dateToIso(data.updated_at || data.last_updated),
    last_added_at: dateToIso(lastAddedAt),
    last_used_at: dateToIso(lastUsedAt),
    initial_stock_at: dateToIso(initialStockAt),
    initial_stock_qty: initialStockQty,
    last_added_qty: data.last_added_qty == null
      ? null
      : number(data.last_added_qty),
    last_added_cost: data.last_added_cost == null
      ? null
      : number(data.last_added_cost),
    last_added_stock_before: data.last_added_stock_before == null
      ? null
      : number(data.last_added_stock_before),
    last_used_qty: data.last_used_qty == null
      ? null
      : number(data.last_used_qty),
    last_used_stock_before: data.last_used_stock_before == null
      ? null
      : number(data.last_used_stock_before),
    total_added: totalAdded,
    total_used: totalUsed,
    status: stockStatus(quantity, minimum),
    stock_percent: stockPercent(quantity, minimum, maximum),
    stock_fill_fraction: stockFillFraction(quantity, minimum, maximum),
    added_in_period: addedInPeriod,
    used_in_period: usedInPeriod,
    recent_action: lastAddedAt && lastUsedAt
      ? (lastAddedAt > lastUsedAt ? "added" : "used")
      : "none",
  };
}

function matchesFilters(item, filters) {
  const query = filters.search.trim().toLowerCase();
  if (query &&
      !item.name.toLowerCase().includes(query) &&
      !item.category.toLowerCase().includes(query)) {
    return false;
  }
  if (filters.category !== "All" && item.category !== filters.category) {
    return false;
  }
  if (filters.stockLevel === "Low Stock" && item.status !== "low_stock") {
    return false;
  }
  if (filters.stockLevel === "Critical" && item.status !== "critical") {
    return false;
  }
  if (filters.stockLevel === "Added" && !item.added_in_period) return false;
  if (filters.stockLevel === "Used" && !item.used_in_period) return false;
  return true;
}

function buildInventoryData(snapshot, request) {
  const period = String(request.period || "overall");
  const window = resolvePeriod(period);
  const items = snapshot.docs
    .map((doc) => normalizeItem(doc, window))
    .sort((a, b) => a.name.localeCompare(b.name));

  const low = items.filter((item) => item.status === "low_stock").length;
  const critical = items.filter((item) => item.status === "critical").length;
  const outOfStock = items.filter((item) => item.status === "out_of_stock").length;
  const addedItems = items.filter((item) =>
    period === "overall" ? item.total_added > 0 : item.added_in_period
  );
  const usedItems = items.filter((item) =>
    period === "overall" ? item.total_used > 0 : item.used_in_period
  );
  const expenditure = period === "overall"
    ? items.reduce((sum, item) => sum + item.total_cost, 0)
    : addedItems.reduce(
      (sum, item) => sum + (
        item.last_added_cost == null
          ? number(item.last_added_qty) * item.unit_cost
          : item.last_added_cost
      ),
      0
    );
  const categories = [...new Set(items.map((item) => item.category))]
    .sort((a, b) => a.localeCompare(b));
  const filters = {
    search: String(request.search || ""),
    category: String(request.category || "All"),
    stockLevel: String(request.stock_level || "All"),
  };

  return {
    period,
    items,
    filtered_items: items.filter((item) => matchesFilters(item, filters)),
    categories,
    stats: {
      expenditure,
      total_items: items.length,
      added_item_count: addedItems.length,
      used_item_count: usedItems.length,
      needs_restock_count: low + critical,
      in_stock_count: items.filter((item) => item.status === "in_stock").length,
      low_stock_count: low,
      critical_count: critical,
      out_of_stock_count: outOfStock,
    },
  };
}

function requiredString(value, field, maxLength = 100) {
  const text = String(value || "").trim();
  if (!text || text.length > maxLength || text.includes("/")) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} is required and must be no more than ${maxLength} characters.`
    );
  }
  return text;
}

function requiredNumber(value, field, { min = 0, max = Number.MAX_SAFE_INTEGER } = {}) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < min || parsed > max) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${field} must be a number between ${min} and ${max}.`
    );
  }
  return parsed;
}

function normalizeSaveInput(raw) {
  if (!raw || typeof raw !== "object") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "item is required."
    );
  }
  const name = requiredString(raw.name, "Material name", 10);
  const category = requiredString(raw.category, "Category");
  const unit = requiredString(raw.unit, "Unit", 40);
  const quantity = requiredNumber(raw.quantity, "Quantity");
  const minimum = requiredNumber(raw.min_required, "Minimum stock");
  const maximum = raw.max_capacity == null
    ? 0
    : requiredNumber(raw.max_capacity, "Maximum capacity");
  const portionSize = raw.portion_size == null
    ? 0
    : requiredNumber(raw.portion_size, "Portion size");
  const portionUnit = portionSize > 0
    ? requiredString(raw.portion_unit, "Portion unit", 40)
    : null;
  const totalCost = raw.total_cost == null
    ? null
    : requiredNumber(raw.total_cost, "Total cost");
  const unitCost = !raw.id && totalCost != null
    ? (quantity > 0 ? totalCost / quantity : 0)
    : requiredNumber(raw.unit_cost, "Unit cost");

  if (!raw.id && quantity === 0 && totalCost !== null && totalCost > 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Initial stock cost must be zero when the initial quantity is zero."
    );
  }

  if (maximum > 0 && minimum > maximum) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Minimum stock cannot exceed maximum capacity."
    );
  }
  if (!raw.id && maximum > 0 && quantity > maximum) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Initial stock cannot exceed maximum storage capacity."
    );
  }
  if (quantity > 0 && minimum > quantity) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Minimum stock cannot exceed the current stock quantity."
    );
  }

  return {
    name,
    category,
    unit,
    quantity,
    minimum,
    maximum,
    portionSize,
    portionUnit,
    unitCost,
    totalCost: totalCost ?? quantity * unitCost,
  };
}

async function saveInventoryItem(raw) {
  const item = normalizeSaveInput(raw);
  const requestedId = String(raw.id || "").trim();
  const now = admin.firestore.Timestamp.now();

  if (!requestedId) {
    const ref = db.collection("inventory").doc(item.name);
    await db.runTransaction(async (transaction) => {
      const current = await transaction.get(ref);
      if (current.exists) {
        throw new functions.https.HttpsError(
          "already-exists",
          "A material with this name already exists."
        );
      }
      transaction.create(ref, {
        name: item.name,
        category: item.category,
        quantity: item.quantity,
        min_required: item.minimum,
        low_stock_threshold: item.minimum,
        max_capacity: item.maximum,
        unit: item.unit,
        portion_size: item.portionSize,
        portion_unit: item.portionUnit,
        unit_cost: item.unitCost,
        total_cost: item.totalCost,
        created_at: now,
        updated_at: now,
        initial_stock_at: now,
        initial_stock_qty: item.quantity,
        last_added_at: item.quantity > 0 ? now : null,
        last_added_qty: item.quantity > 0 ? item.quantity : null,
        last_added_stock_before: item.quantity > 0 ? 0 : null,
        last_used_at: null,
        last_used_qty: null,
        last_used_stock_before: null,
        total_added: item.quantity,
        total_used: 0,
      });
      transaction.create(ref.collection("history").doc(), {
        type: "initial",
        quantity: item.quantity,
        occurred_at: now,
        stock_before: 0,
        stock_after: item.quantity,
        purchase_cost: item.totalCost,
        unit_cost: item.unitCost,
        total_cost: item.totalCost,
      });
    });
    return { id: ref.id };
  }

  const ref = db.collection("inventory").doc(requestedId);
  await db.runTransaction(async (transaction) => {
    const current = await transaction.get(ref);
    if (!current.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Inventory item was not found."
      );
    }
    const data = current.data() || {};
    const quantity = number(data.quantity);
    if (item.minimum > quantity && quantity > 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Minimum stock cannot exceed the current stock quantity."
      );
    }
    transaction.update(ref, {
      min_required: item.minimum,
      low_stock_threshold: item.minimum,
      max_capacity: item.maximum,
      unit: item.unit,
      portion_size: item.portionSize,
      portion_unit: item.portionUnit,
      unit_cost: item.unitCost,
      updated_at: now,
    });
  });
  return { id: requestedId };
}

async function changeStock(action, id, rawQuantity, rawPurchaseCost) {
  const itemId = requiredString(id, "Inventory item ID", 150);
  const quantity = requiredNumber(rawQuantity, "Quantity", {
    min: Number.EPSILON,
    max: action === "addStock" ? 999 : Number.MAX_SAFE_INTEGER,
  });
  const purchaseCost = action === "addStock"
    ? requiredNumber(rawPurchaseCost, "Purchase cost")
    : null;
  const ref = db.collection("inventory").doc(itemId);
  const now = admin.firestore.Timestamp.now();
  const historyCollection = ref.collection("history");
  const historyRef = historyCollection.doc();

  await db.runTransaction(async (transaction) => {
    const current = await transaction.get(ref);
    if (!current.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Inventory item was not found."
      );
    }
    const data = current.data() || {};
    const existingHistory = await transaction.get(historyCollection.limit(1));
    const stock = number(data.quantity);
    if (existingHistory.empty) {
      for (const event of legacyStockHistory(data)) {
        const { id, occurred_at: occurredAt, ...fields } = event;
        transaction.create(historyCollection.doc(id), {
          ...fields,
          occurred_at: admin.firestore.Timestamp.fromDate(new Date(occurredAt)),
        });
      }
    }
    if (action === "addStock") {
      const maximum = number(data.max_capacity);
      if (maximum > 0 && stock + quantity > maximum) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          `Available capacity is ${Math.max(maximum - stock, 0)} ${data.unit || "units"}.`
        );
      }
      const unitCost = number(data.unit_cost);
      const totalCost = number(data.total_cost, stock * unitCost);
      const newQuantity = stock + quantity;
      const newTotalCost = totalCost + purchaseCost;
      transaction.update(ref, {
        quantity: newQuantity,
        total_cost: newTotalCost,
        unit_cost: weightedAverageUnitCost(
          stock,
          totalCost,
          quantity,
          purchaseCost
        ),
        updated_at: now,
        last_added_at: now,
        last_added_qty: quantity,
        last_added_cost: purchaseCost,
        last_added_stock_before: stock,
        total_added: number(data.total_added, number(data.last_added_qty)) + quantity,
      });
      transaction.create(historyRef, {
        type: "added",
        quantity,
        occurred_at: now,
        stock_before: stock,
        stock_after: newQuantity,
        purchase_cost: purchaseCost,
        unit_cost: purchaseCost / quantity,
        total_cost: purchaseCost,
      });
      return;
    }

    if (quantity > stock) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Cannot use more than current stock."
      );
    }
    const unitCost = number(data.unit_cost);
    const newQuantity = Math.max(stock - quantity, 0);
    const usedCost = Math.min(
      number(data.total_cost, stock * unitCost),
      quantity * unitCost
    );
    transaction.update(ref, {
      quantity: newQuantity,
      total_cost: Math.max(number(data.total_cost, stock * unitCost) - usedCost, 0),
      updated_at: now,
      last_used_at: now,
      last_used_qty: quantity,
      last_used_stock_before: stock,
      total_used: number(data.total_used, number(data.last_used_qty)) + quantity,
    });
    transaction.create(historyRef, {
      type: "used",
      quantity,
      occurred_at: now,
      stock_before: stock,
      stock_after: newQuantity,
      unit_cost: unitCost,
      total_cost: usedCost,
    });
  });
}

function legacyStockHistory(data) {
  const events = [];
  const initialAt = toDate(data.initial_stock_at || data.created_at);
  const lastAddedAt = toDate(data.last_added_at);
  const initialQuantity = data.initial_stock_qty == null
    ? initialAt && lastAddedAt &&
        initialAt.getTime() === lastAddedAt.getTime()
      ? number(data.last_added_qty)
      : null
    : number(data.initial_stock_qty);
  if (initialAt && initialQuantity != null) {
    events.push({
      id: "legacy-initial",
      type: "initial",
      quantity: initialQuantity,
      occurred_at: dateToIso(initialAt),
      stock_before: 0,
      stock_after: initialQuantity,
      purchase_cost: null,
      unit_cost: null,
      total_cost: null,
    });
  }

  if (lastAddedAt && data.last_added_qty != null &&
      (!initialAt || lastAddedAt.getTime() !== initialAt.getTime())) {
    events.push({
      id: "legacy-added",
      type: "added",
      quantity: number(data.last_added_qty),
      occurred_at: dateToIso(lastAddedAt),
      stock_before: number(data.last_added_stock_before),
      stock_after: number(data.last_added_stock_before) +
        number(data.last_added_qty),
      purchase_cost: data.last_added_cost == null
        ? null
        : number(data.last_added_cost),
      unit_cost: data.last_added_cost == null
        ? null
        : number(data.last_added_cost) / number(data.last_added_qty, 1),
      total_cost: data.last_added_cost == null
        ? null
        : number(data.last_added_cost),
    });
  }

  const lastUsedAt = toDate(data.last_used_at);
  if (lastUsedAt && data.last_used_qty != null) {
    const quantity = number(data.last_used_qty);
    const stockBefore = number(data.last_used_stock_before);
    events.push({
      id: "legacy-used",
      type: "used",
      quantity,
      occurred_at: dateToIso(lastUsedAt),
      stock_before: stockBefore,
      stock_after: Math.max(stockBefore - quantity, 0),
      unit_cost: null,
      total_cost: null,
    });
  }
  return events.sort((a, b) =>
    String(b.occurred_at).localeCompare(String(a.occurred_at))
  );
}

async function getStockHistory(id, cursorId) {
  const itemId = requiredString(id, "Inventory item ID", 150);
  const ref = db.collection("inventory").doc(itemId);
  const item = await ref.get();
  if (!item.exists) {
    throw new functions.https.HttpsError(
      "not-found",
      "Inventory item was not found."
    );
  }

  const history = ref.collection("history");
  let query = history.orderBy("occurred_at", "desc").limit(100);
  if (cursorId) {
    const cursor = await history.doc(requiredString(cursorId, "History cursor", 150)).get();
    if (!cursor.exists) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "History cursor was not found."
      );
    }
    query = query.startAfter(cursor);
  }
  const snapshot = await query.get();
  if (snapshot.empty && !cursorId) {
    const legacy = legacyStockHistory(item.data() || {});
    return {
      entries: legacy,
      next_cursor: null,
      has_more: false,
    };
  }
  return {
    entries: snapshot.docs.map((doc) => ({
      id: doc.id,
      type: String(doc.get("type") || "unknown"),
      quantity: number(doc.get("quantity")),
      occurred_at: dateToIso(doc.get("occurred_at")),
      stock_before: number(doc.get("stock_before")),
      stock_after: number(doc.get("stock_after")),
      purchase_cost: doc.get("purchase_cost") == null
        ? null
        : number(doc.get("purchase_cost")),
      unit_cost: doc.get("unit_cost") == null
        ? null
        : number(doc.get("unit_cost")),
      total_cost: doc.get("total_cost") == null
        ? null
        : number(doc.get("total_cost")),
    })),
    next_cursor: snapshot.size === 100
      ? snapshot.docs[snapshot.docs.length - 1].id
      : null,
    has_more: snapshot.size === 100,
  };
}

async function deleteInventoryItem(id) {
  const itemId = requiredString(id, "Inventory item ID", 150);
  const ref = db.collection("inventory").doc(itemId);
  const history = ref.collection("history");
  while (true) {
    const snapshot = await history.limit(400).get();
    if (snapshot.empty) break;
    const batch = db.batch();
    for (const doc of snapshot.docs) batch.delete(doc.ref);
    await batch.commit();
  }
  await db.runTransaction(async (transaction) => {
    const current = await transaction.get(ref);
    if (!current.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Inventory item was not found."
      );
    }
    transaction.delete(ref);
  });
}

// APP: ADMIN APP — inventory data and mutations for restaurant operators.
const manageInventory = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const { uid, role } = requireRestaurantUser(context);
    const startedAt = Date.now();
    const action = String(data?.action || "");
    logger.info("Inventory request started", { action, uid, role });

    try {
      if (action === "getInventoryData") {
        const snapshot = await db.collection("inventory").get();
        const result = buildInventoryData(snapshot, data || {});
        logger.info("Inventory data loaded", {
          uid,
          period: result.period,
          total_items: result.stats.total_items,
          filtered_items: result.filtered_items.length,
          duration_ms: Date.now() - startedAt,
        });
        return result;
      }
      if (action === "getStockHistory") {
        const result = await getStockHistory(data.id, data.cursor_id);
        return result;
      }
      if (action === "saveItem") {
        requireAdmin(context);
        const result = await saveInventoryItem(data.item);
        logger.info("Inventory item saved", {
          uid,
          id: result.id,
          duration_ms: Date.now() - startedAt,
        });
        return result;
      }
      if (action === "addStock" || action === "useStock") {
        requireAdmin(context);
        await changeStock(
          action,
          data.id,
          data.quantity,
          data.purchase_cost
        );
        logger.info("Inventory stock changed", {
          uid,
          id: data.id,
          action,
          duration_ms: Date.now() - startedAt,
        });
        return { ok: true };
      }
      if (action === "deleteItem") {
        requireAdmin(context);
        await deleteInventoryItem(data.id);
        logger.info("Inventory item deleted", {
          uid,
          id: data.id,
          duration_ms: Date.now() - startedAt,
        });
        return { ok: true };
      }
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Unsupported inventory action."
      );
    } catch (error) {
      logger.error("Inventory request failed", {
        uid,
        action,
        duration_ms: Date.now() - startedAt,
        error_code: error.code || null,
        error_message: error.message || String(error),
      });
      throw error;
    }
  });

module.exports = {
  manageInventory,
  buildInventoryData,
  resolvePeriod,
  stockStatus,
  stockPercent,
  stockFillFraction,
  weightedAverageUnitCost,
  normalizeSaveInput,
  legacyStockHistory,
};
