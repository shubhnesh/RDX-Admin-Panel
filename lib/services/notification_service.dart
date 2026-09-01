import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('notifications');

  Future<List<NotificationModel>> fetchHistory() async {
    final snap = await _col.orderBy('sent_at', descending: true).limit(50).get();
    return snap.docs.map((d) => NotificationModel.fromFirestore(d)).toList();
  }

  Future<void> sendBroadcast(NotificationModel notification) async {
    await _col.add(notification.toJson());
  }
}
