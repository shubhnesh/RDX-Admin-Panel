import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class LiveOrdersProvider extends ChangeNotifier {
  final OrderService _service;
  LiveOrdersProvider(this._service);

  List<OrderModel> _orders = [];
  bool isLoading = false;
  String? errorMessage;

  List<OrderModel> get pending =>
      _orders.where((o) => o.status == OrderStatus.pending).toList();
  List<OrderModel> get preparing =>
      _orders.where((o) => o.status == OrderStatus.preparing).toList();
  List<OrderModel> get ready =>
      _orders.where((o) => o.status == OrderStatus.ready).toList();

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      _orders = await _service.fetchLiveOrders();
    } catch (e) {
      errorMessage = 'Failed to load live orders.';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> advanceStatus(OrderModel order) async {
    final next = switch (order.status) {
      OrderStatus.pending => OrderStatus.preparing,
      OrderStatus.preparing => OrderStatus.ready,
      OrderStatus.ready => OrderStatus.delivered, // ready → delivered
      OrderStatus.cancelled => OrderStatus.cancelled,
      OrderStatus.delivered => OrderStatus.delivered,
    };
    await _service.updateOrderStatus(order.id, next);
    await load();
  }
}
