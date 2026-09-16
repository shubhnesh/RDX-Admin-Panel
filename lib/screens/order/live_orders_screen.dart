// // import 'package:flutter/material.dart';
// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import '../../core/theme/app_colors.dart';
// // import '../../core/theme/text_styles.dart';
// // import '../../core/utils/responsive_size.dart';
// // import '../../models/order_model.dart';
// // import '../../providers/order_providers.dart';
// // import '../../widgets/buttons/rdx_action_button.dart';
// // import '../../widgets/reusable_widgets/empty_state.dart';
// // import '../../widgets/reusable_widgets/loading_indicator.dart';
// // import '../../widgets/reusable_widgets/rdx_header.dart';
// // import 'place_order_screen.dart';
// // import 'widgets/live_order_card.dart';

// // class LiveOrdersScreen extends ConsumerStatefulWidget {
// //   const LiveOrdersScreen({super.key});

// //   @override
// //   ConsumerState<LiveOrdersScreen> createState() => _LiveOrdersScreenState();
// // }

// // class _LiveOrdersScreenState extends ConsumerState<LiveOrdersScreen> {
// //   /// null = All
// //   OrderType? _typeFilter;
// //   OrderStatus _narrowStage = OrderStatus.pending;

// //   Future<void> _openPlaceOrder() async {
// //     final placed = await Navigator.of(context).push<bool>(
// //       MaterialPageRoute(builder: (_) => const PlaceOrderScreen()),
// //     );
// //     if (placed == true && mounted) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('New order added to the queue.')),
// //       );
// //     }
// //   }

// //   List<OrderModel> _filterByType(List<OrderModel> orders) {
// //     if (_typeFilter == null) return orders;
// //     return orders.where((o) => o.orderType == _typeFilter).toList();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final colors = AppColors.of(context);
// //     final ordersAsync = ref.watch(liveOrdersStreamProvider);
// //     final narrow = MediaQuery.sizeOf(context).width < 900;

// //     return Scaffold(
// //       backgroundColor: colors.background,
// //       body: Column(
// //         children: [
// //           const RdxHeader(title: 'Live Orders', showBackButton: false),
// //           // ── type filter row + New Order button ─────────────────────
// //           Padding(
// //             padding: EdgeInsets.fromLTRB(
// //                 context.w(20), context.h(12), context.w(20), 0),
// //             child: Row(
// //               children: [
// //                 Expanded(
// //                   child: ordersAsync.when(
// //                     data: (orders) => _typeFilterChips(context, colors, orders),
// //                     loading: () => const SizedBox.shrink(),
// //                     error: (_, __) => const SizedBox.shrink(),
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
// //           SizedBox(height: context.h(14)),
// //           // ── board ──────────────────────────────────────────────────
// //           Expanded(
// //             child: ordersAsync.when(
// //               loading: () => const LoadingIndicator(),
// //               error: (err, _) =>
// //                   const EmptyState(message: 'Failed to load live orders.'),
// //               data: (allOrders) {
// //                 final orders = _filterByType(allOrders);
// //                 if (orders.isEmpty) {
// //                   return const EmptyState(message: 'No live orders right now.');
// //                 }

// //                 final pending = orders
// //                     .where((o) => o.status == OrderStatus.pending)
// //                     .toList();
// //                 final preparing = orders
// //                     .where((o) => o.status == OrderStatus.preparing)
// //                     .toList();
// //                 final ready =
// //                     orders.where((o) => o.status == OrderStatus.ready).toList();
// //                 final delivered = orders
// //                     .where((o) => o.status == OrderStatus.delivered)
// //                     .toList();

// //                 if (narrow) {
// //                   final list = switch (_narrowStage) {
// //                     OrderStatus.pending => pending,
// //                     OrderStatus.preparing => preparing,
// //                     OrderStatus.ready => ready,
// //                     OrderStatus.delivered => delivered,
// //                     _ => <OrderModel>[],
// //                   };
// //                   return Column(
// //                     children: [
// //                       Padding(
// //                         padding:
// //                             EdgeInsets.symmetric(horizontal: context.w(20)),
// //                         child: _stageTabs(context, colors),
// //                       ),
// //                       SizedBox(height: context.h(12)),
// //                       Expanded(
// //                         child: list.isEmpty
// //                             ? EmptyState(
// //                                 message:
// //                                     'No ${_narrowStage.label.toLowerCase()} orders.')
// //                             : ListView(
// //                                 padding: EdgeInsets.symmetric(
// //                                     horizontal: context.w(20)),
// //                                 children: [
// //                                   for (final o in list) LiveOrderCard(order: o),
// //                                 ],
// //                               ),
// //                       ),
// //                     ],
// //                   );
// //                 }

// //                 // wide: 4-column kanban
// //                 return Padding(
// //                   padding: EdgeInsets.symmetric(horizontal: context.w(20)),
// //                   child: Row(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Expanded(
// //                           child: _column(context, colors, 'New', pending,
// //                               OrderStatus.pending)),
// //                       SizedBox(width: context.w(14)),
// //                       Expanded(
// //                           child: _column(context, colors, 'Preparing',
// //                               preparing, OrderStatus.preparing)),
// //                       SizedBox(width: context.w(14)),
// //                       Expanded(
// //                           child: _column(context, colors, 'Ready', ready,
// //                               OrderStatus.ready)),
// //                       SizedBox(width: context.w(14)),
// //                       Expanded(
// //                           child: _column(context, colors, 'Delivered',
// //                               delivered, OrderStatus.delivered)),
// //                     ],
// //                   ),
// //                 );
// //               },
// //             ),
// //           ),
// //           SizedBox(height: context.h(16)),
// //         ],
// //       ),
// //     );
// //   }

// //   // ── type filter chips (All / Eat In / To Go / Delivery) ────────────
// //   Widget _typeFilterChips(
// //       BuildContext context, AppColorScheme colors, List<OrderModel> orders) {
// //     final all = orders.length;
// //     final eatIn = orders.where((o) => o.orderType == OrderType.dineIn).length;
// //     // final toGo = orders.where((o) => o.orderType == OrderType.takeaway).length;
// //     final delivery =
// //         orders.where((o) => o.orderType == OrderType.delivery).length;

// //     final chips = [
// //       (null, 'All', all),
// //       (OrderType.dineIn, 'Eat In', eatIn),
// //       // (OrderType.takeaway, 'To Go', toGo),
// //       (OrderType.delivery, 'Delivery', delivery),
// //     ];

// //     return SingleChildScrollView(
// //       scrollDirection: Axis.horizontal,
// //       child: Row(
// //         children: [
// //           for (final (type, label, count) in chips) ...[
// //             InkWell(
// //               onTap: () => setState(() => _typeFilter = type),
// //               borderRadius: BorderRadius.circular(context.h(20)),
// //               child: Container(
// //                 padding: EdgeInsets.symmetric(
// //                     horizontal: context.w(14), vertical: context.h(8)),
// //                 decoration: BoxDecoration(
// //                   color:
// //                       _typeFilter == type ? AppColors.primary : colors.surface,
// //                   borderRadius: BorderRadius.circular(context.h(20)),
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
// //                           horizontal: context.w(6), vertical: context.h(1)),
// //                       decoration: BoxDecoration(
// //                         color: _typeFilter == type
// //                             ? Colors.white.withValues(alpha: 0.25)
// //                             : colors.surfaceVariant,
// //                         borderRadius: BorderRadius.circular(context.h(10)),
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

// //   // ── narrow stage tabs ──────────────────────────────────────────────
// //   Widget _stageTabs(BuildContext context, AppColorScheme colors) {
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
// //               onTap: () => setState(() => _narrowStage = stage),
// //               borderRadius: BorderRadius.circular(context.h(20)),
// //               child: Container(
// //                 padding: EdgeInsets.symmetric(
// //                     horizontal: context.w(14), vertical: context.h(9)),
// //                 decoration: BoxDecoration(
// //                   color: _narrowStage == stage
// //                       ? AppColors.primary
// //                       : colors.surface,
// //                   borderRadius: BorderRadius.circular(context.h(20)),
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

// //   // ── status column ──────────────────────────────────────────────────
// //   Widget _column(
// //     BuildContext context,
// //     AppColorScheme colors,
// //     String title,
// //     List<OrderModel> orders,
// //     OrderStatus status,
// //   ) {
// //     return Container(
// //       padding: EdgeInsets.all(context.h(12)),
// //       decoration: BoxDecoration(
// //         color: colors.surfaceVariant.withValues(alpha: 0.55),
// //         borderRadius: BorderRadius.circular(context.h(12)),
// //         border: Border.all(color: colors.border.withValues(alpha: 0.6)),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             children: [
// //               Text(
// //                 title,
// //                 style: AppTextStyles.section(context)
// //                     .copyWith(color: colors.textPrimary),
// //               ),
// //               SizedBox(width: context.w(8)),
// //               Container(
// //                 padding: EdgeInsets.symmetric(
// //                     horizontal: context.w(8), vertical: context.h(2)),
// //                 decoration: BoxDecoration(
// //                   color: colors.surface,
// //                   borderRadius: BorderRadius.circular(context.h(10)),
// //                 ),
// //                 child: Text(
// //                   '${orders.length}',
// //                   style: AppTextStyles.caption(context)
// //                       .copyWith(color: colors.textSecondary),
// //                 ),
// //               ),
// //             ],
// //           ),
// //           SizedBox(height: context.h(12)),
// //           Expanded(
// //             child: orders.isEmpty
// //                 ? Center(
// //                     child: Text(
// //                       'No orders',
// //                       style: AppTextStyles.bodySecondary(context)
// //                           .copyWith(color: colors.textMuted),
// //                     ),
// //                   )
// //                 : ListView(
// //                     children: [
// //                       for (final order in orders) LiveOrderCard(order: order),
// //                     ],
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
// import '../../widgets/reusable_widgets/loading_indicator.dart';
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
//   /// null = All
//   OrderType? _typeFilter;

//   OrderStatus _narrowStage = OrderStatus.pending;

//   Future<void> _openPlaceOrder() async {
//     final placed = await Navigator.of(context).push<bool>(
//       MaterialPageRoute(
//         builder: (_) => const PlaceOrderScreen(),
//       ),
//     );

//     if (placed == true && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('New order added to the queue.'),
//         ),
//       );
//     }
//   }

//   List<OrderModel> _filterByType(List<OrderModel> orders) {
//     if (_typeFilter == null) return orders;

//     return orders.where((o) => o.orderType == _typeFilter).toList();
//   }

//   // @override
//   // Widget build(BuildContext context) {
//   //   final colors = AppColors.of(context);
//   //   final ordersAsync = ref.watch(liveOrdersStreamProvider);
//   //   final narrow = MediaQuery.sizeOf(context).width < 900;

//   //   return Scaffold(
//   //     backgroundColor: colors.background,
//   //     body: Column(
//   //       children: [
//   //         const RdxHeader(
//   //           title: 'Live Orders',
//   //           showBackButton: false,
//   //         ),

//   //         // ── Type filter row + New Order button ─────────────────────
//   //         Padding(
//   //           padding: EdgeInsets.fromLTRB(
//   //             context.w(20),
//   //             context.h(12),
//   //             context.w(20),
//   //             0,
//   //           ),
//   //           child: Row(
//   //             children: [
//   //               Expanded(
//   //                 child: ordersAsync.when(
//   //                   data: (orders) => _typeFilterChips(context, colors, orders),
//   //                   loading: () => const SizedBox.shrink(),
//   //                   error: (_, __) => const SizedBox.shrink(),
//   //                 ),
//   //               ),
//   //               SizedBox(width: context.w(12)),
//   //               RdxActionButton(
//   //                 label: 'New Order',
//   //                 leadingIcon: Icons.add,
//   //                 onPressed: _openPlaceOrder,
//   //               ),
//   //             ],
//   //           ),
//   //         ),

//   //         SizedBox(height: context.h(14)),

//   //         // ── Content ────────────────────────────────────────────────
//   //         Expanded(
//   //           child: ordersAsync.when(
//   //             loading: () => const LoadingIndicator(),
//   //             error: (err, _) => const EmptyState(
//   //               message: 'Failed to load live orders.',
//   //             ),
//   //             data: (allOrders) {
//   //               // Stats are based on ALL live orders.
//   //               // They intentionally do not change when Eat In / Delivery
//   //               // filter is selected.
//   //               final totalOrders = allOrders.length;

//   //               final pendingOrders = allOrders
//   //                   .where(
//   //                     (order) => order.status == OrderStatus.pending,
//   //                   )
//   //                   .length;

//   //               final orders = _filterByType(allOrders);

//   //               return Column(
//   //                 crossAxisAlignment: CrossAxisAlignment.stretch,
//   //                 children: [
//   //                   // ── Summary stat cards ──────────────────────────
//   //                   Padding(
//   //                     padding: EdgeInsets.symmetric(
//   //                       horizontal: context.w(20),
//   //                     ),
//   //                     child: IntrinsicHeight(
//   //                       child: Row(
//   //                         crossAxisAlignment: CrossAxisAlignment.stretch,
//   //                         children: [
//   //                           Expanded(
//   //                             child: StatCard(
//   //                               label: 'Pending Orders',
//   //                               value: '$pendingOrders orders',
//   //                               icon: Icons.pending_actions_outlined,
//   //                               accentColor: AppColors.primary,
//   //                             ),
//   //                           ),
//   //                           SizedBox(width: context.w(16)),
//   //                           Expanded(
//   //                             child: StatCard(
//   //                               label: 'Total Orders',
//   //                               value: '$totalOrders orders',
//   //                               icon: Icons.receipt_long_outlined,
//   //                               accentColor: AppColors.success,
//   //                             ),
//   //                           ),
//   //                         ],
//   //                       ),
//   //                     ),
//   //                   ),

//   //                   SizedBox(height: context.h(20)),

//   //                   // ── Actual orders section ───────────────────────
//   //                   Expanded(
//   //                     child: orders.isEmpty
//   //                         ? const EmptyState(
//   //                             message: 'No live orders right now.',
//   //                           )
//   //                         : narrow
//   //                             ? _buildNarrowOrders(
//   //                                 context,
//   //                                 colors,
//   //                                 orders,
//   //                               )
//   //                             : _buildWideOrders(
//   //                                 context,
//   //                                 colors,
//   //                                 orders,
//   //                               ),
//   //                   ),
//   //                 ],
//   //               );
//   //             },
//   //           ),
//   //         ),

//   //         SizedBox(height: context.h(16)),
//   //       ],
//   //     ),
//   //   );
//   // }

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);
//     final ordersAsync = ref.watch(liveOrdersStreamProvider);
//     final narrow = MediaQuery.sizeOf(context).width < 900;

//     return Scaffold(
//       backgroundColor: colors.background,
//       body: Column(
//         children: [
//           const RdxHeader(
//             title: 'Live Orders',
//             showBackButton: false,
//           ),

//           // ── Type filter row + New Order button ─────────────────────
//           Padding(
//             padding: EdgeInsets.fromLTRB(
//               context.w(20),
//               context.h(12),
//               context.w(20),
//               0,
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: ordersAsync.when(
//                     data: (orders) => _typeFilterChips(context, colors, orders),
//                     loading: () => const SizedBox.shrink(),
//                     error: (_, __) => const SizedBox.shrink(),
//                   ),
//                 ),
//                 SizedBox(width: context.w(12)),
//                 RdxActionButton(
//                   label: 'New Order',
//                   leadingIcon: Icons.add,
//                   onPressed: _openPlaceOrder,
//                 ),
//               ],
//             ),
//           ),

//           SizedBox(height: context.h(16)),

//           // ── Summary Stat Cards ─────────────────────────────────────
//           ordersAsync.when(
//             data: (allOrders) {
//               final totalOrders = allOrders.length;

//               final pendingOrders = allOrders
//                   .where(
//                     (order) => order.status == OrderStatus.pending,
//                   )
//                   .length;

//               return Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: context.w(20),
//                 ),
//                 child: IntrinsicHeight(
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       Expanded(
//                         child: StatCard(
//                           label: 'Pending Orders',
//                           value: '$pendingOrders orders',
//                           icon: Icons.pending_actions_outlined,
//                           accentColor: AppColors.primary,
//                         ),
//                       ),
//                       SizedBox(width: context.w(16)),
//                       Expanded(
//                         child: StatCard(
//                           label: 'Total Orders',
//                           value: '$totalOrders orders',
//                           icon: Icons.receipt_long_outlined,
//                           accentColor: AppColors.success,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//             loading: () => const SizedBox.shrink(),
//             error: (_, __) => const SizedBox.shrink(),
//           ),

//           SizedBox(height: context.h(20)),

//           // ── Actual Orders ──────────────────────────────────────────
//           Expanded(
//             child: ordersAsync.when(
//               loading: () => const LoadingIndicator(),
//               error: (_, __) => const EmptyState(
//                 message: 'Failed to load live orders.',
//               ),
//               data: (allOrders) {
//                 final orders = _filterByType(allOrders);

//                 if (orders.isEmpty) {
//                   return const EmptyState(
//                     message: 'No live orders right now.',
//                   );
//                 }

//                 final pending = orders
//                     .where(
//                       (o) => o.status == OrderStatus.pending,
//                     )
//                     .toList();

//                 final preparing = orders
//                     .where(
//                       (o) => o.status == OrderStatus.preparing,
//                     )
//                     .toList();

//                 final ready = orders
//                     .where(
//                       (o) => o.status == OrderStatus.ready,
//                     )
//                     .toList();

//                 final delivered = orders
//                     .where(
//                       (o) => o.status == OrderStatus.delivered,
//                     )
//                     .toList();

//                 // ── Mobile / narrow layout ─────────────────────────
//                 if (narrow) {
//                   final list = switch (_narrowStage) {
//                     OrderStatus.pending => pending,
//                     OrderStatus.preparing => preparing,
//                     OrderStatus.ready => ready,
//                     OrderStatus.delivered => delivered,
//                     _ => <OrderModel>[],
//                   };

//                   return Column(
//                     children: [
//                       Padding(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: context.w(20),
//                         ),
//                         child: _stageTabs(context, colors),
//                       ),
//                       SizedBox(height: context.h(12)),
//                       Expanded(
//                         child: list.isEmpty
//                             ? EmptyState(
//                                 message:
//                                     'No ${_narrowStage.label.toLowerCase()} orders.',
//                               )
//                             : ListView(
//                                 padding: EdgeInsets.symmetric(
//                                   horizontal: context.w(20),
//                                 ),
//                                 children: [
//                                   for (final order in list)
//                                     LiveOrderCard(order: order),
//                                 ],
//                               ),
//                       ),
//                     ],
//                   );
//                 }

//                 // ── Wide / desktop Kanban layout ───────────────────
//                 return Padding(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: context.w(20),
//                   ),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: _column(
//                           context,
//                           colors,
//                           'New',
//                           pending,
//                           OrderStatus.pending,
//                         ),
//                       ),
//                       SizedBox(width: context.w(14)),
//                       Expanded(
//                         child: _column(
//                           context,
//                           colors,
//                           'Preparing',
//                           preparing,
//                           OrderStatus.preparing,
//                         ),
//                       ),
//                       SizedBox(width: context.w(14)),
//                       Expanded(
//                         child: _column(
//                           context,
//                           colors,
//                           'Ready',
//                           ready,
//                           OrderStatus.ready,
//                         ),
//                       ),
//                       SizedBox(width: context.w(14)),
//                       Expanded(
//                         child: _column(
//                           context,
//                           colors,
//                           'Delivered',
//                           delivered,
//                           OrderStatus.delivered,
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),

//           SizedBox(height: context.h(16)),
//         ],
//       ),
//     );
//   }

//   // ── Narrow orders ─────────────────────────────────────────────────

//   Widget _buildNarrowOrders(
//     BuildContext context,
//     AppColorScheme colors,
//     List<OrderModel> orders,
//   ) {
//     final pending =
//         orders.where((o) => o.status == OrderStatus.pending).toList();

//     final preparing =
//         orders.where((o) => o.status == OrderStatus.preparing).toList();

//     final ready = orders.where((o) => o.status == OrderStatus.ready).toList();

//     final delivered =
//         orders.where((o) => o.status == OrderStatus.delivered).toList();

//     final list = switch (_narrowStage) {
//       OrderStatus.pending => pending,
//       OrderStatus.preparing => preparing,
//       OrderStatus.ready => ready,
//       OrderStatus.delivered => delivered,
//       _ => <OrderModel>[],
//     };

//     return Column(
//       children: [
//         Padding(
//           padding: EdgeInsets.symmetric(
//             horizontal: context.w(20),
//           ),
//           child: _stageTabs(context, colors),
//         ),
//         SizedBox(height: context.h(12)),
//         Expanded(
//           child: list.isEmpty
//               ? EmptyState(
//                   message: 'No ${_narrowStage.label.toLowerCase()} orders.',
//                 )
//               : ListView(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: context.w(20),
//                   ),
//                   children: [
//                     for (final order in list) LiveOrderCard(order: order),
//                   ],
//                 ),
//         ),
//       ],
//     );
//   }

//   // ── Wide orders ───────────────────────────────────────────────────

//   Widget _buildWideOrders(
//     BuildContext context,
//     AppColorScheme colors,
//     List<OrderModel> orders,
//   ) {
//     final pending =
//         orders.where((o) => o.status == OrderStatus.pending).toList();

//     final preparing =
//         orders.where((o) => o.status == OrderStatus.preparing).toList();

//     final ready = orders.where((o) => o.status == OrderStatus.ready).toList();

//     final delivered =
//         orders.where((o) => o.status == OrderStatus.delivered).toList();

//     return Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: context.w(20),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             child: _column(
//               context,
//               colors,
//               'New',
//               pending,
//               OrderStatus.pending,
//             ),
//           ),
//           SizedBox(width: context.w(14)),
//           Expanded(
//             child: _column(
//               context,
//               colors,
//               'Preparing',
//               preparing,
//               OrderStatus.preparing,
//             ),
//           ),
//           SizedBox(width: context.w(14)),
//           Expanded(
//             child: _column(
//               context,
//               colors,
//               'Ready',
//               ready,
//               OrderStatus.ready,
//             ),
//           ),
//           SizedBox(width: context.w(14)),
//           Expanded(
//             child: _column(
//               context,
//               colors,
//               'Delivered',
//               delivered,
//               OrderStatus.delivered,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Type filter chips ──────────────────────────────────────────────

//   Widget _typeFilterChips(
//     BuildContext context,
//     AppColorScheme colors,
//     List<OrderModel> orders,
//   ) {
//     final all = orders.length;

//     final eatIn = orders.where((o) => o.orderType == OrderType.dineIn).length;

//     final delivery =
//         orders.where((o) => o.orderType == OrderType.delivery).length;

//     final chips = [
//       (null, 'All', all),
//       (OrderType.dineIn, 'Eat In', eatIn),
//       (OrderType.delivery, 'Delivery', delivery),
//     ];

//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: Row(
//         children: [
//           for (final (type, label, count) in chips) ...[
//             InkWell(
//               onTap: () => setState(() => _typeFilter = type),
//               borderRadius: BorderRadius.circular(context.h(20)),
//               child: Container(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: context.w(14),
//                   vertical: context.h(8),
//                 ),
//                 decoration: BoxDecoration(
//                   color:
//                       _typeFilter == type ? AppColors.primary : colors.surface,
//                   borderRadius: BorderRadius.circular(context.h(20)),
//                   border: Border.all(
//                     color:
//                         _typeFilter == type ? AppColors.primary : colors.border,
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       label,
//                       style: AppTextStyles.label(context).copyWith(
//                         color: _typeFilter == type
//                             ? Colors.white
//                             : colors.textPrimary,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     SizedBox(width: context.w(6)),
//                     Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: context.w(6),
//                         vertical: context.h(1),
//                       ),
//                       decoration: BoxDecoration(
//                         color: _typeFilter == type
//                             ? Colors.white.withValues(alpha: 0.25)
//                             : colors.surfaceVariant,
//                         borderRadius: BorderRadius.circular(context.h(10)),
//                       ),
//                       child: Text(
//                         '$count',
//                         style: AppTextStyles.caption(context).copyWith(
//                           color: _typeFilter == type
//                               ? Colors.white
//                               : colors.textSecondary,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(width: context.w(8)),
//           ],
//         ],
//       ),
//     );
//   }

//   // ── Narrow stage tabs ──────────────────────────────────────────────

//   Widget _stageTabs(
//     BuildContext context,
//     AppColorScheme colors,
//   ) {
//     const stages = [
//       OrderStatus.pending,
//       OrderStatus.preparing,
//       OrderStatus.ready,
//       OrderStatus.delivered,
//     ];

//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: Row(
//         children: [
//           for (final stage in stages) ...[
//             InkWell(
//               onTap: () => setState(() => _narrowStage = stage),
//               borderRadius: BorderRadius.circular(context.h(20)),
//               child: Container(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: context.w(14),
//                   vertical: context.h(9),
//                 ),
//                 decoration: BoxDecoration(
//                   color: _narrowStage == stage
//                       ? AppColors.primary
//                       : colors.surface,
//                   borderRadius: BorderRadius.circular(context.h(20)),
//                   border: Border.all(
//                     color: _narrowStage == stage
//                         ? AppColors.primary
//                         : colors.border,
//                   ),
//                 ),
//                 child: Text(
//                   stage.label,
//                   style: AppTextStyles.label(context).copyWith(
//                     color: _narrowStage == stage
//                         ? Colors.white
//                         : colors.textPrimary,
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(width: context.w(8)),
//           ],
//         ],
//       ),
//     );
//   }

//   // ── Status column ──────────────────────────────────────────────────

//   Widget _column(
//     BuildContext context,
//     AppColorScheme colors,
//     String title,
//     List<OrderModel> orders,
//     OrderStatus status,
//   ) {
//     return Container(
//       padding: EdgeInsets.all(context.h(12)),
//       decoration: BoxDecoration(
//         color: colors.surfaceVariant.withValues(alpha: 0.55),
//         borderRadius: BorderRadius.circular(context.h(12)),
//         border: Border.all(
//           color: colors.border.withValues(alpha: 0.6),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Text(
//                 title,
//                 style: AppTextStyles.section(context).copyWith(
//                   color: colors.textPrimary,
//                 ),
//               ),
//               SizedBox(width: context.w(8)),
//               Container(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: context.w(8),
//                   vertical: context.h(2),
//                 ),
//                 decoration: BoxDecoration(
//                   color: colors.surface,
//                   borderRadius: BorderRadius.circular(context.h(10)),
//                 ),
//                 child: Text(
//                   '${orders.length}',
//                   style: AppTextStyles.caption(context).copyWith(
//                     color: colors.textSecondary,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: context.h(12)),
//           Expanded(
//             child: orders.isEmpty
//                 ? Center(
//                     child: Text(
//                       'No orders',
//                       style: AppTextStyles.bodySecondary(context).copyWith(
//                         color: colors.textMuted,
//                       ),
//                     ),
//                   )
//                 : ListView(
//                     children: [
//                       for (final order in orders) LiveOrderCard(order: order),
//                     ],
//                   ),
//           ),
//         ],
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
  OrderStatus _narrowStage = OrderStatus.pending;

  Future<void> _openPlaceOrder() async {
    final placed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PlaceOrderScreen(),
      ),
    );

    if (placed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New order added to the queue.'),
        ),
      );
    }
  }

  List<OrderModel> _filterByType(List<OrderModel> orders) {
    if (_typeFilter == null) {
      return orders;
    }

    return orders.where((order) => order.orderType == _typeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final ordersAsync = ref.watch(liveOrdersStreamProvider);
    final narrow = MediaQuery.sizeOf(context).width < 900;

    // Keep the UI visible while the stream is loading.
    // When data is available, this contains the current orders.
    final allOrders = ordersAsync.valueOrNull ?? <OrderModel>[];

    final filteredOrders = _filterByType(allOrders);

    // ─────────────────────────────────────────────────────────────
    // STAT COUNTS
    // ─────────────────────────────────────────────────────────────

    final totalOrders = allOrders.length;

    final pendingOrders = allOrders
        .where(
          (order) => order.status == OrderStatus.pending,
        )
        .length;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          // ─────────────────────────────────────────────────────────
          // HEADER
          // ─────────────────────────────────────────────────────────

          const RdxHeader(
            title: 'Live Orders',
            showBackButton: false,
          ),

          // ─────────────────────────────────────────────────────────
          // FILTERS + NEW ORDER
          // ─────────────────────────────────────────────────────────

          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(20),
              context.h(12),
              context.w(20),
              0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _typeFilterChips(
                    context,
                    colors,
                    allOrders,
                  ),
                ),
                SizedBox(width: context.w(12)),
                RdxActionButton(
                  label: 'New Order',
                  leadingIcon: Icons.add,
                  onPressed: _openPlaceOrder,
                ),
              ],
            ),
          ),

          SizedBox(height: context.h(20)),

          // ─────────────────────────────────────────────────────────
          // STAT CARDS
          //
          // IMPORTANT:
          // These are NOT inside ordersAsync.when().
          // Therefore they are ALWAYS visible.
          // ─────────────────────────────────────────────────────────

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(20),
            ),
            child: SizedBox(
              height: context.h(110),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Pending Orders',
                      value: '$pendingOrders orders',
                      icon: Icons.access_time_rounded,
                      accentColor: AppColors.primary,
                      horizontal: true,
                    ),
                  ),
                  SizedBox(width: context.w(16)),
                  Expanded(
                    child: StatCard(
                      label: 'Total Orders',
                      value: '$totalOrders orders',
                      icon: Icons.receipt_long_outlined,
                      accentColor: AppColors.success,
                      horizontal: true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: context.h(20)),

          // ─────────────────────────────────────────────────────────
          // BOTTOM ORDER BOARD
          //
          // IMPORTANT:
          // The board is ALWAYS rendered.
          // We do NOT return EmptyState when there are no orders.
          // The four columns remain visible with "No orders".
          // ─────────────────────────────────────────────────────────

          Expanded(
            child: narrow
                ? _buildNarrowOrders(
                    context,
                    colors,
                    filteredOrders,
                  )
                : _buildWideOrders(
                    context,
                    colors,
                    filteredOrders,
                  ),
          ),

          SizedBox(height: context.h(16)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // NARROW / MOBILE
  // ─────────────────────────────────────────────────────────────────

  Widget _buildNarrowOrders(
    BuildContext context,
    AppColorScheme colors,
    List<OrderModel> orders,
  ) {
    final pending =
        orders.where((order) => order.status == OrderStatus.pending).toList();

    final preparing =
        orders.where((order) => order.status == OrderStatus.preparing).toList();

    final ready =
        orders.where((order) => order.status == OrderStatus.ready).toList();

    final delivered =
        orders.where((order) => order.status == OrderStatus.delivered).toList();

    final List<OrderModel> currentOrders;

    switch (_narrowStage) {
      case OrderStatus.pending:
        currentOrders = pending;
        break;

      case OrderStatus.preparing:
        currentOrders = preparing;
        break;

      case OrderStatus.ready:
        currentOrders = ready;
        break;

      case OrderStatus.delivered:
        currentOrders = delivered;
        break;

      case OrderStatus.cancelled:
        currentOrders = const [];
        break;
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(20),
          ),
          child: _stageTabs(
            context,
            colors,
          ),
        ),
        SizedBox(height: context.h(12)),
        Expanded(
          child: currentOrders.isEmpty
              ? const EmptyState(
                  message: 'No orders',
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(20),
                  ),
                  itemCount: currentOrders.length,
                  itemBuilder: (context, index) {
                    return LiveOrderCard(
                      order: currentOrders[index],
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // WIDE / DESKTOP KANBAN BOARD
  // ─────────────────────────────────────────────────────────────────

  Widget _buildWideOrders(
    BuildContext context,
    AppColorScheme colors,
    List<OrderModel> orders,
  ) {
    final pending =
        orders.where((order) => order.status == OrderStatus.pending).toList();

    final preparing =
        orders.where((order) => order.status == OrderStatus.preparing).toList();

    final ready =
        orders.where((order) => order.status == OrderStatus.ready).toList();

    final delivered =
        orders.where((order) => order.status == OrderStatus.delivered).toList();

    // IMPORTANT:
    // No "orders.isEmpty" check here.
    //
    // Even if all four lists are empty, all four columns are
    // still rendered.

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ───────────────────────────────────────────────────────
          // NEW
          // ───────────────────────────────────────────────────────

          Expanded(
            child: _column(
              context,
              colors,
              'New',
              pending,
              OrderStatus.pending,
            ),
          ),

          SizedBox(width: context.w(14)),

          // ───────────────────────────────────────────────────────
          // PREPARING
          // ───────────────────────────────────────────────────────

          Expanded(
            child: _column(
              context,
              colors,
              'Preparing',
              preparing,
              OrderStatus.preparing,
            ),
          ),

          SizedBox(width: context.w(14)),

          // ───────────────────────────────────────────────────────
          // READY
          // ───────────────────────────────────────────────────────

          Expanded(
            child: _column(
              context,
              colors,
              'Ready',
              ready,
              OrderStatus.ready,
            ),
          ),

          SizedBox(width: context.w(14)),

          // ───────────────────────────────────────────────────────
          // DELIVERED
          // ───────────────────────────────────────────────────────

          Expanded(
            child: _column(
              context,
              colors,
              'Delivered',
              delivered,
              OrderStatus.delivered,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TYPE FILTER CHIPS
  // ─────────────────────────────────────────────────────────────────

  Widget _typeFilterChips(
    BuildContext context,
    AppColorScheme colors,
    List<OrderModel> orders,
  ) {
    final all = orders.length;

    final eatIn = orders
        .where(
          (order) => order.orderType == OrderType.dineIn,
        )
        .length;

    final delivery = orders
        .where(
          (order) => order.orderType == OrderType.delivery,
        )
        .length;

    final chips = [
      (null, 'All', all),
      (OrderType.dineIn, 'Eat In', eatIn),
      (OrderType.delivery, 'Delivery', delivery),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (type, label, count) in chips) ...[
            InkWell(
              onTap: () {
                setState(() {
                  _typeFilter = type;
                });
              },
              borderRadius: BorderRadius.circular(
                context.h(20),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(14),
                  vertical: context.h(8),
                ),
                decoration: BoxDecoration(
                  color:
                      _typeFilter == type ? AppColors.primary : colors.surface,
                  borderRadius: BorderRadius.circular(
                    context.h(20),
                  ),
                  border: Border.all(
                    color:
                        _typeFilter == type ? AppColors.primary : colors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.label(context).copyWith(
                        color: _typeFilter == type
                            ? Colors.white
                            : colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: context.w(6)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(6),
                        vertical: context.h(1),
                      ),
                      decoration: BoxDecoration(
                        color: _typeFilter == type
                            ? Colors.white.withValues(alpha: 0.25)
                            : colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(
                          context.h(10),
                        ),
                      ),
                      child: Text(
                        '$count',
                        style: AppTextStyles.caption(context).copyWith(
                          color: _typeFilter == type
                              ? Colors.white
                              : colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: context.w(8)),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // NARROW STAGE TABS
  // ─────────────────────────────────────────────────────────────────

  Widget _stageTabs(
    BuildContext context,
    AppColorScheme colors,
  ) {
    const stages = [
      OrderStatus.pending,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.delivered,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final stage in stages) ...[
            InkWell(
              onTap: () {
                setState(() {
                  _narrowStage = stage;
                });
              },
              borderRadius: BorderRadius.circular(
                context.h(20),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(14),
                  vertical: context.h(9),
                ),
                decoration: BoxDecoration(
                  color: _narrowStage == stage
                      ? AppColors.primary
                      : colors.surface,
                  borderRadius: BorderRadius.circular(
                    context.h(20),
                  ),
                  border: Border.all(
                    color: _narrowStage == stage
                        ? AppColors.primary
                        : colors.border,
                  ),
                ),
                child: Text(
                  stage.label,
                  style: AppTextStyles.label(context).copyWith(
                    color: _narrowStage == stage
                        ? Colors.white
                        : colors.textPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(width: context.w(8)),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // ORDER COLUMN
  // ─────────────────────────────────────────────────────────────────

  Widget _column(
    BuildContext context,
    AppColorScheme colors,
    String title,
    List<OrderModel> orders,
    OrderStatus status,
  ) {
    return Container(
      padding: EdgeInsets.all(
        context.h(12),
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withValues(
          alpha: 0.55,
        ),
        borderRadius: BorderRadius.circular(
          context.h(12),
        ),
        border: Border.all(
          color: colors.border.withValues(
            alpha: 0.6,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ───────────────────────────────────────────────────────
          // COLUMN HEADER
          // ───────────────────────────────────────────────────────

          Row(
            children: [
              Text(
                title,
                style: AppTextStyles.section(context).copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(width: context.w(8)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(8),
                  vertical: context.h(2),
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(
                    context.h(10),
                  ),
                ),
                child: Text(
                  '${orders.length}',
                  style: AppTextStyles.caption(context).copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: context.h(12)),

          // ───────────────────────────────────────────────────────
          // COLUMN CONTENT
          //
          // Always keeps the column visible.
          // Empty column simply displays "No orders".
          // ───────────────────────────────────────────────────────

          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Text(
                      'No orders',
                      style: AppTextStyles.bodySecondary(context).copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: orders.length,
                    separatorBuilder: (_, __) {
                      return SizedBox(
                        height: context.h(8),
                      );
                    },
                    itemBuilder: (context, index) {
                      return LiveOrderCard(
                        order: orders[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
