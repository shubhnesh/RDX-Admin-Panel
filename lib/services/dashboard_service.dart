import 'package:flutter/foundation.dart';

import '../models/dashboard_stats_model.dart';
import 'dashboard_cloud_service.dart';

/// Thin facade over [DashboardCloudService].
///
/// **All aggregations (sales, funnel, mealtime, trends, percentages) run in
/// the `getDashboardStats` Cloud Function.** This class must not recompute
/// metrics from raw orders on the device.
@Deprecated(
  'Use DashboardCloudService directly. Local aggregation has been removed.',
)
class DashboardService {
  DashboardService({DashboardCloudService? cloud})
      : _cloud = cloud ?? DashboardCloudService();

  final DashboardCloudService _cloud;

  void _log(String message) {
    if (kDebugMode) debugPrint('[DashboardService] $message');
  }

  /// Loads dashboard stats for [period]:
  /// `today` | `yesterday` | `last_7_days` (or UI labels Today / Yesterday / Last 7 days).
  Future<DashboardStatsModel> loadStats({required String period}) async {
    _log('Delegating loadStats to Cloud Function (period=$period).');
    return _cloud.fetchStats(period: period);
  }

  /// Removed. Calling this throws — use [loadStats] / Cloud Function only.
  @Deprecated('Client-side buildStats was removed. Use loadStats().')
  Never buildStats({
    required List<dynamic> periodOrders,
    required List<dynamic> previousOrders,
    required List<dynamic> trendOrders,
    int lowStockCount = 0,
    int criticalStockCount = 0,
    int activeCouponCount = 0,
    int couponUsagesToday = 0,
    int activeOrdersCount = 0,
    int pendingPaymentCount = 0,
    List<String> criticalItemNames = const [],
    List<String> lowStockItemNames = const [],
    List<String> expiringCouponCodes = const [],
    String periodLabel = 'Today',
  }) {
    throw UnsupportedError(
      'DashboardService.buildStats is disabled. '
      'Dashboard numbers come only from Cloud Function getDashboardStats.',
    );
  }
}
