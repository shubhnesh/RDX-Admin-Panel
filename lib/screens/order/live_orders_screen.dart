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

// // /// Real-time order board. Backed by [liveOrdersStreamProvider] (a
// // /// Firestore snapshot stream via Riverpod), so every card updates the
// // /// instant an order's status changes anywhere — no manual refresh.
// // class LiveOrdersScreen extends ConsumerStatefulWidget {
// //   const LiveOrdersScreen({super.key});

// //   @override
// //   ConsumerState<LiveOrdersScreen> createState() => _LiveOrdersScreenState();
// // }

// // class _LiveOrdersScreenState extends ConsumerState<LiveOrdersScreen> {
// //   OrderStatus _narrowStage = OrderStatus.pending;

// //   Future<void> _openPlaceOrder() async {
// //     final placed = await Navigator.of(context).push<bool>(
// //       MaterialPageRoute(builder: (_) => const PlaceOrderScreen()),
// //     );
// //     if (placed == true && mounted) {
// //       ScaffoldMessenger.of(context)
// //           .showSnackBar(const SnackBar(content: Text('New order added to the queue.')));
// //     }
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
// //           Padding(
// //             padding: EdgeInsets.fromLTRB(context.w(20), context.h(12), context.w(20), 0),
// //             child: Row(
// //               children: [
// //                 if (narrow) Expanded(child: _stageTabs(context, colors)) else const Spacer(),
// //                 SizedBox(width: context.w(8)),
// //                 RdxActionButton(
// //                   label: 'New Order',
// //                   leadingIcon: Icons.add,
// //                   onPressed: _openPlaceOrder,
// //                 ),
// //               ],
// //             ),
// //           ),
// //           SizedBox(height: context.h(12)),
// //           Expanded(
// //             child: ordersAsync.when(
// //               loading: () => const LoadingIndicator(),
// //               error: (err, _) => const EmptyState(message: 'Failed to load live orders.'),
// //               data: (orders) {
// //                 if (orders.isEmpty) {
// //                   return const EmptyState(message: 'No live orders right now.');
// //                 }
// //                 final pending = orders.where((o) => o.status == OrderStatus.pending).toList();
// //                 final preparing = orders.where((o) => o.status == OrderStatus.preparing).toList();
// //                 final ready = orders.where((o) => o.status == OrderStatus.ready).toList();

// //                 if (narrow) {
// //                   final list = switch (_narrowStage) {
// //                     OrderStatus.pending => pending,
// //                     OrderStatus.preparing => preparing,
// //                     OrderStatus.ready => ready,
// //                     _ => <OrderModel>[],
// //                   };
// //                   return Padding(
// //                     padding: EdgeInsets.symmetric(horizontal: context.w(20)),
// //                     child: list.isEmpty
// //                         ? EmptyState(message: 'No ${_narrowStage.label.toLowerCase()} orders.')
// //                         : ListView(children: [for (final o in list) LiveOrderCard(order: o)]),
// //                   );
// //                 }

// //                 return Padding(
// //                   padding: EdgeInsets.symmetric(horizontal: context.w(20)),
// //                   child: Row(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Expanded(child: _column(context, colors, 'Pending', pending)),
// //                       SizedBox(width: context.w(16)),
// //                       Expanded(child: _column(context, colors, 'Preparing', preparing)),
// //                       SizedBox(width: context.w(16)),
// //                       Expanded(child: _column(context, colors, 'Ready', ready)),
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

// //   Widget _stageTabs(BuildContext context, AppColorScheme colors) {
// //     const stages = [OrderStatus.pending, OrderStatus.preparing, OrderStatus.ready];
// //     return SingleChildScrollView(
// //       scrollDirection: Axis.horizontal,
// //       child: Row(
// //         children: [
// //           for (final stage in stages) ...[
// //             InkWell(
// //               onTap: () => setState(() => _narrowStage = stage),
// //               borderRadius: BorderRadius.circular(context.h(20)),
// //               child: Container(
// //                 padding: EdgeInsets.symmetric(horizontal: context.w(14), vertical: context.h(9)),
// //                 decoration: BoxDecoration(
// //                   color: _narrowStage == stage ? AppColors.primary : colors.surface,
// //                   borderRadius: BorderRadius.circular(context.h(20)),
// //                   border: Border.all(
// //                     color: _narrowStage == stage ? AppColors.primary : colors.border,
// //                   ),
// //                 ),
// //                 child: Text(
// //                   stage.label,
// //                   style: AppTextStyles.label(context).copyWith(
// //                     color: _narrowStage == stage ? Colors.white : colors.textPrimary,
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

// //   Widget _column(
// //     BuildContext context,
// //     AppColorScheme colors,
// //     String title,
// //     List<OrderModel> orders,
// //   ) {
// //     return Container(
// //       padding: EdgeInsets.all(context.h(10)),
// //       decoration: BoxDecoration(
// //         color: colors.surfaceVariant,
// //         borderRadius: BorderRadius.circular(context.h(10)),
// //       ),
// //       constraints: BoxConstraints(minHeight: context.h(200)),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             children: [
// //               Text(title,
// //                   style: AppTextStyles.section(context).copyWith(color: colors.textPrimary)),
// //               SizedBox(width: context.w(8)),
// //               Container(
// //                 padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(2)),
// //                 decoration: BoxDecoration(
// //                   color: colors.surface,
// //                   borderRadius: BorderRadius.circular(context.h(10)),
// //                 ),
// //                 child: Text('${orders.length}',
// //                     style: AppTextStyles.caption(context).copyWith(color: colors.textSecondary)),
// //               ),
// //             ],
// //           ),
// //           SizedBox(height: context.h(10)),
// //           if (orders.isEmpty)
// //             Padding(
// //               padding: EdgeInsets.symmetric(vertical: context.h(20)),
// //               child: Center(
// //                 child: Text('No orders',
// //                     style: AppTextStyles.bodySecondary(context).copyWith(color: colors.textMuted)),
// //               ),
// //             )
// //           else
// //             for (final order in orders) LiveOrderCard(order: order),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // live_orders_screen.dart  (replace the whole file)

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
// import 'place_order_screen.dart';
// import 'widgets/live_order_card.dart';

// class LiveOrdersScreen extends ConsumerStatefulWidget {
//   const LiveOrdersScreen({super.key});

//   @override
//   ConsumerState<LiveOrdersScreen> createState() => _LiveOrdersScreenState();
// }

// class _LiveOrdersScreenState extends ConsumerState<LiveOrdersScreen> {
//   // null = All
//   OrderType? _typeFilter;
//   OrderStatus _narrowStage = OrderStatus.pending;

//   Future<void> _openPlaceOrder() async {
//     final placed = await Navigator.of(context).push<bool>(
//       MaterialPageRoute(builder: (_) => const PlaceOrderScreen()),
//     );
//     if (placed == true && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('New order added to the queue.')),
//       );
//     }
//   }

//   List<OrderModel> _filterByType(List<OrderModel> orders) {
//     if (_typeFilter == null) return orders;
//     return orders.where((o) => o.orderType == _typeFilter).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);
//     final ordersAsync = ref.watch(liveOrdersStreamProvider);
//     final narrow = MediaQuery.sizeOf(context).width < 900;

//     return Scaffold(
//       backgroundColor: colors.background,
//       body: Column(
//         children: [
//           const RdxHeader(title: 'Live Orders', showBackButton: false),
//           // ── type filter row + New Order button ─────────────────────
//           Padding(
//             padding: EdgeInsets.fromLTRB(
//                 context.w(20), context.h(12), context.w(20), 0),
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
//           SizedBox(height: context.h(14)),
//           // ── board ──────────────────────────────────────────────────
//           Expanded(
//             child: ordersAsync.when(
//               loading: () => const LoadingIndicator(),
//               error: (err, _) =>
//                   const EmptyState(message: 'Failed to load live orders.'),
//               data: (allOrders) {
//                 final orders = _filterByType(allOrders);
//                 if (orders.isEmpty) {
//                   return const EmptyState(message: 'No live orders right now.');
//                 }

//                 final pending = orders
//                     .where((o) => o.status == OrderStatus.pending)
//                     .toList();
//                 final preparing = orders
//                     .where((o) => o.status == OrderStatus.preparing)
//                     .toList();
//                 final ready =
//                     orders.where((o) => o.status == OrderStatus.ready).toList();
//                 final delivered = orders
//                     .where((o) =>
//                         o.status == OrderStatus.delivered ||
//                         o.status == OrderStatus.completed)
//                     .toList();

//                 if (narrow) {
//                   final list = switch (_narrowStage) {
//                     OrderStatus.pending => pending,
//                     OrderStatus.preparing => preparing,
//                     OrderStatus.ready => ready,
//                     OrderStatus.delivered || OrderStatus.completed => delivered,
//                     _ => <OrderModel>[],
//                   };
//                   return Column(
//                     children: [
//                       Padding(
//                         padding:
//                             EdgeInsets.symmetric(horizontal: context.w(20)),
//                         child: _stageTabs(context, colors),
//                       ),
//                       SizedBox(height: context.h(12)),
//                       Expanded(
//                         child: list.isEmpty
//                             ? EmptyState(
//                                 message:
//                                     'No ${_narrowStage.label.toLowerCase()} orders.')
//                             : ListView(
//                                 padding: EdgeInsets.symmetric(
//                                     horizontal: context.w(20)),
//                                 children: [
//                                   for (final o in list) LiveOrderCard(order: o),
//                                 ],
//                               ),
//                       ),
//                     ],
//                   );
//                 }

//                 // wide: 4-column kanban
//                 return Padding(
//                   padding: EdgeInsets.symmetric(horizontal: context.w(20)),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                           child: _column(context, colors, 'New', pending,
//                               OrderStatus.pending)),
//                       SizedBox(width: context.w(14)),
//                       Expanded(
//                           child: _column(context, colors, 'Preparing',
//                               preparing, OrderStatus.preparing)),
//                       SizedBox(width: context.w(14)),
//                       Expanded(
//                           child: _column(context, colors, 'Ready', ready,
//                               OrderStatus.ready)),
//                       SizedBox(width: context.w(14)),
//                       Expanded(
//                           child: _column(context, colors, 'Delivered',
//                               delivered, OrderStatus.delivered)),
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

//   // ── type filter chips (All / Eat In / To Go / Delivery) ────────────
//   Widget _typeFilterChips(
//       BuildContext context, AppColorScheme colors, List<OrderModel> orders) {
//     final all = orders.length;
//     final eatIn = orders.where((o) => o.orderType == OrderType.dineIn).length;
//     final toGo = orders.where((o) => o.orderType == OrderType.takeaway).length;
//     final delivery =
//         orders.where((o) => o.orderType == OrderType.delivery).length;

//     final chips = [
//       (null, 'All', all),
//       (OrderType.dineIn, 'Eat In', eatIn),
//       (OrderType.takeaway, 'To Go', toGo),
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
//                     horizontal: context.w(14), vertical: context.h(8)),
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
//                           horizontal: context.w(6), vertical: context.h(1)),
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

//   // ── narrow stage tabs ──────────────────────────────────────────────
//   Widget _stageTabs(BuildContext context, AppColorScheme colors) {
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
//                     horizontal: context.w(14), vertical: context.h(9)),
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

//   // ── status column ──────────────────────────────────────────────────
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
//         border: Border.all(color: colors.border.withValues(alpha: 0.6)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Text(
//                 title,
//                 style: AppTextStyles.section(context)
//                     .copyWith(color: colors.textPrimary),
//               ),
//               SizedBox(width: context.w(8)),
//               Container(
//                 padding: EdgeInsets.symmetric(
//                     horizontal: context.w(8), vertical: context.h(2)),
//                 decoration: BoxDecoration(
//                   color: colors.surface,
//                   borderRadius: BorderRadius.circular(context.h(10)),
//                 ),
//                 child: Text(
//                   '${orders.length}',
//                   style: AppTextStyles.caption(context)
//                       .copyWith(color: colors.textSecondary),
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
//                       style: AppTextStyles.bodySecondary(context)
//                           .copyWith(color: colors.textMuted),
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
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';
import 'place_order_screen.dart';
import 'widgets/live_order_card.dart';

class LiveOrdersScreen extends ConsumerStatefulWidget {
  const LiveOrdersScreen({super.key});

  @override
  ConsumerState<LiveOrdersScreen> createState() => _LiveOrdersScreenState();
}

class _LiveOrdersScreenState extends ConsumerState<LiveOrdersScreen> {
  /// null = All
  OrderType? _typeFilter;
  OrderStatus _narrowStage = OrderStatus.pending;

  Future<void> _openPlaceOrder() async {
    final placed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PlaceOrderScreen()),
    );
    if (placed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New order added to the queue.')),
      );
    }
  }

  List<OrderModel> _filterByType(List<OrderModel> orders) {
    if (_typeFilter == null) return orders;
    return orders.where((o) => o.orderType == _typeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final ordersAsync = ref.watch(liveOrdersStreamProvider);
    final narrow = MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const RdxHeader(title: 'Live Orders', showBackButton: false),
          // ── type filter row + New Order button ─────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
                context.w(20), context.h(12), context.w(20), 0),
            child: Row(
              children: [
                Expanded(
                  child: ordersAsync.when(
                    data: (orders) => _typeFilterChips(context, colors, orders),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
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
          SizedBox(height: context.h(14)),
          // ── board ──────────────────────────────────────────────────
          Expanded(
            child: ordersAsync.when(
              loading: () => const LoadingIndicator(),
              error: (err, _) =>
                  const EmptyState(message: 'Failed to load live orders.'),
              data: (allOrders) {
                final orders = _filterByType(allOrders);
                if (orders.isEmpty) {
                  return const EmptyState(message: 'No live orders right now.');
                }

                final pending = orders
                    .where((o) => o.status == OrderStatus.pending)
                    .toList();
                final preparing = orders
                    .where((o) => o.status == OrderStatus.preparing)
                    .toList();
                final ready =
                    orders.where((o) => o.status == OrderStatus.ready).toList();
                final delivered = orders
                    .where((o) => o.status == OrderStatus.delivered)
                    .toList();

                if (narrow) {
                  final list = switch (_narrowStage) {
                    OrderStatus.pending => pending,
                    OrderStatus.preparing => preparing,
                    OrderStatus.ready => ready,
                    OrderStatus.delivered => delivered,
                    _ => <OrderModel>[],
                  };
                  return Column(
                    children: [
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: context.w(20)),
                        child: _stageTabs(context, colors),
                      ),
                      SizedBox(height: context.h(12)),
                      Expanded(
                        child: list.isEmpty
                            ? EmptyState(
                                message:
                                    'No ${_narrowStage.label.toLowerCase()} orders.')
                            : ListView(
                                padding: EdgeInsets.symmetric(
                                    horizontal: context.w(20)),
                                children: [
                                  for (final o in list) LiveOrderCard(order: o),
                                ],
                              ),
                      ),
                    ],
                  );
                }

                // wide: 4-column kanban
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(20)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _column(context, colors, 'New', pending,
                              OrderStatus.pending)),
                      SizedBox(width: context.w(14)),
                      Expanded(
                          child: _column(context, colors, 'Preparing',
                              preparing, OrderStatus.preparing)),
                      SizedBox(width: context.w(14)),
                      Expanded(
                          child: _column(context, colors, 'Ready', ready,
                              OrderStatus.ready)),
                      SizedBox(width: context.w(14)),
                      Expanded(
                          child: _column(context, colors, 'Delivered',
                              delivered, OrderStatus.delivered)),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: context.h(16)),
        ],
      ),
    );
  }

  // ── type filter chips (All / Eat In / To Go / Delivery) ────────────
  Widget _typeFilterChips(
      BuildContext context, AppColorScheme colors, List<OrderModel> orders) {
    final all = orders.length;
    final eatIn = orders.where((o) => o.orderType == OrderType.dineIn).length;
    // final toGo = orders.where((o) => o.orderType == OrderType.takeaway).length;
    final delivery =
        orders.where((o) => o.orderType == OrderType.delivery).length;

    final chips = [
      (null, 'All', all),
      (OrderType.dineIn, 'Eat In', eatIn),
      // (OrderType.takeaway, 'To Go', toGo),
      (OrderType.delivery, 'Delivery', delivery),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (type, label, count) in chips) ...[
            InkWell(
              onTap: () => setState(() => _typeFilter = type),
              borderRadius: BorderRadius.circular(context.h(20)),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.w(14), vertical: context.h(8)),
                decoration: BoxDecoration(
                  color:
                      _typeFilter == type ? AppColors.primary : colors.surface,
                  borderRadius: BorderRadius.circular(context.h(20)),
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
                          horizontal: context.w(6), vertical: context.h(1)),
                      decoration: BoxDecoration(
                        color: _typeFilter == type
                            ? Colors.white.withValues(alpha: 0.25)
                            : colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(context.h(10)),
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

  // ── narrow stage tabs ──────────────────────────────────────────────
  Widget _stageTabs(BuildContext context, AppColorScheme colors) {
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
              onTap: () => setState(() => _narrowStage = stage),
              borderRadius: BorderRadius.circular(context.h(20)),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.w(14), vertical: context.h(9)),
                decoration: BoxDecoration(
                  color: _narrowStage == stage
                      ? AppColors.primary
                      : colors.surface,
                  borderRadius: BorderRadius.circular(context.h(20)),
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

  // ── status column ──────────────────────────────────────────────────
  Widget _column(
    BuildContext context,
    AppColorScheme colors,
    String title,
    List<OrderModel> orders,
    OrderStatus status,
  ) {
    return Container(
      padding: EdgeInsets.all(context.h(12)),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(context.h(12)),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: AppTextStyles.section(context)
                    .copyWith(color: colors.textPrimary),
              ),
              SizedBox(width: context.w(8)),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.w(8), vertical: context.h(2)),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(context.h(10)),
                ),
                child: Text(
                  '${orders.length}',
                  style: AppTextStyles.caption(context)
                      .copyWith(color: colors.textSecondary),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(12)),
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Text(
                      'No orders',
                      style: AppTextStyles.bodySecondary(context)
                          .copyWith(color: colors.textMuted),
                    ),
                  )
                : ListView(
                    children: [
                      for (final order in orders) LiveOrderCard(order: order),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
