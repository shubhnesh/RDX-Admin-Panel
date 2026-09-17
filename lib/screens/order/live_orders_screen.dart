// // import 'package:flutter/material.dart';
// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import '../../core/theme/app_colors.dart';
// // import '../../core/theme/text_styles.dart';
// // import '../../core/utils/responsive_size.dart';
// // import '../../models/order_model.dart';
// // import '../../providers/order_providers.dart';
// // import '../../widgets/buttons/rdx_action_button.dart';
// // import '../../widgets/reusable_widgets/empty_state.dart';
// // import '../../widgets/reusable_widgets/rdx_header.dart';
// // import '../../widgets/reusable_widgets/stat_card.dart';
// // import 'place_order_screen.dart';
// // import 'widgets/live_order_card.dart';

// // class LiveOrdersScreen extends ConsumerStatefulWidget {
// //   const LiveOrdersScreen({super.key});

// //   @override
// //   ConsumerState<LiveOrdersScreen> createState() => _LiveOrdersScreenState();
// // }

// // class _LiveOrdersScreenState extends ConsumerState<LiveOrdersScreen> {
// //   OrderType? _typeFilter;
// //   OrderStatus _narrowStage = OrderStatus.pending;

// //   // Future<void> _openPlaceOrder() async {
// //   //   final placed = await Navigator.of(context).push<bool>(
// //   //     MaterialPageRoute(
// //   //       builder: (_) => const PlaceOrderScreen(),
// //   //     ),
// //   //   );

// //   //   if (placed == true && mounted) {
// //   //     ScaffoldMessenger.of(context).showSnackBar(
// //   //       const SnackBar(
// //   //         content: Text('New order added to the queue.'),
// //   //       ),
// //   //     );
// //   //   }
// //   // }

// //   void _refreshLiveOrders() {
// //     if (!mounted) return;

// //     ref.invalidate(liveOrdersStreamProvider);
// //   }

// //   Future<void> _openPlaceOrder() async {
// //     final placed = await Navigator.of(context).push<bool>(
// //       MaterialPageRoute(
// //         builder: (_) => const PlaceOrderScreen(),
// //       ),
// //     );

// //     if (!mounted) return;

// //     // Always refresh the live orders from Firestore
// //     // when returning to this screen.
// //     // ref.invalidate(liveOrdersStreamProvider);
// //     _refreshLiveOrders();

// //     if (placed == true) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(
// //           content: Text('New order added to the queue.'),
// //         ),
// //       );
// //     }
// //   }

// //   List<OrderModel> _filterByType(List<OrderModel> orders) {
// //     if (_typeFilter == null) {
// //       return orders;
// //     }

// //     return orders.where((order) => order.orderType == _typeFilter).toList();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final colors = AppColors.of(context);
// //     final ordersAsync = ref.watch(liveOrdersStreamProvider);
// //     final narrow = MediaQuery.sizeOf(context).width < 900;

// //     // Keep the UI visible while the stream is loading.
// //     // When data is available, this contains the current orders.
// //     final allOrders = ordersAsync.valueOrNull ?? <OrderModel>[];

// //     final filteredOrders = _filterByType(allOrders);

// //     // ─────────────────────────────────────────────────────────────
// //     // STAT COUNTS
// //     // ─────────────────────────────────────────────────────────────

// //     final totalOrders = allOrders.length;

// //     final pendingOrders = allOrders
// //         .where(
// //           (order) => order.status == OrderStatus.pending,
// //         )
// //         .length;

// //     return Scaffold(
// //       backgroundColor: colors.background,
// //       body: Column(
// //         children: [
// //           // ─────────────────────────────────────────────────────────
// //           // HEADER
// //           // ─────────────────────────────────────────────────────────

// //           const RdxHeader(
// //             title: 'Live Orders',
// //             showBackButton: false,
// //           ),

// //           // ─────────────────────────────────────────────────────────
// //           // FILTERS + NEW ORDER
// //           // ─────────────────────────────────────────────────────────

// //           Padding(
// //             padding: EdgeInsets.fromLTRB(
// //               context.w(20),
// //               context.h(12),
// //               context.w(20),
// //               0,
// //             ),
// //             child: Row(
// //               crossAxisAlignment: CrossAxisAlignment.center,
// //               children: [
// //                 Expanded(
// //                   child: _typeFilterChips(
// //                     context,
// //                     colors,
// //                     allOrders,
// //                   ),
// //                 ),
// //                 SizedBox(width: context.w(12)),
// //                 RdxActionButton(
// //                   label: 'New Order',
// //                   leadingIcon: Icons.add,
// //                   onPressed: _openPlaceOrder,
// //                 ),
// //               ],
// //             ),
// //           ),

// //           SizedBox(height: context.h(20)),

// //           // ─────────────────────────────────────────────────────────
// //           // STAT CARDS
// //           //
// //           // IMPORTANT:
// //           // These are NOT inside ordersAsync.when().
// //           // Therefore they are ALWAYS visible.
// //           // ─────────────────────────────────────────────────────────

// //           Padding(
// //             padding: EdgeInsets.symmetric(
// //               horizontal: context.w(20),
// //             ),
// //             child: SizedBox(
// //               height: context.h(110),
// //               child: Row(
// //                 children: [
// //                   Expanded(
// //                     child: StatCard(
// //                       label: 'Pending Orders',
// //                       value: '$pendingOrders orders',
// //                       icon: Icons.access_time_rounded,
// //                       accentColor: AppColors.primary,
// //                       horizontal: true,
// //                     ),
// //                   ),
// //                   SizedBox(width: context.w(16)),
// //                   Expanded(
// //                     child: StatCard(
// //                       label: 'Total Orders',
// //                       value: '$totalOrders orders',
// //                       icon: Icons.receipt_long_outlined,
// //                       accentColor: AppColors.success,
// //                       horizontal: true,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),

// //           SizedBox(height: context.h(20)),

// //           // ─────────────────────────────────────────────────────────
// //           // BOTTOM ORDER BOARD
// //           //
// //           // IMPORTANT:
// //           // The board is ALWAYS rendered.
// //           // We do NOT return EmptyState when there are no orders.
// //           // The four columns remain visible with "No orders".
// //           // ─────────────────────────────────────────────────────────

// //           Expanded(
// //             child: narrow
// //                 ? _buildNarrowOrders(
// //                     context,
// //                     colors,
// //                     filteredOrders,
// //                   )
// //                 : _buildWideOrders(
// //                     context,
// //                     colors,
// //                     filteredOrders,
// //                   ),
// //           ),

// //           SizedBox(height: context.h(16)),
// //         ],
// //       ),
// //     );
// //   }

// //   // ─────────────────────────────────────────────────────────────────
// //   // NARROW / MOBILE
// //   // ─────────────────────────────────────────────────────────────────

// //   Widget _buildNarrowOrders(
// //     BuildContext context,
// //     AppColorScheme colors,
// //     List<OrderModel> orders,
// //   ) {
// //     final pending =
// //         orders.where((order) => order.status == OrderStatus.pending).toList();

// //     final preparing =
// //         orders.where((order) => order.status == OrderStatus.preparing).toList();

// //     final ready =
// //         orders.where((order) => order.status == OrderStatus.ready).toList();

// //     final delivered =
// //         orders.where((order) => order.status == OrderStatus.delivered).toList();

// //     final List<OrderModel> currentOrders;

// //     switch (_narrowStage) {
// //       case OrderStatus.pending:
// //         currentOrders = pending;
// //         break;

// //       case OrderStatus.preparing:
// //         currentOrders = preparing;
// //         break;

// //       case OrderStatus.ready:
// //         currentOrders = ready;
// //         break;

// //       case OrderStatus.delivered:
// //         currentOrders = delivered;
// //         break;

// //       case OrderStatus.cancelled:
// //         currentOrders = const [];
// //         break;
// //     }

// //     return Column(
// //       children: [
// //         Padding(
// //           padding: EdgeInsets.symmetric(
// //             horizontal: context.w(20),
// //           ),
// //           child: _stageTabs(
// //             context,
// //             colors,
// //           ),
// //         ),
// //         SizedBox(height: context.h(12)),
// //         Expanded(
// //           child: currentOrders.isEmpty
// //               ? const EmptyState(
// //                   message: 'No orders',
// //                 )
// //               : ListView.builder(
// //                   padding: EdgeInsets.symmetric(
// //                     horizontal: context.w(20),
// //                   ),
// //                   itemCount: currentOrders.length,
// //                   itemBuilder: (context, index) {
// //                     return LiveOrderCard(
// //                       order: currentOrders[index],
// //                     );
// //                   },
// //                 ),
// //         ),
// //       ],
// //     );
// //   }

// //   // ─────────────────────────────────────────────────────────────────
// //   // WIDE / DESKTOP KANBAN BOARD
// //   // ─────────────────────────────────────────────────────────────────

// //   Widget _buildWideOrders(
// //     BuildContext context,
// //     AppColorScheme colors,
// //     List<OrderModel> orders,
// //   ) {
// //     final pending =
// //         orders.where((order) => order.status == OrderStatus.pending).toList();

// //     final preparing =
// //         orders.where((order) => order.status == OrderStatus.preparing).toList();

// //     final ready =
// //         orders.where((order) => order.status == OrderStatus.ready).toList();

// //     final delivered =
// //         orders.where((order) => order.status == OrderStatus.delivered).toList();

// //     // IMPORTANT:
// //     // No "orders.isEmpty" check here.
// //     //
// //     // Even if all four lists are empty, all four columns are
// //     // still rendered.

// //     return Padding(
// //       padding: EdgeInsets.symmetric(
// //         horizontal: context.w(20),
// //       ),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.stretch,
// //         children: [
// //           // ───────────────────────────────────────────────────────
// //           // NEW
// //           // ───────────────────────────────────────────────────────

// //           Expanded(
// //             child: _column(
// //               context,
// //               colors,
// //               'New',
// //               pending,
// //               OrderStatus.pending,
// //             ),
// //           ),

// //           SizedBox(width: context.w(14)),

// //           // ───────────────────────────────────────────────────────
// //           // PREPARING
// //           // ───────────────────────────────────────────────────────

// //           Expanded(
// //             child: _column(
// //               context,
// //               colors,
// //               'Preparing',
// //               preparing,
// //               OrderStatus.preparing,
// //             ),
// //           ),

// //           SizedBox(width: context.w(14)),

// //           // ───────────────────────────────────────────────────────
// //           // READY
// //           // ───────────────────────────────────────────────────────

// //           Expanded(
// //             child: _column(
// //               context,
// //               colors,
// //               'Ready',
// //               ready,
// //               OrderStatus.ready,
// //             ),
// //           ),

// //           SizedBox(width: context.w(14)),

// //           // ───────────────────────────────────────────────────────
// //           // DELIVERED
// //           // ───────────────────────────────────────────────────────

// //           Expanded(
// //             child: _column(
// //               context,
// //               colors,
// //               'Delivered',
// //               delivered,
// //               OrderStatus.delivered,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // ─────────────────────────────────────────────────────────────────
// //   // TYPE FILTER CHIPS
// //   // ─────────────────────────────────────────────────────────────────

// //   Widget _typeFilterChips(
// //     BuildContext context,
// //     AppColorScheme colors,
// //     List<OrderModel> orders,
// //   ) {
// //     final all = orders.length;

// //     final eatIn = orders
// //         .where(
// //           (order) => order.orderType == OrderType.dineIn,
// //         )
// //         .length;

// //     final delivery = orders
// //         .where(
// //           (order) => order.orderType == OrderType.delivery,
// //         )
// //         .length;

// //     final chips = [
// //       (null, 'All', all),
// //       (OrderType.dineIn, 'Eat In', eatIn),
// //       (OrderType.delivery, 'Delivery', delivery),
// //     ];

// //     return SingleChildScrollView(
// //       scrollDirection: Axis.horizontal,
// //       child: Row(
// //         children: [
// //           for (final (type, label, count) in chips) ...[
// //             InkWell(
// //               onTap: () {
// //                 setState(() {
// //                   _typeFilter = type;
// //                 });
// //               },
// //               borderRadius: BorderRadius.circular(
// //                 context.h(20),
// //               ),
// //               child: Container(
// //                 padding: EdgeInsets.symmetric(
// //                   horizontal: context.w(14),
// //                   vertical: context.h(8),
// //                 ),
// //                 decoration: BoxDecoration(
// //                   color:
// //                       _typeFilter == type ? AppColors.primary : colors.surface,
// //                   borderRadius: BorderRadius.circular(
// //                     context.h(20),
// //                   ),
// //                   border: Border.all(
// //                     color:
// //                         _typeFilter == type ? AppColors.primary : colors.border,
// //                   ),
// //                 ),
// //                 child: Row(
// //                   mainAxisSize: MainAxisSize.min,
// //                   children: [
// //                     Text(
// //                       label,
// //                       style: AppTextStyles.label(context).copyWith(
// //                         color: _typeFilter == type
// //                             ? Colors.white
// //                             : colors.textPrimary,
// //                         fontWeight: FontWeight.w600,
// //                       ),
// //                     ),
// //                     SizedBox(width: context.w(6)),
// //                     Container(
// //                       padding: EdgeInsets.symmetric(
// //                         horizontal: context.w(6),
// //                         vertical: context.h(1),
// //                       ),
// //                       decoration: BoxDecoration(
// //                         color: _typeFilter == type
// //                             ? Colors.white.withValues(alpha: 0.25)
// //                             : colors.surfaceVariant,
// //                         borderRadius: BorderRadius.circular(
// //                           context.h(10),
// //                         ),
// //                       ),
// //                       child: Text(
// //                         '$count',
// //                         style: AppTextStyles.caption(context).copyWith(
// //                           color: _typeFilter == type
// //                               ? Colors.white
// //                               : colors.textSecondary,
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //             SizedBox(width: context.w(8)),
// //           ],
// //         ],
// //       ),
// //     );
// //   }

// //   // ─────────────────────────────────────────────────────────────────
// //   // NARROW STAGE TABS
// //   // ─────────────────────────────────────────────────────────────────

// //   Widget _stageTabs(
// //     BuildContext context,
// //     AppColorScheme colors,
// //   ) {
// //     const stages = [
// //       OrderStatus.pending,
// //       OrderStatus.preparing,
// //       OrderStatus.ready,
// //       OrderStatus.delivered,
// //     ];

// //     return SingleChildScrollView(
// //       scrollDirection: Axis.horizontal,
// //       child: Row(
// //         children: [
// //           for (final stage in stages) ...[
// //             InkWell(
// //               onTap: () {
// //                 setState(() {
// //                   _narrowStage = stage;
// //                 });
// //               },
// //               borderRadius: BorderRadius.circular(
// //                 context.h(20),
// //               ),
// //               child: Container(
// //                 padding: EdgeInsets.symmetric(
// //                   horizontal: context.w(14),
// //                   vertical: context.h(9),
// //                 ),
// //                 decoration: BoxDecoration(
// //                   color: _narrowStage == stage
// //                       ? AppColors.primary
// //                       : colors.surface,
// //                   borderRadius: BorderRadius.circular(
// //                     context.h(20),
// //                   ),
// //                   border: Border.all(
// //                     color: _narrowStage == stage
// //                         ? AppColors.primary
// //                         : colors.border,
// //                   ),
// //                 ),
// //                 child: Text(
// //                   stage.label,
// //                   style: AppTextStyles.label(context).copyWith(
// //                     color: _narrowStage == stage
// //                         ? Colors.white
// //                         : colors.textPrimary,
// //                   ),
// //                 ),
// //               ),
// //             ),
// //             SizedBox(width: context.w(8)),
// //           ],
// //         ],
// //       ),
// //     );
// //   }

// //   // ─────────────────────────────────────────────────────────────────
// //   // ORDER COLUMN
// //   // ─────────────────────────────────────────────────────────────────

// //   Widget _column(
// //     BuildContext context,
// //     AppColorScheme colors,
// //     String title,
// //     List<OrderModel> orders,
// //     OrderStatus status,
// //   ) {
// //     return Container(
// //       padding: EdgeInsets.all(
// //         context.h(12),
// //       ),
// //       decoration: BoxDecoration(
// //         color: colors.surfaceVariant.withValues(
// //           alpha: 0.55,
// //         ),
// //         borderRadius: BorderRadius.circular(
// //           context.h(12),
// //         ),
// //         border: Border.all(
// //           color: colors.border.withValues(
// //             alpha: 0.6,
// //           ),
// //         ),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           // ───────────────────────────────────────────────────────
// //           // COLUMN HEADER
// //           // ───────────────────────────────────────────────────────

// //           Row(
// //             children: [
// //               Text(
// //                 title,
// //                 style: AppTextStyles.section(context).copyWith(
// //                   color: colors.textPrimary,
// //                 ),
// //               ),
// //               SizedBox(width: context.w(8)),
// //               Container(
// //                 padding: EdgeInsets.symmetric(
// //                   horizontal: context.w(8),
// //                   vertical: context.h(2),
// //                 ),
// //                 decoration: BoxDecoration(
// //                   color: colors.surface,
// //                   borderRadius: BorderRadius.circular(
// //                     context.h(10),
// //                   ),
// //                 ),
// //                 child: Text(
// //                   '${orders.length}',
// //                   style: AppTextStyles.caption(context).copyWith(
// //                     color: colors.textSecondary,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),

// //           SizedBox(height: context.h(12)),

// //           // ───────────────────────────────────────────────────────
// //           // COLUMN CONTENT
// //           //
// //           // Always keeps the column visible.
// //           // Empty column simply displays "No orders".
// //           // ───────────────────────────────────────────────────────

// //           Expanded(
// //             child: orders.isEmpty
// //                 ? Center(
// //                     child: Text(
// //                       'No orders',
// //                       style: AppTextStyles.bodySecondary(context).copyWith(
// //                         color: colors.textMuted,
// //                       ),
// //                     ),
// //                   )
// //                 : ListView.separated(
// //                     padding: EdgeInsets.zero,
// //                     itemCount: orders.length,
// //                     separatorBuilder: (_, __) {
// //                       return SizedBox(
// //                         height: context.h(8),
// //                       );
// //                     },
// //                     itemBuilder: (context, index) {
// //                       return LiveOrderCard(
// //                         order: orders[index],
// //                       );
// //                     },
// //                   ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

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
//   const LiveOrdersScreen({super.key});

//   @override
//   ConsumerState<LiveOrdersScreen> createState() => _LiveOrdersScreenState();
// }

// class _LiveOrdersScreenState extends ConsumerState<LiveOrdersScreen> {
//   OrderType? _typeFilter;
//   OrderStatus? _statusFilter;

//   void _refreshLiveOrders() {
//     if (!mounted) return;

//     ref.invalidate(liveOrdersStreamProvider);
//   }

//   Future<void> _openPlaceOrder() async {
//     final placed = await Navigator.of(context).push<bool>(
//       MaterialPageRoute(
//         builder: (_) => const PlaceOrderScreen(),
//       ),
//     );

//     if (!mounted) return;

//     _refreshLiveOrders();

//     if (placed == true) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('New order added to the queue.'),
//         ),
//       );
//     }
//   }

//   List<OrderModel> _filterOrders(List<OrderModel> orders) {
//     return orders.where((order) {
//       final matchesType = _typeFilter == null || order.orderType == _typeFilter;

//       final matchesStatus =
//           _statusFilter == null || order.status == _statusFilter;

//       return matchesType && matchesStatus;
//     }).toList();
//   }

//   String _statusLabel() {
//     switch (_statusFilter) {
//       case OrderStatus.pending:
//         return 'New';
//       case OrderStatus.preparing:
//         return 'Preparing';
//       case OrderStatus.ready:
//         return 'Ready';
//       case OrderStatus.delivered:
//         return 'Delivered';
//       case OrderStatus.cancelled:
//         return 'Cancelled';
//       case null:
//         return 'All';
//     }
//   }

//   OrderStatus? _statusFromLabel(String label) {
//     switch (label) {
//       case 'New':
//         return OrderStatus.pending;
//       case 'Preparing':
//         return OrderStatus.preparing;
//       case 'Ready':
//         return OrderStatus.ready;
//       case 'Delivered':
//         return OrderStatus.delivered;
//       case 'Cancelled':
//         return OrderStatus.cancelled;
//       default:
//         return null;
//     }
//   }

//   String _typeLabel() {
//     switch (_typeFilter) {
//       case OrderType.dineIn:
//         return 'Dine In';
//       case OrderType.takeaway:
//         return 'Takeaway';
//       case OrderType.delivery:
//         return 'Delivery';
//       case null:
//         return 'All';
//     }
//   }

//   OrderType? _typeFromLabel(String label) {
//     switch (label) {
//       case 'Dine In':
//         return OrderType.dineIn;
//       case 'Takeaway':
//         return OrderType.takeaway;
//       case 'Delivery':
//         return OrderType.delivery;
//       default:
//         return null;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);
//     final ordersAsync = ref.watch(liveOrdersStreamProvider);

//     final allOrders = ordersAsync.valueOrNull ?? <OrderModel>[];
//     final filteredOrders = _filterOrders(allOrders);

//     final pendingOrders =
//         allOrders.where((order) => order.status == OrderStatus.pending).length;

//     final preparingOrders = allOrders
//         .where((order) => order.status == OrderStatus.preparing)
//         .length;

//     final readyOrders =
//         allOrders.where((order) => order.status == OrderStatus.ready).length;

//     return Scaffold(
//       backgroundColor: colors.background,
//       body: SafeArea(
//         child: Padding(
//           padding: Responsive.pagePadding(
//             context,
//             top: context.h(14),
//             bottom: 0,
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const RdxHeader(
//                 title: 'Live Orders',
//                 showBackButton: false,
//               ),

//               SizedBox(height: context.h(14)),

//               // ---------------------------------------------------------
//               // FILTERS + NEW ORDER
//               // ---------------------------------------------------------
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Expanded(
//                     child: SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: Row(
//                         children: [
//                           _filterChip(
//                             context,
//                             colors,
//                             label: 'All',
//                             selected:
//                                 _typeFilter == null && _statusFilter == null,
//                             onTap: () {
//                               setState(() {
//                                 _typeFilter = null;
//                                 _statusFilter = null;
//                               });
//                             },
//                           ),
//                           SizedBox(width: context.w(8)),
//                           _filterChip(
//                             context,
//                             colors,
//                             label: 'New',
//                             selected: _statusFilter == OrderStatus.pending,
//                             onTap: () {
//                               setState(() {
//                                 _statusFilter =
//                                     _statusFilter == OrderStatus.pending
//                                         ? null
//                                         : OrderStatus.pending;
//                               });
//                             },
//                           ),
//                           SizedBox(width: context.w(8)),
//                           _filterChip(
//                             context,
//                             colors,
//                             label: 'Preparing',
//                             selected: _statusFilter == OrderStatus.preparing,
//                             onTap: () {
//                               setState(() {
//                                 _statusFilter =
//                                     _statusFilter == OrderStatus.preparing
//                                         ? null
//                                         : OrderStatus.preparing;
//                               });
//                             },
//                           ),
//                           SizedBox(width: context.w(8)),
//                           _filterChip(
//                             context,
//                             colors,
//                             label: 'Ready',
//                             selected: _statusFilter == OrderStatus.ready,
//                             onTap: () {
//                               setState(() {
//                                 _statusFilter =
//                                     _statusFilter == OrderStatus.ready
//                                         ? null
//                                         : OrderStatus.ready;
//                               });
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: context.w(12)),
//                   RdxActionButton(
//                     label: 'New Order',
//                     leadingIcon: Icons.add,
//                     onPressed: _openPlaceOrder,
//                   ),
//                 ],
//               ),

//               SizedBox(height: context.h(20)),

//               // ---------------------------------------------------------
//               // TITLE
//               // ---------------------------------------------------------
//               Text(
//                 'Live Orders',
//                 style: AppTextStyles.heading(context),
//               ),

//               SizedBox(height: context.h(4)),

//               Text(
//                 'Manage incoming orders and track their current status.',
//                 style: AppTextStyles.bodySecondary(context).copyWith(
//                   color: colors.textSecondary,
//                 ),
//               ),

//               SizedBox(height: context.h(20)),

//               // ---------------------------------------------------------
//               // SUMMARY CARDS
//               // ---------------------------------------------------------
//               SizedBox(
//                 height: context.h(110),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: StatCard(
//                         label: 'New Orders',
//                         value: '$pendingOrders orders',
//                         icon: Icons.access_time_rounded,
//                         accentColor: AppColors.primary,
//                         horizontal: true,
//                       ),
//                     ),
//                     SizedBox(width: context.w(16)),
//                     Expanded(
//                       child: StatCard(
//                         label: 'Preparing',
//                         value: '$preparingOrders orders',
//                         icon: Icons.restaurant_rounded,
//                         accentColor: AppColors.success,
//                         horizontal: true,
//                       ),
//                     ),
//                     SizedBox(width: context.w(16)),
//                     Expanded(
//                       child: StatCard(
//                         label: 'Ready',
//                         value: '$readyOrders orders',
//                         icon: Icons.check_circle_outline_rounded,
//                         accentColor: AppColors.primary,
//                         horizontal: true,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               SizedBox(height: context.h(20)),

//               // ---------------------------------------------------------
//               // ORDER CARDS
//               // ---------------------------------------------------------
//               Expanded(
//                 child: ordersAsync.isLoading && allOrders.isEmpty
//                     ? const Center(
//                         child: CircularProgressIndicator(),
//                       )
//                     : filteredOrders.isEmpty
//                         ? const EmptyState(
//                             message: 'No orders found',
//                             icon: Icons.receipt_long_outlined,
//                           )
//                         : LayoutBuilder(
//                             builder: (context, constraints) {
//                               final width = constraints.maxWidth;

//                               int columns;

//                               if (width >= 1100) {
//                                 columns = 4;
//                               } else if (width >= 800) {
//                                 columns = 3;
//                               } else if (width >= 560) {
//                                 columns = 2;
//                               } else {
//                                 columns = 1;
//                               }

//                               final spacing = context.w(16);

//                               final cardWidth = columns == 1
//                                   ? width
//                                   : (width - ((columns - 1) * spacing)) /
//                                       columns;

//                               return SingleChildScrollView(
//                                 child: Wrap(
//                                   spacing: spacing,
//                                   runSpacing: spacing,
//                                   children: filteredOrders.map((order) {
//                                     return SizedBox(
//                                       width: cardWidth,
//                                       child: LiveOrderCard(
//                                         order: order,
//                                       ),
//                                     );
//                                   }).toList(),
//                                 ),
//                               );
//                             },
//                           ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _filterChip(
//     BuildContext context,
//     AppColorScheme colors, {
//     required String label,
//     required bool selected,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(
//         context.h(20),
//       ),
//       child: Container(
//         padding: EdgeInsets.symmetric(
//           horizontal: context.w(14),
//           vertical: context.h(8),
//         ),
//         decoration: BoxDecoration(
//           color: selected ? AppColors.primary : colors.surface,
//           borderRadius: BorderRadius.circular(
//             context.h(20),
//           ),
//           border: Border.all(
//             color: selected ? AppColors.primary : colors.border,
//           ),
//         ),
//         child: Text(
//           label,
//           style: AppTextStyles.label(context).copyWith(
//             color: selected ? Colors.white : colors.textPrimary,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/order_model.dart';
import '../../providers/order_providers.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/empty_state.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';
import '../../widgets/reusable_widgets/stat_card.dart';

import 'place_order_screen.dart';
import 'widgets/live_order_card.dart';

class LiveOrdersScreen extends ConsumerStatefulWidget {
  const LiveOrdersScreen({super.key});

  @override
  ConsumerState<LiveOrdersScreen> createState() => _LiveOrdersScreenState();
}

class _LiveOrdersScreenState extends ConsumerState<LiveOrdersScreen> {
  OrderType? _typeFilter;

  /// null = All
  /// pending = New
  /// preparing = Preparing
  /// ready = Ready
  OrderStatus? _statusFilter;

  Future<void> _openPlaceOrder() async {
    final placed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PlaceOrderScreen(),
      ),
    );

    if (!mounted) return;

    // The Firestore stream is already reactive.
    // Invalidating here also guarantees a fresh provider read
    // when returning from the order flow.
    ref.invalidate(liveOrdersStreamProvider);

    if (placed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New order added to the queue.'),
        ),
      );
    }
  }

  List<OrderModel> _filterOrders(
    List<OrderModel> orders,
  ) {
    return orders.where((order) {
      final matchesType = _typeFilter == null || order.orderType == _typeFilter;

      final matchesStatus =
          _statusFilter == null || order.status == _statusFilter;

      return matchesType && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    // final ordersAsync = ref.watch(liveOrdersStreamProvider);

    // final allOrders = ordersAsync.valueOrNull ?? const <OrderModel>[];

    final ordersAsync = ref.watch(liveOrdersStreamProvider);

    final allOrders = ordersAsync.valueOrNull ?? <OrderModel>[];

    if (ordersAsync.hasError) {
      debugPrint(
        'Live orders stream error: ${ordersAsync.error}',
      );
    }
    final visibleOrders = _filterOrders(allOrders);

    final newOrders = allOrders
        .where(
          (order) => order.status == OrderStatus.pending,
        )
        .toList();

    final preparingOrders = allOrders
        .where(
          (order) => order.status == OrderStatus.preparing,
        )
        .toList();

    final readyOrders = allOrders
        .where(
          (order) => order.status == OrderStatus.ready,
        )
        .toList();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: Responsive.pagePadding(
            context,
            top: context.h(0),
            bottom: context.h(0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================================================
              // HEADER
              // =========================================================
              const RdxHeader(
                title: 'Live Orders',
                showBackButton: false,
              ),

              SizedBox(height: context.h(8)),

              // =========================================================
              // FILTERS + NEW ORDER
              // =========================================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildStatusTabs(
                      context,
                      colors,
                    ),
                  ),
                  SizedBox(width: context.w(16)),
                  RdxActionButton(
                    label: 'New Order',
                    leadingIcon: Icons.add,
                    onPressed: _openPlaceOrder,
                  ),
                ],
              ),

              SizedBox(height: context.h(18)),

              // =========================================================
              // PAGE TITLE
              // =========================================================
              Text(
                'Live Orders',
                style: AppTextStyles.heading(context),
              ),

              SizedBox(height: context.h(4)),

              Text(
                'Manage incoming orders and track their current status.',
                style: AppTextStyles.bodySecondary(context).copyWith(
                  color: colors.textSecondary,
                ),
              ),

              SizedBox(height: context.h(18)),

              // =========================================================
              // SUMMARY CARDS
              // =========================================================
              _buildSummaryCards(
                context,
                colors,
                newCount: newOrders.length,
                preparingCount: preparingOrders.length,
                readyCount: readyOrders.length,
              ),

              SizedBox(height: context.h(18)),

              // =========================================================
              // ORDER LIST
              // =========================================================
              Expanded(
                child: ordersAsync.when(
                  loading: () {
                    // Keep the layout clean while Firestore is loading.
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                  error: (error, stackTrace) {
                    return _buildErrorState(
                      context,
                      colors,
                    );
                  },
                  data: (_) {
                    if (visibleOrders.isEmpty) {
                      return const EmptyState(
                        message: 'No orders found',
                        icon: Icons.receipt_long_outlined,
                      );
                    }

                    return _buildOrderGrid(
                      context,
                      colors,
                      visibleOrders,
                    );
                  },
                ),
              ),

              SizedBox(height: context.h(4)),
            ],
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // STATUS TABS
  // ===================================================================

  Widget _buildStatusTabs(
    BuildContext context,
    AppColorScheme colors,
  ) {
    final tabs = [
      const _OrderFilterTab(
        label: 'All',
        status: null,
      ),
      const _OrderFilterTab(
        label: 'New',
        status: OrderStatus.pending,
      ),
      const _OrderFilterTab(
        label: 'Preparing',
        status: OrderStatus.preparing,
      ),
      const _OrderFilterTab(
        label: 'Ready',
        status: OrderStatus.ready,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in tabs) ...[
            _buildFilterChip(
              context,
              colors,
              label: tab.label,
              selected: _statusFilter == tab.status,
              onTap: () {
                setState(() {
                  _statusFilter = tab.status;
                });
              },
            ),
            SizedBox(width: context.w(8)),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    AppColorScheme colors, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          context.h(20),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: EdgeInsets.symmetric(
            horizontal: context.w(15),
            vertical: context.h(8),
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : colors.surface,
            borderRadius: BorderRadius.circular(
              context.h(20),
            ),
            border: Border.all(
              color: selected ? AppColors.primary : colors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.label(context).copyWith(
              color: selected ? Colors.white : colors.textPrimary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // SUMMARY CARDS
  // ===================================================================

  Widget _buildSummaryCards(
    BuildContext context,
    AppColorScheme colors, {
    required int newCount,
    required int preparingCount,
    required int readyCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 700;

        if (narrow) {
          return Column(
            children: [
              _summaryCard(
                context,
                label: 'New Orders',
                value: '$newCount orders',
                icon: Icons.access_time_rounded,
                accentColor: AppColors.primary,
              ),
              SizedBox(height: context.h(10)),
              _summaryCard(
                context,
                label: 'Preparing',
                value: '$preparingCount orders',
                icon: Icons.restaurant_rounded,
                accentColor: AppColors.success,
              ),
              SizedBox(height: context.h(10)),
              _summaryCard(
                context,
                label: 'Ready',
                value: '$readyCount orders',
                icon: Icons.check_circle_outline_rounded,
                accentColor: AppColors.primary,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _summaryCard(
                context,
                label: 'New Orders',
                value: '$newCount orders',
                icon: Icons.access_time_rounded,
                accentColor: AppColors.primary,
              ),
            ),
            SizedBox(width: context.w(16)),
            Expanded(
              child: _summaryCard(
                context,
                label: 'Preparing',
                value: '$preparingCount orders',
                icon: Icons.restaurant_rounded,
                accentColor: AppColors.success,
              ),
            ),
            SizedBox(width: context.w(16)),
            Expanded(
              child: _summaryCard(
                context,
                label: 'Ready',
                value: '$readyCount orders',
                icon: Icons.check_circle_outline_rounded,
                accentColor: AppColors.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return StatCard(
      label: label,
      value: value,
      icon: icon,
      accentColor: accentColor,
      horizontal: true,
    );
  }

  // ===================================================================
  // ORDER GRID
  // ===================================================================

  Widget _buildOrderGrid(
    BuildContext context,
    AppColorScheme colors,
    List<OrderModel> orders,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns;

        if (width >= 1050) {
          columns = 4;
        } else if (width >= 760) {
          columns = 3;
        } else if (width >= 500) {
          columns = 2;
        } else {
          columns = 1;
        }

        const spacing = 16.0;

        final cardWidth = columns == 1
            ? width
            : (width - ((columns - 1) * spacing)) / columns;

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: context.h(24),
          ),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final order in orders)
                SizedBox(
                  width: cardWidth,
                  child: LiveOrderCard(
                    order: order,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ===================================================================
  // ERROR STATE
  // ===================================================================

  Widget _buildErrorState(
    BuildContext context,
    AppColorScheme colors,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: context.w(48),
            height: context.w(48),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(
                context.h(12),
              ),
            ),
            child: Icon(
              Icons.cloud_off_outlined,
              color: AppColors.danger,
              size: context.w(24),
            ),
          ),
          SizedBox(height: context.h(12)),
          Text(
            'Unable to load orders',
            style: AppTextStyles.section(context).copyWith(
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: context.h(5)),
          Text(
            'Please check your connection and try again.',
            style: AppTextStyles.bodySecondary(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: context.h(14)),
          RdxActionButton(
            label: 'Refresh',
            leadingIcon: Icons.refresh_rounded,
            onPressed: () {
              ref.invalidate(liveOrdersStreamProvider);
            },
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// FILTER TAB MODEL
// =====================================================================

class _OrderFilterTab {
  final String label;
  final OrderStatus? status;

  const _OrderFilterTab({
    required this.label,
    required this.status,
  });
}
