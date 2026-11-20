import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/notification_model.dart';

import '../core/theme/app_colors.dart';

String notificationCategoryLabel(String category) {
  switch (category) {
    case 'order':
      return 'Order';
    case 'payment':
      return 'Payment';
    case 'refund':
      return 'Refund';
    case 'support':
      return 'Support request';
    default:
      return 'Activity';
  }
}

IconData notificationCategoryIcon(String category) {
  switch (category) {
    case 'order':
      return Icons.receipt_long_outlined;
    case 'payment':
      return Icons.payments_outlined;
    case 'refund':
      return Icons.currency_exchange_outlined;
    case 'support':
      return Icons.support_agent_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

Future<void> showNotificationDetails(
  BuildContext context,
  NotificationModel notification,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => NotificationDetailsDialog(notification: notification),
  );
}

class NotificationDetailsDialog extends StatelessWidget {
  const NotificationDetailsDialog({
    required this.notification,
    super.key,
  });

  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isNarrow = MediaQuery.sizeOf(context).width < 480;
    final referenceLabel =
        notification.category == 'support' ? 'Request' : 'Order';
    final maxWidth = (MediaQuery.sizeOf(context).width - context.w(32))
        .clamp(0.0, 520.0)
        .toDouble();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(24),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(context.h(18)),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.16),
                blurRadius: context.h(32),
                offset: Offset(0, context.h(12)),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.w(20),
                  context.h(18),
                  context.w(12),
                  context.h(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: context.h(44),
                      height: context.h(44),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(context.h(13)),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        notificationCategoryIcon(notification.category),
                        color: AppColors.primary,
                        size: context.h(22),
                      ),
                    ),
                    SizedBox(width: context.w(12)),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: context.h(1)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notificationCategoryLabel(notification.category)
                                  .toUpperCase(),
                              style: AppTextStyles.caption(context).copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            SizedBox(height: context.h(4)),
                            Text(
                              notification.title,
                              maxLines: isNarrow ? 3 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.h3(context)
                                  .copyWith(color: colors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close details',
                      onPressed: () => Navigator.pop(context),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.close,
                        color: colors.textMuted,
                        size: context.h(19),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.divider),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(context.h(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: EdgeInsets.all(context.h(16)),
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(context.h(12)),
                          border: Border.all(color: colors.border),
                        ),
                        child: Text(
                          notification.message,
                          style: AppTextStyles.body(context)
                              .copyWith(color: colors.textPrimary),
                        ),
                      ),
                      SizedBox(height: context.h(16)),
                      if (notification.sourceId != null &&
                          notification.sourceId!.isNotEmpty)
                        _DetailRow(
                          label: referenceLabel,
                          value: notification.sourceId!,
                        ),
                      _DetailRow(
                        label: 'Received',
                        value: _formatDateTime(notification.createdAt),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.w(16),
                  context.h(4),
                  context.w(16),
                  context.h(14),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(22),
                        vertical: context.h(11),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.h(9)),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year} '
        '$hour:$minute $period';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.w(80),
            child: Text(
              label,
              style:
                  AppTextStyles.body(context).copyWith(color: colors.textMuted),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: AppTextStyles.bodySemi(context)
                  .copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
