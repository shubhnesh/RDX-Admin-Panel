import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/order_service.dart';

/// Simple provider for the Admin OrderService.
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});
