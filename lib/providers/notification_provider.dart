import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;

  NotificationProvider(this._service);

  List<NotificationModel> history = [];
  List<NotificationModel> activity = [];
  final List<NotificationModel> incomingActivity = [];

  bool isLoading = false;
  bool isActivityLoading = false;

  String? errorMessage;
  String? activityErrorMessage;

  NotificationAudience audience = NotificationAudience.allApp;
  StreamSubscription<List<NotificationModel>>? _activitySubscription;
  String? _activityUid;
  bool _hasActivitySnapshot = false;

  int unreadActivityCountFor(String? uid) {
    if (uid == null) return 0;
    return activity.where((notification) => !notification.isReadBy(uid)).length;
  }

  void watchAdminActivity(String uid) {
    if (_activityUid == uid && _activitySubscription != null) return;

    _activityUid = uid;
    activity = [];
    incomingActivity.clear();
    _hasActivitySnapshot = false;
    activityErrorMessage = null;
    isActivityLoading = true;
    notifyListeners();
    _activitySubscription?.cancel();
    _activitySubscription = _service.watchAdminActivity().listen(
      (notifications) {
        if (_hasActivitySnapshot) {
          final knownIds = activity.map((item) => item.id).toSet();
          incomingActivity.addAll(
            notifications.where((item) => !knownIds.contains(item.id)),
          );
        }
        activity = notifications;
        _hasActivitySnapshot = true;
        activityErrorMessage = null;
        isActivityLoading = false;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        activityErrorMessage = 'Failed to load business activity.';
        isActivityLoading = false;
        notifyListeners();
      },
    );
  }

  void stopAdminActivityWatch() {
    _activityUid = null;
    _activitySubscription?.cancel();
    _activitySubscription = null;
    activity = [];
    incomingActivity.clear();
    _hasActivitySnapshot = false;
    isActivityLoading = false;
    activityErrorMessage = null;
    notifyListeners();
  }

  Future<void> refreshAdminActivity() async {
    isActivityLoading = true;
    activityErrorMessage = null;
    notifyListeners();
    try {
      activity = await _service.fetchAdminActivity();
    } catch (error) {
      activityErrorMessage = 'Failed to load business activity.';
    } finally {
      isActivityLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markActivityRead(String notificationId, String uid) async {
    try {
      await _service.markActivityRead(notificationId, uid);
      activity = activity
          .map(
              (item) => item.id == notificationId ? item.withReadBy(uid) : item)
          .toList(growable: false);
      notifyListeners();
      return true;
    } catch (error) {
      activityErrorMessage = 'Failed to mark notification as read.';
      notifyListeners();
      return false;
    }
  }

  void dismissIncomingActivity(String notificationId) {
    incomingActivity.removeWhere((item) => item.id == notificationId);
    notifyListeners();
  }

  Future<bool> markAllActivityRead(String uid) async {
    final unread = activity.where((item) => !item.isReadBy(uid)).toList();
    if (unread.isEmpty) return true;

    try {
      await _service.markAllActivityRead(
        unread.map((item) => item.id),
        uid,
      );
      activity =
          activity.map((item) => item.withReadBy(uid)).toList(growable: false);
      notifyListeners();
      return true;
    } catch (error) {
      activityErrorMessage = 'Failed to mark notifications as read.';
      notifyListeners();
      return false;
    }
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      history = await _service.fetchHistory();
    } catch (e) {
      errorMessage = 'Failed to load notifications.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendBroadcast({
    required String title,
    required String message,
  }) async {
    if (title.trim().isEmpty || message.trim().isEmpty) {
      errorMessage = 'Please fill in both notification title and message.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();

      final notification = NotificationModel(
        id: 'n${now.millisecondsSinceEpoch}',
        title: title.trim(),
        message: message.trim(),
        audience: NotificationAudience.allApp,
        createdAt: now,
        scheduledAt: null,
        sentAt: now,
        recipientCount: 0,
        scheduled: false,
      );

      await _service.sendBroadcast(notification);

      await load();

      return true;
    } catch (e) {
      errorMessage = 'Failed to send broadcast.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> scheduleBroadcast({
    required String title,
    required String message,
    required DateTime scheduledAt,
  }) async {
    if (title.trim().isEmpty || message.trim().isEmpty) {
      errorMessage = 'Please fill in both notification title and message.';
      notifyListeners();
      return false;
    }

    if (!scheduledAt.isAfter(DateTime.now())) {
      errorMessage = 'Please select a future date and time.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();

      final notification = NotificationModel(
        id: 'n${now.millisecondsSinceEpoch}',
        title: title.trim(),
        message: message.trim(),
        audience: NotificationAudience.allApp,
        createdAt: now,
        scheduledAt: scheduledAt,
        sentAt: null,
        recipientCount: 0,
        scheduled: true,
      );

      await _service.scheduleBroadcast(
        notification,
        scheduledAt,
      );

      await load();

      return true;
    } catch (e) {
      errorMessage = 'Failed to schedule notification.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void setError(String message) {
    errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _activitySubscription?.cancel();
    super.dispose();
  }
}

/// Riverpod provider wrapping [NotificationProvider].
final notificationProvider = ChangeNotifierProvider<NotificationProvider>(
  (ref) => NotificationProvider(NotificationService()),
);
