import 'package:cloud_firestore/cloud_firestore.dart';

enum DiscountType { percentage, flat }

enum CouponStatus { active, scheduled, expired }

class CouponModel {
  final String id;
  final String code;
  final String description;
  final DiscountType discountType;
  final double discountValue;
  final double? minOrderValue;
  final int? usageLimit;
  final int usageCount;
  final DateTime startDate;
  final DateTime endDate;
  final CouponStatus status;

  CouponModel({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderValue,
    this.usageLimit,
    this.usageCount = 0,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>? ?? {};
    return CouponModel.fromJson({...json, 'id': doc.id});
  }

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discount_type'] == 'flat'
          ? DiscountType.flat
          : DiscountType.percentage,
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0,
      minOrderValue: (json['min_order_value'] as num?)?.toDouble(),
      usageLimit: json['usage_limit'] as int?,
      usageCount: json['usage_count'] as int? ?? 0,
      startDate: _parseTimestamp(json['start_date']) ?? DateTime.now(),
      endDate: _parseTimestamp(json['end_date']) ?? DateTime.now().add(const Duration(days: 30)),
      status: CouponStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CouponStatus.active,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'description': description,
        'discount_type': discountType.name,
        'discount_value': discountValue,
        'min_order_value': minOrderValue,
        'usage_limit': usageLimit,
        'usage_count': usageCount,
        'start_date': Timestamp.fromDate(startDate),
        'end_date': Timestamp.fromDate(endDate),
        'status': status.name,
        'updated_at': FieldValue.serverTimestamp(),
      };

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
