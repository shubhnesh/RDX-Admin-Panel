import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item_model.dart';
import '../services/inventory_service.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryService _service;
  InventoryProvider(this._service);

  List<InventoryItemModel> items = [];
  bool isLoading = false;
  String? errorMessage;

  // ── Filters / search ────────────────────────────────────────────────
  String searchQuery = '';
  String selectedCategory = 'All';
  String stockLevelFilter = 'All'; // All | In Stock | Low Stock | Critical

  // ── Derived counts ──────────────────────────────────────────────────
  int get totalItems => items.length;
  int get inStockCount =>
      items.where((e) => e.status == StockStatus.inStock).length;
  int get lowStockCount =>
      items.where((e) => e.status == StockStatus.lowStock).length;
  int get criticalCount =>
      items.where((e) => e.status == StockStatus.critical).length;
  int get needsRestockCount => lowStockCount + criticalCount;

  /// Overall cost of every material currently in inventory. This is a
  /// straight sum of each item's `totalCost`, which itself is the value
  /// persisted in Firestore (quantity x unit cost, computed and saved by
  /// InventoryService) — not a value recomputed here on the fly.
  double get overallCost =>
      items.fold<double>(0, (sum, item) => sum + item.totalCost);

  double get restockCostEstimate {
    double total = 0;
    for (final item in items.where((e) => e.needsRestock)) {
      final short = item.shortage;
      if (short > 0) total += short * item.unitCost;
    }
    return total;
  }

  /// Categories present in the current inventory (for filter chips).
  List<String> get categories {
    final set = <String>{};
    for (final i in items) {
      set.add(i.category);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Filtered list used by the main table.
  List<InventoryItemModel> get filteredItems {
    return items.where((item) {
      // Search
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        if (!item.name.toLowerCase().contains(q) &&
            !item.category.toLowerCase().contains(q)) {
          return false;
        }
      }
      // Category
      if (selectedCategory != 'All' && item.category != selectedCategory) {
        return false;
      }
      // Stock level
      switch (stockLevelFilter) {
        case 'In Stock':
          if (item.status != StockStatus.inStock) return false;
          break;
        case 'Low Stock':
          if (item.status != StockStatus.lowStock) return false;
          break;
        case 'Critical':
          if (item.status != StockStatus.critical) return false;
          break;
        default:
          break;
      }
      return true;
    }).toList();
  }

  List<InventoryItemModel> get lowStockItems =>
      items.where((e) => e.needsRestock).toList();

  // ── Actions ─────────────────────────────────────────────────────────
  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      items = await _service.fetchInventory();
    } catch (e) {
      errorMessage = 'Failed to load inventory.';
    }
    isLoading = false;
    notifyListeners();
  }

  void setSearch(String q) {
    searchQuery = q;
    notifyListeners();
  }

  void setCategory(String cat) {
    selectedCategory = cat;
    notifyListeners();
  }

  void setStockLevelFilter(String level) {
    stockLevelFilter = level;
    notifyListeners();
  }

  Future<void> updateQuantity(String id, double quantity) async {
    await _service.updateQuantity(id, quantity, timestamp: DateTime.now());
    await load();
  }

  /// Restock: adds [quantity] to the item's current stock and adds
  /// (quantity * current unit cost) to its existing totalCost — the
  /// cost basis of stock already on hand is never re-priced.
  ///
  /// A single [DateTime.now()] is captured here and sent down to the
  /// service so `updated_at` and `last_added_at` are written with the
  /// exact same value.
  Future<void> addStock(String id, double quantity) async {
    final ts = DateTime.now();
    await _service.addStock(id, quantity, timestamp: ts);
    await load();
  }

  /// Consumption: subtracts [quantity] from the item's current stock.
  /// totalCost is left unchanged — using already-paid-for stock isn't a
  /// new financial transaction.
  Future<void> useStock(String id, double quantity) async {
    final ts = DateTime.now();
    await _service.useStock(id, quantity, timestamp: ts);
    await load();
  }

  /// [timestamp] lets the caller (e.g. AddMaterialScreen) pin created_at /
  /// updated_at to the exact same moment it used to build [item]. Falls
  /// back to now when not provided.
  Future<String> saveItem(InventoryItemModel item, {DateTime? timestamp}) async {
    final id = await _service.saveItem(item, timestamp: timestamp);
    await load();
    return id;
  }

  Future<void> deleteItem(String id) async {
    await _service.deleteItem(id);
    await load();
  }
}

/// Riverpod provider wrapping [InventoryProvider].
final inventoryProvider = ChangeNotifierProvider<InventoryProvider>(
  (ref) => InventoryProvider(InventoryService()),
);
