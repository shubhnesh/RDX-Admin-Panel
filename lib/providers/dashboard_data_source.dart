import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/dashboard_cloud_service.dart';
import 'dashboard_provider.dart';

/// Previously fetched orders / inventory on the client and aggregated locally.
///
/// **Removed.** Use [dashboardCloudServiceProvider] and [dashboardProvider]
/// which call `getDashboardStats` only.
@Deprecated('Client-side dashboard data source removed. Use DashboardCloudService.')
final realDashboardDataSourceProvider = Provider<DashboardCloudService>((ref) {
  return ref.watch(dashboardCloudServiceProvider);
});
