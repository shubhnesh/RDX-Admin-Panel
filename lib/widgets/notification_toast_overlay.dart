import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/notification_model.dart';
import 'package:rdx_admin/providers/auth_provider.dart';
import 'package:rdx_admin/providers/notification_provider.dart';
import 'package:rdx_admin/widgets/notification_details_dialog.dart';

import '../core/theme/app_colors.dart';

class NotificationToastOverlay extends ConsumerWidget {
  const NotificationToastOverlay({
    required this.bottomInset,
    super.key,
  });

  final double bottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(notificationProvider);
    final notification = provider.incomingActivity.isEmpty
        ? null
        : provider.incomingActivity.first;
    final width = (MediaQuery.sizeOf(context).width - context.w(32))
        .clamp(0.0, context.w(390))
        .toDouble();

    return Positioned(
      right: context.w(16),
      bottom: bottomInset,
      child: SizedBox(
        width: width,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: notification == null
              ? const SizedBox.shrink()
              : _IncomingNotificationToast(
                  key: ValueKey(notification.id),
                  notification: notification,
                ),
        ),
      ),
    );
  }
}

class _IncomingNotificationToast extends ConsumerStatefulWidget {
  const _IncomingNotificationToast({
    required this.notification,
    super.key,
  });

  final NotificationModel notification;

  @override
  ConsumerState<_IncomingNotificationToast> createState() =>
      _IncomingNotificationToastState();
}

class _IncomingNotificationToastState
    extends ConsumerState<_IncomingNotificationToast> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _startDismissTimer();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;
    ref
        .read(notificationProvider)
        .dismissIncomingActivity(widget.notification.id);
  }

  void _startDismissTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 8), _dismiss);
  }

  Future<void> _openDetails() async {
    final notification = widget.notification;
    final provider = ref.read(notificationProvider);
    final uid = ref.read(authProvider).user?.uid;
    if (uid != null) {
      await provider.markActivityRead(notification.id, uid);
    }
    if (!mounted) return;

    provider.dismissIncomingActivity(notification.id);
    await showNotificationDetails(context, notification);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final notification = widget.notification;

    return MouseRegion(
      onEnter: (_) => _dismissTimer?.cancel(),
      onExit: (_) => _startDismissTimer(),
      child: Material(
        color: colors.surface,
        elevation: 14,
        shadowColor: AppColors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(context.h(16)),
        child: InkWell(
          onTap: _openDetails,
          borderRadius: BorderRadius.circular(context.h(16)),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              context.w(15),
              context.h(13),
              context.w(10),
              context.h(13),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.h(16)),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: context.h(38),
                      height: context.h(38),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(context.h(11)),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        notificationCategoryIcon(notification.category),
                        color: AppColors.primary,
                        size: context.h(20),
                      ),
                    ),
                    SizedBox(width: context.w(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEW ${notificationCategoryLabel(notification.category).toUpperCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(context).copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.55,
                            ),
                          ),
                          SizedBox(height: context.h(2)),
                          Text(
                            _relativeTime(notification.createdAt),
                            style: AppTextStyles.caption(context)
                                .copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Dismiss notification',
                      onPressed: _dismiss,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.close,
                        size: context.h(17),
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(11)),
                Text(
                  notification.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLargeSemi(context)
                      .copyWith(color: colors.textPrimary),
                ),
                SizedBox(height: context.h(4)),
                Text(
                  notification.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(context)
                      .copyWith(color: colors.textSecondary),
                ),
                SizedBox(height: context.h(9)),
                Row(
                  children: [
                    Icon(
                      Icons.open_in_new_rounded,
                      size: context.h(14),
                      color: AppColors.primary,
                    ),
                    SizedBox(width: context.w(5)),
                    Text(
                      'View details',
                      style: AppTextStyles.caption(context).copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (notification.sourceId != null &&
                        notification.sourceId!.isNotEmpty)
                      Flexible(
                        child: Text(
                          notification.sourceId!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: AppTextStyles.caption(context)
                              .copyWith(color: colors.textMuted),
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

  static String _relativeTime(DateTime date) {
    final elapsed = DateTime.now().difference(date);
    if (elapsed.inSeconds < 60) return 'Just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} min ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours} hr ago';
    return '${elapsed.inDays} days ago';
  }
}
