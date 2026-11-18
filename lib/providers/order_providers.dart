import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';

/// Shared [OrderService] instance.
/// This is the ONLY definition: delete order_service_provider.dart and
/// order_service_provider_1.dart, and import this file instead.
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

/// Live orders as a one-shot fetch (compatible with OrderService.fetchLiveOrders).
final liveOrdersStreamProvider = FutureProvider<List<OrderModel>>((ref) async {
  final service = ref.watch(orderServiceProvider);
  return service.fetchLiveOrders();
});

/// Tracks which order IDs currently have an in-flight status update.
class OrderActionsNotifier extends StateNotifier<Set<String>> {
  OrderActionsNotifier(this._ref) : super({});

  final Ref _ref;

  OrderService get _service => _ref.read(orderServiceProvider);

  Future<void> advanceStatus(OrderModel order) async {
    // Ignore double taps while a request for this order is in flight.
    if (state.contains(order.id)) return;

    final next = _nextStatus(order.status);
    if (next == null) return;
    if (next == OrderStatus.delivered && !order.isPaid) {
      throw StateError('Payment must be completed before delivering this order.');
    }

    state = {...state, order.id};
    try {
      await _service.updateOrderStatus(
        orderId: order.id,
        newStatus: next,
      );
      _ref.invalidate(liveOrdersStreamProvider);
    } finally {
      state = {...state}..remove(order.id);
    }
  }

  Future<void> cancelOrder(OrderModel order) async {
    if (state.contains(order.id)) return;

    state = {...state, order.id};
    try {
      await _service.updateOrderStatus(
        orderId: order.id,
        newStatus: OrderStatus.cancelled,
      );
      _ref.invalidate(liveOrdersStreamProvider);
    } finally {
      state = {...state}..remove(order.id);
    }
  }

  OrderStatus? _nextStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.ready;
      case OrderStatus.ready:
        return OrderStatus.delivered;
      case OrderStatus.cancelled:
      case OrderStatus.delivered:
        return null;
    }
  }
}

final orderActionsProvider =
    StateNotifierProvider<OrderActionsNotifier, Set<String>>((ref) {
  return OrderActionsNotifier(ref);
});

/// Submits a brand-new POS / staff order via Cloud Function.
class PlaceOrderController extends StateNotifier<AsyncValue<String?>> {
  PlaceOrderController(this._service) : super(const AsyncData(null));

  final OrderService _service;

  bool get isLoading => state.isLoading;

  /// Create a staff order through the secure Cloud Function.
  /// Returns the new order id on success, null on failure.
  Future<String?> submitStaffOrder({
    required List<Map<String, dynamic>> items,
    required String orderType,
    String? tableNumber,
    String customerName = 'Walk-in',
    String customerPhone = '',
    String? deliveryAddress,
    String? notes,
    bool applyLongDistanceFee = false,
    String? couponCode,
    String? paymentMethod,
  }) async {
    // Prevent double submit creating duplicate orders.
    if (state.isLoading) return null;

    state = const AsyncLoading();
    try {
      final order = await _service.createStaffOrder(
        items: items,
        orderType: orderType,
        tableNumber: tableNumber,
        customerName: customerName,
        customerPhone: customerPhone,
        deliveryAddress: deliveryAddress,
        notes: notes,
        applyLongDistanceFee: applyLongDistanceFee,
        couponCode: couponCode,
        paymentMethod: paymentMethod,
      );
      state = AsyncData(order.id);
      return order.id;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

final placeOrderControllerProvider =
    StateNotifierProvider<PlaceOrderController, AsyncValue<String?>>((ref) {
  return PlaceOrderController(ref.watch(orderServiceProvider));
});
