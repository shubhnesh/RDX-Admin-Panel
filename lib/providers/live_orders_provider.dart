import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';

class LiveOrdersProvider extends ChangeNotifier {
  final OrderService _service;
  LiveOrdersProvider(this._service);

  List<OrderModel> _orders = [];
  bool isLoading = false;
  String? errorMessage;

  void _log(String message) {
    if (kDebugMode) debugPrint('[LiveOrdersProvider] $message');
  }

  List<OrderModel> get pending =>
      _orders.where((o) => o.status == OrderStatus.pending).toList();

  /// Same as [pending] — UI labels this column "Live Orders".
  /// Prefer [liveWalkIn] for the walk-in board column.
  List<OrderModel> get live => pending;
  List<OrderModel> get preparing =>
      _orders.where((o) => o.status == OrderStatus.preparing).toList();
  List<OrderModel> get ready =>
      _orders.where((o) => o.status == OrderStatus.ready).toList();
  List<OrderModel> get delivered =>
      _orders.where((o) => o.status == OrderStatus.delivered).toList();

  /// Orders placed by customers through the app (not staff POS).
  List<OrderModel> get appOrders =>
      _orders.where((o) => o.orderSource == OrderSource.app).toList();

  /// Staff / restaurant POS (walk-in) orders only — Create Order screen.
  List<OrderModel> get staffOrders =>
      _orders.where((o) => o.orderSource == OrderSource.staff).toList();

  // ── Walk-in (staff POS) by status ──────────────────────────────────────
  List<OrderModel> get liveWalkIn =>
      pending.where((o) => o.orderSource == OrderSource.staff).toList();
  List<OrderModel> get preparingWalkIn =>
      preparing.where((o) => o.orderSource == OrderSource.staff).toList();
  List<OrderModel> get readyWalkIn =>
      ready.where((o) => o.orderSource == OrderSource.staff).toList();
  List<OrderModel> get deliveredWalkIn =>
      delivered.where((o) => o.orderSource == OrderSource.staff).toList();

  // ── App (customer) by status ───────────────────────────────────────────
  /// Active app orders on the board (pending / preparing / ready).
  List<OrderModel> get appOrdersActive => appOrders
      .where(
        (o) =>
            o.status == OrderStatus.pending ||
            o.status == OrderStatus.preparing ||
            o.status == OrderStatus.ready,
      )
      .toList();
  List<OrderModel> get liveApp =>
      pending.where((o) => o.orderSource == OrderSource.app).toList();
  List<OrderModel> get preparingApp =>
      preparing.where((o) => o.orderSource == OrderSource.app).toList();
  List<OrderModel> get readyApp =>
      ready.where((o) => o.orderSource == OrderSource.app).toList();
  List<OrderModel> get deliveredApp =>
      delivered.where((o) => o.orderSource == OrderSource.app).toList();

  List<OrderModel> get cancelled =>
      _orders.where((o) => o.status == OrderStatus.cancelled).toList();
  List<OrderModel> get cancelledWalkIn =>
      cancelled.where((o) => o.orderSource == OrderSource.staff).toList();
  List<OrderModel> get cancelledApp =>
      cancelled.where((o) => o.orderSource == OrderSource.app).toList();

  Future<void> load() async {
    _log('Order list refresh started.');
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      _orders = await _service.fetchLiveOrders();
      _log('Order list refresh completed (${_orders.length} orders).');
    } catch (error) {
      _log('Order list refresh failed (${error.runtimeType}): $error');
      errorMessage = 'Failed to load live orders.';
    }
    isLoading = false;
    notifyListeners();
  }

  /// Marks the order as cancelled. Order is kept (not deleted) for history.
  Future<void> cancelOrder(OrderModel order) async {
    if (order.status == OrderStatus.cancelled) return;
    await _service.updateOrderStatus(
      orderId: order.id,
      newStatus: OrderStatus.cancelled,
    );
    await load();
  }

  Future<void> advanceStatus(OrderModel order) async {
    final next = order.status.nextStatus;
    if (next == null) {
      throw StateError('Order ${order.id} has no next status.');
    }
    if (next == OrderStatus.delivered && !order.isPaid) {
      throw StateError('Payment must be completed before delivering this order.');
    }
    _log(
      'Status advance requested (order: ${order.id}, '
      '${order.status.name} -> ${next.name}).',
    );
    try {
      await _service.updateOrderStatus(orderId: order.id, newStatus: next);
      _log('Status update accepted by service (order: ${order.id}).');
      await load();
    } catch (error) {
      _log(
        'Status advance failed (order: ${order.id}, '
        '${order.status.name} -> ${next.name}, '
        '${error.runtimeType}): $error',
      );
      rethrow;
    }
  }
}

/// Riverpod binding for [LiveOrdersProvider].
final liveOrdersProvider = ChangeNotifierProvider<LiveOrdersProvider>(
  (ref) => LiveOrdersProvider(OrderService()),
);
