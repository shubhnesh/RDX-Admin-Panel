"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  buildInventoryData,
  legacyStockHistory,
  normalizeSaveInput,
  stockPercent,
  stockStatus,
  weightedAverageUnitCost,
} = require("./manageInventory");

function snapshot(items) {
  return {
    docs: items.map(([id, data]) => ({
      id,
      data: () => data,
    })),
  };
}

test("stock status and percentage are server-derived", () => {
  assert.equal(stockStatus(0, 10), "out_of_stock");
  assert.equal(stockStatus(2, 10), "critical");
  assert.equal(stockStatus(10, 10), "in_stock");
  assert.equal(stockPercent(12, 0, 10), 100);
});

test("inventory response applies table filters and returns aggregate stats", () => {
  const result = buildInventoryData(
    snapshot([
      ["Flour", {
        name: "Flour",
        category: "Dry Goods",
        quantity: 2,
        min_required: 10,
        max_capacity: 20,
        unit_cost: 3,
        total_cost: 6,
        total_added: 5,
      }],
      ["Milk", {
        name: "Milk",
        category: "Dairy",
        quantity: 12,
        min_required: 4,
        max_capacity: 20,
        unit_cost: 2,
        total_cost: 24,
        total_used: 3,
      }],
    ]),
    { period: "overall", stock_level: "Critical" }
  );

  assert.equal(result.stats.total_items, 2);
  assert.equal(result.stats.expenditure, 30);
  assert.equal(result.stats.critical_count, 1);
  assert.equal(result.stats.needs_restock_count, 1);
  assert.deepEqual(result.filtered_items.map((item) => item.id), ["Flour"]);
  assert.deepEqual(result.categories, ["Dairy", "Dry Goods"]);
});

test("initial purchase total determines the per-item restock cost", () => {
  const item = normalizeSaveInput({
    name: "Flour",
    category: "Dry Goods",
    unit: "kg",
    quantity: 10,
    min_required: 2,
    portion_size: 12,
    portion_unit: "g",
    total_cost: 500,
  });

  assert.equal(item.totalCost, 500);
  assert.equal(item.unitCost, 50);
  assert.equal(item.portionSize, 12);
  assert.equal(item.portionUnit, "g");
});

test("portion unit is required only when portion size is positive", () => {
  const noPortions = normalizeSaveInput({
    name: "Rice",
    category: "Dry Goods",
    unit: "packet",
    quantity: 1,
    min_required: 0,
    unit_cost: 10,
    portion_size: 0,
  });
  assert.equal(noPortions.portionUnit, null);

  assert.throws(
    () => normalizeSaveInput({
      name: "Rice",
      category: "Dry Goods",
      unit: "packet",
      quantity: 1,
      min_required: 0,
      unit_cost: 10,
      portion_size: 12,
    }),
    (error) => error.code === "invalid-argument"
  );
});

test("restock purchase cost updates the weighted average unit cost", () => {
  const updatedUnitCost = weightedAverageUnitCost(10, 500, 5, 300);
  assert.equal(updatedUnitCost, 800 / 15);
});

test("inventory reads preserve initial and latest stock activity values", () => {
  const result = buildInventoryData(
    snapshot([
      ["Rice", {
        name: "Rice",
        category: "Dry Goods",
        quantity: 15,
        min_required: 2,
        unit: "kg",
        portion_size: 1000,
        portion_unit: "g",
        created_at: "2026-11-06T08:00:00.000Z",
        initial_stock_at: "2026-11-06T08:00:00.000Z",
        initial_stock_qty: 10,
        last_added_at: "2026-11-06T09:00:00.000Z",
        last_added_qty: 8,
        last_added_stock_before: 7,
        last_used_at: "2026-11-06T10:00:00.000Z",
        last_used_qty: 3,
        last_used_stock_before: 18,
      }],
    ]),
    { period: "overall" }
  );
  const [item] = result.items;

  assert.equal(item.initial_stock_qty, 10);
  assert.equal(item.initial_stock_at, "2026-11-06T08:00:00.000Z");
  assert.equal(item.last_added_qty, 8);
  assert.equal(item.last_added_stock_before, 7);
  assert.equal(item.last_used_qty, 3);
  assert.equal(item.last_used_stock_before, 18);
  assert.equal(item.portion_size, 1000);
  assert.equal(item.portion_unit, "g");
});

test("legacy stock history preserves recorded purchase costs", () => {
  const history = legacyStockHistory({
    unit_cost: 80,
    total_cost: 800,
    created_at: "2026-11-06T08:00:00.000Z",
    initial_stock_at: "2026-11-06T08:00:00.000Z",
    initial_stock_qty: 10,
    last_added_at: "2026-11-06T09:00:00.000Z",
    last_added_qty: 5,
    last_added_cost: 300,
    last_added_stock_before: 10,
  });

  assert.equal(history.length, 2);
  assert.equal(history[0].purchase_cost, 300);
  assert.equal(history[0].unit_cost, 60);
  assert.equal(history[1].purchase_cost, null);
});
