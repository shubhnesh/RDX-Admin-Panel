// import 'package:cloud_firestore/cloud_firestore.dart';

// import '../models/order_model.dart';

// /// Handles reading and writing orders to Firestore.
// ///
// /// NOTE: this file was reconstructed to add order-placement + real-time
// /// streaming support. `fetchLiveOrders` and `updateOrderStatus` keep the
// /// exact signatures your existing [LiveOrdersProvider] (provider package)
// /// already calls, so nothing there breaks. If your real order_service.dart
// /// has additional logic, merge it in rather than overwriting wholesale.
// class OrderService {
//   OrderService({FirebaseFirestore? firestore})
//       : _db = firestore ?? FirebaseFirestore.instance;

//   final FirebaseFirestore _db;

//   CollectionReference<Map<String, dynamic>> get _col =>
//       _db.collection('orders');

//   static const _liveStatuses = [
//     OrderStatus.pending,
//     OrderStatus.preparing,
//     OrderStatus.ready,
//   ];

//   static const _historyStatuses = [
//     OrderStatus.delivered,
//     OrderStatus.cancelled,
//   ];

//   /// One-off fetch of every order currently in the live pipeline
//   /// (pending/preparing/ready), oldest first — kept for any existing
//   /// call sites using the ChangeNotifier-based LiveOrdersProvider.
//   Future<List<OrderModel>> fetchLiveOrders() async {
//     final snapshot = await _col
//         .where('status', whereIn: _liveStatuses.map((s) => s.name).toList())
//         .orderBy('created_at')
//         .get();
//     return snapshot.docs.map(OrderModel.fromFirestore).toList();
//   }

//   /// Real-time stream of live orders, oldest first (kitchen-queue order).
//   /// Powers the interactive Live Orders board.
//   Stream<List<OrderModel>> streamLiveOrders() {
//     return _col
//         .where('status', whereIn: _liveStatuses.map((s) => s.name).toList())
//         .orderBy('created_at')
//         .snapshots()
//         .map(
//             (snapshot) => snapshot.docs.map(OrderModel.fromFirestore).toList());
//   }

//   /// Real-time stream of completed/cancelled orders, most recent first —
//   /// for an optional "History" view.
//   Stream<List<OrderModel>> streamOrderHistory({int limit = 50}) {
//     return _col
//         .where('status', whereIn: _historyStatuses.map((s) => s.name).toList())
//         .orderBy('created_at', descending: true)
//         .limit(limit)
//         .snapshots()
//         .map(
//             (snapshot) => snapshot.docs.map(OrderModel.fromFirestore).toList());
//   }

//   /// Creates a new order (e.g. from the Place Order / checkout flow) and
//   /// returns the generated Firestore document ID.
//   Future<String> createOrder(OrderModel order) async {
//     final doc = _col.doc();
//     final data = order.toJson();
//     data['created_at'] = FieldValue.serverTimestamp();
//     await doc.set(data);
//     return doc.id;
//   }

//   /// Fetches one order by its Firestore document ID.
//   Future<OrderModel?> fetchOrderById(String id) async {
//     if (id.trim().isEmpty) return null;

//     final snapshot = await _col.doc(id).get();
//     if (!snapshot.exists) return null;
//     return OrderModel.fromFirestore(snapshot);
//   }

//   Future<void> updateOrderStatus(String id, OrderStatus status) async {
//     if (id.trim().isEmpty) {
//       throw ArgumentError('Cannot update status without an order ID.');
//     }
//     await _col.doc(id).update({
//       'status': status.name,
//       'updated_at': FieldValue.serverTimestamp(),
//     });
//   }
// }

// import 'package:cloud_firestore/cloud_firestore.dart';

// import '../models/order_model.dart';

// class OrderService {
//   OrderService({FirebaseFirestore? firestore})
//       : _db = firestore ?? FirebaseFirestore.instance;

//   final FirebaseFirestore _db;

//   CollectionReference<Map<String, dynamic>> get _col =>
//       _db.collection('orders');

//   static const _liveStatuses = [
//     OrderStatus.pending,
//     OrderStatus.preparing,
//     OrderStatus.ready,
//   ];

//   static const _historyStatuses = [
//     OrderStatus.delivered,
//     OrderStatus.cancelled,
//   ];

//   Future<List<OrderModel>> fetchLiveOrders() async {
//     final snapshot = await _col
//         .where(
//           'status',
//           whereIn: _liveStatuses.map((status) => status.name).toList(),
//         )
//         .orderBy('created_at')
//         .get();

//     return snapshot.docs.map(OrderModel.fromFirestore).toList();
//   }

//   Stream<List<OrderModel>> streamLiveOrders() {
//     return _col
//         .where(
//           'status',
//           whereIn: _liveStatuses.map((status) => status.name).toList(),
//         )
//         .orderBy('created_at')
//         .snapshots()
//         .map(
//           (snapshot) => snapshot.docs.map(OrderModel.fromFirestore).toList(),
//         );
//   }

//   Stream<List<OrderModel>> streamOrderHistory({
//     int limit = 50,
//   }) {
//     return _col
//         .where(
//           'status',
//           whereIn: _historyStatuses.map((status) => status.name).toList(),
//         )
//         .orderBy('created_at', descending: true)
//         .limit(limit)
//         .snapshots()
//         .map(
//           (snapshot) => snapshot.docs.map(OrderModel.fromFirestore).toList(),
//         );
//   }

//   Future<String> createOrder(OrderModel order) async {
//     final doc = _col.doc();

//     final data = order.toJson();

//     data['created_at'] = FieldValue.serverTimestamp();

//     await doc.set(data);

//     return doc.id;
//   }

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

    _sortByCreatedAt(orders);

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

      _sortByCreatedAt(orders);

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

      orders.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      return orders;
    });
  }

  // ---------------------------------------------------------------------------
  // CREATE ORDER
  // ---------------------------------------------------------------------------

  Future<String> createOrder(OrderModel order) async {
    final doc = _col.doc();

    final data = order.toJson();

    data['created_at'] = FieldValue.serverTimestamp();

    await doc.set(data);

    return doc.id;
  }

  // ---------------------------------------------------------------------------
  // FETCH SINGLE ORDER
  // ---------------------------------------------------------------------------

  Future<OrderModel?> fetchOrderById(String id) async {
    if (id.trim().isEmpty) {
      return null;
    }

    final snapshot = await _col.doc(id).get();

    if (!snapshot.exists) {
      return null;
    }

    return OrderModel.fromFirestore(snapshot);
  }

  // ---------------------------------------------------------------------------
  // UPDATE STATUS
  // ---------------------------------------------------------------------------

  Future<void> updateOrderStatus(
    String id,
    OrderStatus status,
  ) async {
    if (id.trim().isEmpty) {
      throw ArgumentError(
        'Cannot update status without an order ID.',
      );
    }

    await _col.doc(id).update({
      'status': status.name,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // SETTLE ORDER
  // ---------------------------------------------------------------------------

  Future<void> settleOrder({
    required String orderId,
    required PaymentMethod paymentMethod,
  }) async {
    if (orderId.trim().isEmpty) {
      throw ArgumentError(
        'Cannot settle an order without an order ID.',
      );
    }

    await _col.doc(orderId).update({
      'payment_method': paymentMethod.name,
      'payment_status': PaymentStatus.paid.name,
      'status': OrderStatus.delivered.name,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // SORTING
  // ---------------------------------------------------------------------------

  void _sortByCreatedAt(List<OrderModel> orders) {
    orders.sort(
      (a, b) => a.createdAt.compareTo(b.createdAt),
    );
  }
}
