import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

/// Single shared OrderService instance.
final orderServiceProvider = Provider<OrderService>(
  (ref) => OrderService(),
);

/// Real-time list of orders currently in:
/// pending / preparing / ready.
///
/// This is the ONLY provider that should drive the Live Orders screen.
final liveOrdersStreamProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(orderServiceProvider).streamLiveOrders();
});

/// Real-time delivered/cancelled orders for order history.
final orderHistoryStreamProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(orderServiceProvider).streamOrderHistory();
});

/// Tracks which order IDs currently have a status change in flight.
///
/// This allows only the tapped card to show a loading state and prevents
/// duplicate taps while the Firestore update is running.
class OrderActionsNotifier extends StateNotifier<Set<String>> {
  OrderActionsNotifier(this._service) : super(<String>{});

  final OrderService _service;

  bool isUpdating(String orderId) {
    return state.contains(orderId);
  }

  Future<void> advanceStatus(OrderModel order) async {
    final next = order.status.nextStatus;

    if (next == null || state.contains(order.id)) {
      return;
    }

    state = {
      ...state,
      order.id,
    };

    try {
      await _service.updateOrderStatus(
        order.id,
        next,
      );
    } finally {
      state = {
        ...state,
      }..remove(order.id);
    }
  }

  Future<void> cancelOrder(OrderModel order) async {
    if (state.contains(order.id)) {
      return;
    }

    state = {
      ...state,
      order.id,
    };

    try {
      await _service.updateOrderStatus(
        order.id,
        OrderStatus.cancelled,
      );
    } finally {
      state = {
        ...state,
      }..remove(order.id);
    }
  }
}

final orderActionsProvider =
    StateNotifierProvider<OrderActionsNotifier, Set<String>>(
  (ref) {
    return OrderActionsNotifier(
      ref.watch(orderServiceProvider),
    );
  },
);

/// Handles order creation from Checkout.
class PlaceOrderController extends StateNotifier<AsyncValue<String?>> {
  PlaceOrderController(this._service) : super(const AsyncValue.data(null));

  final OrderService _service;

  Future<String?> submit(OrderModel order) async {
    state = const AsyncValue.loading();

    try {
      final id = await _service.createOrder(order);

      state = AsyncValue.data(id);

      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);

      return null;
    }
  }
}

final placeOrderControllerProvider = StateNotifierProvider.autoDispose<
    PlaceOrderController, AsyncValue<String?>>(
  (ref) {
    return PlaceOrderController(
      ref.watch(orderServiceProvider),
    );
  },
);

/// State for a single order-detail screen.
class OrderDetailState {
  final OrderModel? order;
  final bool isLoading;
  final String? errorMessage;

  const OrderDetailState({
    this.order,
    this.isLoading = false,
    this.errorMessage,
  });

  OrderDetailState copyWith({
    OrderModel? order,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OrderDetailState(
      order: order ?? this.order,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class OrderDetailNotifier extends StateNotifier<OrderDetailState> {
  OrderDetailNotifier(
    this._service,
    this.orderId,
  ) : super(const OrderDetailState());

  final OrderService _service;
  final String orderId;

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final order = await _service.fetchOrderById(orderId);

      state = state.copyWith(
        isLoading: false,
        order: order,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load order.',
      );
    }
  }

  Future<void> updateStatus(OrderStatus status) async {
    final current = state.order;

    if (current == null) {
      return;
    }

    await _service.updateOrderStatus(
      current.id,
      status,
    );

    state = state.copyWith(
      order: current.copyWith(
        status: status,
      ),
    );
  }
}

final orderDetailProvider = StateNotifierProvider.autoDispose
    .family<OrderDetailNotifier, OrderDetailState, String>(
  (ref, orderId) {
    return OrderDetailNotifier(
      ref.watch(orderServiceProvider),
      orderId,
    );
  },
);
