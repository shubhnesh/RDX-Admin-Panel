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
//   final VoidCallback? onTap;

//   const LiveOrderCard({
//     super.key,
//     required this.order,
//     this.onTap,
//   });

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
//         return const Color(0xFFE8F5E9);
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

//   Future<void> _confirmCancel(
//     BuildContext context,
//     WidgetRef ref,
//   ) async {
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

//     if (confirmed != true) {
//       return;
//     }

//     await ref.read(orderActionsProvider.notifier).cancelOrder(order);
//   }

//   @override
//   Widget build(
//     BuildContext context,
//     WidgetRef ref,
//   ) {
//     final colors = AppColors.of(context);

//     final updating = ref.watch(
//       orderActionsProvider.select(
//         (state) => state.contains(order.id),
//       ),
//     );

//     final actionLabel = order.status.advanceActionLabel;

//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(
//           context.h(12),
//         ),
//         child: Container(
//           width: double.infinity,
//           margin: EdgeInsets.only(
//             bottom: context.h(12),
//           ),
//           padding: EdgeInsets.all(
//             context.h(14),
//           ),
//           decoration: BoxDecoration(
//             color: colors.surface,
//             borderRadius: BorderRadius.circular(
//               context.h(12),
//             ),
//             border: Border.all(
//               color: colors.border,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withValues(alpha: 0.04),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ----------------------------------------------------------
//               // Header
//               // ----------------------------------------------------------
//               Row(
//                 children: [
//                   Text(
//                     '#$_orderIdShort',
//                     style: AppTextStyles.section(context).copyWith(
//                       color: colors.textPrimary,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   SizedBox(
//                     width: context.w(8),
//                   ),
//                   Container(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: context.w(8),
//                       vertical: context.h(3),
//                     ),
//                     decoration: BoxDecoration(
//                       color: _typeBadgeColor(colors),
//                       borderRadius: BorderRadius.circular(
//                         context.h(6),
//                       ),
//                     ),
//                     child: Text(
//                       _typeLabel,
//                       style: AppTextStyles.caption(context).copyWith(
//                         color: _typeBadgeText(colors),
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                   const Spacer(),
//                   Text(
//                     _elapsed,
//                     style: AppTextStyles.caption(context).copyWith(
//                       color: colors.textMuted,
//                     ),
//                   ),
//                 ],
//               ),

//               SizedBox(
//                 height: context.h(10),
//               ),

//               // ----------------------------------------------------------
//               // Items
//               // ----------------------------------------------------------
//               for (final item in order.items.take(4))
//                 Padding(
//                   padding: EdgeInsets.only(
//                     bottom: context.h(4),
//                   ),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           '${item.quantity}x ${item.name}',
//                           style: AppTextStyles.bodySecondary(context).copyWith(
//                             color: colors.textSecondary,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       SizedBox(
//                         width: context.w(8),
//                       ),
//                       Text(
//                         '₹${(item.price * item.quantity).toStringAsFixed(0)}',
//                         style: AppTextStyles.caption(context).copyWith(
//                           color: colors.textMuted,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//               // Remaining items
//               if (order.items.length > 4)
//                 Padding(
//                   padding: EdgeInsets.only(
//                     top: context.h(2),
//                   ),
//                   child: Text(
//                     '+${order.items.length - 4} more',
//                     style: AppTextStyles.caption(context).copyWith(
//                       color: colors.textMuted,
//                     ),
//                   ),
//                 ),

//               // ----------------------------------------------------------
//               // Order note
//               // ----------------------------------------------------------
//               if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
//                 SizedBox(
//                   height: context.h(6),
//                 ),
//                 Text(
//                   'Note: ${order.notes!.trim()}',
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: AppTextStyles.caption(context).copyWith(
//                     color: colors.textMuted,
//                     fontStyle: FontStyle.italic,
//                   ),
//                 ),
//               ],

//               SizedBox(
//                 height: context.h(10),
//               ),

//               Divider(
//                 height: 1,
//                 color: colors.divider,
//               ),

//               SizedBox(
//                 height: context.h(10),
//               ),

//               // ----------------------------------------------------------
//               // Total + Primary Action
//               // ----------------------------------------------------------
//               Row(
//                 children: [
//                   Text(
//                     '₹${order.total.toStringAsFixed(0)}',
//                     style: AppTextStyles.section(context).copyWith(
//                       color: colors.textPrimary,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const Spacer(),
//                   if (actionLabel != null)
//                     SizedBox(
//                       height: context.h(34),
//                       child: RdxActionButton(
//                         label: updating ? '…' : actionLabel,
//                         isPrimary: true,
//                         onPressed: updating
//                             ? null
//                             : () {
//                                 ref
//                                     .read(
//                                       orderActionsProvider.notifier,
//                                     )
//                                     .advanceStatus(order);
//                               },
//                       ),
//                     ),
//                 ],
//               ),

//               // ----------------------------------------------------------
//               // Cancel
//               // ----------------------------------------------------------
//               if (actionLabel != null) ...[
//                 SizedBox(
//                   height: context.h(6),
//                 ),
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: TextButton(
//                     onPressed: updating
//                         ? null
//                         : () => _confirmCancel(
//                               context,
//                               ref,
//                             ),
//                     style: TextButton.styleFrom(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: context.w(8),
//                       ),
//                       minimumSize: Size.zero,
//                       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                     ),
//                     child: Text(
//                       'Cancel',
//                       style: AppTextStyles.caption(context).copyWith(
//                         color: AppColors.danger,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   String get _elapsed {
//     final difference = DateTime.now().difference(
//       order.createdAt,
//     );

//     final minutes = difference.inMinutes;

//     if (minutes < 1) {
//       return 'Just now';
//     }

//     if (minutes < 60) {
//       return '${minutes}m ago';
//     }

//     final hours = minutes ~/ 60;
//     final remainingMinutes = minutes % 60;

//     if (remainingMinutes == 0) {
//       return '${hours}h ago';
//     }

//     return '${hours}h ${remainingMinutes}m ago';
//   }
// }

import 'package:flutter/material.dart';

import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/order_model.dart';

class LiveOrderCard extends StatelessWidget {
  final OrderModel order;
  final String? actionText;
  final ValueChanged<OrderModel>? onAdvance;
  final VoidCallback? onTap;

  const LiveOrderCard({
    super.key,
    required this.order,
    this.actionText,
    this.onAdvance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(
          color: const Color(0xFF302B2B),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(context.h(10)),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(14),
              context.h(13),
              context.w(14),
              context.h(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------------------------------------------------
                // ORDER ID + TIME
                // ---------------------------------------------------------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        '#RDX-${order.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
                          color: const Color(0xFFE0DCDC),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.schedule_outlined,
                      size: context.h(12),
                      color: const Color(0xFF777070),
                    ),
                    SizedBox(width: context.w(5)),
                    Text(
                      _formatOrderTime(order.createdAt),
                      style: AppTextStyles.caption(context).copyWith(
                        color: const Color(0xFF888080),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.h(10)),

                // ---------------------------------------------------------
                // ITEMS
                // ---------------------------------------------------------
                Text(
                  order.items.isEmpty
                      ? 'Order'
                      : order.items
                          .map(
                            (item) => '${item.quantity}x ${item.name}',
                          )
                          .join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: const Color(0xFFD7D1D1),
                  ),
                ),

                SizedBox(height: context.h(6)),

                // ---------------------------------------------------------
                // CUSTOMER
                // ---------------------------------------------------------
                Text(
                  'Customer: ${order.customerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: const Color(0xFF858080),
                  ),
                ),

                SizedBox(height: context.h(12)),

                // ---------------------------------------------------------
                // DIVIDER
                // ---------------------------------------------------------
                Container(
                  height: 1,
                  color: const Color(0xFF292525),
                ),

                SizedBox(height: context.h(11)),

                // ---------------------------------------------------------
                // ITEMS COUNT + ACTION
                // ---------------------------------------------------------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(7),
                        vertical: context.h(5),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252020),
                        borderRadius: BorderRadius.circular(
                          context.h(5),
                        ),
                        border: Border.all(
                          color: const Color(0xFF302A2A),
                        ),
                      ),
                      child: Text(
                        '${order.items.length} '
                        '${order.items.length == 1 ? 'Item' : 'Items'}',
                        style: AppTextStyles.caption(context).copyWith(
                          color: const Color(0xFFA69D9D),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (actionText != null && onAdvance != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            context.h(5),
                          ),
                          onTap: () => onAdvance!(order),
                          child: Container(
                            height: context.h(28),
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(11),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF214D9B),
                              borderRadius: BorderRadius.circular(
                                context.h(5),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              actionText!,
                              style: AppTextStyles.caption(context).copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatOrderTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}
