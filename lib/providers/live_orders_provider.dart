import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';

class LiveOrdersProvider extends ChangeNotifier {
  final OrderService _service;
  LiveOrdersProvider(this._service);

  List<OrderModel> _orders = [];
  final Map<String, _CachedOrderList> _orderLists = {};
  bool isLoading = false;
  String? errorMessage;
  bool _hasLoaded = false;

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

  List<OrderModel> ordersFor({
    required List<OrderStatus> statuses,
    required OrderSource source,
    PaymentStatus? paymentStatus,
  }) {
    final statusNames = statuses.map((status) => status.name).toList()..sort();
    final key =
        '${source.name}:${statusNames.join(",")}:${paymentStatus?.name ?? "*"}';
    return _orderLists
        .putIfAbsent(
          key,
          () => _CachedOrderList(
            statuses: statuses.toSet(),
            source: source,
            paymentStatus: paymentStatus,
            orders: List.unmodifiable(
              _orders.where(
                (order) =>
                    statuses.contains(order.status) &&
                    order.orderSource == source &&
                    (paymentStatus == null ||
                        order.paymentStatus == paymentStatus),
              ),
            ),
          ),
        )
        .orders;
  }

  ({
    int totalOrders,
    int liveCount,
    int appCount,
    int pendingPaymentCount,
  }) get overviewStats {
    final liveCount = liveWalkIn.length;
    final appCount = appOrdersActive.length;
    final completedPaidCount = delivered
        .where((order) => order.paymentStatus == PaymentStatus.paid)
        .length;
    final pendingPaymentCount = [
      ...ready,
      ...delivered,
    ].where((order) => order.paymentStatus != PaymentStatus.paid).length;

    return (
      totalOrders: liveCount +
          preparingWalkIn.length +
          readyWalkIn.length +
          appCount +
          completedPaidCount,
      liveCount: liveCount,
      appCount: appCount,
      pendingPaymentCount: pendingPaymentCount,
    );
  }

  Future<void> load() async {
    _log('Order list refresh started.');
    if (!_hasLoaded) {
      isLoading = true;
      notifyListeners();
    }
    errorMessage = null;
    try {
      _orders = await _service.fetchLiveOrders();
      _orderLists.clear();
      _log('Order list refresh completed (${_orders.length} orders).');
    } catch (error) {
      _log('Order list refresh failed (${error.runtimeType}): $error');
      errorMessage = 'Failed to load live orders.';
    }
    _hasLoaded = true;
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
    applyOrderUpdate(order.copyWith(status: OrderStatus.cancelled));
  }

  Future<void> advanceStatus(OrderModel order) async {
    final next = order.status.nextStatus;
    if (next == null) {
      throw StateError('Order ${order.id} has no next status.');
    }
    if (next == OrderStatus.delivered && !order.isPaid) {
      throw StateError(
          'Payment must be completed before delivering this order.');
    }
    _log(
      'Status advance requested (order: ${order.id}, '
      '${order.status.name} -> ${next.name}).',
    );
    try {
      await _service.updateOrderStatus(orderId: order.id, newStatus: next);
      _log('Status update accepted by service (order: ${order.id}).');
      applyOrderUpdate(order.copyWith(status: next));
    } catch (error) {
      _log(
        'Status advance failed (order: ${order.id}, '
        '${order.status.name} -> ${next.name}, '
        '${error.runtimeType}): $error',
      );
      rethrow;
    }
  }

  void applyOrderUpdate(OrderModel updatedOrder) {
    final index = _orders.indexWhere((order) => order.id == updatedOrder.id);
    if (index == -1) return;

    final previousOrder = _orders[index];
    _orders = [..._orders]..[index] = updatedOrder;
    _orderLists.removeWhere(
      (_, cached) =>
          cached.matches(previousOrder) || cached.matches(updatedOrder),
    );
    notifyListeners();
  }
}

class _CachedOrderList {
  final Set<OrderStatus> statuses;
  final OrderSource source;
  final PaymentStatus? paymentStatus;
  final List<OrderModel> orders;

  const _CachedOrderList({
    required this.statuses,
    required this.source,
    required this.paymentStatus,
    required this.orders,
  });

  bool matches(OrderModel order) =>
      statuses.contains(order.status) &&
      source == order.orderSource &&
      (paymentStatus == null || paymentStatus == order.paymentStatus);
}

/// Riverpod binding for [LiveOrdersProvider].
final liveOrdersProvider = ChangeNotifierProvider<LiveOrdersProvider>(
  (ref) => LiveOrdersProvider(OrderService()),
);
