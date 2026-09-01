import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;
  NotificationProvider(this._service);

  List<NotificationModel> history = [];
  bool isLoading = false;
  String? errorMessage;

  NotificationAudience audience = NotificationAudience.allApp;
  bool sendImmediately = true;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      history = await _service.fetchHistory();
    } catch (e) {
      errorMessage = 'Failed to load notifications.';
    }
    isLoading = false;
    notifyListeners();
  }

  void setAudience(NotificationAudience a) {
    audience = a;
    notifyListeners();
  }

  void setSendImmediately(bool value) {
    sendImmediately = value;
    notifyListeners();
  }

  Future<bool> sendBroadcast({required String title, required String message}) async {
    if (title.trim().isEmpty || message.trim().isEmpty) {
      errorMessage = 'Please fill in both subject and message.';
      notifyListeners();
      return false;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final notification = NotificationModel(
        id: 'n${DateTime.now().millisecondsSinceEpoch}',
        title: title.trim(),
        message: message.trim(),
        audience: audience,
        sentAt: DateTime.now(),
        recipientCount: 0,
        scheduled: !sendImmediately,
      );
      await _service.sendBroadcast(notification);
      await load();
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Failed to send broadcast.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
