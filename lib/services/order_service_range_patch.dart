/// ADD this method to your existing `OrderService` class in
/// `lib/services/order_service.dart`.
///
/// Required for revenue trend + multi-day charts. Without it the dashboard
/// still works using today's live-board orders as a fallback.
///
/// ```dart
/// /// Orders with created_at in [from, to).
/// /// Requires a Firestore composite index on `created_at` if you add
/// /// extra where clauses later.
/// Future<List<OrderModel>> fetchOrdersInRange({
///   required DateTime from,
///   required DateTime to,
/// }) async {
///   final snapshot = await _col
///       .where(
///         'created_at',
///         isGreaterThanOrEqualTo: Timestamp.fromDate(from),
///       )
///       .where(
///         'created_at',
///         isLessThan: Timestamp.fromDate(to),
///       )
///       .get();
///
///   final orders = snapshot.docs.map(OrderModel.fromFirestore).toList();
///   _sortNewestFirst(orders);
///   return orders;
/// }
/// ```
///
/// Full method ready to paste:

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

// --- Paste inside class OrderService { ... } ---

/*
  Future<List<OrderModel>> fetchOrdersInRange({
    required DateTime from,
    required DateTime to,
  }) async {
    final snapshot = await _col
        .where(
          'created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from),
        )
        .where(
          'created_at',
          isLessThan: Timestamp.fromDate(to),
        )
        .get();

    final orders = snapshot.docs.map(OrderModel.fromFirestore).toList();
    _sortNewestFirst(orders);
    return orders;
  }
*/
