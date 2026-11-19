import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/store/inventory_cache.dart';
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

/// Paginated, cached inventory state.
///
/// * Only [pageSize] items are fetched at a time ([loadMore] fetches the next).
/// * Every result is persisted, so reopening the screen / app (even offline)
///   shows data instantly.
/// * No polling: we listen to a single "version" document and only re-fetch
///   when something was actually added, used, edited or deleted.
class InventoryProvider extends ChangeNotifier {
  InventoryProvider(
    this._service, {
    InventoryCache? cache,
    this.pageSize = 10,
    this.maxCacheAge = const Duration(minutes: 10),
  }) : _cache = cache ?? InventoryCache();

  final InventoryService _service;
  final InventoryCache _cache;
  final int pageSize;
  final Duration maxCacheAge;

  StreamSubscription<int>? _versionSub;
  Timer? _searchDebounce;
  int _requestId = 0;
  bool _started = false;
  bool _disposed = false;

  int _version = -1; // version of the list on screen
  int _statsVersion = -1; // version of the stats on screen
  int _latestVersion = -1; // newest version we have heard of
  String? _nextCursor;
  List<Map<String, dynamic>> _rawItems = [];

  // ---- Public state -------------------------------------------------------
  List<InventoryItemModel> items = [];
  List<String> categories = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = false;
  bool hasLoadedOnce = false;
  bool isOffline = false;
  int totalMatching = 0;
  DateTime? lastSyncedAt;
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

  /// Items are already filtered server-side; kept for screen compatibility.
  List<InventoryItemModel> get filteredItems => items;

  // ---- Keys ---------------------------------------------------------------
  String get _queryKey => '${periodFilter.cloudKey}|$selectedCategory|'
      '$stockLevelFilter|${searchQuery.trim().toLowerCase()}';
  String get _statsKey => 'stats|${periodFilter.cloudKey}';

  void _log(String message) {
    if (kDebugMode) debugPrint('[InventoryProvider] $message');
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ---- Lifecycle ----------------------------------------------------------
  /// Safe to call every time the screen opens: after the first call it only
  /// hits the network if the cache is older than [maxCacheAge].
  Future<void> load() async {
    if (_started) {
      final age = lastSyncedAt == null
          ? null
          : DateTime.now().difference(lastSyncedAt!);
      if (age == null || age > maxCacheAge) await refresh();
      return;
    }
    _started = true;

    final cachedList = await _cache.read(_queryKey);
    final cachedStats = await _cache.read(_statsKey);
    if (_disposed) return;

    if (cachedStats != null) _applyStats(cachedStats);
    if (cachedList != null) {
      _applyPage(cachedList);
      lastSyncedAt = _savedAt(cachedList);
      isLoading = false;
      _notify();
    }

    _listenForChanges();
    if (cachedList == null || _isStale(cachedList)) await refresh();
  }

  /// Forces a re-fetch (retry button / manual refresh).
  Future<void> refresh() async {
    refreshError = null;
    await Future.wait([
      _refreshList(keepDepth: true, silent: items.isNotEmpty),
      _refreshStats(),
    ]);
  }

  Future<void> retryAutoRefresh() => refresh();

  void _listenForChanges() {
    _versionSub ??= _service.watchVersion().listen(
      (version) {
        if (_disposed) return;
        _latestVersion = math.max(_latestVersion, version);
        // Fetch only what is actually out of date.
        if (version != _version) {
          unawaited(_refreshList(keepDepth: true, silent: true));
        }
        if (version != _statsVersion) unawaited(_refreshStats());
      },
      onError: (Object error) {
        _log('Version listener failed: $error');
      },
    );
  }

  // ---- Fetching -----------------------------------------------------------
  Future<void> _refreshList({
    bool keepDepth = false,
    bool silent = true,
  }) async {
    if (_disposed) return;
    final requestId = ++_requestId;
    final key = _queryKey;
    final limit = keepDepth
        ? math.min(math.max(_rawItems.length, pageSize), 100)
        : pageSize;

    if (!silent && items.isEmpty) {
      isLoading = true;
      _notify();
    }

    try {
      final page = await _service.fetchPage(
        period: periodFilter.cloudKey,
        search: searchQuery,
        category: selectedCategory,
        stockLevel: stockLevelFilter,
        limit: limit,
      );
      if (_disposed || requestId != _requestId) return;
      _applyPage(page);
      errorMessage = null;
      refreshError = null;
      isOffline = false;
      lastSyncedAt = DateTime.now();
      await _cache.write(key, _snapshot());
    } catch (error) {
      if (_disposed || requestId != _requestId) return;
      _log('Page request failed: $error');
      if (items.isEmpty) {
        errorMessage = 'Failed to load inventory: $error';
      } else {
        isOffline = true;
        refreshError = 'Could not refresh. Showing saved inventory'
            '${lastSyncedAt == null ? '' : ' from ${_clock(lastSyncedAt!)}'}.';
      }
    } finally {
      if (requestId == _requestId) {
        isLoading = false;
        _notify();
      }
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoadingMore || isLoading || _nextCursor == null) return;
    final requestId = _requestId;
    final key = _queryKey;
    isLoadingMore = true;
    _notify();
    try {
      final page = await _service.fetchPage(
        period: periodFilter.cloudKey,
        search: searchQuery,
        category: selectedCategory,
        stockLevel: stockLevelFilter,
        limit: pageSize,
        cursor: _nextCursor,
      );
      if (_disposed || requestId != _requestId) return; // filters changed
      if (_integer(page['version']) != _version) {
        // Data changed while paging: re-sync instead of mixing versions.
        unawaited(_refreshList(keepDepth: true, silent: true));
        return;
      }
      _applyPage(page, append: true);
      refreshError = null;
      await _cache.write(key, _snapshot());
    } catch (error) {
      if (_disposed || requestId != _requestId) return;
      refreshError = 'Could not load more items. Check your connection.';
      _log('loadMore failed: $error');
    } finally {
      isLoadingMore = false;
      _notify();
    }
  }

  Future<void> _refreshStats() async {
    final period = periodFilter;
    final key = _statsKey;
    try {
      final stats = await _service.fetchStats(period: period.cloudKey);
      if (_disposed || period != periodFilter) return;
      _applyStats(stats);
      await _cache.write(key, {
        ...stats,
        'saved_at': DateTime.now().toIso8601String(),
      });
      _notify();
    } catch (error) {
      _log('Stats request failed: $error'); // keep cached stats
    }
  }

  // ---- Applying data ------------------------------------------------------
  void _applyPage(Map<String, dynamic> page, {bool append = false}) {
    final incoming = (page['items'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final merged = <Map<String, dynamic>>[];
    if (append) {
      merged.addAll(_rawItems);
      final seen = {for (final r in _rawItems) '${r['id']}'};
      merged.addAll(incoming.where((r) => !seen.contains('${r['id']}')));
    } else {
      merged.addAll(incoming);
    }

    // Re-use existing model objects for rows whose data did not change, so
    // unchanged rows keep their identity and are not rebuilt.
    final Map<String, InventoryItemModel> oldModels = {
  for (final m in items) m.id.toString(): m,
};
final Map<String, String> oldJson = {
  for (final r in _rawItems) '${r['id']}': jsonEncode(r),
};
items = merged.map<InventoryItemModel>((raw) {
  final id = '${raw['id']}';
  final InventoryItemModel? old = oldModels[id];
  if (old != null && oldJson[id] == jsonEncode(raw)) return old;
  return InventoryItemModel.fromCloud(raw);
}).toList(growable: false);
    _rawItems = merged;

    _nextCursor = page['next_cursor']?.toString();
    hasMore = page['has_more'] == true && _nextCursor != null;
    if (page['total_matching'] != null) {
      totalMatching = _integer(page['total_matching']);
    } else if (!append) {
      totalMatching = items.length;
    }

    final version = _integer(page['version']);
    if (!append) _version = version;
    _latestVersion = math.max(_latestVersion, version);
    hasLoadedOnce = true;
  }

  void _applyStats(Map<String, dynamic> response) {
    final stats = Map<String, dynamic>.from(
      response['stats'] as Map? ?? const {},
    );
    final rawCategories = response['categories'];
    categories = rawCategories is List
        ? rawCategories.map((v) => v.toString()).toList()
        : const [];
    periodExpenditure = _number(stats['expenditure']);
    totalItems = _integer(stats['total_items']);
    periodAddedItemCount = _integer(stats['added_item_count']);
    periodUsedItemCount = _integer(stats['used_item_count']);
    needsRestockCount = _integer(stats['needs_restock_count']);
    _statsVersion = _integer(response['version']);
    _latestVersion = math.max(_latestVersion, _statsVersion);
  }

  Map<String, dynamic> _snapshot() => {
        'version': _version,
        'items': _rawItems,
        'next_cursor': _nextCursor,
        'has_more': hasMore,
        'total_matching': totalMatching,
        'saved_at': DateTime.now().toIso8601String(),
      };

  DateTime? _savedAt(Map<String, dynamic> snap) =>
      DateTime.tryParse('${snap['saved_at']}');

  bool _isStale(Map<String, dynamic> snap) {
    final saved = _savedAt(snap);
    return saved == null || DateTime.now().difference(saved) > maxCacheAge;
  }

  String _clock(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

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

  // ---- Filters ------------------------------------------------------------
  void setSearch(String query) {
    if (searchQuery == query) return;
    searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_onQueryChanged()),
    );
  }

  void setCategory(String category) {
    if (selectedCategory == category) return;
    selectedCategory = category;
    unawaited(_onQueryChanged());
  }

  void setStockLevelFilter(String level, {StatsPeriod? period}) {
    final periodChanged = period != null && periodFilter != period;
    if (stockLevelFilter == level && !periodChanged) return;
    stockLevelFilter = level;
    if (periodChanged) periodFilter = period;
    unawaited(_onQueryChanged(periodChanged: periodChanged));
  }

  void setPeriodFilter(StatsPeriod period) {
    if (periodFilter == period) return;
    periodFilter = period;
    unawaited(_onQueryChanged(periodChanged: true));
  }

  /// Shows the cached result for the new filters immediately (if any) and
  /// only goes to the network when that cache is missing, stale or outdated.
  Future<void> _onQueryChanged({bool periodChanged = false}) async {
    final requestId = ++_requestId;
    final cached = await _cache.read(_queryKey);
    if (_disposed || requestId != _requestId) return;

    items = [];
    _rawItems = [];
    hasMore = false;
    totalMatching = 0;
    _nextCursor = null;
    _version = -1;
    isLoadingMore = false;

    if (periodChanged) {
      _statsVersion = -1;
      final cachedStats = await _cache.read(_statsKey);
      if (_disposed || requestId != _requestId) return;
      if (cachedStats != null) _applyStats(cachedStats);
      unawaited(_refreshStats());
    }

    if (cached != null) {
      _applyPage(cached);
      isLoading = false;
      _notify();
      final upToDate =
          _integer(cached['version']) == _latestVersion && !_isStale(cached);
      if (upToDate) return;
      await _refreshList(keepDepth: false, silent: true);
    } else {
      isLoading = true;
      _notify();
      await _refreshList(keepDepth: false, silent: false);
    }
  }

  // ---- Mutations (writes need a connection) -------------------------------
  Future<void> _afterMutation() async {
    await Future.wait([
      _refreshList(keepDepth: true, silent: true),
      _refreshStats(),
    ]);
  }

  Future<void> addStock(
    String id,
    double quantity, {
    required double purchaseCost,
  }) async {
    await _service.addStock(id, quantity, purchaseCost: purchaseCost);
    await _afterMutation();
  }

  Future<void> useStock(String id, double quantity) async {
    await _service.useStock(id, quantity);
    await _afterMutation();
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

    await _afterMutation();
    return failures;
  }

  Future<String> saveItem(InventoryItemModel item) async {
    final id = await _service.saveItem(item);
    await _afterMutation();
    return id;
  }

  Future<void> deleteItem(String id) async {
    await _service.deleteItem(id);
    await _afterMutation();
  }

  /// Call on logout.
  Future<void> clearCache() => _cache.clear();

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    _versionSub?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
  }
}

final inventoryProvider = ChangeNotifierProvider<InventoryProvider>(
  (ref) => InventoryProvider(InventoryService()),
);
