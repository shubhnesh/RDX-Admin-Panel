import 'package:flutter_test/flutter_test.dart';
import 'package:rdx_admin/models/coupon_model.dart';

void main() {
  group('CouponModel', () {
    test('parses coupon fields after backend numeric type changes', () {
      final startDate = DateTime.utc(2025, 1, 1);
      final endDate = DateTime.utc(2035, 1, 1);

      final coupon = CouponModel.fromJson({
        'id': 'coupon-1',
        'code': 'summer',
        'description': 'Summer discount',
        'discount_type': 'flat',
        'discount_value': '25.5',
        'min_order_value': '100',
        'usage_limit': '20',
        'usage_count': 3.0,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'status': 'active',
        'applicable_categories': ['category-1', 42],
      });

      expect(coupon.id, 'coupon-1');
      expect(coupon.code, 'SUMMER');
      expect(coupon.discountType, DiscountType.flat);
      expect(coupon.discountValue, 25.5);
      expect(coupon.minOrderValue, 100);
      expect(coupon.usageLimit, 20);
      expect(coupon.usageCount, 3);
      expect(coupon.startDate, startDate);
      expect(coupon.endDate, endDate);
      expect(coupon.applicableCategories, ['category-1']);
    });

    test('does not throw when optional backend fields have unexpected types',
        () {
      final coupon = CouponModel.fromJson({
        'id': 42,
        'code': 12,
        'description': false,
        'discount_value': 'invalid',
        'usage_count': 'invalid',
        'applicable_categories': 'not-a-list',
      });

      expect(coupon.id, isEmpty);
      expect(coupon.code, isEmpty);
      expect(coupon.description, isEmpty);
      expect(coupon.discountValue, 0);
      expect(coupon.usageCount, 0);
      expect(coupon.applicableCategories, isEmpty);
    });
  });
}
