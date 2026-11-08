import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';

class LiveOrdersProvider extends ChangeNotifier {
  final OrderService _service;
  LiveOrdersProvider(this._service);

  List<OrderModel> _orders = [];
  final Map<String, OrderModel> _ordersById = {};
  final Map<String, _CachedOrderList> _orderLists = {};
  StreamSubscription<List<OrderModel>>? _ordersSubscription;
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

  OrderModel? orderById(String id) => _ordersById[id];

  List<String> orderIdsFor({
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
            orderIds: List.unmodifiable(
              _orders
                  .where(
                    (order) =>
                        statuses.contains(order.status) &&
                        order.orderSource == source &&
                        (paymentStatus == null ||
                            order.paymentStatus == paymentStatus),
                  )
                  .map((order) => order.id),
            ),
          ),
        )
        .orderIds;
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

  Future<void> load() {
    if (_ordersSubscription != null) return Future<void>.value();

    _log('Live order subscription started.');
    isLoading = !_hasLoaded;
    errorMessage = null;
    notifyListeners();

    late final StreamSubscription<List<OrderModel>> subscription;
    subscription = _service.watchLiveOrders().listen(
      _applySnapshot,
      onError: (Object error, StackTrace stackTrace) {
        _log('Live order subscription failed (${error.runtimeType}): $error');
        if (identical(_ordersSubscription, subscription)) {
          _ordersSubscription = null;
        }
        errorMessage = 'Live order updates are unavailable.';
        isLoading = false;
        notifyListeners();
      },
      onDone: () {
        if (identical(_ordersSubscription, subscription)) {
          _ordersSubscription = null;
          errorMessage = 'Live order updates have stopped.';
          isLoading = false;
          notifyListeners();
        }
      },
    );
    _ordersSubscription = subscription;
    return Future<void>.value();
  }

  void _applySnapshot(List<OrderModel> snapshot) {
    final snapshotById = {for (final order in snapshot) order.id: order};
    final previousOrders = <OrderModel>[];
    final addedOrders = <OrderModel>[];
    final nextOrders = <OrderModel>[];

    for (final order in snapshot) {
      final previousOrder = _ordersById[order.id];
      if (previousOrder == null) {
        addedOrders.add(order);
        nextOrders.add(order);
      } else if (_sameOrder(previousOrder, order)) {
        nextOrders.add(previousOrder);
      } else {
        previousOrders.add(previousOrder);
        nextOrders.add(order);
      }
    }

    for (final order in _orders) {
      if (!snapshotById.containsKey(order.id)) {
        previousOrders.add(order);
      }
    }

    if (_hasLoaded && addedOrders.isEmpty && previousOrders.isEmpty) return;

    _orders = nextOrders;
    _ordersById
      ..clear()
      ..addEntries(_orders.map((order) => MapEntry(order.id, order)));
    _hasLoaded = true;
    isLoading = false;
    errorMessage = null;

    if (previousOrders.isEmpty && addedOrders.isEmpty) {
      _orderLists.clear();
    } else {
      for (final previousOrder in previousOrders) {
        _invalidateOrderListMembership(
          previousOrder,
          snapshotById[previousOrder.id],
        );
      }
      for (final addedOrder in addedOrders) {
        _invalidateOrderListMembership(null, addedOrder);
      }
    }

    _log('Live order snapshot applied (${_orders.length} orders).');
    notifyListeners();
  }

  bool _sameOrder(OrderModel first, OrderModel second) {
    if (first.id != second.id ||
        first.customerName != second.customerName ||
        first.customerPhone != second.customerPhone ||
        first.deliveryAddress != second.deliveryAddress ||
        first.status != second.status ||
        first.total != second.total ||
        first.itemTotal != second.itemTotal ||
        first.taxes != second.taxes ||
        first.gstPercent != second.gstPercent ||
        first.deliveryFee != second.deliveryFee ||
        first.lateNightFee != second.lateNightFee ||
        first.longDistanceFee != second.longDistanceFee ||
        first.couponDiscount != second.couponDiscount ||
        first.rewardDiscount != second.rewardDiscount ||
        first.createdAt != second.createdAt ||
        first.deliveryLat != second.deliveryLat ||
        first.deliveryLng != second.deliveryLng ||
        first.customerId != second.customerId ||
        first.notes != second.notes ||
        first.orderType != second.orderType ||
        first.tableNumber != second.tableNumber ||
        first.paymentMethod != second.paymentMethod ||
        first.paymentStatus != second.paymentStatus ||
        first.orderSource != second.orderSource ||
        first.items.length != second.items.length) {
      return false;
    }

    for (var index = 0; index < first.items.length; index++) {
      final firstItem = first.items[index];
      final secondItem = second.items[index];
      if (firstItem.name != secondItem.name ||
          firstItem.quantity != secondItem.quantity ||
          firstItem.price != secondItem.price ||
          firstItem.spiceLevel != secondItem.spiceLevel ||
          firstItem.notes != secondItem.notes ||
          !listEquals(firstItem.addOns, secondItem.addOns)) {
        return false;
      }
    }
    return true;
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
    _ordersById[updatedOrder.id] = updatedOrder;
    _invalidateOrderListMembership(previousOrder, updatedOrder);
    notifyListeners();
  }

  void _invalidateOrderListMembership(
    OrderModel? previousOrder,
    OrderModel? updatedOrder,
  ) {
    _orderLists.removeWhere((_, cached) {
      final matchedBefore =
          previousOrder != null && cached.matches(previousOrder);
      final matchesNow = updatedOrder != null && cached.matches(updatedOrder);
      return matchedBefore != matchesNow ||
          (matchedBefore &&
              matchesNow &&
              previousOrder.createdAt != updatedOrder.createdAt);
    });
  }

  @override
  void dispose() {
    final subscription = _ordersSubscription;
    _ordersSubscription = null;
    if (subscription != null) unawaited(subscription.cancel());
    super.dispose();
  }
}

class _CachedOrderList {
  final Set<OrderStatus> statuses;
  final OrderSource source;
  final PaymentStatus? paymentStatus;
  final List<String> orderIds;

  const _CachedOrderList({
    required this.statuses,
    required this.source,
    required this.paymentStatus,
    required this.orderIds,
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
