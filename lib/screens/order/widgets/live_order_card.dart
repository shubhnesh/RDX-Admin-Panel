// // import 'package:flutter/material.dart';
// // import 'package:flutter_riverpod/flutter_riverpod.dart';

// // import '../../../core/theme/app_colors.dart';
// // import '../../../core/theme/text_styles.dart';
// // import '../../../core/utils/responsive_size.dart';
// // import '../../../models/order_model.dart';
// // import '../../../providers/order_providers.dart';
// // import '../../../widgets/buttons/rdx_action_button.dart';
// // import '../../../widgets/reusable_widgets/rdx_delete_dialog.dart';

// // class LiveOrderCard extends ConsumerWidget {
// //   final OrderModel order;
// //   const LiveOrderCard({super.key, required this.order});

// //   IconData get _orderTypeIcon {
// //     switch (order.orderType) {
// //       case OrderType.dineIn:
// //         return Icons.restaurant_outlined;
// //       case OrderType.takeaway:
// //         return Icons.shopping_bag_outlined;
// //       case OrderType.delivery:
// //         return Icons.delivery_dining_outlined;
// //     }
// //   }

// //   String get _elapsed {
// //     final minutes = DateTime.now().difference(order.createdAt).inMinutes;
// //     if (minutes < 1) return 'Just now';
// //     if (minutes < 60) return '${minutes}m ago';
// //     return '${(minutes / 60).floor()}h ${minutes % 60}m ago';
// //   }

// //   Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
// //     final confirmed = await showDialog<bool>(
// //       context: context,
// //       builder: (_) => RdxDeleteDialog(
// //         title: 'Cancel Order',
// //         itemName: '#${order.id.length >= 6 ? order.id.substring(0, 6) : order.id}',
// //         deleteButtonLabel: 'Cancel Order',
// //         warningMessage: 'This will mark the order as cancelled. This cannot be undone.',
// //       ),
// //     );
// //     if (confirmed == true) {
// //       await ref.read(orderActionsProvider.notifier).cancelOrder(order);
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context, WidgetRef ref) {
// //     final colors = AppColors.of(context);
// //     final updating = ref.watch(orderActionsProvider.select((s) => s.contains(order.id)));
// //     final actionLabel = order.status.advanceActionLabel;

// //     final itemsSummary = order.items.take(3).map((i) => '${i.quantity}x ${i.name}').join(', ');
// //     final moreCount = order.items.length - 3;

// //     return Container(
// //       width: double.infinity,
// //       margin: EdgeInsets.only(bottom: context.h(12)),
// //       padding: EdgeInsets.all(context.h(14)),
// //       decoration: BoxDecoration(
// //         color: colors.surface,
// //         borderRadius: BorderRadius.circular(context.h(10)),
// //         border: Border.all(color: colors.border),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             children: [
// //               Icon(_orderTypeIcon, size: context.h(16), color: AppColors.primary),
// //               SizedBox(width: context.w(6)),
// //               Text(
// //                 order.orderType == OrderType.dineIn && (order.tableNumber ?? '').isNotEmpty
// //                     ? '${order.orderType.label} · ${order.tableNumber}'
// //                     : order.orderType.label,
// //                 style: AppTextStyles.label(context).copyWith(color: colors.textPrimary),
// //               ),
// //               const Spacer(),
// //               Text(_elapsed,
// //                   style: AppTextStyles.caption(context).copyWith(color: colors.textMuted)),
// //             ],
// //           ),
// //           SizedBox(height: context.h(8)),
// //           Text(order.customerName,
// //               style: AppTextStyles.body(context)
// //                   .copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600)),
// //           if (order.customerPhone.isNotEmpty)
// //             Text(order.customerPhone,
// //                 style: AppTextStyles.bodyTertiary(context).copyWith(color: colors.textSecondary)),
// //           SizedBox(height: context.h(8)),
// //           Text(
// //             moreCount > 0 ? '$itemsSummary, +$moreCount more' : itemsSummary,
// //             style: AppTextStyles.bodySecondary(context).copyWith(color: colors.textSecondary),
// //           ),
// //           if (order.orderType == OrderType.delivery && order.deliveryAddress.isNotEmpty) ...[
// //             SizedBox(height: context.h(6)),
// //             Row(
// //               children: [
// //                 Icon(Icons.location_on_outlined, size: context.h(14), color: colors.textMuted),
// //                 SizedBox(width: context.w(4)),
// //                 Expanded(
// //                   child: Text(
// //                     order.deliveryAddress,
// //                     maxLines: 1,
// //                     overflow: TextOverflow.ellipsis,
// //                     style: AppTextStyles.caption(context).copyWith(color: colors.textMuted),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ],
// //           if (order.notes != null && order.notes!.isNotEmpty) ...[
// //             SizedBox(height: context.h(6)),
// //             Text(
// //               'Note: ${order.notes}',
// //               maxLines: 2,
// //               overflow: TextOverflow.ellipsis,
// //               style: AppTextStyles.caption(context)
// //                   .copyWith(color: colors.textMuted, fontStyle: FontStyle.italic),
// //             ),
// //           ],
// //           SizedBox(height: context.h(10)),
// //           Row(
// //             children: [
// //               if (order.paymentMethod != null)
// //                 Container(
// //                   padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(3)),
// //                   decoration: BoxDecoration(
// //                     color: colors.surfaceVariant,
// //                     borderRadius: BorderRadius.circular(context.h(6)),
// //                   ),
// //                   child: Text(order.paymentMethod!.label,
// //                       style: AppTextStyles.caption(context).copyWith(color: colors.textSecondary)),
// //                 ),
// //               const Spacer(),
// //               Text('₹${order.total.toStringAsFixed(0)}',
// //                   style: AppTextStyles.section(context).copyWith(color: colors.textPrimary)),
// //             ],
// //           ),
// //           if (actionLabel != null) ...[
// //             SizedBox(height: context.h(10)),
// //             Row(
// //               children: [
// //                 Expanded(
// //                   child: RdxActionButton(
// //                     label: updating ? 'Updating...' : actionLabel,
// //                     isPrimary: true,
// //                     onPressed: updating
// //                         ? null
// //                         : () => ref.read(orderActionsProvider.notifier).advanceStatus(order),
// //                   ),
// //                 ),
// //                 SizedBox(width: context.w(8)),
// //                 TextButton(
// //                   onPressed: updating ? null : () => _confirmCancel(context, ref),
// //                   child: Text('Cancel',
// //                       style: AppTextStyles.label(context).copyWith(color: AppColors.danger)),
// //                 ),
// //               ],
// //             ),
// //           ],
// //         ],
// //       ),
// //     );
// //   }
// // }

// // widgets/live_order_card.dart  (replace the whole file)

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../../core/theme/app_colors.dart';
// import '../../../core/theme/text_styles.dart';
// import '../../../core/utils/responsive_size.dart';
// import '../../../models/order_model.dart';
// import '../../../providers/order_providers.dart';
// import '../../../widgets/buttons/rdx_action_button.dart';
// import '../../../widgets/reusable_widgets/rdx_delete_dialog.dart';

// class LiveOrderCard extends ConsumerWidget {
//   final OrderModel order;
//   const LiveOrderCard({super.key, required this.order});

//   String get _orderIdShort {
//     final id = order.id;
//     return id.length >= 4 ? id.substring(id.length - 4) : id;
//   }

//   String get _typeLabel {
//     switch (order.orderType) {
//       case OrderType.dineIn:
//         final table = order.tableNumber?.trim();
//         return (table != null && table.isNotEmpty)
//             ? 'Eat In · Table $table'
//             : 'Eat In';
//       case OrderType.takeaway:
//         return 'To Go';
//       case OrderType.delivery:
//         return 'Delivery';
//     }
//   }

//   Color _typeBadgeColor(AppColorScheme colors) {
//     switch (order.orderType) {
//       case OrderType.dineIn:
//         return AppColors.primary.withValues(alpha: 0.12);
//       case OrderType.takeaway:
//         return colors.surfaceVariant;
//       case OrderType.delivery:
//         return const Color(0xFFE8F5E9); // soft green tint for delivery
//     }
//   }

//   Color _typeBadgeText(AppColorScheme colors) {
//     switch (order.orderType) {
//       case OrderType.dineIn:
//         return AppColors.primary;
//       case OrderType.takeaway:
//         return colors.textSecondary;
//       case OrderType.delivery:
//         return const Color(0xFF2E7D32);
//     }
//   }

//   Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (_) => RdxDeleteDialog(
//         title: 'Cancel Order',
//         itemName: '#$_orderIdShort',
//         deleteButtonLabel: 'Cancel Order',
//         warningMessage:
//             'This will mark the order as cancelled. This cannot be undone.',
//       ),
//     );
//     if (confirmed == true) {
//       await ref.read(orderActionsProvider.notifier).cancelOrder(order);
//     }
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final colors = AppColors.of(context);
//     final updating =
//         ref.watch(orderActionsProvider.select((s) => s.contains(order.id)));
//     final actionLabel = order.status.advanceActionLabel;

//     return Container(
//       width: double.infinity,
//       margin: EdgeInsets.only(bottom: context.h(12)),
//       padding: EdgeInsets.all(context.h(14)),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(context.h(12)),
//         border: Border.all(color: colors.border),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // header: #id + type badge + time
//           Row(
//             children: [
//               Text(
//                 '#$_orderIdShort',
//                 style: AppTextStyles.section(context).copyWith(
//                   color: colors.textPrimary,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               SizedBox(width: context.w(8)),
//               Container(
//                 padding: EdgeInsets.symmetric(
//                     horizontal: context.w(8), vertical: context.h(3)),
//                 decoration: BoxDecoration(
//                   color: _typeBadgeColor(colors),
//                   borderRadius: BorderRadius.circular(context.h(6)),
//                 ),
//                 child: Text(
//                   _typeLabel,
//                   style: AppTextStyles.caption(context).copyWith(
//                     color: _typeBadgeText(colors),
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//               const Spacer(),
//               Text(
//                 _elapsed,
//                 style: AppTextStyles.caption(context)
//                     .copyWith(color: colors.textMuted),
//               ),
//             ],
//           ),
//           SizedBox(height: context.h(10)),

//           // items list (name + price per line)
//           for (final item in order.items.take(4))
//             Padding(
//               padding: EdgeInsets.only(bottom: context.h(4)),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       '${item.quantity}x ${item.name}',
//                       style: AppTextStyles.bodySecondary(context)
//                           .copyWith(color: colors.textSecondary),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   Text(
//                     '₹${(item.price * item.quantity).toStringAsFixed(0)}',
//                     style: AppTextStyles.caption(context)
//                         .copyWith(color: colors.textMuted),
//                   ),
//                 ],
//               ),
//             ),
//           if (order.items.length > 4)
//             Text(
//               '+${order.items.length - 4} more',
//               style: AppTextStyles.caption(context)
//                   .copyWith(color: colors.textMuted),
//             ),

//           if (order.notes != null && order.notes!.isNotEmpty) ...[
//             SizedBox(height: context.h(6)),
//             Text(
//               'Note: ${order.notes}',
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//               style: AppTextStyles.caption(context).copyWith(
//                 color: colors.textMuted,
//                 fontStyle: FontStyle.italic,
//               ),
//             ),
//           ],

//           SizedBox(height: context.h(10)),
//           Divider(height: 1, color: colors.divider),
//           SizedBox(height: context.h(10)),

//           // total + action
//           Row(
//             children: [
//               Text(
//                 '₹${order.total.toStringAsFixed(0)}',
//                 style: AppTextStyles.section(context).copyWith(
//                   color: colors.textPrimary,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               const Spacer(),
//               if (actionLabel != null)
//                 SizedBox(
//                   height: context.h(34),
//                   child: RdxActionButton(
//                     label: updating ? '…' : actionLabel,
//                     isPrimary: true,
//                     onPressed: updating
//                         ? null
//                         : () => ref
//                             .read(orderActionsProvider.notifier)
//                             .advanceStatus(order),
//                   ),
//                 ),
//             ],
//           ),

//           // secondary cancel
//           if (actionLabel != null) ...[
//             SizedBox(height: context.h(6)),
//             Align(
//               alignment: Alignment.centerRight,
//               child: TextButton(
//                 onPressed: updating ? null : () => _confirmCancel(context, ref),
//                 style: TextButton.styleFrom(
//                   padding: EdgeInsets.symmetric(horizontal: context.w(8)),
//                   minimumSize: Size.zero,
//                   tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                 ),
//                 child: Text(
//                   'Cancel',
//                   style: AppTextStyles.caption(context)
//                       .copyWith(color: AppColors.danger),
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   String get _elapsed {
//     final minutes = DateTime.now().difference(order.createdAt).inMinutes;
//     if (minutes < 1) return 'Just now';
//     if (minutes < 60) return '${minutes}m ago';
//     return '${(minutes / 60).floor()}h ${minutes % 60}m ago';
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/responsive_size.dart';
import '../../../models/order_model.dart';
import '../../../providers/order_providers.dart';
import '../../../widgets/buttons/rdx_action_button.dart';
import '../../../widgets/reusable_widgets/rdx_delete_dialog.dart';

class LiveOrderCard extends ConsumerWidget {
  final OrderModel order;
  const LiveOrderCard({super.key, required this.order});

  String get _orderIdShort {
    final id = order.id;
    return id.length >= 4 ? id.substring(id.length - 4) : id;
  }

  String get _typeLabel {
    switch (order.orderType) {
      case OrderType.dineIn:
        final table = order.tableNumber?.trim();
        return (table != null && table.isNotEmpty)
            ? 'Eat In · Table $table'
            : 'Eat In';
      // case OrderType.takeaway:
      // return 'To Go';
      case OrderType.delivery:
        return 'Delivery';
    }
  }

  Color _typeBadgeColor(AppColorScheme colors) {
    switch (order.orderType) {
      case OrderType.dineIn:
        return AppColors.primary.withValues(alpha: 0.12);
      // case OrderType.takeaway:
      // return colors.surfaceVariant;
      case OrderType.delivery:
        return const Color(0xFFE8F5E9);
    }
  }

  Color _typeBadgeText(AppColorScheme colors) {
    switch (order.orderType) {
      case OrderType.dineIn:
        return AppColors.primary;
      // case OrderType.takeaway:
      // return colors.textSecondary;
      case OrderType.delivery:
        return const Color(0xFF2E7D32);
    }
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Cancel Order',
        itemName: '#$_orderIdShort',
        deleteButtonLabel: 'Cancel Order',
        warningMessage:
            'This will mark the order as cancelled. This cannot be undone.',
      ),
    );
    if (confirmed == true) {
      await ref.read(orderActionsProvider.notifier).cancelOrder(order);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final updating =
        ref.watch(orderActionsProvider.select((s) => s.contains(order.id)));
    final actionLabel = order.status.advanceActionLabel;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: context.h(12)),
      padding: EdgeInsets.all(context.h(14)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(12)),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header: #id + type badge + time
          Row(
            children: [
              Text(
                '#$_orderIdShort',
                style: AppTextStyles.section(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: context.w(8)),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.w(8), vertical: context.h(3)),
                decoration: BoxDecoration(
                  color: _typeBadgeColor(colors),
                  borderRadius: BorderRadius.circular(context.h(6)),
                ),
                child: Text(
                  _typeLabel,
                  style: AppTextStyles.caption(context).copyWith(
                    color: _typeBadgeText(colors),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _elapsed,
                style: AppTextStyles.caption(context)
                    .copyWith(color: colors.textMuted),
              ),
            ],
          ),
          SizedBox(height: context.h(10)),

          // items list (name + price per line)
          for (final item in order.items.take(4))
            Padding(
              padding: EdgeInsets.only(bottom: context.h(4)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.name}',
                      style: AppTextStyles.bodySecondary(context)
                          .copyWith(color: colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                    style: AppTextStyles.caption(context)
                        .copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ),
          if (order.items.length > 4)
            Text(
              '+${order.items.length - 4} more',
              style: AppTextStyles.caption(context)
                  .copyWith(color: colors.textMuted),
            ),

          if (order.notes != null && order.notes!.isNotEmpty) ...[
            SizedBox(height: context.h(6)),
            Text(
              'Note: ${order.notes}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                color: colors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          SizedBox(height: context.h(10)),
          Divider(height: 1, color: colors.divider),
          SizedBox(height: context.h(10)),

          // total + action
          Row(
            children: [
              Text(
                '₹${order.total.toStringAsFixed(0)}',
                style: AppTextStyles.section(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (actionLabel != null)
                SizedBox(
                  height: context.h(34),
                  child: RdxActionButton(
                    label: updating ? '…' : actionLabel,
                    isPrimary: true,
                    onPressed: updating
                        ? null
                        : () => ref
                            .read(orderActionsProvider.notifier)
                            .advanceStatus(order),
                  ),
                ),
            ],
          ),

          // secondary cancel
          if (actionLabel != null) ...[
            SizedBox(height: context.h(6)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: updating ? null : () => _confirmCancel(context, ref),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: context.w(8)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.caption(context)
                      .copyWith(color: AppColors.danger),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _elapsed {
    final minutes = DateTime.now().difference(order.createdAt).inMinutes;
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return '${minutes}m ago';
    return '${(minutes / 60).floor()}h ${minutes % 60}m ago';
  }
}
