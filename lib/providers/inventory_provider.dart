import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory_item_model.dart';
import '../services/inventory_service.dart';

enum StatsPeriod { overall, today, yesterday, thisWeek, thisMonth }

enum InventoryStockMode { add, use }

class InventoryStockChange {
  const InventoryStockChange({
    required this.mode,
    required this.quantity,
    this.purchaseCost,
  });

  final InventoryStockMode mode;
  final double quantity;
  final double? purchaseCost;
}

extension StatsPeriodLabel on StatsPeriod {
  String get label {
    switch (this) {
      case StatsPeriod.overall:
        return 'Overall';
      case StatsPeriod.today:
        return 'Today';
      case StatsPeriod.yesterday:
        return 'Yesterday';
      case StatsPeriod.thisWeek:
        return 'This Week';
      case StatsPeriod.thisMonth:
        return 'This Month';
    }
  }

  String get cloudKey {
    switch (this) {
      case StatsPeriod.overall:
        return 'overall';
      case StatsPeriod.today:
        return 'today';
      case StatsPeriod.yesterday:
        return 'yesterday';
      case StatsPeriod.thisWeek:
        return 'this_week';
      case StatsPeriod.thisMonth:
        return 'this_month';
    }
  }
}

class InventoryProvider extends ChangeNotifier {
  InventoryProvider(this._service);

  final InventoryService _service;
  Timer? _searchDebounce;
  int _requestId = 0;

  List<InventoryItemModel> items = [];
  List<InventoryItemModel> filteredItems = [];
  List<String> categories = [];
  bool isLoading = false;
  String? errorMessage;

  String searchQuery = '';
  String selectedCategory = 'All';
  String stockLevelFilter = 'All';
  StatsPeriod periodFilter = StatsPeriod.overall;

  double periodExpenditure = 0;
  int totalItems = 0;
  int periodAddedItemCount = 0;
  int periodUsedItemCount = 0;
  int needsRestockCount = 0;

  void _log(String message) {
    if (kDebugMode) debugPrint('[InventoryProvider] $message');
  }

  Future<void> load() => _loadFromCloud();

  Future<void> _loadFromCloud() async {
    final requestId = ++_requestId;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    _log(
      'Inventory request started '
      '(period: ${periodFilter.cloudKey}, category: $selectedCategory, '
      'stock level: $stockLevelFilter).',
    );

    try {
      final response = await _service.fetchInventoryData(
        period: periodFilter.cloudKey,
        search: searchQuery,
        category: selectedCategory,
        stockLevel: stockLevelFilter,
      );
      if (requestId != _requestId) return;

      final rawItems = response['items'];
      final rawFilteredItems = response['filtered_items'];
      final rawCategories = response['categories'];
      final stats = Map<String, dynamic>.from(
        response['stats'] as Map? ?? const {},
      );
      items = _parseItems(rawItems);
      filteredItems = _parseItems(rawFilteredItems);
      categories = rawCategories is List
          ? rawCategories.map((value) => value.toString()).toList()
          : const [];
      periodExpenditure = _number(stats['expenditure']);
      totalItems = _integer(stats['total_items']);
      periodAddedItemCount = _integer(stats['added_item_count']);
      periodUsedItemCount = _integer(stats['used_item_count']);
      needsRestockCount = _integer(stats['needs_restock_count']);
      errorMessage = null;
      _log(
        'Inventory response applied '
        '(items: ${items.length}, filtered: ${filteredItems.length}).',
      );
    } catch (error, stackTrace) {
      if (requestId != _requestId) return;
      errorMessage = 'Failed to load inventory: $error';
      _log('Inventory request failed: $error\n$stackTrace');
    } finally {
      if (requestId == _requestId) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  List<InventoryItemModel> _parseItems(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => InventoryItemModel.fromCloud(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  int _integer(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  void setSearch(String query) {
    searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 250),
      () => unawaited(_loadFromCloud()),
    );
  }

  void setCategory(String category) {
    if (selectedCategory == category) return;
    selectedCategory = category;
    unawaited(_loadFromCloud());
  }

  void setStockLevelFilter(String level, {StatsPeriod? period}) {
    if (stockLevelFilter == level &&
        (period == null || periodFilter == period)) {
      return;
    }
    stockLevelFilter = level;
    if (period != null) periodFilter = period;
    unawaited(_loadFromCloud());
  }

  void setPeriodFilter(StatsPeriod period) {
    if (periodFilter == period) return;
    periodFilter = period;
    unawaited(_loadFromCloud());
  }

  Future<void> addStock(
    String id,
    double quantity, {
    required double purchaseCost,
  }) async {
    await _service.addStock(
      id,
      quantity,
      purchaseCost: purchaseCost,
    );
    await load();
  }

  Future<void> useStock(String id, double quantity) async {
    await _service.useStock(id, quantity);
    await load();
  }

  Future<InventoryStockHistoryPage> fetchStockHistory(
    String id, {
    String? cursor,
  }) {
    return _service.fetchStockHistory(id, cursor: cursor);
  }

  Future<Map<String, String>> applyStockChanges(
    Map<String, InventoryStockChange> changes,
  ) async {
    final failures = <String, String>{};
    final currentItems = {for (final item in items) item.id: item};

    for (final entry in changes.entries) {
      final item = currentItems[entry.key];
      if (item == null) {
        failures[entry.key] = 'Item is no longer available.';
        continue;
      }

      final change = entry.value;
      if (change.quantity <= 0) {
        failures[entry.key] = 'Enter a quantity greater than zero.';
        continue;
      }

      try {
        if (change.mode == InventoryStockMode.add) {
          final purchaseCost = change.purchaseCost;
          if (purchaseCost == null) {
            failures[entry.key] =
                'Enter the total cost paid for this stock purchase.';
            continue;
          }
          await _service.addStock(
            item.id,
            change.quantity,
            purchaseCost: purchaseCost,
          );
        } else {
          await _service.useStock(item.id, change.quantity);
        }
      } catch (error) {
        failures[entry.key] = error.toString();
        _log('Stock update failed for ${item.name}: $error');
      }
    }

    await load();
    return failures;
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

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}

final inventoryProvider = ChangeNotifierProvider<InventoryProvider>(
  (ref) => InventoryProvider(InventoryService()),
);
