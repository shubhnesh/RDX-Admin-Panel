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

  const LiveOrderCard({
    super.key,
    required this.order,
  });

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

      case OrderType.takeaway:
        return 'To Go';

      case OrderType.delivery:
        return 'Delivery';
    }
  }

  Color _typeBadgeColor(AppColorScheme colors) {
    switch (order.orderType) {
      case OrderType.dineIn:
        return AppColors.primary.withValues(alpha: 0.12);

      case OrderType.takeaway:
        return colors.surfaceVariant;

      case OrderType.delivery:
        return const Color(0xFFE8F5E9);
    }
  }

  Color _typeBadgeText(AppColorScheme colors) {
    switch (order.orderType) {
      case OrderType.dineIn:
        return AppColors.primary;

      case OrderType.takeaway:
        return colors.textSecondary;

      case OrderType.delivery:
        return const Color(0xFF2E7D32);
    }
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
  ) async {
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

    if (confirmed != true) {
      return;
    }

    await ref.read(orderActionsProvider.notifier).cancelOrder(order);
  }

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final colors = AppColors.of(context);

    final updating = ref.watch(
      orderActionsProvider.select(
        (state) => state.contains(order.id),
      ),
    );

    final actionLabel = order.status.advanceActionLabel;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(
        bottom: context.h(12),
      ),
      padding: EdgeInsets.all(
        context.h(14),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(
          context.h(12),
        ),
        border: Border.all(
          color: colors.border,
        ),
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
          // ----------------------------------------------------------
          // Header
          // ----------------------------------------------------------
          Row(
            children: [
              Text(
                '#$_orderIdShort',
                style: AppTextStyles.section(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(
                width: context.w(8),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(8),
                  vertical: context.h(3),
                ),
                decoration: BoxDecoration(
                  color: _typeBadgeColor(colors),
                  borderRadius: BorderRadius.circular(
                    context.h(6),
                  ),
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
                style: AppTextStyles.caption(context).copyWith(
                  color: colors.textMuted,
                ),
              ),
            ],
          ),

          SizedBox(
            height: context.h(10),
          ),

          // ----------------------------------------------------------
          // Items
          // ----------------------------------------------------------
          for (final item in order.items.take(4))
            Padding(
              padding: EdgeInsets.only(
                bottom: context.h(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.name}',
                      style: AppTextStyles.bodySecondary(context).copyWith(
                        color: colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: context.w(8),
                  ),
                  Text(
                    '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                    style: AppTextStyles.caption(context).copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

          // Remaining items
          if (order.items.length > 4)
            Padding(
              padding: EdgeInsets.only(
                top: context.h(2),
              ),
              child: Text(
                '+${order.items.length - 4} more',
                style: AppTextStyles.caption(context).copyWith(
                  color: colors.textMuted,
                ),
              ),
            ),

          // ----------------------------------------------------------
          // Order note
          // ----------------------------------------------------------
          if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
            SizedBox(
              height: context.h(6),
            ),
            Text(
              'Note: ${order.notes!.trim()}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                color: colors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          SizedBox(
            height: context.h(10),
          ),

          Divider(
            height: 1,
            color: colors.divider,
          ),

          SizedBox(
            height: context.h(10),
          ),

          // ----------------------------------------------------------
          // Total + Primary Action
          // ----------------------------------------------------------
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
                        : () {
                            ref
                                .read(
                                  orderActionsProvider.notifier,
                                )
                                .advanceStatus(order);
                          },
                  ),
                ),
            ],
          ),

          // ----------------------------------------------------------
          // Cancel
          // ----------------------------------------------------------
          if (actionLabel != null) ...[
            SizedBox(
              height: context.h(6),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: updating
                    ? null
                    : () => _confirmCancel(
                          context,
                          ref,
                        ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(8),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _elapsed {
    final difference = DateTime.now().difference(
      order.createdAt,
    );

    final minutes = difference.inMinutes;

    if (minutes < 1) {
      return 'Just now';
    }

    if (minutes < 60) {
      return '${minutes}m ago';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '${hours}h ago';
    }

    return '${hours}h ${remainingMinutes}m ago';
  }
}
