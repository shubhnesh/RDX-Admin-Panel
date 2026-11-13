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
  InventoryProvider(
    this._service, {
    Duration refreshInterval = const Duration(seconds: 10),
  }) : _refreshInterval = refreshInterval;

  final InventoryService _service;
  final Duration _refreshInterval;
  Timer? _refreshTimer;
  int _requestId = 0;
  int _activeFetches = 0;
  bool _hasLoadedData = false;
  bool _disposed = false;

  List<InventoryItemModel> items = [];
  List<InventoryItemModel> filteredItems = [];
  List<String> categories = [];
  bool isLoading = false;
  String? errorMessage;
  String? refreshError;

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

  Future<void> load() async {
    _startAutoRefresh();
    await _loadFromCloud();
  }

  void _startAutoRefresh() {
    if (_disposed || _refreshTimer != null) return;
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (_activeFetches == 0) {
        unawaited(_loadFromCloud(silent: true));
      }
    });
  }

  Future<void> retryAutoRefresh() async {
    refreshError = null;
    notifyListeners();
    await _loadFromCloud(silent: _hasLoadedData);
  }

  Future<void> _loadFromCloud({bool silent = false}) async {
    if (_disposed) return;
    final requestId = ++_requestId;
    _activeFetches++;
    isLoading = !silent && !_hasLoadedData;
    final previousItems = items;
    final previousFilteredItems = filteredItems;
    final previousCategories = categories;
    final previousExpenditure = periodExpenditure;
    final previousTotalItems = totalItems;
    final previousAddedCount = periodAddedItemCount;
    final previousUsedCount = periodUsedItemCount;
    final previousRestockCount = needsRestockCount;
    final previousError = errorMessage;
    final previousRefreshError = refreshError;
    var shouldNotify = !silent;
    if (!silent) {
      errorMessage = null;
      notifyListeners();
    }
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
      if (_disposed || requestId != _requestId) return;

      final nextItems = _parseItems(response['items']);
      final nextItemsById = {
        for (final item in _preserveUnchangedItems(nextItems, items))
          item.id: item,
      };
      items = nextItemsById.values.toList(growable: false)
        ..sort((a, b) => a.name.compareTo(b.name));
      filteredItems = _filterItems(items);
      final rawCategories = response['categories'];
      final stats = Map<String, dynamic>.from(
        response['stats'] as Map? ?? const {},
      );
      categories = rawCategories is List
          ? rawCategories.map((value) => value.toString()).toList()
          : const [];
      periodExpenditure = _number(stats['expenditure']);
      totalItems = _integer(stats['total_items']);
      periodAddedItemCount = _integer(stats['added_item_count']);
      periodUsedItemCount = _integer(stats['used_item_count']);
      needsRestockCount = _integer(stats['needs_restock_count']);
      errorMessage = null;
      refreshError = null;
      _hasLoadedData = true;
      shouldNotify = shouldNotify ||
          !_sameItemReferences(previousItems, items) ||
          !_sameItemReferences(previousFilteredItems, filteredItems) ||
          !_sameStrings(previousCategories, categories) ||
          previousExpenditure != periodExpenditure ||
          previousTotalItems != totalItems ||
          previousAddedCount != periodAddedItemCount ||
          previousUsedCount != periodUsedItemCount ||
          previousRestockCount != needsRestockCount ||
          previousError != null ||
          previousRefreshError != null;
      _log(
        'Inventory response applied '
        '(items: ${items.length}, filtered: ${filteredItems.length}).',
      );
    } catch (error, stackTrace) {
      if (_disposed || requestId != _requestId) return;
      errorMessage = 'Failed to load inventory: $error';
      if (_hasLoadedData) {
        refreshError = 'Automatic inventory refresh failed: $error';
      }
      shouldNotify = true;
      _log('Inventory request failed: $error\n$stackTrace');
    } finally {
      _activeFetches--;
      if (requestId == _requestId) {
        isLoading = false;
        if (!_disposed && shouldNotify) notifyListeners();
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

  List<InventoryItemModel> _preserveUnchangedItems(
    List<InventoryItemModel> nextItems,
    List<InventoryItemModel> currentItems,
  ) {
    final currentById = {for (final item in currentItems) item.id: item};
    return nextItems.map<InventoryItemModel>((item) {
      final current = currentById[item.id];
      return current != null && _sameItem(current, item) ? current : item;
    }).toList(growable: false);
  }

  bool _sameItem(InventoryItemModel a, InventoryItemModel b) {
    return a.id == b.id &&
        a.name == b.name &&
        a.category == b.category &&
        a.quantity == b.quantity &&
        a.minRequired == b.minRequired &&
        a.maxCapacity == b.maxCapacity &&
        a.unit == b.unit &&
        a.portionSize == b.portionSize &&
        a.portionUnit == b.portionUnit &&
        a.unitCost == b.unitCost &&
        a.totalCost == b.totalCost &&
        a.createdAt == b.createdAt &&
        a.updatedAt == b.updatedAt &&
        a.lastAddedAt == b.lastAddedAt &&
        a.lastUsedAt == b.lastUsedAt &&
        a.initialStockAt == b.initialStockAt &&
        a.initialStockQty == b.initialStockQty &&
        a.lastAddedQty == b.lastAddedQty &&
        a.lastAddedCost == b.lastAddedCost &&
        a.lastAddedStockBefore == b.lastAddedStockBefore &&
        a.lastUsedQty == b.lastUsedQty &&
        a.lastUsedStockBefore == b.lastUsedStockBefore &&
        a.totalAdded == b.totalAdded &&
        a.totalUsed == b.totalUsed &&
        a.notes == b.notes &&
        a.status == b.status &&
        a.stockPercent == b.stockPercent &&
        a.stockFillFraction == b.stockFillFraction &&
        a.addedInPeriod == b.addedInPeriod &&
        a.usedInPeriod == b.usedInPeriod &&
        a.recentAction == b.recentAction;
  }

  bool _sameItemReferences(
    List<InventoryItemModel> a,
    List<InventoryItemModel> b,
  ) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (!identical(a[index], b[index])) return false;
    }
    return true;
  }

  bool _sameStrings(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  List<InventoryItemModel> _filterItems(
    List<InventoryItemModel> source,
  ) {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    return source.where((item) {
      if (selectedCategory != 'All' && item.category != selectedCategory) {
        return false;
      }
      if (normalizedQuery.isNotEmpty &&
          !item.name.toLowerCase().contains(normalizedQuery) &&
          !item.category.toLowerCase().contains(normalizedQuery)) {
        return false;
      }
      switch (stockLevelFilter) {
        case 'Low Stock':
          return item.status == StockStatus.lowStock;
        case 'Critical':
          return item.status == StockStatus.critical;
        case 'Added':
          return item.addedInPeriod;
        case 'Used':
          return item.usedInPeriod;
        default:
          return true;
      }
    }).toList(growable: false);
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
    if (searchQuery == query) return;
    searchQuery = query;
    filteredItems = _filterItems(items);
    notifyListeners();
  }

  void setCategory(String category) {
    if (selectedCategory == category) return;
    selectedCategory = category;
    filteredItems = _filterItems(items);
    notifyListeners();
  }

  void setStockLevelFilter(String level, {StatsPeriod? period}) {
    if (stockLevelFilter == level &&
        (period == null || periodFilter == period)) {
      return;
    }
    stockLevelFilter = level;
    final periodChanged = period != null && periodFilter != period;
    if (period != null) periodFilter = period;
    filteredItems = _filterItems(items);
    notifyListeners();
    if (periodChanged) {
      unawaited(_loadFromCloud(silent: _hasLoadedData));
    }
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
    await _loadFromCloud(silent: true);
  }

  Future<void> useStock(String id, double quantity) async {
    await _service.useStock(id, quantity);
    await _loadFromCloud(silent: true);
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

    await _loadFromCloud(silent: true);
    return failures;
  }

  Future<String> saveItem(InventoryItemModel item) async {
    final id = await _service.saveItem(item);
    await _loadFromCloud(silent: true);
    return id;
  }

  Future<void> deleteItem(String id) async {
    await _service.deleteItem(id);
    await _loadFromCloud(silent: true);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _disposed = true;
    _requestId++;
    super.dispose();
  }
}

final inventoryProvider = ChangeNotifierProvider<InventoryProvider>(
  (ref) => InventoryProvider(InventoryService()),
);
