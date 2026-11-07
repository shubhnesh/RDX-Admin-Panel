import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_stats_model.dart';
import '../services/dashboard_cloud_service.dart';

/// All dashboard numbers come from [DashboardCloudService] / `getDashboardStats`.
/// The app does not aggregate orders, inventory, or coupons locally.
class DashboardProvider extends ChangeNotifier {
  DashboardProvider({DashboardCloudService? service})
      : _service = service ?? DashboardCloudService();

  final DashboardCloudService _service;

  bool isLoading = false;
  String? errorMessage;
  DashboardStatsModel? stats;

  void _log(String message) {
    if (kDebugMode) debugPrint('[DashboardProvider] $message');
  }

  void _logFailure(String operation, Object error, StackTrace stackTrace) {
    _log('$operation failed (${error.runtimeType}): $error\n$stackTrace');
  }

  /// Today | Yesterday | Last 7 days
  String selectedPeriod = 'Today';

  String get _periodKey {
    switch (selectedPeriod) {
      case 'Yesterday':
        return 'yesterday';
      case 'Last 7 days':
        return 'last_7_days';
      default:
        return 'today';
    }
  }

  Future<void> load() async {
    _log(
      'Dashboard load started '
      '(period: $selectedPeriod, key: $_periodKey, '
      'existing stats: ${stats != null}).',
    );
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      stats = await _service.fetchStats(period: _periodKey);
      errorMessage = null;
      _log(
        'Dashboard load completed '
        '(period: $selectedPeriod, stats available: ${stats != null}).',
      );
    } catch (error, stackTrace) {
      _logFailure('Dashboard load', error, stackTrace);
      errorMessage = 'Failed to load dashboard.';
    } finally {
      isLoading = false;
      notifyListeners();
      _log(
        'Dashboard loading state cleared '
        '(error: ${errorMessage != null}, stats available: ${stats != null}).',
      );
    }
  }

  /// Re-fetch from cloud (e.g. pull-to-refresh or after settling an order).
  Future<void> refreshOperational() async {
    // Operational counts are included in getDashboardStats — full refresh.
    _log('Operational dashboard refresh started (period: $_periodKey).');
    try {
      final next = await _service.fetchStats(period: _periodKey);
      stats = next;
      errorMessage = null;
      notifyListeners();
      _log('Operational dashboard refresh completed.');
    } catch (error, stackTrace) {
      _logFailure('Operational dashboard refresh', error, stackTrace);
      // Keep existing stats on background refresh failure.
    }
  }

  Future<void> setPeriod(String period) async {
    if (selectedPeriod == period) {
      _log('Period change skipped; "$period" is already selected.');
      return;
    }
    _log('Dashboard period change requested: $selectedPeriod -> $period.');
    selectedPeriod = period;
    notifyListeners();
    await load();
  }
}

final dashboardCloudServiceProvider = Provider<DashboardCloudService>(
  (ref) => DashboardCloudService(),
);

final dashboardProvider = ChangeNotifierProvider<DashboardProvider>((ref) {
  return DashboardProvider(service: ref.watch(dashboardCloudServiceProvider));
});
