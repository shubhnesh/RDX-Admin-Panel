// import 'package:cloud_firestore/cloud_firestore.dart';

// enum OrderStatus { pending, preparing, ready, cancelled, delivered }

// extension OrderStatusX on OrderStatus {
//   String get label {
//     switch (this) {
//       case OrderStatus.pending:
//         return 'Pending';
//       case OrderStatus.preparing:
//         return 'Preparing';
//       case OrderStatus.ready:
//         return 'Ready';
//       case OrderStatus.cancelled:
//         return 'Cancelled';
//       case OrderStatus.delivered:
//         return 'Delivered';
//     }
//   }

//   /// The label of the action that moves an order from this status to the
//   /// next stage of the pipeline (pending -> preparing -> ready ->
//   /// delivered). Null for terminal statuses (nothing to advance to).
//   String? get advanceActionLabel {
//     switch (this) {
//       case OrderStatus.pending:
//         return 'Start Preparing';
//       case OrderStatus.preparing:
//         return 'Mark Ready';
//       case OrderStatus.ready:
//         return 'Mark Delivered';
//       case OrderStatus.cancelled:
//       case OrderStatus.delivered:
//         return null;
//     }
//   }

//   OrderStatus? get nextStatus {
//     switch (this) {
//       case OrderStatus.pending:
//         return OrderStatus.preparing;
//       case OrderStatus.preparing:
//         return OrderStatus.ready;
//       case OrderStatus.ready:
//         return OrderStatus.delivered;
//       case OrderStatus.cancelled:
//       case OrderStatus.delivered:
//         return null;
//     }
//   }

//   static OrderStatus fromString(String value) {
//     return OrderStatus.values.firstWhere(
//       (e) => e.name == value,
//       orElse: () => OrderStatus.pending,
//     );
//   }
// }

// /// How the order is being served. Drives which extra fields the checkout
// /// form shows (table number for dine-in, address for delivery).
// enum OrderType { dineIn, delivery }

// extension OrderTypeX on OrderType {
//   String get label {
//     switch (this) {
//       case OrderType.dineIn:
//         return 'Dine-in';
//       case OrderType.delivery:
//         return 'Delivery';
//     }
//   }

//   static OrderType fromString(String? value) {
//     return OrderType.values.firstWhere(
//       (e) => e.name == value,
//       orElse: () => OrderType.dineIn,
//     );
//   }
// }

// enum PaymentMethod { cash, card, upi, online }

// extension PaymentMethodX on PaymentMethod {
//   String get label {
//     switch (this) {
//       case PaymentMethod.cash:
//         return 'Cash';
//       case PaymentMethod.card:
//         return 'Card';
//       case PaymentMethod.upi:
//         return 'UPI';
//       case PaymentMethod.online:
//         return 'Online';
//     }
//   }

//   static PaymentMethod? fromString(String? value) {
//     if (value == null) return null;
//     for (final method in PaymentMethod.values) {
//       if (method.name == value) return method;
//     }
//     return null;
//   }
// }

// class OrderItemModel {
//   final String name;
//   final int quantity;

//   /// Unit price INCLUDING any selected add-ons — this is what gets
//   /// multiplied by [quantity] to get the line total.
//   final double price;

//   /// Descriptive fields for the kitchen — not used in price math, just
//   /// shown on the order card / KOT so staff know how to prepare it.
//   final String? spiceLevel;
//   final List<String> addOns;
//   final String? notes;

//   OrderItemModel({
//     required this.name,
//     required this.quantity,
//     required this.price,
//     this.spiceLevel,
//     this.addOns = const [],
//     this.notes,
//   });

//   factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
//         name: json['name'] ?? '',
//         quantity: json['quantity'] as int? ?? 1,
//         price: (json['price'] as num?)?.toDouble() ?? 0,
//         spiceLevel: json['spice_level'] as String?,
//         addOns: (json['add_ons'] as List? ?? const [])
//             .map((e) => e.toString())
//             .toList(),
//         notes: json['notes'] as String?,
//       );

//   Map<String, dynamic> toJson() => {
//         'name': name,
//         'quantity': quantity,
//         'price': price,
//         'spice_level': spiceLevel,
//         'add_ons': addOns,
//         'notes': notes,
//       };
// }

// class OrderModel {
//   final String id;
//   final String customerName;
//   final String customerPhone;
//   final String deliveryAddress;
//   final OrderStatus status;
//   final double total;
//   final DateTime createdAt;
//   final List<OrderItemModel> items;
//   final double? deliveryLat;
//   final double? deliveryLng;
//   final String? customerId;

//   /// Overall order-level note (e.g. "no onions in anything", "ring the
//   /// bell twice"), separate from per-item notes in [OrderItemModel].
//   final String? notes;

//   final OrderType orderType;

//   /// Only meaningful when [orderType] is [OrderType.dineIn].
//   final String? tableNumber;

//   final PaymentMethod? paymentMethod;

//   OrderModel({
//     required this.id,
//     required this.customerName,
//     required this.customerPhone,
//     required this.deliveryAddress,
//     required this.status,
//     required this.total,
//     required this.createdAt,
//     required this.items,
//     this.deliveryLat,
//     this.deliveryLng,
//     this.customerId,
//     this.notes,
//     this.orderType = OrderType.dineIn,
//     this.tableNumber,
//     this.paymentMethod,
//   });

//   OrderModel copyWith({
//     OrderStatus? status,
//     double? total,
//     List<OrderItemModel>? items,
//   }) {
//     return OrderModel(
//       id: id,
//       customerName: customerName,
//       customerPhone: customerPhone,
//       deliveryAddress: deliveryAddress,
//       status: status ?? this.status,
//       total: total ?? this.total,
//       createdAt: createdAt,
//       items: items ?? this.items,
//       deliveryLat: deliveryLat,
//       deliveryLng: deliveryLng,
//       customerId: customerId,
//       notes: notes,
//       orderType: orderType,
//       tableNumber: tableNumber,
//       paymentMethod: paymentMethod,
//     );
//   }

//   factory OrderModel.fromFirestore(DocumentSnapshot doc) {
//     final json = doc.data() as Map<String, dynamic>? ?? {};
//     return OrderModel.fromJson({...json, 'id': doc.id});
//   }

//   factory OrderModel.fromJson(Map<String, dynamic> json) {
//     return OrderModel(
//       id: json['id'] ?? '',
//       customerName: json['customer_name'] ?? '',
//       customerPhone: json['customer_phone'] ?? '',
//       deliveryAddress: json['delivery_address'] ?? '',
//       status: OrderStatusX.fromString(json['status'] ?? 'pending'),
//       total: (json['total'] as num?)?.toDouble() ?? 0,
//       createdAt: _parseTimestamp(json['created_at']) ?? DateTime.now(),
//       items: (json['items'] as List? ?? [])
//           .map((e) => OrderItemModel.fromJson(Map<String, dynamic>.from(e)))
//           .toList(),
//       deliveryLat: (json['delivery_lat'] as num?)?.toDouble(),
//       deliveryLng: (json['delivery_lng'] as num?)?.toDouble(),
//       customerId: json['customer_id'],
//       notes: json['notes'],
//       orderType: OrderTypeX.fromString(json['order_type'] as String?),
//       tableNumber: json['table_number'] as String?,
//       paymentMethod:
//           PaymentMethodX.fromString(json['payment_method'] as String?),
//     );
//   }

//   Map<String, dynamic> toJson() => {
//         'customer_name': customerName,
//         'customer_phone': customerPhone,
//         'delivery_address': deliveryAddress,
//         'status': status.name,
//         'total': total,
//         'created_at': Timestamp.fromDate(createdAt),
//         'items': items.map((e) => e.toJson()).toList(),
//         'delivery_lat': deliveryLat,
//         'delivery_lng': deliveryLng,
//         'customer_id': customerId,
//         'notes': notes,
//         'order_type': orderType.name,
//         'table_number': tableNumber,
//         'payment_method': paymentMethod?.name,
//         'updated_at': FieldValue.serverTimestamp(),
//       };

//   static DateTime? _parseTimestamp(dynamic value) {
//     if (value == null) return null;
//     if (value is Timestamp) return value.toDate();
//     if (value is String) return DateTime.tryParse(value);
//     return null;
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';

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

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

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
    return OrderType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => OrderType.dineIn,
    );
  }
}

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

  static PaymentMethod? fromString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    for (final method in PaymentMethod.values) {
      if (method.name == value) {
        return method;
      }
    }

    return null;
  }
}

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
    return PaymentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PaymentStatus.unpaid,
    );
  }
}

class OrderItemModel {
  final String name;
  final int quantity;
  final double price;
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

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      name: json['name'] ?? '',
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      spiceLevel: json['spice_level'] as String?,
      addOns: (json['add_ons'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      notes: json['notes'] as String?,
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
    this.paymentStatus = PaymentStatus.unpaid,
  });

  OrderModel copyWith({
    OrderStatus? status,
    double? total,
    List<OrderItemModel>? items,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
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
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>? ?? {};

    return OrderModel.fromJson({
      ...json,
      'id': doc.id,
    });
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      deliveryAddress: json['delivery_address'] ?? '',
      status: OrderStatusX.fromString(
        json['status'] ?? 'pending',
      ),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      createdAt: _parseTimestamp(json['created_at']) ?? DateTime.now(),
      items: (json['items'] as List? ?? [])
          .map(
            (item) => OrderItemModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      deliveryLat: (json['delivery_lat'] as num?)?.toDouble(),
      deliveryLng: (json['delivery_lng'] as num?)?.toDouble(),
      customerId: json['customer_id'],
      notes: json['notes'],
      orderType: OrderTypeX.fromString(
        json['order_type'] as String?,
      ),
      tableNumber: json['table_number'] as String?,
      paymentMethod: PaymentMethodX.fromString(
        json['payment_method'] as String?,
      ),
      paymentStatus: PaymentStatusX.fromString(
        json['payment_status'] as String?,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'delivery_address': deliveryAddress,
      'status': status.name,
      'total': total,
      'created_at': Timestamp.fromDate(createdAt),
      'items': items.map((item) => item.toJson()).toList(),
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

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}










// and



// import 'package:flutter/material.dart';



// import 'package:flutter_riverpod/flutter_riverpod.dart';



// import '../../core/theme/app_colors.dart';



// import '../../core/theme/text_styles.dart';



// import '../../core/utils/responsive_size.dart';



// import '../../models/order_model.dart';



// import '../../providers/order_providers.dart';



// import '../../widgets/buttons/rdx_action_button.dart';



// import '../../widgets/reusable_widgets/empty_state.dart';



// import '../../widgets/reusable_widgets/rdx_header.dart';



// import '../../widgets/reusable_widgets/stat_card.dart';



// import 'place_order_screen.dart';



// import 'widgets/live_order_card.dart';



// class LiveOrdersScreen extends ConsumerStatefulWidget {



//   const LiveOrdersScreen({super.key});



//   @override



//   ConsumerState<LiveOrdersScreen> createState() => _LiveOrdersScreenState();



// }



// class _LiveOrdersScreenState extends ConsumerState<LiveOrdersScreen> {



//   OrderType? _typeFilter;



//   OrderStatus _narrowStage = OrderStatus.pending;



//   Future<void> _openPlaceOrder() async {



//     final placed = await Navigator.of(context).push<bool>(



//       MaterialPageRoute(



//         builder: (_) => const PlaceOrderScreen(),



//       ),



//     );



//     if (placed == true && mounted) {



//       ScaffoldMessenger.of(context).showSnackBar(



//         const SnackBar(



//           content: Text('New order added to the queue.'),



//         ),



//       );



//     }



//   }



//   List<OrderModel> _filterByType(List<OrderModel> orders) {



//     if (_typeFilter == null) {



//       return orders;



//     }



//     return orders.where((order) => order.orderType == _typeFilter).toList();



//   }



//   @override



//   Widget build(BuildContext context) {



//     final colors = AppColors.of(context);



//     final ordersAsync = ref.watch(liveOrdersStreamProvider);



//     final narrow = MediaQuery.sizeOf(context).width < 900;



//     // Keep the UI visible while the stream is loading.



//     // When data is available, this contains the current orders.



//     final allOrders = ordersAsync.valueOrNull ?? <OrderModel>[];



//     final filteredOrders = _filterByType(allOrders);



//     // ─────────────────────────────────────────────────────────────



//     // STAT COUNTS



//     // ─────────────────────────────────────────────────────────────



//     final totalOrders = allOrders.length;



//     final pendingOrders = allOrders



//         .where(



//           (order) => order.status == OrderStatus.pending,



//         )



//         .length;



//     return Scaffold(



//       backgroundColor: colors.background,



//       body: Column(



//         children: [



//           // ─────────────────────────────────────────────────────────



//           // HEADER



//           // ─────────────────────────────────────────────────────────



//           const RdxHeader(



//             title: 'Live Orders',



//             showBackButton: false,



//           ),



//           // ─────────────────────────────────────────────────────────



//           // FILTERS + NEW ORDER



//           // ─────────────────────────────────────────────────────────



//           Padding(



//             padding: EdgeInsets.fromLTRB(



//               context.w(20),



//               context.h(12),



//               context.w(20),



//               0,



//             ),



//             child: Row(



//               crossAxisAlignment: CrossAxisAlignment.center,



//               children: [



//                 Expanded(



//                   child: _typeFilterChips(



//                     context,



//                     colors,



//                     allOrders,



//                   ),



//                 ),



//                 SizedBox(width: context.w(12)),



//                 RdxActionButton(



//                   label: 'New Order',



//                   leadingIcon: Icons.add,



//                   onPressed: _openPlaceOrder,



//                 ),



//               ],



//             ),



//           ),



//           SizedBox(height: context.h(20)),



//           // ─────────────────────────────────────────────────────────



//           // STAT CARDS



//           //



//           // IMPORTANT:



//           // These are NOT inside ordersAsync.when().



//           // Therefore they are ALWAYS visible.



//           // ─────────────────────────────────────────────────────────



//           Padding(



//             padding: EdgeInsets.symmetric(



//               horizontal: context.w(20),



//             ),



//             child: SizedBox(



//               height: context.h(110),



//               child: Row(



//                 children: [



//                   Expanded(



//                     child: StatCard(



//                       label: 'Pending Orders',



//                       value: '$pendingOrders orders',



//                       icon: Icons.access_time_rounded,



//                       accentColor: AppColors.primary,



//                       horizontal: true,



//                     ),



//                   ),



//                   SizedBox(width: context.w(16)),



//                   Expanded(



//                     child: StatCard(



//                       label: 'Total Orders',



//                       value: '$totalOrders orders',



//                       icon: Icons.receipt_long_outlined,



//                       accentColor: AppColors.success,



//                       horizontal: true,



//                     ),



//                   ),



//                 ],



//               ),



//             ),



//           ),



//           SizedBox(height: context.h(20)),



//           // ─────────────────────────────────────────────────────────



//           // BOTTOM ORDER BOARD



//           //



//           // IMPORTANT:



//           // The board is ALWAYS rendered.



//           // We do NOT return EmptyState when there are no orders.



//           // The four columns remain visible with "No orders".



//           // ─────────────────────────────────────────────────────────



//           Expanded(



//             child: narrow



//                 ? _buildNarrowOrders(



//                     context,



//                     colors,



//                     filteredOrders,



//                   )



//                 : _buildWideOrders(



//                     context,



//                     colors,



//                     filteredOrders,



//                   ),



//           ),



//           SizedBox(height: context.h(16)),



//         ],



//       ),



//     );



//   }



//   // ─────────────────────────────────────────────────────────────────



//   // NARROW / MOBILE



//   // ─────────────────────────────────────────────────────────────────



//   Widget _buildNarrowOrders(



//     BuildContext context,



//     AppColorScheme colors,



//     List<OrderModel> orders,



//   ) {



//     final pending =



//         orders.where((order) => order.status == OrderStatus.pending).toList();



//     final preparing =



//         orders.where((order) => order.status == OrderStatus.preparing).toList();



//     final ready =



//         orders.where((order) => order.status == OrderStatus.ready).toList();



//     final delivered =



//         orders.where((order) => order.status == OrderStatus.delivered).toList();



//     final List<OrderModel> currentOrders;



//     switch (_narrowStage) {



//       case OrderStatus.pending:



//         currentOrders = pending;



//         break;



//       case OrderStatus.preparing:



//         currentOrders = preparing;



//         break;



//       case OrderStatus.ready:



//         currentOrders = ready;



//         break;



//       case OrderStatus.delivered:



//         currentOrders = delivered;



//         break;



//       case OrderStatus.cancelled:



//         currentOrders = const [];



//         break;



//     }



//     return Column(



//       children: [



//         Padding(



//           padding: EdgeInsets.symmetric(



//             horizontal: context.w(20),



//           ),



//           child: _stageTabs(



//             context,



//             colors,



//           ),



//         ),



//         SizedBox(height: context.h(12)),



//         Expanded(



//           child: currentOrders.isEmpty



//               ? const EmptyState(



//                   message: 'No orders',



//                 )



//               : ListView.builder(



//                   padding: EdgeInsets.symmetric(



//                     horizontal: context.w(20),



//                   ),



//                   itemCount: currentOrders.length,



//                   itemBuilder: (context, index) {



//                     return LiveOrderCard(



//                       order: currentOrders[index],



//                     );



//                   },



//                 ),



//         ),



//       ],



//     );



//   }



//   // ─────────────────────────────────────────────────────────────────



//   // WIDE / DESKTOP KANBAN BOARD



//   // ─────────────────────────────────────────────────────────────────



//   Widget _buildWideOrders(



//     BuildContext context,



//     AppColorScheme colors,



//     List<OrderModel> orders,



//   ) {



//     final pending =



//         orders.where((order) => order.status == OrderStatus.pending).toList();



//     final preparing =



//         orders.where((order) => order.status == OrderStatus.preparing).toList();



//     final ready =



//         orders.where((order) => order.status == OrderStatus.ready).toList();



//     final delivered =



//         orders.where((order) => order.status == OrderStatus.delivered).toList();



//     // IMPORTANT:



//     // No "orders.isEmpty" check here.



//     //



//     // Even if all four lists are empty, all four columns are



//     // still rendered.



//     return Padding(



//       padding: EdgeInsets.symmetric(



//         horizontal: context.w(20),



//       ),



//       child: Row(



//         crossAxisAlignment: CrossAxisAlignment.stretch,



//         children: [



//           // ───────────────────────────────────────────────────────



//           // NEW



//           // ───────────────────────────────────────────────────────



//           Expanded(



//             child: _column(



//               context,



//               colors,



//               'New',



//               pending,



//               OrderStatus.pending,



//             ),



//           ),



//           SizedBox(width: context.w(14)),



//           // ───────────────────────────────────────────────────────



//           // PREPARING



//           // ───────────────────────────────────────────────────────



//           Expanded(



//             child: _column(



//               context,



//               colors,



//               'Preparing',



//               preparing,



//               OrderStatus.preparing,



//             ),



//           ),



//           SizedBox(width: context.w(14)),



//           // ───────────────────────────────────────────────────────



//           // READY



//           // ───────────────────────────────────────────────────────



//           Expanded(



//             child: _column(



//               context,



//               colors,



//               'Ready',



//               ready,



//               OrderStatus.ready,



//             ),



//           ),



//           SizedBox(width: context.w(14)),



//           // ───────────────────────────────────────────────────────



//           // DELIVERED



//           // ───────────────────────────────────────────────────────



//           Expanded(



//             child: _column(



//               context,



//               colors,



//               'Delivered',



//               delivered,



//               OrderStatus.delivered,



//             ),



//           ),



//         ],



//       ),



//     );



//   }



//   // ─────────────────────────────────────────────────────────────────



//   // TYPE FILTER CHIPS



//   // ─────────────────────────────────────────────────────────────────



//   Widget _typeFilterChips(



//     BuildContext context,



//     AppColorScheme colors,



//     List<OrderModel> orders,



//   ) {



//     final all = orders.length;



//     final eatIn = orders



//         .where(



//           (order) => order.orderType == OrderType.dineIn,



//         )



//         .length;



//     final delivery = orders



//         .where(



//           (order) => order.orderType == OrderType.delivery,



//         )



//         .length;



//     final chips = [



//       (null, 'All', all),



//       (OrderType.dineIn, 'Eat In', eatIn),



//       (OrderType.delivery, 'Delivery', delivery),



//     ];



//     return SingleChildScrollView(



//       scrollDirection: Axis.horizontal,



//       child: Row(



//         children: [



//           for (final (type, label, count) in chips) ...[



//             InkWell(



//               onTap: () {



//                 setState(() {



//                   _typeFilter = type;



//                 });



//               },



//               borderRadius: BorderRadius.circular(



//                 context.h(20),



//               ),



//               child: Container(



//                 padding: EdgeInsets.symmetric(



//                   horizontal: context.w(14),



//                   vertical: context.h(8),



//                 ),



//                 decoration: BoxDecoration(



//                   color:



//                       _typeFilter == type ? AppColors.primary : colors.surface,



//                   borderRadius: BorderRadius.circular(



//                     context.h(20),



//                   ),



//                   border: Border.all(



//                     color:



//                         _typeFilter == type ? AppColors.primary : colors.border,



//                   ),



//                 ),



//                 child: Row(



//                   mainAxisSize: MainAxisSize.min,



//                   children: [



//                     Text(



//                       label,



//                       style: AppTextStyles.label(context).copyWith(



//                         color: _typeFilter == type



//                             ? Colors.white



//                             : colors.textPrimary,



//                         fontWeight: FontWeight.w600,



//                       ),



//                     ),



//                     SizedBox(width: context.w(6)),



//                     Container(



//                       padding: EdgeInsets.symmetric(



//                         horizontal: context.w(6),



//                         vertical: context.h(1),



//                       ),



//                       decoration: BoxDecoration(



//                         color: _typeFilter == type



//                             ? Colors.white.withValues(alpha: 0.25)



//                             : colors.surfaceVariant,



//                         borderRadius: BorderRadius.circular(



//                           context.h(10),



//                         ),



//                       ),



//                       child: Text(



//                         '$count',



//                         style: AppTextStyles.caption(context).copyWith(



//                           color: _typeFilter == type



//                               ? Colors.white



//                               : colors.textSecondary,



//                         ),



//                       ),



//                     ),



//                   ],



//                 ),



//               ),



//             ),



//             SizedBox(width: context.w(8)),



//           ],



//         ],



//       ),



//     );



//   }



//   // ─────────────────────────────────────────────────────────────────



//   // NARROW STAGE TABS



//   // ─────────────────────────────────────────────────────────────────



//   Widget _stageTabs(



//     BuildContext context,



//     AppColorScheme colors,



//   ) {



//     const stages = [



//       OrderStatus.pending,



//       OrderStatus.preparing,



//       OrderStatus.ready,



//       OrderStatus.delivered,



//     ];



//     return SingleChildScrollView(



//       scrollDirection: Axis.horizontal,



//       child: Row(



//         children: [



//           for (final stage in stages) ...[



//             InkWell(



//               onTap: () {



//                 setState(() {



//                   _narrowStage = stage;



//                 });



//               },



//               borderRadius: BorderRadius.circular(



//                 context.h(20),



//               ),



//               child: Container(



//                 padding: EdgeInsets.symmetric(



//                   horizontal: context.w(14),



//                   vertical: context.h(9),



//                 ),



//                 decoration: BoxDecoration(



//                   color: _narrowStage == stage



//                       ? AppColors.primary



//                       : colors.surface,



//                   borderRadius: BorderRadius.circular(



//                     context.h(20),



//                   ),



//                   border: Border.all(



//                     color: _narrowStage == stage



//                         ? AppColors.primary



//                         : colors.border,



//                   ),



//                 ),



//                 child: Text(



//                   stage.label,



//                   style: AppTextStyles.label(context).copyWith(



//                     color: _narrowStage == stage



//                         ? Colors.white



//                         : colors.textPrimary,



//                   ),



//                 ),



//               ),



//             ),



//             SizedBox(width: context.w(8)),



//           ],



//         ],



//       ),



//     );



//   }



//   // ─────────────────────────────────────────────────────────────────



//   // ORDER COLUMN



//   // ─────────────────────────────────────────────────────────────────



//   Widget _column(



//     BuildContext context,



//     AppColorScheme colors,



//     String title,



//     List<OrderModel> orders,



//     OrderStatus status,



//   ) {



//     return Container(



//       padding: EdgeInsets.all(



//         context.h(12),



//       ),



//       decoration: BoxDecoration(



//         color: colors.surfaceVariant.withValues(



//           alpha: 0.55,



//         ),



//         borderRadius: BorderRadius.circular(



//           context.h(12),



//         ),



//         border: Border.all(



//           color: colors.border.withValues(



//             alpha: 0.6,



//           ),



//         ),



//       ),



//       child: Column(



//         crossAxisAlignment: CrossAxisAlignment.start,



//         children: [



//           // ───────────────────────────────────────────────────────



//           // COLUMN HEADER



//           // ───────────────────────────────────────────────────────



//           Row(



//             children: [



//               Text(



//                 title,



//                 style: AppTextStyles.section(context).copyWith(



//                   color: colors.textPrimary,



//                 ),



//               ),



//               SizedBox(width: context.w(8)),



//               Container(



//                 padding: EdgeInsets.symmetric(



//                   horizontal: context.w(8),



//                   vertical: context.h(2),



//                 ),



//                 decoration: BoxDecoration(



//                   color: colors.surface,



//                   borderRadius: BorderRadius.circular(



//                     context.h(10),



//                   ),



//                 ),



//                 child: Text(



//                   '${orders.length}',



//                   style: AppTextStyles.caption(context).copyWith(



//                     color: colors.textSecondary,



//                   ),



//                 ),



//               ),



//             ],



//           ),



//           SizedBox(height: context.h(12)),



//           // ───────────────────────────────────────────────────────



//           // COLUMN CONTENT



//           //



//           // Always keeps the column visible.



//           // Empty column simply displays "No orders".



//           // ───────────────────────────────────────────────────────



//           Expanded(



//             child: orders.isEmpty



//                 ? Center(



//                     child: Text(



//                       'No orders',



//                       style: AppTextStyles.bodySecondary(context).copyWith(



//                         color: colors.textMuted,



//                       ),



//                     ),



//                   )



//                 : ListView.separated(



//                     padding: EdgeInsets.zero,



//                     itemCount: orders.length,



//                     separatorBuilder: (_, __) {



//                       return SizedBox(



//                         height: context.h(8),



//                       );



//                     },



//                     itemBuilder: (context, index) {



//                       return LiveOrderCard(



//                         order: orders[index],



//                       );



//                     },



//                   ),



//           ),



//         ],



//       ),



//     );



//   }



// }and

// import 'package:flutter/material.dart';



// import 'package:flutter_riverpod/flutter_riverpod.dart';



// import 'package:rdx_admin/screens/order/checkout_screen.dart';



// import '../../core/theme/app_colors.dart';



// import '../../core/theme/text_styles.dart';



// import '../../core/utils/responsive_size.dart';



// import '../../providers/cart_provider.dart';



// import '../../providers/menu_provider.dart';



// import '../../widgets/reusable_widgets/empty_state.dart';



// import '../../widgets/reusable_widgets/loading_indicator.dart';



// import '../../widgets/reusable_widgets/rdx_header.dart';



// import '../../widgets/resuable_options/rdx_category_tabs.dart';



// import '../../widgets/resuable_options/rdx_search_bar.dart';



// import '../../widgets/resuable_options/rdx_text_field.dart';



// import 'widgets/cart_panel.dart';



// import 'widgets/order_menu_item_card.dart';



// class PlaceOrderScreen extends ConsumerStatefulWidget {



//   const PlaceOrderScreen({super.key});



//   @override



//   ConsumerState<PlaceOrderScreen> createState() => _PlaceOrderScreenState();



// }



// class _PlaceOrderScreenState extends ConsumerState<PlaceOrderScreen> {



//   @override



//   void initState() {



//     super.initState();



//     WidgetsBinding.instance.addPostFrameCallback((_) {



//       if (!mounted) return;



//       ref.read(menuNotifierProvider.notifier).load();



//     });



//   }



//   /// Moves from the active order/cart screen to checkout.



//   ///



//   /// IMPORTANT:



//   /// This does NOT create the Firestore order.



//   /// CheckoutScreen is responsible for final submission.



//   void _goToCheckout() {



//     final cart = ref.read(cartProvider);



//     if (cart.isEmpty) return;



//     Navigator.of(context).push(



//       MaterialPageRoute(



//         builder: (_) => const CheckoutScreen(),



//       ),



//     );



//   }



//   @override



//   Widget build(BuildContext context) {



//     final menuState = ref.watch(menuNotifierProvider);



//     final colors = AppColors.of(context);



//     final width = MediaQuery.sizeOf(context).width;



//     // Keep the two-column POS layout on desktop/tablet.



//     final isCompact = width < 900;



//     return Scaffold(



//       backgroundColor: colors.background,



//       body: Column(



//         children: [



//           const RdxHeader(



//             title: 'Create New Order',



//             showBackButton: true,



//           ),



//           Expanded(



//             child: menuState.isLoading



//                 ? const LoadingIndicator()



//                 : Padding(



//                     padding: Responsive.pagePadding(



//                       context,



//                       top: context.h(10),



//                       bottom: context.h(10),



//                     ),



//                     child: isCompact



//                         ? _buildCompactLayout(



//                             context,



//                             menuState,



//                             colors,



//                           )



//                         : _buildDesktopLayout(



//                             context,



//                             menuState,



//                             colors,



//                           ),



//                   ),



//           ),



//         ],



//       ),



//     );



//   }



//   // ===========================================================================



//   // DESKTOP / TABLET



//   // ===========================================================================



//   Widget _buildDesktopLayout(



//     BuildContext context,



//     MenuState menuState,



//     AppColorScheme colors,



//   ) {



//     return Row(



//       crossAxisAlignment: CrossAxisAlignment.stretch,



//       children: [



//         // ---------------------------------------------------------------------



//         // LEFT - MENU



//         // ---------------------------------------------------------------------



//         Expanded(



//           child: Padding(



//             padding: EdgeInsets.only(



//               right: context.w(14),



//             ),



//             child: _buildMenuArea(



//               context,



//               menuState,



//               colors,



//             ),



//           ),



//         ),



//         // ---------------------------------------------------------------------



//         // DIVIDER



//         // ---------------------------------------------------------------------



//         VerticalDivider(



//           width: context.w(1),



//           thickness: 1,



//           color: colors.border,



//         ),



//         // ---------------------------------------------------------------------



//         // RIGHT - ACTIVE ORDER / CART



//         // ---------------------------------------------------------------------



//         SizedBox(



//           width: context.w(350),



//           child: Padding(



//             padding: EdgeInsets.only(



//               left: context.w(14),



//             ),



//             child: CartPanel(



//               onProceed: _goToCheckout,



//             ),



//           ),



//         ),



//       ],



//     );



//   }



//   // ===========================================================================



//   // COMPACT



//   // ===========================================================================



//   Widget _buildCompactLayout(



//     BuildContext context,



//     MenuState menuState,



//     AppColorScheme colors,



//   ) {



//     return Column(



//       children: [



//         // Menu section.



//         Expanded(



//           child: _buildMenuArea(



//             context,



//             menuState,



//             colors,



//           ),



//         ),



//         SizedBox(height: context.h(12)),



//         // Cart remains on the same screen.



//         //



//         // No bottom sheet is used.



//         SizedBox(



//           height: context.h(360),



//           child: CartPanel(



//             onProceed: _goToCheckout,



//           ),



//         ),



//       ],



//     );



//   }



//   // ===========================================================================



//   // MENU AREA



//   // ===========================================================================



//   Widget _buildMenuArea(



//     BuildContext context,



//     MenuState menuState,



//     AppColorScheme colors,



//   ) {



//     final notifier = ref.read(menuNotifierProvider.notifier);



//     return Column(



//       crossAxisAlignment: CrossAxisAlignment.start,



//       children: [



//         // ---------------------------------------------------------------------



//         // ORDER TYPE + TABLE



//         // ---------------------------------------------------------------------



//         _buildOrderConfiguration(



//           context,



//           colors,



//         ),



//         SizedBox(height: context.h(10)),



//         // ---------------------------------------------------------------------



//         // SEARCH



//         // ---------------------------------------------------------------------



//         RdxSearchBar(



//           height: RdxTextField.singleLineHeight(context),



//           hintText: 'Search menu items...',



//           onChanged: notifier.setSearchQuery,



//         ),



//         SizedBox(height: context.h(10)),



//         // ---------------------------------------------------------------------



//         // CATEGORY TABS



//         // ---------------------------------------------------------------------



//         SizedBox(



//           height: context.h(38),



//           child: RdxCategoryTabs(



//             labels: menuState.categories



//                 .where((category) => category != 'All')



//                 .toList(),



//             allLabel: 'All',



//             selectedLabel: menuState.selectedCategory,



//             onSelected: notifier.setCategory,



//             expand: false,



//           ),



//         ),



//         SizedBox(height: context.h(8)),



//         // ---------------------------------------------------------------------



//         // MENU GRID



//         // ---------------------------------------------------------------------



//         Expanded(



//           child: menuState.filteredItems.isEmpty



//               ? const EmptyState(



//                   message: 'No menu items found',



//                 )



//               : GridView.builder(



//                   padding: EdgeInsets.only(



//                     bottom: context.h(4),



//                   ),



//                   gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(



//                     maxCrossAxisExtent: context.w(220),



//                     mainAxisExtent: context.h(116),



//                     mainAxisSpacing: context.h(10),



//                     crossAxisSpacing: context.w(10),



//                   ),



//                   itemCount: menuState.filteredItems.length,



//                   itemBuilder: (context, index) {



//                     return OrderMenuItemCard(



//                       item: menuState.filteredItems[index],



//                     );



//                   },



//                 ),



//         ),



//       ],



//     );



//   }



//   // ===========================================================================



//   // ORDER CONFIGURATION



//   // ===========================================================================



//   Widget _buildOrderConfiguration(



//     BuildContext context,



//     AppColorScheme colors,



//   ) {



//     return Container(



//       width: double.infinity,



//       height: context.h(48),



//       padding: EdgeInsets.symmetric(



//         horizontal: context.w(10),



//         vertical: context.h(7),



//       ),



//       decoration: BoxDecoration(



//         color: colors.surface,



//         borderRadius: BorderRadius.circular(



//           context.h(8),



//         ),



//         border: Border.all(



//           color: colors.border,



//         ),



//       ),



//       child: Row(



//         children: [



//           Text(



//             'ORDER TYPE',



//             style: AppTextStyles.caption(context).copyWith(



//               fontSize: context.h(9),



//               color: colors.textMuted,



//               fontWeight: FontWeight.w600,



//             ),



//           ),



//           SizedBox(width: context.w(7)),



//           _orderTypeChip(



//             context,



//             colors,



//             'Eat In',



//             true,



//           ),



//           SizedBox(width: context.w(5)),



//           _orderTypeChip(



//             context,



//             colors,



//             'To Go',



//             false,



//           ),



//           SizedBox(width: context.w(5)),



//           _orderTypeChip(



//             context,



//             colors,



//             'Delivery',



//             false,



//           ),



//           const Spacer(),



//           Icon(



//             Icons.table_restaurant_outlined,



//             size: context.h(13),



//             color: colors.textMuted,



//           ),



//           SizedBox(width: context.w(4)),



//           Text(



//             'Table',



//             style: AppTextStyles.caption(context).copyWith(



//               fontSize: context.h(10),



//               color: colors.textMuted,



//             ),



//           ),



//           SizedBox(width: context.w(5)),



//           Text(



//             'No Table (Counter)',



//             style: AppTextStyles.caption(context).copyWith(



//               fontSize: context.h(10),



//               color: colors.textSecondary,



//             ),



//           ),



//         ],



//       ),



//     );



//   }



//   // ===========================================================================



//   // ORDER TYPE CHIP



//   // ===========================================================================



//   Widget _orderTypeChip(



//     BuildContext context,



//     AppColorScheme colors,



//     String label,



//     bool selected,



//   ) {



//     return Container(



//       padding: EdgeInsets.symmetric(



//         horizontal: context.w(10),



//         vertical: context.h(5),



//       ),



//       decoration: BoxDecoration(



//         color: selected ? AppColors.primary : colors.surfaceVariant,



//         borderRadius: BorderRadius.circular(



//           context.h(6),



//         ),



//         border: Border.all(



//           color: selected ? AppColors.primary : colors.border,



//         ),



//       ),



//       child: Text(



//         label,



//         style: AppTextStyles.caption(context).copyWith(



//           fontSize: context.h(10),



//           color: selected ? Colors.white : colors.textPrimary,



//           fontWeight: FontWeight.w600,



//         ),



//       ),



//     );



//   }



// }and

// // import 'package:flutter/material.dart';



// // import 'package:flutter_riverpod/flutter_riverpod.dart';



// // import 'package:rdx_admin/screens/order_details/order_details_screen.dart';



// // import '../../core/theme/app_colors.dart';



// // import '../../core/theme/text_styles.dart';



// // import '../../core/utils/responsive_size.dart';



// // import '../../models/order_model.dart';



// // import '../../providers/cart_provider.dart';



// // import '../../providers/order_providers.dart';



// // import '../../widgets/buttons/rdx_action_button.dart';



// // import '../../widgets/reusable_widgets/rdx_header.dart';



// // import '../../widgets/resuable_options/rdx_dropdown.dart';



// // import '../../widgets/resuable_options/rdx_text_field.dart';



// // class CheckoutScreen extends ConsumerStatefulWidget {



// //   const CheckoutScreen({super.key});



// //   @override



// //   ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();



// // }



// // class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {



// //   final _formKey = GlobalKey<FormState>();



// //   final _customerName = TextEditingController();



// //   final _customerPhone = TextEditingController();



// //   final _tableNumber = TextEditingController();



// //   final _deliveryAddress = TextEditingController();



// //   final _orderNotes = TextEditingController();



// //   OrderType _orderType = OrderType.dineIn;



// //   PaymentMethod _paymentMethod = PaymentMethod.cash;



// //   @override



// //   void dispose() {



// //     _customerName.dispose();



// //     _customerPhone.dispose();



// //     _tableNumber.dispose();



// //     _deliveryAddress.dispose();



// //     _orderNotes.dispose();



// //     super.dispose();



// //   }



// //   Future<void> _placeOrder() async {



// //     if (!_formKey.currentState!.validate()) return;



// //     final cart = ref.read(cartProvider);



// //     if (cart.isEmpty) return;



// //     final total = ref.read(cartTotalProvider);



// //     final order = OrderModel(



// //       id: '',



// //       customerName: _customerName.text.trim(),



// //       customerPhone: _customerPhone.text.trim(),



// //       deliveryAddress:



// //           _orderType == OrderType.delivery ? _deliveryAddress.text.trim() : '',



// //       status: OrderStatus.pending,



// //       total: total,



// //       createdAt: DateTime.now(),



// //       items: [



// //         for (final line in cart)



// //           OrderItemModel(



// //             name: line.menuItem.name,



// //             quantity: line.quantity,



// //             price: line.unitPrice,



// //             spiceLevel: line.spiceLevel,



// //             addOns: line.addOns.map((a) => a.displayLabel).toList(),



// //             notes: line.notes,



// //           ),



// //       ],



// //       notes: _orderNotes.text.trim().isEmpty ? null : _orderNotes.text.trim(),



// //       orderType: _orderType,



// //       tableNumber:



// //           _orderType == OrderType.dineIn ? _tableNumber.text.trim() : null,



// //       paymentMethod: _paymentMethod,



// //     );



// //     // final success = await ref.read(placeOrderControllerProvider.notifier).submit(order);



// //     // if (!mounted) return;



// //     // if (success) {



// //     //   ref.read(cartProvider.notifier).clear();



// //     //   ScaffoldMessenger.of(context).showSnackBar(



// //     //     const SnackBar(content: Text('Order placed successfully.')),



// //     //   );



// //     //   Navigator.of(context).pop(true);



// //     // } else {



// //     //   ScaffoldMessenger.of(context).showSnackBar(



// //     //     const SnackBar(content: Text('Failed to place order. Please try again.')),



// //     //   );



// //     // }



// //     // inside _placeOrder, replace the success handling



// //     final success =



// //         await ref.read(placeOrderControllerProvider.notifier).submit(order);



// //     if (!mounted) return;



// //     final newOrderId =



// //         await ref.read(placeOrderControllerProvider.notifier).submit(order);



// //     if (!mounted) return;



// //     if (newOrderId != null && newOrderId.isNotEmpty) {



// //       ref.read(cartProvider.notifier).clear();



// //       ScaffoldMessenger.of(context).showSnackBar(



// //         const SnackBar(content: Text('Order placed successfully.')),



// //       );



// //       // Navigate to the real Bill / Order Details screen with the server ID



// //       Navigator.of(context).pushReplacement(



// //         MaterialPageRoute(



// //           builder: (_) => OrderDetailsScreen(orderId: newOrderId),



// //         ),



// //       );



// //     } else {



// //       ScaffoldMessenger.of(context).showSnackBar(



// //         const SnackBar(



// //             content: Text('Failed to place order. Please try again.')),



// //       );



// //     }



// //   }



// //   @override



// //   Widget build(BuildContext context) {



// //     final colors = AppColors.of(context);



// //     final cart = ref.watch(cartProvider);



// //     final total = ref.watch(cartTotalProvider);



// //     final placing = ref.watch(placeOrderControllerProvider).isLoading;



// //     return Scaffold(



// //       backgroundColor: colors.background,



// //       body: Column(



// //         children: [



// //           const RdxHeader(title: 'Checkout', showBackButton: true),



// //           Expanded(



// //             child: Form(



// //               key: _formKey,



// //               child: SingleChildScrollView(



// //                 padding: EdgeInsets.fromLTRB(



// //                     context.w(20), context.h(16), context.w(20), context.h(28)),



// //                 child: Column(



// //                   crossAxisAlignment: CrossAxisAlignment.start,



// //                   children: [



// //                     _panel(context, colors, 'Order Summary', [



// //                       for (final line in cart)



// //                         Padding(



// //                           padding: EdgeInsets.only(bottom: context.h(6)),



// //                           child: Row(



// //                             children: [



// //                               Expanded(



// //                                 child: Text(



// //                                   '${line.quantity}x ${line.menuItem.name}',



// //                                   style: AppTextStyles.body(context)



// //                                       .copyWith(color: colors.textPrimary),



// //                                 ),



// //                               ),



// //                               Text('₹${line.subtotal.toStringAsFixed(0)}',



// //                                   style: AppTextStyles.body(context)



// //                                       .copyWith(color: colors.textPrimary)),



// //                             ],



// //                           ),



// //                         ),



// //                       Divider(color: colors.divider, height: context.h(20)),



// //                       Row(



// //                         children: [



// //                           Text('Total',



// //                               style: AppTextStyles.section(context)



// //                                   .copyWith(color: colors.textPrimary)),



// //                           const Spacer(),



// //                           Text('₹${total.toStringAsFixed(0)}',



// //                               style: AppTextStyles.section(context)



// //                                   .copyWith(color: colors.textPrimary)),



// //                         ],



// //                       ),



// //                     ]),



// //                     SizedBox(height: context.h(16)),



// //                     _panel(context, colors, 'Customer Details', [



// //                       RdxTextField(



// //                         controller: _customerName,



// //                         label: 'Customer Name *',



// //                         hint: 'Enter customer name',



// //                         validator: (v) =>



// //                             v == null || v.trim().isEmpty ? 'Required' : null,



// //                       ),



// //                       SizedBox(height: context.h(14)),



// //                       RdxTextField(



// //                         controller: _customerPhone,



// //                         label: 'Phone Number *',



// //                         hint: 'Enter phone number',



// //                         keyboardType: TextInputType.phone,



// //                         validator: (v) =>



// //                             v == null || v.trim().isEmpty ? 'Required' : null,



// //                       ),



// //                     ]),



// //                     SizedBox(height: context.h(16)),



// //                     _panel(context, colors, 'Order Type', [



// //                       Wrap(



// //                         spacing: context.w(8),



// //                         runSpacing: context.h(8),



// //                         children: [



// //                           for (final type in OrderType.values)



// //                             ChoiceChip(



// //                               label: Text(type.label),



// //                               selected: _orderType == type,



// //                               onSelected: (_) =>



// //                                   setState(() => _orderType = type),



// //                               selectedColor:



// //                                   AppColors.primary.withValues(alpha: 0.15),



// //                               side: BorderSide(



// //                                 color: _orderType == type



// //                                     ? AppColors.primary



// //                                     : colors.border,



// //                               ),



// //                               labelStyle: AppTextStyles.label(context).copyWith(



// //                                 color: _orderType == type



// //                                     ? AppColors.primary



// //                                     : colors.textPrimary,



// //                               ),



// //                               backgroundColor: colors.surfaceVariant,



// //                             ),



// //                         ],



// //                       ),



// //                       if (_orderType == OrderType.dineIn) ...[



// //                         SizedBox(height: context.h(14)),



// //                         RdxTextField(



// //                           controller: _tableNumber,



// //                           label: 'Table Number *',



// //                           hint: 'e.g. T-04',



// //                           validator: (v) => _orderType == OrderType.dineIn &&



// //                                   (v == null || v.trim().isEmpty)



// //                               ? 'Required'



// //                               : null,



// //                         ),



// //                       ],



// //                       if (_orderType == OrderType.delivery) ...[



// //                         SizedBox(height: context.h(14)),



// //                         RdxTextField(



// //                           controller: _deliveryAddress,



// //                           label: 'Delivery Address *',



// //                           hint: 'Enter delivery address',



// //                           maxLines: 3,



// //                           validator: (v) => _orderType == OrderType.delivery &&



// //                                   (v == null || v.trim().isEmpty)



// //                               ? 'Required'



// //                               : null,



// //                         ),



// //                       ],



// //                     ]),



// //                     SizedBox(height: context.h(16)),



// //                     _panel(context, colors, 'Payment', [



// //                       RdxDropdown<PaymentMethod>(



// //                         label: 'Payment Method',



// //                         value: _paymentMethod,



// //                         items: PaymentMethod.values,



// //                         labelBuilder: (m) => m.label,



// //                         hint: 'Select payment method',



// //                         onChanged: (value) {



// //                           if (value != null)



// //                             setState(() => _paymentMethod = value);



// //                         },



// //                       ),



// //                       SizedBox(height: context.h(14)),



// //                       RdxTextField(



// //                         controller: _orderNotes,



// //                         label: 'Order Notes',



// //                         hint: 'Any overall instructions for this order',



// //                         maxLines: 3,



// //                       ),



// //                     ]),



// //                   ],



// //                 ),



// //               ),



// //             ),



// //           ),



// //           SafeArea(



// //             top: false,



// //             child: Padding(



// //               padding: EdgeInsets.fromLTRB(



// //                   context.w(20), context.h(10), context.w(20), context.h(14)),



// //               child: RdxActionButton.save(



// //                 isLoading: placing,



// //                 onPressed: cart.isEmpty ? null : _placeOrder,



// //               ),



// //             ),



// //           ),



// //         ],



// //       ),



// //     );



// //   }



// //   Widget _panel(BuildContext context, AppColorScheme colors, String title,



// //       List<Widget> children) {



// //     return Container(



// //       width: double.infinity,



// //       padding: EdgeInsets.all(context.h(14)),



// //       decoration: BoxDecoration(



// //         color: colors.surface,



// //         borderRadius: BorderRadius.circular(context.h(8)),



// //         border: Border.all(color: colors.border),



// //       ),



// //       child: Column(



// //         crossAxisAlignment: CrossAxisAlignment.start,



// //         children: [



// //           Text(title,



// //               style: AppTextStyles.section(context)



// //                   .copyWith(color: colors.textPrimary)),



// //           SizedBox(height: context.h(14)),



// //           ...children,



// //         ],



// //       ),



// //     );



// //   }



// // }



// import 'package:flutter/material.dart';



// import 'package:flutter_riverpod/flutter_riverpod.dart';



// import 'package:rdx_admin/screens/order/place_order_screen.dart';



// import 'package:rdx_admin/screens/order_details/order_details_screen.dart';



// import '../../core/theme/app_colors.dart';



// import '../../core/theme/text_styles.dart';



// import '../../core/utils/responsive_size.dart';



// import '../../models/order_model.dart';



// import '../../providers/cart_provider.dart';



// import '../../providers/order_providers.dart';



// import '../../widgets/buttons/rdx_action_button.dart';



// import '../../widgets/reusable_widgets/rdx_header.dart';



// import '../../widgets/resuable_options/rdx_dropdown.dart';



// import '../../widgets/resuable_options/rdx_text_field.dart';



// class CheckoutScreen extends ConsumerStatefulWidget {



//   const CheckoutScreen({super.key});



//   @override



//   ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();



// }



// class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {



//   final _formKey = GlobalKey<FormState>();



//   final _customerName = TextEditingController();



//   final _customerPhone = TextEditingController();



//   final _tableNumber = TextEditingController();



//   final _deliveryAddress = TextEditingController();



//   final _orderNotes = TextEditingController();



//   OrderType _orderType = OrderType.dineIn;



//   PaymentMethod _paymentMethod = PaymentMethod.cash;



//   @override



//   void dispose() {



//     _customerName.dispose();



//     _customerPhone.dispose();



//     _tableNumber.dispose();



//     _deliveryAddress.dispose();



//     _orderNotes.dispose();



//     super.dispose();



//   }



//   // Future<void> _placeOrder() async {



//   //   if (!_formKey.currentState!.validate()) return;



//   //   final cart = ref.read(cartProvider);



//   //   if (cart.isEmpty) {



//   //     ScaffoldMessenger.of(context).showSnackBar(



//   //       const SnackBar(



//   //         content: Text('Your order is empty. Please add items first.'),



//   //       ),



//   //     );



//   //     return;



//   //   }



//   //   final total = ref.read(cartTotalProvider);



//   //   final order = OrderModel(



//   //     id: '',



//   //     customerName: _customerName.text.trim(),



//   //     customerPhone: _customerPhone.text.trim(),



//   //     deliveryAddress:



//   //         _orderType == OrderType.delivery ? _deliveryAddress.text.trim() : '',



//   //     status: OrderStatus.pending,



//   //     total: total,



//   //     createdAt: DateTime.now(),



//   //     items: [



//   //       for (final line in cart)



//   //         OrderItemModel(



//   //           name: line.menuItem.name,



//   //           quantity: line.quantity,



//   //           price: line.unitPrice,



//   //           spiceLevel: line.spiceLevel,



//   //           addOns: line.addOns.map((a) => a.displayLabel).toList(),



//   //           notes: line.notes,



//   //         ),



//   //     ],



//   //     notes: _orderNotes.text.trim().isEmpty ? null : _orderNotes.text.trim(),



//   //     orderType: _orderType,



//   //     tableNumber:



//   //         _orderType == OrderType.dineIn ? _tableNumber.text.trim() : null,



//   //     paymentMethod: _paymentMethod,



//   //   );



//   //   // Submit the order only once.



//   //   final newOrderId =



//   //       await ref.read(placeOrderControllerProvider.notifier).submit(order);



//   //   if (!mounted) return;



//   //   if (newOrderId != null && newOrderId.isNotEmpty) {



//   //     ref.read(cartProvider.notifier).clear();



//   //     ScaffoldMessenger.of(context).showSnackBar(



//   //       const SnackBar(



//   //         content: Text('Order placed successfully.'),



//   //       ),



//   //     );



//   //     Navigator.of(context).pushReplacement(



//   //       MaterialPageRoute(



//   //         builder: (_) => OrderDetailsScreen(



//   //           orderId: newOrderId,



//   //         ),



//   //       ),



//   //     );



//   //   } else {



//   //     ScaffoldMessenger.of(context).showSnackBar(



//   //       const SnackBar(



//   //         content: Text(



//   //           'Failed to place order. Please try again.',



//   //         ),



//   //       ),



//   //     );



//   //   }



//   // }



//   Future<void> _placeOrder() async {



//     if (!_formKey.currentState!.validate()) return;



//     final cart = ref.read(cartProvider);



//     if (cart.isEmpty) {



//       ScaffoldMessenger.of(context).showSnackBar(



//         const SnackBar(



//           content: Text('Your order is empty. Please add items first.'),



//         ),



//       );



//       return;



//     }



//     final total = ref.read(cartTotalProvider);



//     final order = OrderModel(



//       id: '',



//       customerName: _customerName.text.trim(),



//       customerPhone: _customerPhone.text.trim(),



//       deliveryAddress:



//           _orderType == OrderType.delivery ? _deliveryAddress.text.trim() : '',



//       status: OrderStatus.pending,



//       total: total,



//       createdAt: DateTime.now(),



//       items: [



//         for (final line in cart)



//           OrderItemModel(



//             name: line.menuItem.name,



//             quantity: line.quantity,



//             price: line.unitPrice,



//             spiceLevel: line.spiceLevel,



//             addOns: line.addOns.map((addOn) => addOn.displayLabel).toList(),



//             notes: line.notes,



//           ),



//       ],



//       notes: _orderNotes.text.trim().isEmpty ? null : _orderNotes.text.trim(),



//       orderType: _orderType,



//       tableNumber:



//           _orderType == OrderType.dineIn ? _tableNumber.text.trim() : null,



//       // No payment method here.



//     );



//     try {



//       final newOrderId =



//           await ref.read(placeOrderControllerProvider.notifier).submit(order);



//       if (!mounted) return;



//       if (newOrderId == null || newOrderId.isEmpty) {



//         ScaffoldMessenger.of(context).showSnackBar(



//           const SnackBar(



//             content: Text(



//               'Failed to place order. Please try again.',



//             ),



//           ),



//         );



//         return;



//       }



//       // The order has successfully been created in Firestore.



//       ref.read(cartProvider.notifier).clear();



//       Navigator.of(context).pushReplacement(



//         MaterialPageRoute(



//           builder: (_) => OrderDetailsScreen(



//             orderId: newOrderId,



//           ),



//         ),



//       );



//     } catch (e) {



//       if (!mounted) return;



//       ScaffoldMessenger.of(context).showSnackBar(



//         const SnackBar(



//           content: Text(



//             'Failed to place order. Please try again.',



//           ),



//         ),



//       );



//     }



//   }



//   void _editOrder() {



//     Navigator.of(context).pushReplacement(



//       MaterialPageRoute(



//         builder: (_) => const PlaceOrderScreen(),



//       ),



//     );



//   }



//   @override



//   Widget build(BuildContext context) {



//     final colors = AppColors.of(context);



//     final cart = ref.watch(cartProvider);



//     final total = ref.watch(cartTotalProvider);



//     final placing = ref.watch(placeOrderControllerProvider).isLoading;



//     return Scaffold(



//       backgroundColor: colors.background,



//       body: Column(



//         children: [



//           const RdxHeader(



//             title: 'Checkout',



//             showBackButton: true,



//           ),



//           Expanded(



//             child: Form(



//               key: _formKey,



//               child: SingleChildScrollView(



//                 padding: EdgeInsets.fromLTRB(



//                   context.w(20),



//                   context.h(16),



//                   context.w(20),



//                   context.h(28),



//                 ),



//                 child: Column(



//                   crossAxisAlignment: CrossAxisAlignment.start,



//                   children: [



//                     _buildOrderSummary(



//                       context,



//                       colors,



//                       cart,



//                       total,



//                     ),



//                     SizedBox(height: context.h(16)),



//                     _panel(



//                       context,



//                       colors,



//                       'Customer Details',



//                       [



//                         RdxTextField(



//                           controller: _customerName,



//                           label: 'Customer Name(Optional)',



//                           hint: 'Enter customer name',



//                           // validator: (value) {



//                           //   if (value == null || value.trim().isEmpty) {



//                           //     return 'Required';



//                           //   }



//                           //   return null;



//                           // },



//                         ),



//                         SizedBox(height: context.h(14)),



//                         RdxTextField(



//                           controller: _customerPhone,



//                           label: 'Phone Number(Optional)',



//                           hint: 'Enter phone number',



//                           keyboardType: TextInputType.phone,



//                           // validator: (value) {



//                           //   if (value == null || value.trim().isEmpty) {



//                           //     return 'Required';



//                           //   }



//                           //   return null;



//                           // },



//                         ),



//                       ],



//                     ),



//                     SizedBox(height: context.h(16)),



//                     _panel(



//                       context,



//                       colors,



//                       'Order Type',



//                       [



//                         RdxDropdown<OrderType>(



//                           label: 'Order Type',



//                           value: _orderType,



//                           items: OrderType.values,



//                           labelBuilder: (type) => type.label,



//                           hint: 'Select order type',



//                           onChanged: (value) {



//                             if (value == null) return;



//                             setState(() {



//                               _orderType = value;



//                             });



//                           },



//                         ),



//                         if (_orderType == OrderType.dineIn) ...[



//                           SizedBox(height: context.h(14)),



//                           RdxTextField(



//                             controller: _tableNumber,



//                             label: 'Table Number *',



//                             hint: 'e.g. T-04',



//                             validator: (value) {



//                               if (_orderType == OrderType.dineIn &&



//                                   (value == null || value.trim().isEmpty)) {



//                                 return 'Required';



//                               }



//                               return null;



//                             },



//                           ),



//                         ],



//                         if (_orderType == OrderType.delivery) ...[



//                           SizedBox(height: context.h(14)),



//                           RdxTextField(



//                             controller: _deliveryAddress,



//                             label: 'Delivery Address *',



//                             hint: 'Enter delivery address',



//                             maxLines: 3,



//                             validator: (value) {



//                               if (_orderType == OrderType.delivery &&



//                                   (value == null || value.trim().isEmpty)) {



//                                 return 'Required';



//                               }



//                               return null;



//                             },



//                           ),



//                         ],



//                       ],



//                     ),



//                     SizedBox(height: context.h(16)),



//                     _panel(



//                       context,



//                       colors,



//                       'Payment',



//                       [



//                         RdxDropdown<PaymentMethod>(



//                           label: 'Payment Method',



//                           value: _paymentMethod,



//                           items: PaymentMethod.values,



//                           labelBuilder: (method) => method.label,



//                           hint: 'Select payment method',



//                           onChanged: (value) {



//                             if (value == null) return;



//                             setState(() {



//                               _paymentMethod = value;



//                             });



//                           },



//                         ),



//                         SizedBox(height: context.h(14)),



//                         RdxTextField(



//                           controller: _orderNotes,



//                           label: 'Order Notes',



//                           hint: 'Any overall instructions for this order',



//                           maxLines: 3,



//                         ),



//                       ],



//                     ),



//                   ],



//                 ),



//               ),



//             ),



//           ),



//           SafeArea(



//             top: false,



//             child: Padding(



//               padding: EdgeInsets.fromLTRB(



//                 context.w(20),



//                 context.h(10),



//                 context.w(20),



//                 context.h(14),



//               ),



//               child: RdxActionButton.save(



//                 isLoading: placing,



//                 onPressed: cart.isEmpty ? null : _placeOrder,



//               ),



//             ),



//           ),



//         ],



//       ),



//     );



//   }



//   Widget _buildOrderSummary(



//     BuildContext context,



//     AppColorScheme colors,



//     List cart,



//     double total,



//   ) {



//     return Container(



//       width: double.infinity,



//       padding: EdgeInsets.all(context.h(14)),



//       decoration: BoxDecoration(



//         color: colors.surface,



//         borderRadius: BorderRadius.circular(context.h(8)),



//         border: Border.all(



//           color: colors.border,



//         ),



//       ),



//       child: Column(



//         crossAxisAlignment: CrossAxisAlignment.start,



//         children: [



//           Row(



//             children: [



//               Expanded(



//                 child: Text(



//                   'Order Summary',



//                   style: AppTextStyles.section(context).copyWith(



//                     color: colors.textPrimary,



//                   ),



//                 ),



//               ),



//               TextButton.icon(



//                 onPressed: _editOrder,



//                 style: TextButton.styleFrom(



//                   padding: EdgeInsets.symmetric(



//                     horizontal: context.w(8),



//                     vertical: context.h(6),



//                   ),



//                   minimumSize: Size.zero,



//                   tapTargetSize: MaterialTapTargetSize.shrinkWrap,



//                 ),



//                 icon: Icon(



//                   Icons.edit_outlined,



//                   size: context.h(16),



//                   color: AppColors.primary,



//                 ),



//                 label: Text(



//                   'Edit Order',



//                   style: AppTextStyles.label(context).copyWith(



//                     color: AppColors.primary,



//                     fontWeight: FontWeight.w600,



//                   ),



//                 ),



//               ),



//             ],



//           ),



//           SizedBox(height: context.h(14)),



//           if (cart.isEmpty)



//             Text(



//               'No items in the order.',



//               style: AppTextStyles.body(context).copyWith(



//                 color: colors.textSecondary,



//               ),



//             )



//           else



//             for (final line in cart)



//               _buildSummaryItem(



//                 context,



//                 colors,



//                 line,



//               ),



//           Divider(



//             color: colors.divider,



//             height: context.h(20),



//           ),



//           Row(



//             children: [



//               Text(



//                 'Total',



//                 style: AppTextStyles.section(context).copyWith(



//                   color: colors.textPrimary,



//                 ),



//               ),



//               const Spacer(),



//               Text(



//                 '₹${total.toStringAsFixed(0)}',



//                 style: AppTextStyles.section(context).copyWith(



//                   color: AppColors.primary,



//                   fontWeight: FontWeight.w700,



//                 ),



//               ),



//             ],



//           ),



//         ],



//       ),



//     );



//   }



//   Widget _buildSummaryItem(



//     BuildContext context,



//     AppColorScheme colors,



//     dynamic line,



//   ) {



//     return Padding(



//       padding: EdgeInsets.only(



//         bottom: context.h(12),



//       ),



//       child: Column(



//         crossAxisAlignment: CrossAxisAlignment.start,



//         children: [



//           Row(



//             crossAxisAlignment: CrossAxisAlignment.start,



//             children: [



//               Expanded(



//                 child: Text(



//                   '${line.quantity}x ${line.menuItem.name}',



//                   style: AppTextStyles.body(context).copyWith(



//                     color: colors.textPrimary,



//                     fontWeight: FontWeight.w600,



//                   ),



//                 ),



//               ),



//               SizedBox(width: context.w(12)),



//               Text(



//                 '₹${line.subtotal.toStringAsFixed(0)}',



//                 style: AppTextStyles.body(context).copyWith(



//                   color: colors.textPrimary,



//                   fontWeight: FontWeight.w600,



//                 ),



//               ),



//             ],



//           ),



//           SizedBox(height: context.h(4)),



//           Text(



//             '₹${line.unitPrice.toStringAsFixed(0)} each',



//             style: AppTextStyles.caption(context).copyWith(



//               color: colors.textSecondary,



//             ),



//           ),



//           if (line.spiceLevel != null &&



//               line.spiceLevel.toString().trim().isNotEmpty) ...[



//             SizedBox(height: context.h(3)),



//             Text(



//               'Spice: ${line.spiceLevel}',



//               style: AppTextStyles.caption(context).copyWith(



//                 color: colors.textSecondary,



//               ),



//             ),



//           ],



//           if (line.addOns.isNotEmpty) ...[



//             SizedBox(height: context.h(3)),



//             Text(



//               'Add-ons: ${line.addOns.map((a) => a.displayLabel).join(', ')}',



//               style: AppTextStyles.caption(context).copyWith(



//                 color: colors.textSecondary,



//               ),



//             ),



//           ],



//           if (line.notes != null &&



//               line.notes.toString().trim().isNotEmpty) ...[



//             SizedBox(height: context.h(3)),



//             Text(



//               'Note: ${line.notes}',



//               style: AppTextStyles.caption(context).copyWith(



//                 color: colors.textSecondary,



//               ),



//             ),



//           ],



//         ],



//       ),



//     );



//   }



//   Widget _panel(



//     BuildContext context,



//     AppColorScheme colors,



//     String title,



//     List<Widget> children,



//   ) {



//     return Container(



//       width: double.infinity,



//       padding: EdgeInsets.all(



//         context.h(14),



//       ),



//       decoration: BoxDecoration(



//         color: colors.surface,



//         borderRadius: BorderRadius.circular(



//           context.h(8),



//         ),



//         border: Border.all(



//           color: colors.border,



//         ),



//       ),



//       child: Column(



//         crossAxisAlignment: CrossAxisAlignment.start,



//         children: [



//           Text(



//             title,



//             style: AppTextStyles.section(context).copyWith(



//               color: colors.textPrimary,



//             ),



//           ),



//           SizedBox(height: context.h(14)),



//           ...children,



//         ],



//       ),



//     );



//   }



// }

// when admin creating a new order and it is navigated to checkout screen via place order screen and on the checkout screen there are two buttons 