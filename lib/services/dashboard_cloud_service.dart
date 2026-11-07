import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../models/dashboard_stats_model.dart';

/// Fetches dashboard aggregations from the `getDashboardStats` Cloud Function.
///
/// The app must not recompute sales / funnel / mealtime / trends from raw
/// orders — all of that logic lives server-side.
class DashboardCloudService {
  DashboardCloudService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  void _log(String message) {
    if (kDebugMode) debugPrint('[DashboardCloudService] $message');
  }

  /// [period] is one of: `today`, `yesterday`, `last_7_days`.
  Future<DashboardStatsModel> fetchStats({required String period}) async {
    final normalized = _normalizePeriod(period);
    _log('getDashboardStats request started (period: $normalized).');

    try {
      final result = await _functions
          .httpsCallable('getDashboardStats')
          .call<Map<dynamic, dynamic>>({'period': normalized});

      _log(
        'getDashboardStats response received '
        '(period: $normalized, data type: ${result.data.runtimeType}).',
      );
      final data = Map<String, dynamic>.from(result.data as Map? ?? {});
      _log('Parsing dashboard response fields: ${data.keys.join(', ')}.');
      final stats = dashboardStatsFromCloud(data);
      _log(
        'Dashboard response parsed successfully '
        '(period label: ${stats.periodLabel}, '
        'attention items: ${stats.attentionItems.length}, '
        'top-selling items: ${stats.topSellingItems.length}).',
      );
      return stats;
    } on FirebaseFunctionsException catch (e) {
      _log('getDashboardStats failed (Functions code: ${e.code}).');
      rethrow;
    } catch (error) {
      _log(
          'getDashboardStats response processing failed (${error.runtimeType}).');
      rethrow;
    }
  }

  static String _normalizePeriod(String period) {
    final p = period.trim().toLowerCase();
    if (p == 'yesterday') return 'yesterday';
    if (p.contains('7') || p.contains('last')) return 'last_7_days';
    return 'today';
  }
}
