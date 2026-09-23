import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_stats_model.dart';
import '../providers/coupon_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/live_orders_provider.dart';
import '../providers/settings_provider.dart';
import '../services/dashboard_service.dart';
import 'dashboard_data_source.dart';

/// Bridge to real modules.
class DashboardDataSource {
  final Future<List<DashboardOrderInput>> Function() fetchTodayOrders;
  final Future<List<DashboardOrderInput>> Function(int days) fetchTrendOrders;
  final DashboardOperationalSnapshot Function() readOperational;

  const DashboardDataSource({
    required this.fetchTodayOrders,
    required this.fetchTrendOrders,
    required this.readOperational,
  });
}

class DashboardOperationalSnapshot {
  final int activeOrdersCount;
  final int pendingPaymentCount;
  final int lowStockCount;
  final int criticalStockCount;
  final int activeCouponCount;
  final int couponUsagesToday;
  final List<String> criticalItemNames;
  final List<String> lowStockItemNames;
  final List<String> expiringCouponCodes;

  const DashboardOperationalSnapshot({
    this.activeOrdersCount = 0,
    this.pendingPaymentCount = 0,
    this.lowStockCount = 0,
    this.criticalStockCount = 0,
    this.activeCouponCount = 0,
    this.couponUsagesToday = 0,
    this.criticalItemNames = const [],
    this.lowStockItemNames = const [],
    this.expiringCouponCodes = const [],
  });
}

/// Uses real Order / Inventory / Coupon modules by default.
final dashboardDataSourceProvider = Provider<DashboardDataSource>((ref) {
  return buildDashboardDataSource(ref);
});

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._ref) : _service = DashboardService();

  final Ref _ref;
  final DashboardService _service;

  bool isLoading = false;
  String? errorMessage;
  DashboardStatsModel? stats;
  String chartPeriod = 'Weekly';

  DashboardDataSource get _source => _ref.read(dashboardDataSourceProvider);

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Load operational modules first so readOperational() is meaningful.
      await Future.wait([
        _ref.read(liveOrdersProvider).load(),
        _ref.read(inventoryProvider).load(),
        _ref.read(couponProvider).load(),
      ]);

      final days = DashboardService.daysForPeriod(chartPeriod);
      final todayOrders = await _source.fetchTodayOrders();
      final trendOrders = await _source.fetchTrendOrders(days);
      final ops = _source.readOperational();
      final hours = _todaysOperatingHours();

      stats = _service.buildStats(
        todayOrders: todayOrders,
        trendOrders: trendOrders,
        lowStockCount: ops.lowStockCount,
        criticalStockCount: ops.criticalStockCount,
        activeCouponCount: ops.activeCouponCount,
        couponUsagesToday: ops.couponUsagesToday,
        activeOrdersCount: ops.activeOrdersCount,
        pendingPaymentCount: ops.pendingPaymentCount,
        criticalItemNames: ops.criticalItemNames,
        lowStockItemNames: ops.lowStockItemNames,
        expiringCouponCodes: ops.expiringCouponCodes,
        openHour: hours.openHour,
        closeHour: hours.closeHour,
      );
    } catch (e, st) {
      errorMessage = 'Failed to load dashboard.';
      if (kDebugMode) {
        // ignore: avoid_print
        print('DashboardProvider.load: $e\n$st');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Instant pulse update when live orders / inventory / coupons change.
  void refreshOperational() {
    if (stats == null) return;
    final ops = _source.readOperational();
    final attention = _service
        .buildStats(
          todayOrders: const [],
          trendOrders: const [],
          lowStockCount: ops.lowStockCount,
          criticalStockCount: ops.criticalStockCount,
          activeCouponCount: ops.activeCouponCount,
          couponUsagesToday: ops.couponUsagesToday,
          activeOrdersCount: ops.activeOrdersCount,
          pendingPaymentCount: ops.pendingPaymentCount,
          criticalItemNames: ops.criticalItemNames,
          lowStockItemNames: ops.lowStockItemNames,
          expiringCouponCodes: ops.expiringCouponCodes,
        )
        .attentionItems;

    stats = stats!.copyWith(
      activeOrdersCount: ops.activeOrdersCount,
      pendingPaymentCount: ops.pendingPaymentCount,
      lowStockCount: ops.lowStockCount,
      criticalStockCount: ops.criticalStockCount,
      activeCouponCount: ops.activeCouponCount,
      couponUsagesToday: ops.couponUsagesToday,
      attentionItems: attention,
    );
    notifyListeners();
  }

  Future<void> setChartPeriod(String period) async {
    if (chartPeriod == period) return;
    chartPeriod = period;
    notifyListeners();
    await load();
  }

  /// Picks weekday/weekend operating hours from Settings for today and
  /// parses them into 24-hour ints for bucketing the volume trend chart.
  ({int openHour, int closeHour}) _todaysOperatingHours() {
    final settings = _ref.read(settingsProvider);
    final now = DateTime.now();
    final isWeekend = now.weekday == DateTime.saturday ||
        now.weekday == DateTime.sunday;
    final hours = isWeekend ? settings.weekends : settings.weekdays;

    return (
      openHour: _parseHour(hours.open) ?? 10,
      closeHour: _parseHour(hours.close) ?? 22,
    );
  }

  /// Parses a "08:00 AM" / "11:30 PM" style string into a 24-hour int.
  /// Returns null if the string can't be parsed.
  int? _parseHour(String time) {
    final match =
        RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false)
            .firstMatch(time.trim());
    if (match == null) return null;

    var hour = int.tryParse(match.group(1)!);
    final meridiem = match.group(3)!.toUpperCase();
    if (hour == null) return null;

    if (meridiem == 'AM') {
      if (hour == 12) hour = 0;
    } else {
      if (hour != 12) hour += 12;
    }
    return hour % 24;
  }
}

final dashboardProvider = ChangeNotifierProvider<DashboardProvider>((ref) {
  return DashboardProvider(ref);
});
