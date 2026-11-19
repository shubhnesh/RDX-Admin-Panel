import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/store/rewards_cache.dart';

import '../models/menu_item_model.dart';
import '../models/rewards_admin_model.dart';
import '../services/menu_service.dart';
import '../services/rewards_admin_service.dart';

/// State for one paginated table (transactions / referrals / redemptions).
/// Keeps the raw page maps so the exact data can be persisted and re-parsed.
class _Section<T> {
  _Section({
    required this.name,
    required this.parse,
    required this.fetch,
    required this.versionOf,
  });

  final String name;
  final T Function(Map<String, dynamic>) parse;
  final Future<Map<String, dynamic>> Function(
    String? filter,
    String search,
    String? cursor,
  ) fetch;
  final int? Function(Map<String, int>? versions) versionOf;

  String? filter;
  String search = '';
  List<T> items = <T>[];
  List<Map<String, dynamic>> pages = <Map<String, dynamic>>[];
  String? cursor;
  bool hasMore = false;
  bool loaded = false;
  bool loadingMore = false;
  int version = -1; // change-counter of the data currently on screen
  int requestId = 0;
  DateTime? syncedAt;

  String get key => '$name|${filter ?? 'all'}|${search.trim().toLowerCase()}';

  void reset() {
    items = <T>[];
    pages = <Map<String, dynamic>>[];
    cursor = null;
    hasMore = false;
    loaded = false;
    loadingMore = false;
    version = -1;
    syncedAt = null;
  }
}

/// Cached, paginated rewards admin state.
///
/// * Tables load [RewardsAdminService.pageSize] rows at a time.
/// * Everything is persisted (Hive), so reopening the screen or app, even
///   offline, shows data instantly.
/// * No polling: one tiny "versions" document is watched, and a section is
///   re-fetched only when its own counter changed.
class RewardsAdminProvider extends ChangeNotifier {
  RewardsAdminProvider({
    required RewardsAdminService service,
    required MenuService menuService,
    RewardsCache? cache,
    this.maxCacheAge = const Duration(minutes: 10),
  })  : _service = service,
        _menuService = menuService,
        _cache = cache ?? RewardsCache();

  static const int _maxDepthPages = 5;

  final RewardsAdminService _service;
  final MenuService _menuService;
  final RewardsCache _cache;
  final Duration maxCacheAge;

  StreamSubscription<Map<String, int>>? _versionSub;
  Timer? _changeDebounce;
  Completer<void> _firstVersion = Completer<void>();
  Map<String, int>? _versions;
  bool _started = false;
  bool _disposed = false;
  int _busy = 0;

  // ---- Public state -------------------------------------------------------
  bool isMutating = false;
  bool canRead = false;
  bool canConfigure = false;
  bool isOffline = false;
  String? errorMessage;
  String? refreshError;
  RewardConfiguration? configuration;
  RewardAnalytics? analytics;
  List<FoodReward> foodRewards = [];
  List<MenuItemModel> menuItems = [];

  bool get isLoading => _busy > 0;

  // Held versions / timestamps for the non-table data.
  int _configVersion = -1;
  int _analyticsVersionHeld = -1;
  int _catalogVersion = -1;
  bool _catalogLoaded = false;
  final Map<String, DateTime?> _syncedAt = {};
  DateTime? _menuSyncedAt;

  late final _Section<RewardTransaction> _transactions =
      _Section<RewardTransaction>(
    name: 'transactions',
    parse: RewardTransaction.fromMap,
    fetch: (filter, search, cursor) => _service.fetchPageRaw(
      'fetchRewardTransactions',
      type: filter,
      search: search,
      cursor: cursor,
    ),
    versionOf: (v) => v?['ledger'],
  );

  late final _Section<RewardReferralRecord> _referrals =
      _Section<RewardReferralRecord>(
    name: 'referrals',
    parse: RewardReferralRecord.fromMap,
    fetch: (filter, search, cursor) => _service.fetchPageRaw(
      'fetchReferralRecords',
      status: filter,
      search: search,
      cursor: cursor,
    ),
    versionOf: (v) => v?['referrals'],
  );

  late final _Section<RewardRedemptionRecord> _redemptions =
      _Section<RewardRedemptionRecord>(
    name: 'redemptions',
    parse: RewardRedemptionRecord.fromMap,
    fetch: (filter, search, cursor) => _service.fetchPageRaw(
      'fetchRedemptionRecords',
      status: filter,
      search: search,
      cursor: cursor,
    ),
    versionOf: (v) => v?['redemptions'],
  );

  // Table state, same names the screens already use.
  List<RewardTransaction> get transactions => _transactions.items;
  List<RewardReferralRecord> get referrals => _referrals.items;
  List<RewardRedemptionRecord> get redemptions => _redemptions.items;
  String? get transactionCursor => _transactions.cursor;
  String? get referralCursor => _referrals.cursor;
  String? get redemptionCursor => _redemptions.cursor;
  bool get hasMoreTransactions => _transactions.hasMore;
  bool get hasMoreReferrals => _referrals.hasMore;
  bool get hasMoreRedemptions => _redemptions.hasMore;
  String? get transactionFilter => _transactions.filter;
  String? get referralFilter => _referrals.filter;
  String? get redemptionFilter => _redemptions.filter;
  String get transactionSearch => _transactions.search;
  String get referralSearch => _referrals.search;
  String get redemptionSearch => _redemptions.search;

  /// New: true while the next page of a table is loading (show a footer
  /// spinner instead of blocking the whole screen).
  bool get isLoadingMoreTransactions => _transactions.loadingMore;
  bool get isLoadingMoreReferrals => _referrals.loadingMore;
  bool get isLoadingMoreRedemptions => _redemptions.loadingMore;

  // ---- Helpers ------------------------------------------------------------
  void _log(String message) {
    if (kDebugMode) debugPrint('[RewardsProvider] $message');
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _begin() {
    _busy++;
    _notify();
  }

  void _end() {
    if (_busy > 0) _busy--;
    _notify();
  }

  int _int(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  DateTime? _savedAt(Map<String, dynamic> snap) =>
      DateTime.tryParse('${snap['saved_at']}');

  bool _isStale(DateTime? savedAt) =>
      savedAt == null || DateTime.now().difference(savedAt) > maxCacheAge;

  String _clock(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int? _versionFor<T>(_Section<T> s) => s.versionOf(_versions);

  int? get _analyticsVersion {
    final v = _versions;
    if (v == null) return null;
    return (v['ledger'] ?? 0) + (v['referrals'] ?? 0) + (v['redemptions'] ?? 0);
  }

  void _markOffline(DateTime? syncedAt) {
    isOffline = true;
    refreshError = 'Could not refresh. Showing saved rewards data'
        '${syncedAt == null ? '' : ' from ${_clock(syncedAt)}'}.';
  }

  void _fire(Future<void> Function() task) {
    unawaited(task().catchError((Object error) {
      _log('Background refresh failed (${error.runtimeType}).');
    }));
  }

  // ---- Permissions --------------------------------------------------------
  /// Falls back to the last known permissions when offline.
  Future<void> _resolvePermissions() async {
    try {
      canRead = await _service.hasReadPermission();
      canConfigure = canRead && await _service.hasConfigurationPermission();
      await _cache.write('permissions', {'read': canRead, 'config': canConfigure});
    } catch (error) {
      _log('Permission check failed (${error.runtimeType}); using saved result.');
      final saved = await _cache.read('permissions');
      canRead = saved?['read'] == true;
      canConfigure = canRead && saved?['config'] == true;
    }
  }

  Future<bool> _ensureReady() async {
    if (!canRead) await _resolvePermissions();
    if (!canRead) return false;
    _listenForChanges();
    if (!_firstVersion.isCompleted) {
      await _firstVersion.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () {},
      );
    }
    return true;
  }

  // ---- Change listener ----------------------------------------------------
  void _listenForChanges() {
    _versionSub ??= _service.watchVersions().listen(
      (versions) {
        if (_disposed) return;
        _versions = versions;
        if (!_firstVersion.isCompleted) _firstVersion.complete();
        // Bursts of writes (several orders at once) collapse into one refresh.
        _changeDebounce?.cancel();
        _changeDebounce = Timer(const Duration(seconds: 2), _onVersionsChanged);
      },
      onError: (Object error) {
        _log('Version listener failed (${error.runtimeType}).');
        if (!_firstVersion.isCompleted) _firstVersion.complete();
      },
    );
  }

  void _onVersionsChanged() {
    if (_disposed) return;
    _resyncIfChanged(_transactions);
    _resyncIfChanged(_referrals);
    _resyncIfChanged(_redemptions);
    if (analytics != null) _fire(_syncAnalytics);
    if (configuration != null) _fire(_syncConfiguration);
    if (_catalogLoaded) _fire(_syncCatalog);
  }

  void _resyncIfChanged<T>(_Section<T> s) {
    final current = _versionFor(s);
    if (s.loaded && current != null && s.version != current) {
      _fire(() => _refreshList(s, keepDepth: true));
    }
  }

  // ---- Dashboard (configuration + analytics) ------------------------------
  /// Safe to call every time the screen opens: if nothing changed since the
  /// last fetch it returns immediately without touching the network.
  Future<void> load({bool force = false}) async {
    if (_started && !force) {
      await _syncConfigAndAnalytics();
      return;
    }
    errorMessage = null;
    _begin();
    try {
      if (!await _ensureReady()) {
        errorMessage = 'Your account does not have Rewards read permission.';
        return;
      }
      _started = true;
      await _syncConfigAndAnalytics(force: force);
    } finally {
      _end();
    }
  }

  /// Pull-to-refresh: re-fetches everything that is on screen.
  Future<void> refresh() async {
    refreshError = null;
    await load(force: true);
    await Future.wait<void>([
      if (_transactions.loaded) _refreshList(_transactions, keepDepth: true),
      if (_referrals.loaded) _refreshList(_referrals, keepDepth: true),
      if (_redemptions.loaded) _refreshList(_redemptions, keepDepth: true),
      if (_catalogLoaded) loadCatalog(force: true),
    ]);
  }

  Future<void> _syncConfigAndAnalytics({bool force = false}) async {
    Object? firstError;
    await Future.wait<void>([
      _syncConfiguration(force: force).catchError((Object e) {
        firstError ??= e;
      }),
      _syncAnalytics(force: force).catchError((Object e) {
        firstError ??= e;
      }),
    ]);
    final error = firstError;
    if (error != null) errorMessage = _displayError(error);
    _notify();
  }

  Future<void> _syncConfiguration({bool force = false}) => _syncSingle(
        key: 'config',
        currentVersion: () => _versions?['config'],
        heldVersion: () => _configVersion,
        hasValue: () => configuration != null,
        fetch: _service.fetchConfigurationRaw,
        apply: (raw, version) {
          configuration = RewardConfiguration.fromCallable(raw);
          _configVersion = version;
        },
        force: force,
      );

  Future<void> _syncAnalytics({bool force = false}) => _syncSingle(
        key: 'analytics',
        currentVersion: () => _analyticsVersion,
        heldVersion: () => _analyticsVersionHeld,
        hasValue: () => analytics != null,
        fetch: () => _service.fetchAnalyticsRaw(
          from: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          to: DateTime.now(),
        ),
        apply: (raw, version) {
          analytics = RewardAnalytics.fromMap(raw);
          _analyticsVersionHeld = version;
        },
        force: force,
      );

  /// Shared logic for single-document data: show the cache first, then hit
  /// the network only if the change counter moved (or the cache is too old
  /// when no counter is available).
  Future<void> _syncSingle({
    required String key,
    required int? Function() currentVersion,
    required int Function() heldVersion,
    required bool Function() hasValue,
    required Future<Map<String, dynamic>> Function() fetch,
    required void Function(Map<String, dynamic> raw, int version) apply,
    bool force = false,
  }) async {
    if (!hasValue()) {
      final cached = await _cache.read(key);
      if (_disposed) return;
      if (cached != null && cached['data'] is Map) {
        try {
          apply(
            Map<String, dynamic>.from(cached['data'] as Map),
            _int(cached['version']),
          );
          _syncedAt[key] = _savedAt(cached);
          _notify();
        } catch (_) {
          // unreadable cache: fall through to the network
        }
      }
    }

    final current = currentVersion();
    if (!force && hasValue()) {
      final fresh = current != null
          ? heldVersion() == current
          : !_isStale(_syncedAt[key]);
      if (fresh) return;
    }

    try {
      final raw = await fetch();
      if (_disposed) return;
      final version = current ?? -1;
      apply(raw, version);
      _syncedAt[key] = DateTime.now();
      isOffline = false;
      refreshError = null;
      await _cache.write(key, {
        'version': version,
        'data': raw,
        'saved_at': DateTime.now().toIso8601String(),
      });
      _notify();
    } catch (error) {
      if (_disposed) return;
      if (error is FormatException || !hasValue()) rethrow;
      _markOffline(_syncedAt[key]); // keep showing what we have
      _notify();
    }
  }

  // ---- Paginated tables ---------------------------------------------------
  Future<void> loadTransactions({
    String? type,
    String? search,
    bool nextPage = false,
  }) =>
      _loadList(_transactions, filter: type, search: search, nextPage: nextPage);

  Future<void> loadReferrals({
    String? status,
    String? search,
    bool nextPage = false,
  }) =>
      _loadList(_referrals, filter: status, search: search, nextPage: nextPage);

  Future<void> loadRedemptions({
    String? status,
    String? search,
    bool nextPage = false,
  }) =>
      _loadList(_redemptions, filter: status, search: search, nextPage: nextPage);

  Future<void> _loadList<T>(
    _Section<T> s, {
    String? filter,
    String? search,
    bool nextPage = false,
  }) async {
    if (nextPage) return _loadMore(s);
    if (!await _ensureReady()) {
      errorMessage = 'Your account does not have Rewards read permission.';
      _notify();
      return;
    }

    final newSearch = search ?? '';
    final sameQuery = s.loaded && s.filter == filter && s.search == newSearch;
    s.filter = filter;
    s.search = newSearch;

    if (sameQuery) {
      // Re-opening the same table: only fetch if something changed.
      final current = _versionFor(s);
      final fresh =
          current != null ? s.version == current : !_isStale(s.syncedAt);
      if (fresh) return;
      return _refreshList(s, keepDepth: true);
    }

    final id = ++s.requestId;
    final cached = await _cache.read(s.key);
    if (_disposed || id != s.requestId) return;

    s.reset();
    if (cached != null && _applyCached(s, cached)) {
      errorMessage = null;
      _notify();
      final current = _versionFor(s);
      final fresh =
          !_isStale(s.syncedAt) && (current == null || s.version == current);
      if (fresh) return;
      await _refreshList(s);
    } else {
      await _refreshList(s, silent: false);
    }
  }

  bool _applyCached<T>(_Section<T> s, Map<String, dynamic> cached) {
    try {
      final pages = (cached['pages'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (pages.isEmpty) return false;
      _applyPages(s, pages);
      s.version = _int(cached['version']);
      s.syncedAt = _savedAt(cached);
      return true;
    } catch (_) {
      s.reset();
      return false;
    }
  }

  void _applyPages<T>(_Section<T> s, List<Map<String, dynamic>> pages) {
    final items = <T>[];
    String? next;
    for (final raw in pages) {
      final page = RewardPage<T>.fromCallable(raw, s.parse);
      items.addAll(page.items);
      next = page.nextPageToken;
    }
    s.pages = pages;
    s.items = items;
    s.cursor = next;
    s.hasMore = next != null;
    s.loaded = true;
  }

  Map<String, dynamic> _listSnapshot<T>(_Section<T> s) => {
        'version': s.version,
        'pages': s.pages,
        'saved_at': DateTime.now().toIso8601String(),
      };

  /// Re-fetches a table. With [keepDepth] it re-reads as many pages as the
  /// user had loaded (capped), so the scroll position survives a refresh.
  Future<void> _refreshList<T>(
    _Section<T> s, {
    bool keepDepth = false,
    bool silent = true,
  }) async {
    if (_disposed) return;
    final id = ++s.requestId;
    final key = s.key;
    final versionAtStart = _versionFor(s);
    final depth = keepDepth
        ? math.min(math.max(s.pages.length, 1), _maxDepthPages)
        : 1;

    if (!silent) {
      errorMessage = null;
      _begin();
    }
    try {
      final pages = <Map<String, dynamic>>[];
      String? cursor;
      for (var i = 0; i < depth; i++) {
        final raw = await s.fetch(s.filter, s.search, cursor);
        if (_disposed || id != s.requestId) return;
        pages.add(raw);
        cursor = RewardPage<T>.fromCallable(raw, s.parse).nextPageToken;
        if (cursor == null) break;
      }
      _applyPages(s, pages);
      s.version = versionAtStart ?? -1;
      s.syncedAt = DateTime.now();
      isOffline = false;
      refreshError = null;
      errorMessage = null;
      await _cache.write(key, _listSnapshot(s));
    } catch (error) {
      if (_disposed || id != s.requestId) return;
      _log('${s.name} refresh failed (${error.runtimeType}).');
      if (s.loaded) {
        _markOffline(s.syncedAt);
      } else {
        errorMessage = _displayError(error);
      }
    } finally {
      if (!silent) {
        _end();
      } else {
        _notify();
      }
    }
  }

  Future<void> _loadMore<T>(_Section<T> s) async {
    if (!s.hasMore || s.loadingMore || s.cursor == null) return;
    final id = s.requestId;
    final key = s.key;
    s.loadingMore = true;
    _notify();
    try {
      final raw = await s.fetch(s.filter, s.search, s.cursor);
      if (_disposed || id != s.requestId) return; // filters changed meanwhile
      final current = _versionFor(s);
      if (current != null && s.version != current) {
        // Data changed while paging: re-sync instead of mixing versions.
        _fire(() => _refreshList(s, keepDepth: true));
        return;
      }
      _applyPages(s, [...s.pages, raw]);
      refreshError = null;
      await _cache.write(key, _listSnapshot(s));
    } catch (error) {
      if (_disposed || id != s.requestId) return;
      _log('${s.name} loadMore failed (${error.runtimeType}).');
      refreshError = 'Could not load more. Check your connection.';
    } finally {
      s.loadingMore = false;
      _notify();
    }
  }

  // ---- Catalog + menu -----------------------------------------------------
  /// Reward catalog is read straight from Firestore (its own SDK cache covers
  /// offline on mobile); here we only avoid re-reading it until it changes.
  Future<void> loadCatalog({bool force = false}) async {
    final current = _versions?['catalog'];
    final needCatalog = force ||
        !_catalogLoaded ||
        current == null ||
        _catalogVersion != current;
    final needMenu =
        force || _menuSyncedAt == null || _isStale(_menuSyncedAt);
    if (!needCatalog && !needMenu) return;

    await _runLoad('catalog', () async {
      await Future.wait<void>([
        if (needCatalog)
          _service.fetchFoodRewards().then((value) {
            foodRewards = value;
            _catalogLoaded = true;
            _catalogVersion = current ?? -1;
          }),
        if (needMenu)
          _menuService.fetchMenuItems().then((value) {
            menuItems = value;
            _menuSyncedAt = DateTime.now();
          }),
      ]);
    });
  }

  Future<void> loadMenuItems({bool force = false}) async {
    if (!force && _menuSyncedAt != null && !_isStale(_menuSyncedAt)) return;
    await _runLoad('menu items', () async {
      menuItems = await _menuService.fetchMenuItems();
      _menuSyncedAt = DateTime.now();
    });
  }

  Future<void> _syncCatalog() async {
    final current = _versions?['catalog'];
    if (current != null && _catalogVersion == current) return;
    final rewards = await _service.fetchFoodRewards();
    if (_disposed) return;
    foodRewards = rewards;
    _catalogLoaded = true;
    _catalogVersion = current ?? -1;
    _notify();
  }

  // ---- Mutations (writes need a connection) -------------------------------
  Future<void> saveConfiguration(RewardConfiguration value) async {
    await _runMutation('configuration', () async {
      await _service.updateConfiguration(value);
      configuration = value;
    });
    try {
      await _syncConfiguration(force: true);
    } catch (_) {}
  }

  Future<void> saveFoodReward(FoodReward value) async {
    final operation = value.id.isEmpty ? 'create reward' : 'update reward';
    await _runMutation(operation, () async {
      if (value.id.isEmpty) {
        await _service.createFoodReward(value);
      } else {
        await _service.updateFoodReward(value);
      }
    });
    await loadCatalog(force: true);
  }

  Future<void> disableFoodReward(String rewardId) async {
    await _runMutation('disable reward', () async {
      await _service.disableFoodReward(rewardId);
    });
    await loadCatalog(force: true);
  }

  Future<void> _runLoad(
    String operation,
    Future<void> Function() action,
  ) async {
    errorMessage = null;
    _begin();
    try {
      if (!await _ensureReady()) {
        throw StateError('Your account does not have Rewards read permission.');
      }
      await action();
    } catch (error) {
      errorMessage = _displayError(error);
      _log('$operation load failed (${error.runtimeType}).');
    } finally {
      _end();
    }
  }

  Future<void> _runMutation(
    String operation,
    Future<void> Function() action,
  ) async {
    isMutating = true;
    errorMessage = null;
    _notify();
    try {
      if (!await _service.hasConfigurationPermission()) {
        canConfigure = false;
        throw StateError(
          'Your account does not have Rewards configuration permission.',
        );
      }
      canConfigure = true;
      await action();
    } catch (error) {
      errorMessage = _displayError(error);
      _log('$operation mutation failed (${error.runtimeType}).');
      rethrow;
    } finally {
      isMutating = false;
      _notify();
    }
  }

  String _displayError(Object error) {
    if (error is FormatException) {
      return 'Rewards API returned data in an unsupported format.';
    }
    return error.toString();
  }

  /// Call on logout: wipes the saved data and resets in-memory state.
  Future<void> clearCache() async {
    await _cache.clear();
    await _versionSub?.cancel();
    _versionSub = null;
    _changeDebounce?.cancel();
    _firstVersion = Completer<void>();
    _versions = null;
    _started = false;
    canRead = false;
    canConfigure = false;
    configuration = null;
    analytics = null;
    foodRewards = [];
    menuItems = [];
    _catalogLoaded = false;
    _menuSyncedAt = null;
    _syncedAt.clear();
    for (final s in [_transactions, _referrals, _redemptions]) {
      s.requestId++;
      s.reset();
    }
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _versionSub?.cancel();
    _changeDebounce?.cancel();
    super.dispose();
  }
}

final rewardsAdminServiceProvider = Provider<RewardsAdminService>(
  (ref) => RewardsAdminService(),
);

final rewardsAdminProvider = ChangeNotifierProvider<RewardsAdminProvider>(
  (ref) => RewardsAdminProvider(
    service: ref.watch(rewardsAdminServiceProvider),
    menuService: MenuService(),
  ),
);
