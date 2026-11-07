import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_item_model.dart';
import '../models/rewards_admin_models.dart';
import '../services/menu_service.dart';
import '../services/rewards_admin_service.dart';

class RewardsAdminProvider extends ChangeNotifier {
  RewardsAdminProvider({
    required RewardsAdminService service,
    required MenuService menuService,
  })  : _service = service,
        _menuService = menuService;

  final RewardsAdminService _service;
  final MenuService _menuService;

  bool isLoading = false;
  bool isMutating = false;
  bool canRead = false;
  bool canConfigure = false;
  String? errorMessage;
  RewardConfiguration? configuration;
  RewardAnalytics? analytics;
  List<FoodReward> foodRewards = [];
  List<MenuItemModel> menuItems = [];
  List<RewardTransaction> transactions = [];
  List<RewardReferralRecord> referrals = [];
  List<RewardRedemptionRecord> redemptions = [];
  String? transactionCursor;
  String? referralCursor;
  String? redemptionCursor;
  bool hasMoreTransactions = false;
  bool hasMoreReferrals = false;
  bool hasMoreRedemptions = false;
  String? transactionFilter;
  String? referralFilter;
  String? redemptionFilter;
  String transactionSearch = '';
  String referralSearch = '';
  String redemptionSearch = '';

  void _log(String message) {
    if (kDebugMode) debugPrint('[RewardsProvider] $message');
  }

  Future<void> load() async {
    _log('Dashboard data load started.');
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      canRead = await _service.hasReadPermission();
      _log('Read permission result: $canRead.');
      canConfigure = canRead && await _service.hasConfigurationPermission();
      _log('Configuration permission result: $canConfigure.');
      if (!canRead) {
        errorMessage = 'Your account does not have Rewards read permission.';
        _log('Dashboard data load stopped: read permission is missing.');
        return;
      }

      final now = DateTime.now();
      _log('Loading rewards configuration and analytics.');
      final results = await Future.wait<Object>([
        _service.fetchConfiguration(),
        _service.fetchAnalytics(
          from: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          to: now,
        ),
      ]);
      configuration = results[0] as RewardConfiguration;
      analytics = results[1] as RewardAnalytics;
      _log('Rewards configuration and analytics loaded.');
    } catch (error) {
      errorMessage = _displayError(error);
      _log('Dashboard data load failed (${error.runtimeType}).');
    } finally {
      isLoading = false;
      notifyListeners();
      _log('Dashboard data load finished.');
    }
  }

  Future<void> loadCatalog() async {
    await _runLoad('catalog', () async {
      _log('Loading reward catalog and menu items.');
      final results = await Future.wait([
        _service.fetchFoodRewards(),
        _menuService.fetchMenuItems(),
      ]);
      foodRewards = results[0] as List<FoodReward>;
      menuItems = results[1] as List<MenuItemModel>;
      _log(
        'Catalog load completed (${foodRewards.length} rewards, '
        '${menuItems.length} menu items).',
      );
    });
  }

  Future<void> loadTransactions({
    String? type,
    String? search,
    bool nextPage = false,
  }) async {
    if (!nextPage) {
      transactionFilter = type;
      transactionSearch = search ?? '';
      transactionCursor = null;
      transactions = [];
    } else if (!hasMoreTransactions) {
      return;
    }
    await _runLoad('transactions', () async {
      _log('Loading transactions (next page: $nextPage).');
      final page = await _service.fetchTransactions(
        type: transactionFilter,
        cursor: nextPage ? transactionCursor : null,
        search: transactionSearch,
      );
      transactions = [...transactions, ...page.items];
      transactionCursor = page.nextPageToken;
      hasMoreTransactions = page.nextPageToken != null;
      _log(
        'Loaded ${page.items.length} transactions; '
        'more available: $hasMoreTransactions.',
      );
    });
  }

  Future<void> loadReferrals({
    String? status,
    String? search,
    bool nextPage = false,
  }) async {
    if (!nextPage) {
      referralFilter = status;
      referralSearch = search ?? '';
      referralCursor = null;
      referrals = [];
    } else if (!hasMoreReferrals) {
      return;
    }
    await _runLoad('referrals', () async {
      _log('Loading referrals (next page: $nextPage).');
      final page = await _service.fetchReferrals(
        status: referralFilter,
        cursor: nextPage ? referralCursor : null,
        search: referralSearch,
      );
      referrals = [...referrals, ...page.items];
      referralCursor = page.nextPageToken;
      hasMoreReferrals = page.nextPageToken != null;
      _log(
        'Loaded ${page.items.length} referrals; '
        'more available: $hasMoreReferrals.',
      );
    });
  }

  Future<void> loadRedemptions({
    String? status,
    String? search,
    bool nextPage = false,
  }) async {
    if (!nextPage) {
      redemptionFilter = status;
      redemptionSearch = search ?? '';
      redemptionCursor = null;
      redemptions = [];
    } else if (!hasMoreRedemptions) {
      return;
    }
    await _runLoad('redemptions', () async {
      _log('Loading redemptions (next page: $nextPage).');
      final page = await _service.fetchRedemptions(
        status: redemptionFilter,
        cursor: nextPage ? redemptionCursor : null,
        search: redemptionSearch,
      );
      redemptions = [...redemptions, ...page.items];
      redemptionCursor = page.nextPageToken;
      hasMoreRedemptions = page.nextPageToken != null;
      _log(
        'Loaded ${page.items.length} redemptions; '
        'more available: $hasMoreRedemptions.',
      );
    });
  }

  Future<void> saveConfiguration(RewardConfiguration value) async {
    await _runMutation('configuration', () async {
      _log('Saving rewards configuration.');
      await _service.updateConfiguration(value);
      configuration = value;
      _log('Rewards configuration saved.');
    });
    await load();
  }

  Future<void> saveFoodReward(FoodReward value) async {
    final operation = value.id.isEmpty ? 'create reward' : 'update reward';
    await _runMutation(operation, () async {
      _log('$operation started.');
      if (value.id.isEmpty) {
        await _service.createFoodReward(value);
      } else {
        await _service.updateFoodReward(value);
      }
      _log('$operation completed.');
    });
    await loadCatalog();
  }

  Future<void> disableFoodReward(String rewardId) async {
    await _runMutation('disable reward', () async {
      _log('Disabling reward.');
      await _service.disableFoodReward(rewardId);
      _log('Reward disable request completed.');
    });
    await loadCatalog();
  }

  Future<void> _runLoad(
    String operation,
    Future<void> Function() action,
  ) async {
    _log('$operation load started.');
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      if (!canRead) {
        canRead = await _service.hasReadPermission();
      }
      if (!canRead) {
        _log('$operation load denied: read permission is missing.');
        throw StateError('Your account does not have Rewards read permission.');
      }
      await action();
      _log('$operation load completed.');
    } catch (error) {
      errorMessage = _displayError(error);
      _log('$operation load failed (${error.runtimeType}).');
    } finally {
      isLoading = false;
      notifyListeners();
      _log('$operation load finished.');
    }
  }

  Future<void> _runMutation(
    String operation,
    Future<void> Function() action,
  ) async {
    _log('$operation mutation started.');
    isMutating = true;
    errorMessage = null;
    notifyListeners();
    try {
      if (!await _service.hasConfigurationPermission()) {
        canConfigure = false;
        _log('$operation mutation denied: configuration permission missing.');
        throw StateError(
          'Your account does not have Rewards configuration permission.',
        );
      }
      canConfigure = true;
      await action();
      _log('$operation mutation completed.');
    } catch (error) {
      errorMessage = _displayError(error);
      _log('$operation mutation failed (${error.runtimeType}).');
      rethrow;
    } finally {
      isMutating = false;
      notifyListeners();
      _log('$operation mutation finished.');
    }
  }

  String _displayError(Object error) {
    if (error is FormatException) {
      return 'Rewards API returned data in an unsupported format.';
    }
    return error.toString();
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
