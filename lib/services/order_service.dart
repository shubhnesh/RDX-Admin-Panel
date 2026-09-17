import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_model.dart';

class OrderService {
  OrderService({
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col {
    return _db.collection('orders');
  }

  static const _liveStatuses = [
    OrderStatus.pending,
    OrderStatus.preparing,
    OrderStatus.ready,
  ];

  static const _historyStatuses = [
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  Future<List<OrderModel>> fetchLiveOrders() async {
    final snapshot = await _col
        .where(
          'status',
          whereIn: _liveStatuses.map((status) => status.name).toList(),
        )
        .get();

    final orders = snapshot.docs.map(OrderModel.fromFirestore).toList();
    _sortNewestFirst(orders);
    return orders;
  }

  Stream<List<OrderModel>> streamLiveOrders() {
    return _col
        .where(
          'status',
          whereIn: _liveStatuses.map((status) => status.name).toList(),
        )
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map(OrderModel.fromFirestore).toList();
      _sortNewestFirst(orders);
      return orders;
    });
  }

  Stream<List<OrderModel>> streamOrderHistory({int limit = 50}) {
    return _col
        .where(
          'status',
          whereIn: _historyStatuses.map((status) => status.name).toList(),
        )
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map(OrderModel.fromFirestore).toList();
      _sortNewestFirst(orders);
      return orders;
    });
  }

  Future<String> createOrder(OrderModel order) async {
    final doc = _col.doc();
    final data = order.toJson();

    // The server must be the source of truth for creation time.
    data['created_at'] = FieldValue.serverTimestamp();

    // New orders are unpaid unless the caller explicitly supplied
    // another payment status.
    data.putIfAbsent('payment_status', () => PaymentStatus.unpaid.name);

    await doc.set(data);
    return doc.id;
  }

  Future<OrderModel?> fetchOrderById(String id) async {
    final orderId = id.trim();
    if (orderId.isEmpty) return null;

    final snapshot = await _col.doc(orderId).get();
    if (!snapshot.exists) return null;

    return OrderModel.fromFirestore(snapshot);
  }

  Future<void> updateOrderStatus(String id, OrderStatus status) async {
    final orderId = id.trim();
    if (orderId.isEmpty) {
      throw ArgumentError('Cannot update status without an order ID.');
    }

    await _col.doc(orderId).update({
      'status': status.name,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Payment lifecycle is independent from order lifecycle. Paying an
  /// order does NOT automatically advance its delivery status.
  Future<void> markPaymentUnpaid(String orderId) async {
    final id = orderId.trim();
    if (id.isEmpty) {
      throw ArgumentError('Cannot update payment without an order ID.');
    }

    await _col.doc(id).update({
      'payment_status': PaymentStatus.unpaid.name,
      'payment_method': FieldValue.delete(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePaymentStatus({
    required String orderId,
    required PaymentMethod paymentMethod,
  }) async {
    final id = orderId.trim();
    if (id.isEmpty) {
      throw ArgumentError('Cannot update payment without an order ID.');
    }

    await _col.doc(id).update({
      'payment_method': paymentMethod.name,
      'payment_status': PaymentStatus.paid.name,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  void _sortNewestFirst(List<OrderModel> orders) {
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
