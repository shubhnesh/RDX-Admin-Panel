import 'package:flutter/material.dart';
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
    await _service.updateQuantity(id, quantity);
    await load();
  }

  Future<String> saveItem(InventoryItemModel item) async {
    final id = await _service.saveItem(item);
    await load();
    return id;
  }

  Future<void> deleteItem(String id) async {
    await _service.deleteItem(id);
    await load();
  }
}
