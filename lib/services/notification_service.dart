import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  Future<List<NotificationModel>> fetchHistory() async {
    final snap =
        await _col.orderBy('created_at', descending: true).limit(50).get();

    return snap.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .toList();
  }

  Future<void> sendBroadcast(
    NotificationModel notification,
  ) async {
    await _functions.httpsCallable('sendBroadcastNotification').call({
      'title': notification.title,
      'message': notification.message,
    });
  }

  Future<void> scheduleBroadcast(
    NotificationModel notification,
    DateTime scheduledAt,
  ) async {
    final data = notification.toJson();

    data['scheduled_at'] = Timestamp.fromDate(scheduledAt);
    data['scheduled'] = true;
    data['sent_at'] = null;
    data['delivery_status'] = 'scheduled';
    data['delivery_attempts'] = 0;
    data['source'] = 'admin';

    await _col.add(data);
  }
}
