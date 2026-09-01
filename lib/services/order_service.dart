import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/order_model.dart';

class OrderService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('orders');

  Future<List<OrderModel>> fetchLiveOrders() async {
    if (Firebase.apps.isEmpty) return [];
    final snap = await _col
        .where('status', whereIn: ['pending', 'preparing', 'ready'])
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs.map((d) => OrderModel.fromFirestore(d)).toList();
  }

  Stream<List<OrderModel>> streamLiveOrders() {
    if (Firebase.apps.isEmpty) return Stream.value([]);
    return _col
        .where('status', whereIn: ['pending', 'preparing', 'ready'])
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => OrderModel.fromFirestore(d)).toList());
  }

  Future<OrderModel> fetchOrderById(String id) async {
    if (Firebase.apps.isEmpty) throw Exception('Firebase is not configured.');
    final doc = await _col.doc(id).get();
    if (!doc.exists) throw Exception('Order not found');
    return OrderModel.fromFirestore(doc);
  }

  Future<void> updateOrderStatus(String id, OrderStatus status) async {
    if (Firebase.apps.isEmpty) return;
    await _col.doc(id).update({
      'status': status.name,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<List<OrderModel>> fetchRecentOrders({int limit = 50}) async {
    if (Firebase.apps.isEmpty) return [];
    final snap =
        await _col.orderBy('created_at', descending: true).limit(limit).get();
    return snap.docs.map((d) => OrderModel.fromFirestore(d)).toList();
  }
}
