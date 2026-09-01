import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, preparing, ready, cancelled, delivered }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

class OrderItemModel {
  final String name;
  final int quantity;
  final double price;

  OrderItemModel({
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        name: json['name'] ?? '',
        quantity: json['quantity'] as int? ?? 1,
        price: (json['price'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'price': price,
      };
}

class OrderModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final OrderStatus status;
  final double total;
  final DateTime createdAt;
  final List<OrderItemModel> items;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? customerId;
  final String? notes;

  OrderModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.items,
    this.deliveryLat,
    this.deliveryLng,
    this.customerId,
    this.notes,
  });

  OrderModel copyWith({
    OrderStatus? status,
    double? total,
    List<OrderItemModel>? items,
  }) {
    return OrderModel(
      id: id,
      customerName: customerName,
      customerPhone: customerPhone,
      deliveryAddress: deliveryAddress,
      status: status ?? this.status,
      total: total ?? this.total,
      createdAt: createdAt,
      items: items ?? this.items,
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
      customerId: customerId,
      notes: notes,
    );
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>? ?? {};
    return OrderModel.fromJson({...json, 'id': doc.id});
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      deliveryAddress: json['delivery_address'] ?? '',
      status: OrderStatusX.fromString(json['status'] ?? 'pending'),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      createdAt: _parseTimestamp(json['created_at']) ?? DateTime.now(),
      items: (json['items'] as List? ?? [])
          .map((e) => OrderItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      deliveryLat: (json['delivery_lat'] as num?)?.toDouble(),
      deliveryLng: (json['delivery_lng'] as num?)?.toDouble(),
      customerId: json['customer_id'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'delivery_address': deliveryAddress,
        'status': status.name,
        'total': total,
        'created_at': Timestamp.fromDate(createdAt),
        'items': items.map((e) => e.toJson()).toList(),
        'delivery_lat': deliveryLat,
        'delivery_lng': deliveryLng,
        'customer_id': customerId,
        'notes': notes,
        'updated_at': FieldValue.serverTimestamp(),
      };

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
