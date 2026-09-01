import 'package:flutter/material.dart';
import '../models/dashboard_stats_model.dart';
import '../models/activity_log_model.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service;
  DashboardProvider(this._service);

  DashboardStatsModel? stats;
  List<ActivityLogModel> recentActivity = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      stats = await _service.fetchStats();
      recentActivity = await _service.fetchRecentActivity();
    } catch (e) {
      errorMessage = 'Failed to load dashboard data.';
    }
    isLoading = false;
    notifyListeners();
  }
}
