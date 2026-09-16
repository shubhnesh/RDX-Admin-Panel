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

  /// The label of the action that moves an order from this status to the
  /// next stage of the pipeline (pending -> preparing -> ready ->
  /// delivered). Null for terminal statuses (nothing to advance to).
  String? get advanceActionLabel {
    switch (this) {
      case OrderStatus.pending:
        return 'Start Preparing';
      case OrderStatus.preparing:
        return 'Mark Ready';
      case OrderStatus.ready:
        return 'Mark Delivered';
      case OrderStatus.cancelled:
      case OrderStatus.delivered:
        return null;
    }
  }

  OrderStatus? get nextStatus {
    switch (this) {
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

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

/// How the order is being served. Drives which extra fields the checkout
/// form shows (table number for dine-in, address for delivery).
enum OrderType { dineIn, delivery }

extension OrderTypeX on OrderType {
  String get label {
    switch (this) {
      case OrderType.dineIn:
        return 'Dine-in';
      case OrderType.delivery:
        return 'Delivery';
    }
  }

  static OrderType fromString(String? value) {
    return OrderType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderType.dineIn,
    );
  }
}

enum PaymentMethod { cash, card, upi, online }

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.online:
        return 'Online';
    }
  }

  static PaymentMethod? fromString(String? value) {
    if (value == null) return null;
    for (final method in PaymentMethod.values) {
      if (method.name == value) return method;
    }
    return null;
  }
}

class OrderItemModel {
  final String name;
  final int quantity;

  /// Unit price INCLUDING any selected add-ons — this is what gets
  /// multiplied by [quantity] to get the line total.
  final double price;

  /// Descriptive fields for the kitchen — not used in price math, just
  /// shown on the order card / KOT so staff know how to prepare it.
  final String? spiceLevel;
  final List<String> addOns;
  final String? notes;

  OrderItemModel({
    required this.name,
    required this.quantity,
    required this.price,
    this.spiceLevel,
    this.addOns = const [],
    this.notes,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        name: json['name'] ?? '',
        quantity: json['quantity'] as int? ?? 1,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        spiceLevel: json['spice_level'] as String?,
        addOns: (json['add_ons'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'price': price,
        'spice_level': spiceLevel,
        'add_ons': addOns,
        'notes': notes,
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

  /// Overall order-level note (e.g. "no onions in anything", "ring the
  /// bell twice"), separate from per-item notes in [OrderItemModel].
  final String? notes;

  final OrderType orderType;

  /// Only meaningful when [orderType] is [OrderType.dineIn].
  final String? tableNumber;

  final PaymentMethod? paymentMethod;

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
    this.orderType = OrderType.dineIn,
    this.tableNumber,
    this.paymentMethod,
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
      orderType: orderType,
      tableNumber: tableNumber,
      paymentMethod: paymentMethod,
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
      orderType: OrderTypeX.fromString(json['order_type'] as String?),
      tableNumber: json['table_number'] as String?,
      paymentMethod:
          PaymentMethodX.fromString(json['payment_method'] as String?),
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
        'order_type': orderType.name,
        'table_number': tableNumber,
        'payment_method': paymentMethod?.name,
        'updated_at': FieldValue.serverTimestamp(),
      };

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
