import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/order_model.dart';

/// Complete Admin OrderService.
///
/// • createStaffOrder / settleOrder  → Cloud Functions (secure)
/// • All previous methods kept so existing screens continue to compile
class OrderService {
  OrderService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  void _log(String message) {
    if (kDebugMode) debugPrint('[OrderService] $message');
  }

  CollectionReference<Map<String, dynamic>> get _ordersCol =>
      _db.collection('orders');

  // ===========================================================================
  // CLOUD FUNCTIONS (new secure path)
  // ===========================================================================

  /// Creates a walk-in / POS order via Cloud Function.
  /// Client must never send prices / totals / taxes — the server calculates them.
  Future<OrderModel> createStaffOrder({
    required List<Map<String, dynamic>> items,
    required String orderType, // 'dineIn' | 'takeaway' | 'delivery'
    String? tableNumber,
    String customerName = 'Walk-in',
    String customerPhone = '',
    String? deliveryAddress,
    String? couponCode,
    String? paymentMethod, // cash | upi | card
    String? notes,
    bool applyLongDistanceFee = false,
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('You must be signed in to create a staff order.');
    }
    if (items.isEmpty) {
      throw Exception('Order must contain at least one item.');
    }

    final cleanItems = items.map((item) {
      final productId =
          (item['product_id'] ?? item['menu_item_id'] ?? '').toString().trim();
      if (productId.isEmpty) {
        throw ArgumentError('Every item must have a product_id');
      }
      return {
        'product_id': productId,
        'quantity': item['quantity'],
        'size': item['size'] ?? item['selected_size'],
        'notes': item['notes'],
        'spice_level': item['spice_level'] ?? item['spiceLevel'],
        'add_ons': item['add_ons'] ?? item['addOns'],
      };
    }).toList();

    try {
      final result = await _functions.httpsCallable('createStaffOrder').call({
        'items': cleanItems,
        'order_type': orderType,
        'table_number': tableNumber,
        'customer_name':
            customerName.trim().isEmpty ? 'Walk-in' : customerName.trim(),
        'customer_phone': customerPhone.trim(),
        'delivery_address': deliveryAddress?.trim() ?? '',
        'coupon_code': couponCode?.trim(),
        'payment_method': paymentMethod?.toLowerCase().trim(),
        'notes': notes?.trim(),
        'apply_long_distance_fee': applyLongDistanceFee,
      });

      final data = result.data;
      if (data is! Map) {
        throw StateError('createStaffOrder returned invalid response');
      }
      return OrderModel.fromJson(Map<String, dynamic>.from(data));
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to create staff order');
    } catch (e) {
      throw Exception('Failed to create staff order: $e');
    }
  }

  /// Marks an order as paid (cash / upi / card) via Cloud Function.
  Future<OrderModel> settleOrder({
    required String orderId,
    required String paymentMethod, // cash | upi | card
    String? notes,
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('You must be signed in to settle an order.');
    }

    final method = paymentMethod.toLowerCase().trim();
    if (!['cash', 'upi', 'card'].contains(method)) {
      throw Exception('Payment method must be cash, upi or card');
    }

    try {
      final result = await _functions.httpsCallable('settleOrder').call({
        'order_id': orderId.trim(),
        'payment_method': method,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      });

      final data = result.data;
      if (data is! Map) {
        throw StateError('settleOrder returned invalid response');
      }
      return OrderModel.fromJson(Map<String, dynamic>.from(data));
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to settle order');
    } catch (e) {
      throw Exception('Failed to settle order: $e');
    }
  }

  // ===========================================================================
  // LEGACY / EXISTING METHODS (kept for compatibility)
  // ===========================================================================

  /// Fetch orders between two dates (inclusive).
  /// Used by dashboard / reports.
  Future<List<OrderModel>> fetchOrdersInRange(
    DateTime start,
    DateTime end, {
    OrderSource? source,
  }) async {
    Query<Map<String, dynamic>> query = _ordersCol
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(end));

    if (source != null) {
      query = query.where('order_source', isEqualTo: source.name);
    }

    try {
      final snap = await query.orderBy('created_at', descending: true).get();
      return snap.docs.map(OrderModel.fromFirestore).toList();
    } on FirebaseException catch (e) {
      // Fallback if composite index is missing
      if (e.code == 'failed-precondition') {
        final snap = await _ordersCol
            .where('created_at',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(end))
            .get();
        final list = snap.docs.map(OrderModel.fromFirestore).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (source != null) {
          return list.where((o) => o.orderSource == source).toList();
        }
        return list;
      }
      rethrow;
    }
  }

  /// Fetches active and completed orders used by the live-order board.
  Future<List<OrderModel>> fetchLiveOrders({OrderSource? source}) async {
    const boardStatuses = [
      'pending',
      'preparing',
      'ready',
      'delivered',
      'served',
      'cancelled',
    ];
    Query<Map<String, dynamic>> query =
        _ordersCol.where('status', whereIn: boardStatuses);

    if (source != null) {
      query = query.where('order_source', isEqualTo: source.name);
    }

    try {
      final snap = await query.orderBy('created_at', descending: true).get();
      return snap.docs.map(OrderModel.fromFirestore).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        final snap = await _ordersCol
            .where('status', whereIn: boardStatuses)
            .get();
        final list = snap.docs.map(OrderModel.fromFirestore).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (source != null) {
          return list.where((o) => o.orderSource == source).toList();
        }
        return list;
      }
      rethrow;
    }
  }

  /// Real-time stream of live orders.
  Stream<List<OrderModel>> watchLiveOrders({OrderSource? source}) {
    Query<Map<String, dynamic>> query = _ordersCol.where(
      'status',
      whereIn: [
        'pending',
        'preparing',
        'ready',
        'delivered',
        'served',
        'cancelled',
      ],
    );

    if (source != null) {
      query = query.where('order_source', isEqualTo: source.name);
    }

    return query.snapshots().map((snap) {
      final list = snap.docs.map(OrderModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Real-time stream of all recent orders (history).
  Stream<List<OrderModel>> watchAllOrders({int limit = 100}) {
    return _ordersCol
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(OrderModel.fromFirestore).toList());
  }

  Future<OrderModel?> fetchOrderById(String id) async {
    final doc = await _ordersCol.doc(id).get();
    if (!doc.exists) return null;
    return OrderModel.fromFirestore(doc);
  }

  // ---------------------------------------------------------------------------
  // Status updates (Cloud Function — no direct Firestore writes)
  // ---------------------------------------------------------------------------

  /// Advances or cancels an order via the secure `updateOrderStatus` function.
  ///
  /// Allowed transitions (enforced server-side):
  /// - pending → preparing | cancelled
  /// - preparing → ready | cancelled
  /// - ready → delivered | cancelled
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? reason,
  }) async {
    _log(
      'updateOrderStatus started (order: ${orderId.trim()}, '
      'target status: ${newStatus.name}).',
    );
    if (_auth.currentUser == null) {
      _log('updateOrderStatus stopped: no signed-in user.');
      throw Exception('You must be signed in to update order status.');
    }
    if (orderId.trim().isEmpty) {
      _log('updateOrderStatus stopped: order ID is empty.');
      throw Exception('orderId is required.');
    }

    try {
      final response =
          await _functions.httpsCallable('updateOrderStatus').call({
        'order_id': orderId.trim(),
        'new_status': newStatus.name,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });
      _log(
        'updateOrderStatus callable completed (order: ${orderId.trim()}, '
        'response: ${response.data is Map ? 'received' : 'unexpected'}).',
      );
    } on FirebaseFunctionsException catch (e) {
      _log(
        'updateOrderStatus callable failed '
        '(order: ${orderId.trim()}, code: ${e.code}, message: ${e.message}, '
        'details: ${e.details}).',
      );
      rethrow;
    } catch (e) {
      _log(
        'updateOrderStatus failed unexpectedly '
        '(order: ${orderId.trim()}, ${e.runtimeType}): $e',
      );
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Convenience overload used by some screens that pass positional args.
  Future<void> updateOrderStatusPositional(
    String orderId,
    OrderStatus newStatus, [
    String? reason,
  ]) {
    return updateOrderStatus(
      orderId: orderId,
      newStatus: newStatus,
      reason: reason,
    );
  }

  /// Cancels an order (same CF, status = cancelled).
  Future<void> cancelOrder(
    String orderId, {
    String? reason,
  }) async {
    return updateOrderStatus(
      orderId: orderId,
      newStatus: OrderStatus.cancelled,
      reason: reason,
    );
  }

  // ---------------------------------------------------------------------------
  // Payment status (legacy → now redirects to settleOrder when possible)
  // ---------------------------------------------------------------------------

  /// Prefer [settleOrder] for marking paid.
  ///
  /// Only the paid + valid payment-method path is supported (via Cloud Function).
  /// Any other use throws — direct Firestore payment updates are blocked.
  Future<void> updatePaymentStatus({
    required String orderId,
    required PaymentStatus status,
    String? paymentMethod,
  }) async {
    if (status == PaymentStatus.paid &&
        paymentMethod != null &&
        ['cash', 'upi', 'card'].contains(paymentMethod.toLowerCase().trim())) {
      await settleOrder(
        orderId: orderId,
        paymentMethod: paymentMethod,
      );
      return;
    }

    throw Exception(
      'Direct payment updates are blocked. '
      'Use settleOrder(orderId, paymentMethod: cash|upi|card) to mark paid.',
    );
  }

  /// Overload that accepts positional arguments (some old call sites use this).
  Future<void> updatePaymentStatusPositional(
    String orderId,
    PaymentStatus status, [
    String? paymentMethod,
  ]) {
    return updatePaymentStatus(
      orderId: orderId,
      status: status,
      paymentMethod: paymentMethod,
    );
  }

  // ===========================================================================
  // LEGACY createOrder — DISABLED (no direct Firestore writes)
  // ===========================================================================

  /// Old direct-write create path. **Do not use.**
  ///
  /// Always throws. Use [createStaffOrder] with product ids instead.
  @Deprecated('Use createStaffOrder — direct order writes are blocked')
  Future<String> createOrder(OrderModel order) async {
    throw Exception(
      'createOrder is disabled. '
      'Use createStaffOrder(items: [{product_id, quantity, ...}], orderType: ...).',
    );
  }
}
