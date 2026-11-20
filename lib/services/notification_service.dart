import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  Future<List<NotificationModel>> fetchHistory() async {
    final snap =
        await _col.orderBy('created_at', descending: true).limit(50).get();

    return snap.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .where((notification) => notification.shouldShowInAdminHistory)
        .toList();
  }

  Stream<List<NotificationModel>> watchAdminActivity() {
    return _adminActivityQuery().snapshots().map(_latestActivity);
  }

  Future<List<NotificationModel>> fetchAdminActivity() async {
    final snapshot = await _adminActivityQuery().get();
    return _latestActivity(snapshot);
  }

  List<NotificationModel> _latestActivity(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final notifications = snapshot.docs
        .map(NotificationModel.fromFirestore)
        .toList(growable: false);
    final sorted = notifications.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(50).toList(growable: false);
  }

  Query<Map<String, dynamic>> _adminActivityQuery() {
    return _col.where('audience', isEqualTo: 'admin');
  }

  Future<void> markActivityRead(String notificationId, String uid) async {
    await _col.doc(notificationId).update({
      'read_by': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> markAllActivityRead(
    Iterable<String> notificationIds,
    String uid,
  ) async {
    final batch = _db.batch();
    for (final notificationId in notificationIds) {
      batch.update(_col.doc(notificationId), {
        'read_by': FieldValue.arrayUnion([uid]),
      });
    }
    await batch.commit();
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
