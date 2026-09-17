// import 'package:cloud_firestore/cloud_firestore.dart';

// import '../models/order_model.dart';

// class OrderService {
//   OrderService({
//     FirebaseFirestore? firestore,
//   }) : _db = firestore ?? FirebaseFirestore.instance;

//   final FirebaseFirestore _db;

//   CollectionReference<Map<String, dynamic>> get _col {
//     return _db.collection('orders');
//   }

//   static const _liveStatuses = [
//     OrderStatus.pending,
//     OrderStatus.preparing,
//     OrderStatus.ready,
//   ];

//   static const _historyStatuses = [
//     OrderStatus.delivered,
//     OrderStatus.cancelled,
//   ];

//   // ---------------------------------------------------------------------------
//   // LIVE ORDERS
//   // ---------------------------------------------------------------------------

//   Future<List<OrderModel>> fetchLiveOrders() async {
//     final snapshot = await _col
//         .where(
//           'status',
//           whereIn: _liveStatuses.map((status) => status.name).toList(),
//         )
//         .get();

//     final orders = snapshot.docs.map(OrderModel.fromFirestore).toList();

//     _sortByCreatedAt(orders);

//     return orders;
//   }

//   Stream<List<OrderModel>> streamLiveOrders() {
//     return _col
//         .where(
//           'status',
//           whereIn: _liveStatuses.map((status) => status.name).toList(),
//         )
//         .snapshots()
//         .map((snapshot) {
//       final orders = snapshot.docs.map(OrderModel.fromFirestore).toList();

//       _sortByCreatedAt(orders);

//       return orders;
//     });
//   }

//   // ---------------------------------------------------------------------------
//   // ORDER HISTORY
//   // ---------------------------------------------------------------------------

//   Stream<List<OrderModel>> streamOrderHistory({
//     int limit = 50,
//   }) {
//     return _col
//         .where(
//           'status',
//           whereIn: _historyStatuses.map((status) => status.name).toList(),
//         )
//         .limit(limit)
//         .snapshots()
//         .map((snapshot) {
//       final orders = snapshot.docs.map(OrderModel.fromFirestore).toList();

//       orders.sort(
//         (a, b) => b.createdAt.compareTo(a.createdAt),
//       );

//       return orders;
//     });
//   }

//   // ---------------------------------------------------------------------------
//   // CREATE ORDER
//   // ---------------------------------------------------------------------------

//   Future<String> createOrder(OrderModel order) async {
//     final doc = _col.doc();

//     final data = order.toJson();

//     data['created_at'] = FieldValue.serverTimestamp();

//     await doc.set(data);

//     return doc.id;
//   }

//   // ---------------------------------------------------------------------------
//   // FETCH SINGLE ORDER
//   // ---------------------------------------------------------------------------

//   Future<OrderModel?> fetchOrderById(String id) async {
//     if (id.trim().isEmpty) {
//       return null;
//     }

//     final snapshot = await _col.doc(id).get();

//     if (!snapshot.exists) {
//       return null;
//     }

//     return OrderModel.fromFirestore(snapshot);
//   }

//   // ---------------------------------------------------------------------------
//   // UPDATE STATUS
//   // ---------------------------------------------------------------------------

//   Future<void> updateOrderStatus(
//     String id,
//     OrderStatus status,
//   ) async {
//     if (id.trim().isEmpty) {
//       throw ArgumentError(
//         'Cannot update status without an order ID.',
//       );
//     }

//     await _col.doc(id).update({
//       'status': status.name,
//       'updated_at': FieldValue.serverTimestamp(),
//     });
//   }

//   // ---------------------------------------------------------------------------
//   // SETTLE ORDER
//   // ---------------------------------------------------------------------------

//   Future<void> settleOrder({
//     required String orderId,
//     required PaymentMethod paymentMethod,
//   }) async {
//     if (orderId.trim().isEmpty) {
//       throw ArgumentError(
//         'Cannot settle an order without an order ID.',
//       );
//     }

//     await _col.doc(orderId).update({
//       'payment_method': paymentMethod.name,
//       'payment_status': PaymentStatus.paid.name,
//       'status': OrderStatus.delivered.name,
//       'updated_at': FieldValue.serverTimestamp(),
//     });
//   }

//   // ---------------------------------------------------------------------------
//   // SORTING
//   // ---------------------------------------------------------------------------

//   void _sortByCreatedAt(List<OrderModel> orders) {
//     orders.sort(
//       (a, b) => a.createdAt.compareTo(b.createdAt),
//     );
//   }
// }

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

  // ---------------------------------------------------------------------------
  // STATUS GROUPS
  // ---------------------------------------------------------------------------

  static const _liveStatuses = [
    OrderStatus.pending,
    OrderStatus.preparing,
    OrderStatus.ready,
  ];

  static const _historyStatuses = [
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  // ---------------------------------------------------------------------------
  // LIVE ORDERS
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // ORDER HISTORY
  // ---------------------------------------------------------------------------

  Stream<List<OrderModel>> streamOrderHistory({
    int limit = 50,
  }) {
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

  // ---------------------------------------------------------------------------
  // CREATE ORDER
  // ---------------------------------------------------------------------------

  Future<String> createOrder(OrderModel order) async {
    final doc = _col.doc();

    final data = order.toJson();

    // The server must be the source of truth for creation time.
    data['created_at'] = FieldValue.serverTimestamp();

    // New orders are unpaid unless the caller explicitly supplied
    // another payment status.
    data.putIfAbsent(
      'payment_status',
      () => PaymentStatus.unpaid.name,
    );

    // Payment method should remain null until payment is actually made.
    //
    // Do not do:
    // data['payment_method'] = PaymentMethod.cash.name;
    //
    // because that would make an unpaid order appear paid.

    await doc.set(data);

    return doc.id;
  }

  // ---------------------------------------------------------------------------
  // FETCH SINGLE ORDER
  // ---------------------------------------------------------------------------

  Future<OrderModel?> fetchOrderById(String id) async {
    final orderId = id.trim();

    if (orderId.isEmpty) {
      return null;
    }

    final snapshot = await _col.doc(orderId).get();

    if (!snapshot.exists) {
      return null;
    }

    return OrderModel.fromFirestore(snapshot);
  }

  // ---------------------------------------------------------------------------
  // UPDATE ORDER STATUS
  // ---------------------------------------------------------------------------

  Future<void> updateOrderStatus(
    String id,
    OrderStatus status,
  ) async {
    final orderId = id.trim();

    if (orderId.isEmpty) {
      throw ArgumentError(
        'Cannot update status without an order ID.',
      );
    }

    await _col.doc(orderId).update({
      'status': status.name,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // SETTLE / MAKE PAYMENT
  // ---------------------------------------------------------------------------
  //
  // IMPORTANT:
  // Payment lifecycle is independent from order lifecycle.
  //
  // Example:
  //
  // Order:
  //   pending + unpaid
  //
  // After payment:
  //   pending + paid
  //
  // The order does NOT automatically become delivered.
  //
  // The admin can separately move the order through:
  //
  // pending -> preparing -> ready -> delivered
  //
  // ---------------------------------------------------------------------------

  // Future<void> settleOrder({
  //   required String orderId,
  //   required PaymentMethod paymentMethod,
  // }) async {
  //   final id = orderId.trim();

  //   if (id.isEmpty) {
  //     throw ArgumentError(
  //       'Cannot settle an order without an order ID.',
  //     );
  //   }

  //   await _col.doc(id).update({
  //     'payment_method': paymentMethod.name,
  //     'payment_status': PaymentStatus.paid.name,
  //     'updated_at': FieldValue.serverTimestamp(),
  //   });
  // }

  // ---------------------------------------------------------------------------
  // MARK PAYMENT AS UNPAID
  // ---------------------------------------------------------------------------
  //
  // Useful if you ever need to reverse a payment state from admin.
  //
  Future<void> markPaymentUnpaid(String orderId) async {
    final id = orderId.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'Cannot update payment without an order ID.',
      );
    }

    await _col.doc(id).update({
      'payment_status': PaymentStatus.unpaid.name,
      'payment_method': FieldValue.delete(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // MARK PAYMENT PAID
  // ---------------------------------------------------------------------------
  //
  // This is an explicit alternative to settleOrder if you already
  // have the payment method selected elsewhere.
  //
  // Future<void> updatePaymentStatus({
  //   required String orderId,
  //   required PaymentStatus status,
  //   PaymentMethod? paymentMethod,
  // }) async {
  //   final id = orderId.trim();

  //   if (id.isEmpty) {
  //     throw ArgumentError(
  //       'Cannot update payment without an order ID.',
  //     );
  //   }

  //   final data = <String, dynamic>{
  //     'payment_status': status.name,
  //     'updated_at': FieldValue.serverTimestamp(),
  //   };

  //   if (status == PaymentStatus.paid && paymentMethod != null) {
  //     data['payment_method'] = paymentMethod.name;
  //   }

  //   if (status == PaymentStatus.unpaid) {
  //     data['payment_method'] = FieldValue.delete();
  //   }

  //   await _col.doc(id).update(data);
  // }

  Future<void> updatePaymentStatus({
    required String orderId,
    required PaymentMethod paymentMethod,
  }) async {
    final id = orderId.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'Cannot update payment without an order ID.',
      );
    }

    await _col.doc(id).update({
      'payment_method': paymentMethod.name,
      'payment_status': PaymentStatus.paid.name,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // SORTING
  // ---------------------------------------------------------------------------

  void _sortNewestFirst(List<OrderModel> orders) {
    orders.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );
  }
}
