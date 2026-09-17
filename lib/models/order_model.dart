import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// ORDER STATUS
// =============================================================================

enum OrderStatus {
  pending,
  preparing,
  ready,
  cancelled,
  delivered,
}

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

  static OrderStatus fromString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return OrderStatus.pending;
    }

    return OrderStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

// =============================================================================
// ORDER TYPE
// =============================================================================

enum OrderType {
  dineIn,
  takeaway,
  delivery,
}

extension OrderTypeX on OrderType {
  String get label {
    switch (this) {
      case OrderType.dineIn:
        return 'Dine-in';

      case OrderType.takeaway:
        return 'Takeaway';

      case OrderType.delivery:
        return 'Delivery';
    }
  }

  static OrderType fromString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return OrderType.dineIn;
    }

    return OrderType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => OrderType.dineIn,
    );
  }
}

// =============================================================================
// PAYMENT METHOD
// =============================================================================

enum PaymentMethod {
  cash,
  card,
  upi,
  online,
  split,
}

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

      case PaymentMethod.split:
        return 'Split';
    }
  }

  // static PaymentMethod? fromString(String? value) {
  //   if (value == null || value.trim().isEmpty) {
  //     return null;
  //   }

  //   return PaymentMethod.values.cast<PaymentMethod?>().firstWhere(
  //         (method) => method?.name == value,
  //         orElse: () => null,
  //       );
  // }
  static PaymentMethod? fromString(String? value) {
    final normalized = value?.trim();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    for (final method in PaymentMethod.values) {
      if (method.name == normalized) {
        return method;
      }
    }

    return null;
  }
}

// =============================================================================
// PAYMENT STATUS
// =============================================================================

enum PaymentStatus {
  unpaid,
  paid,
}

extension PaymentStatusX on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'Unpaid';

      case PaymentStatus.paid:
        return 'Paid';
    }
  }

  static PaymentStatus fromString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return PaymentStatus.unpaid;
    }

    return PaymentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PaymentStatus.unpaid,
    );
  }
}

// =============================================================================
// ORDER ITEM
// =============================================================================

class OrderItemModel {
  final String name;
  final int quantity;
  final double price;
  final String? spiceLevel;
  final List<String> addOns;
  final String? notes;

  const OrderItemModel({
    required this.name,
    required this.quantity,
    required this.price,
    this.spiceLevel,
    this.addOns = const [],
    this.notes,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      name: json['name']?.toString().trim() ?? '',
      quantity: _parseInt(
        json['quantity'],
        fallback: 1,
      ),
      price: _parseDouble(
        json['price'],
      ),
      spiceLevel: _parseNullableString(
        json['spice_level'],
      ),
      addOns: _parseStringList(
        json['add_ons'],
      ),
      notes: _parseNullableString(
        json['notes'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'spice_level': spiceLevel,
      'add_ons': addOns,
      'notes': notes,
    };
  }
}

/// Safely parses an integer from Firestore/API data.
int _parseInt(
  dynamic value, {
  int fallback = 0,
}) {
  if (value == null) {
    return fallback;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    final parsed = int.tryParse(value.trim());

    if (parsed != null) {
      return parsed;
    }

    final doubleValue = double.tryParse(value.trim());

    if (doubleValue != null) {
      return doubleValue.toInt();
    }
  }

  return fallback;
}

/// Safely parses a double from Firestore/API data.
double _parseDouble(
  dynamic value, {
  double fallback = 0.0,
}) {
  if (value == null) {
    return fallback;
  }

  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value.trim()) ?? fallback;
  }

  return fallback;
}

/// Safely converts a nullable value to String.
///
/// Empty strings are treated as null.
String? _parseNullableString(
  dynamic value,
) {
  if (value == null) {
    return null;
  }

  final result = value.toString().trim();

  if (result.isEmpty) {
    return null;
  }

  return result;
}

/// Safely converts Firestore/API list data into List<String>.
List<String> _parseStringList(
  dynamic value,
) {
  if (value == null) {
    return const [];
  }

  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  // Handles cases where an API/database accidentally stores
  // a single add-on as a string instead of a list.
  if (value is String) {
    final result = value.trim();

    if (result.isEmpty) {
      return const [];
    }

    return [result];
  }

  return const [];
}

// =============================================================================
// ORDER MODEL
// =============================================================================

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

  final OrderType orderType;
  final String? tableNumber;

  final PaymentMethod? paymentMethod;
  final PaymentStatus paymentStatus;

  const OrderModel({
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
    this.paymentStatus = PaymentStatus.unpaid,
  });

  // ===========================================================================
  // PAYMENT HELPERS
  // ===========================================================================

  bool get isPaid {
    return paymentStatus == PaymentStatus.paid;
  }

  bool get isUnpaid {
    return paymentStatus == PaymentStatus.unpaid;
  }

  // ===========================================================================
  // COPY WITH
  // ===========================================================================

  OrderModel copyWith({
    OrderStatus? status,
    double? total,
    List<OrderItemModel>? items,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,

    // Allows paymentMethod to actually be cleared.
    bool clearPaymentMethod = false,
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
      paymentMethod:
          clearPaymentMethod ? null : paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  // ===========================================================================
  // FIRESTORE
  // ===========================================================================

  factory OrderModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final json = doc.data() ?? {};

    return OrderModel.fromJson({
      ...json,
      'id': doc.id,
    });
  }

  // ===========================================================================
  // JSON -> MODEL
  // ===========================================================================

  factory OrderModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return OrderModel(
      id: json['id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      deliveryAddress: json['delivery_address']?.toString() ?? '',
      status: OrderStatusX.fromString(
        json['status']?.toString(),
      ),
      total: _parseDouble(
        json['total'],
      ),
      createdAt: _parseTimestamp(json['created_at']) ?? DateTime.now(),
      items: _parseItems(
        json['items'],
      ),
      deliveryLat: _parseNullableDouble(
        json['delivery_lat'],
      ),
      deliveryLng: _parseNullableDouble(
        json['delivery_lng'],
      ),
      customerId: _parseNullableString(
        json['customer_id'],
      ),
      notes: _parseNullableString(
        json['notes'],
      ),
      orderType: OrderTypeX.fromString(
        json['order_type']?.toString(),
      ),
      tableNumber: _parseNullableString(
        json['table_number'],
      ),
      paymentMethod: PaymentMethodX.fromString(
        json['payment_method']?.toString(),
      ),
      paymentStatus: PaymentStatusX.fromString(
        json['payment_status']?.toString(),
      ),
    );
  }

  // ===========================================================================
  // MODEL -> JSON
  // ===========================================================================

  Map<String, dynamic> toJson() {
    return {
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'delivery_address': deliveryAddress,
      'status': status.name,
      'total': total,
      'created_at': Timestamp.fromDate(
        createdAt,
      ),
      'items': items
          .map(
            (item) => item.toJson(),
          )
          .toList(),
      'delivery_lat': deliveryLat,
      'delivery_lng': deliveryLng,
      'customer_id': customerId,
      'notes': notes,
      'order_type': orderType.name,
      'table_number': tableNumber,
      'payment_method': paymentMethod?.name,
      'payment_status': paymentStatus.name,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  // ===========================================================================
  // PARSERS
  // ===========================================================================

  static DateTime? _parseTimestamp(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static double _parseDouble(
    dynamic value, {
    double fallback = 0,
  }) {
    if (value == null) {
      return fallback;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  static double? _parseNullableDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  static int _parseInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value == null) {
      return fallback;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  static String? _parseNullableString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
  }

  static List<String> _parseStringList(
    dynamic value,
  ) {
    if (value is! List) {
      return const [];
    }

    return value
        .map(
          (item) => item.toString(),
        )
        .toList();
  }

  static List<OrderItemModel> _parseItems(
    dynamic value,
  ) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => OrderItemModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}