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

  IconData get _orderTypeIcon {
    switch (order.orderType) {
      case OrderType.dineIn:
        return Icons.restaurant_outlined;
      case OrderType.takeaway:
        return Icons.shopping_bag_outlined;
      case OrderType.delivery:
        return Icons.delivery_dining_outlined;
    }
  }

  String get _elapsed {
    final minutes = DateTime.now().difference(order.createdAt).inMinutes;
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return '${minutes}m ago';
    return '${(minutes / 60).floor()}h ${minutes % 60}m ago';
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Cancel Order',
        itemName: '#${order.id.length >= 6 ? order.id.substring(0, 6) : order.id}',
        deleteButtonLabel: 'Cancel Order',
        warningMessage: 'This will mark the order as cancelled. This cannot be undone.',
      ),
    );
    if (confirmed == true) {
      await ref.read(orderActionsProvider.notifier).cancelOrder(order);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final updating = ref.watch(orderActionsProvider.select((s) => s.contains(order.id)));
    final actionLabel = order.status.advanceActionLabel;

    final itemsSummary = order.items.take(3).map((i) => '${i.quantity}x ${i.name}').join(', ');
    final moreCount = order.items.length - 3;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: context.h(12)),
      padding: EdgeInsets.all(context.h(14)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_orderTypeIcon, size: context.h(16), color: AppColors.primary),
              SizedBox(width: context.w(6)),
              Text(
                order.orderType == OrderType.dineIn && (order.tableNumber ?? '').isNotEmpty
                    ? '${order.orderType.label} · ${order.tableNumber}'
                    : order.orderType.label,
                style: AppTextStyles.label(context).copyWith(color: colors.textPrimary),
              ),
              const Spacer(),
              Text(_elapsed,
                  style: AppTextStyles.caption(context).copyWith(color: colors.textMuted)),
            ],
          ),
          SizedBox(height: context.h(8)),
          Text(order.customerName,
              style: AppTextStyles.body(context)
                  .copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600)),
          if (order.customerPhone.isNotEmpty)
            Text(order.customerPhone,
                style: AppTextStyles.bodyTertiary(context).copyWith(color: colors.textSecondary)),
          SizedBox(height: context.h(8)),
          Text(
            moreCount > 0 ? '$itemsSummary, +$moreCount more' : itemsSummary,
            style: AppTextStyles.bodySecondary(context).copyWith(color: colors.textSecondary),
          ),
          if (order.orderType == OrderType.delivery && order.deliveryAddress.isNotEmpty) ...[
            SizedBox(height: context.h(6)),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: context.h(14), color: colors.textMuted),
                SizedBox(width: context.w(4)),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(color: colors.textMuted),
                  ),
                ),
              ],
            ),
          ],
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            SizedBox(height: context.h(6)),
            Text(
              'Note: ${order.notes}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context)
                  .copyWith(color: colors.textMuted, fontStyle: FontStyle.italic),
            ),
          ],
          SizedBox(height: context.h(10)),
          Row(
            children: [
              if (order.paymentMethod != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.w(8), vertical: context.h(3)),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(context.h(6)),
                  ),
                  child: Text(order.paymentMethod!.label,
                      style: AppTextStyles.caption(context).copyWith(color: colors.textSecondary)),
                ),
              const Spacer(),
              Text('₹${order.total.toStringAsFixed(0)}',
                  style: AppTextStyles.section(context).copyWith(color: colors.textPrimary)),
            ],
          ),
          if (actionLabel != null) ...[
            SizedBox(height: context.h(10)),
            Row(
              children: [
                Expanded(
                  child: RdxActionButton(
                    label: updating ? 'Updating...' : actionLabel,
                    isPrimary: true,
                    onPressed: updating
                        ? null
                        : () => ref.read(orderActionsProvider.notifier).advanceStatus(order),
                  ),
                ),
                SizedBox(width: context.w(8)),
                TextButton(
                  onPressed: updating ? null : () => _confirmCancel(context, ref),
                  child: Text('Cancel',
                      style: AppTextStyles.label(context).copyWith(color: AppColors.danger)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
