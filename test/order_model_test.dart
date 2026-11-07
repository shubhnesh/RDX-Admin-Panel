import 'package:flutter_test/flutter_test.dart';
import 'package:rdx_admin/models/order_model.dart';

void main() {
  group('OrderStatusX.fromString', () {
    test('treats served orders as completed orders', () {
      expect(OrderStatusX.fromString('served'), OrderStatus.delivered);
    });

    test('normalizes completed status casing and whitespace', () {
      expect(OrderStatusX.fromString(' DELIVERED '), OrderStatus.delivered);
    });
  });
}
