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

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      canRead = await _service.hasReadPermission();
      canConfigure = canRead && await _service.hasConfigurationPermission();
      if (!canRead) {
        errorMessage = 'Your account does not have Rewards read permission.';
        return;
      }

      final now = DateTime.now();
      final results = await Future.wait<Object>([
        _service.fetchConfiguration(),
        _service.fetchAnalytics(
          from: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          to: now,
        ),
      ]);
      configuration = results[0] as RewardConfiguration;
      analytics = results[1] as RewardAnalytics;
    } catch (error, stackTrace) {
      errorMessage = _displayError(error);
      if (kDebugMode) {
        debugPrint('RewardsAdminProvider.load: $error\n$stackTrace');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCatalog() async {
    await _runLoad(() async {
      final results = await Future.wait([
        _service.fetchFoodRewards(),
        _menuService.fetchMenuItems(),
      ]);
      foodRewards = results[0] as List<FoodReward>;
      menuItems = results[1] as List<MenuItemModel>;
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
    await _runLoad(() async {
      final page = await _service.fetchTransactions(
        type: transactionFilter,
        cursor: nextPage ? transactionCursor : null,
        search: transactionSearch,
      );
      transactions = [...transactions, ...page.items];
      transactionCursor = page.nextPageToken;
      hasMoreTransactions = page.nextPageToken != null;
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
    await _runLoad(() async {
      final page = await _service.fetchReferrals(
        status: referralFilter,
        cursor: nextPage ? referralCursor : null,
        search: referralSearch,
      );
      referrals = [...referrals, ...page.items];
      referralCursor = page.nextPageToken;
      hasMoreReferrals = page.nextPageToken != null;
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
    await _runLoad(() async {
      final page = await _service.fetchRedemptions(
        status: redemptionFilter,
        cursor: nextPage ? redemptionCursor : null,
        search: redemptionSearch,
      );
      redemptions = [...redemptions, ...page.items];
      redemptionCursor = page.nextPageToken;
      hasMoreRedemptions = page.nextPageToken != null;
    });
  }

  Future<void> saveConfiguration(RewardConfiguration value) async {
    await _runMutation(() async {
      await _service.updateConfiguration(value);
      configuration = value;
    });
    await load();
  }

  Future<void> saveFoodReward(FoodReward value) async {
    await _runMutation(() async {
      if (value.id.isEmpty) {
        await _service.createFoodReward(value);
      } else {
        await _service.updateFoodReward(value);
      }
    });
    await loadCatalog();
  }

  Future<void> disableFoodReward(String rewardId) async {
    await _runMutation(() async {
      await _service.disableFoodReward(rewardId);
    });
    await loadCatalog();
  }

  Future<void> _runLoad(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      if (!canRead) {
        canRead = await _service.hasReadPermission();
      }
      if (!canRead) {
        throw StateError('Your account does not have Rewards read permission.');
      }
      await action();
    } catch (error, stackTrace) {
      errorMessage = _displayError(error);
      if (kDebugMode) {
        debugPrint('RewardsAdminProvider._runLoad: $error\n$stackTrace');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    isMutating = true;
    errorMessage = null;
    notifyListeners();
    try {
      if (!await _service.hasConfigurationPermission()) {
        canConfigure = false;
        throw StateError(
          'Your account does not have Rewards configuration permission.',
        );
      }
      canConfigure = true;
      await action();
    } catch (error, stackTrace) {
      errorMessage = _displayError(error);
      if (kDebugMode) {
        debugPrint('RewardsAdminProvider._runMutation: $error\n$stackTrace');
      }
      rethrow;
    } finally {
      isMutating = false;
      notifyListeners();
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
