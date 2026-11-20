import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/providers/auth_provider.dart';
import 'package:rdx_admin/providers/notification_provider.dart';
import 'package:rdx_admin/widgets/notification_details_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/loading_indicator.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_header.dart';

import '../../core/theme/app_colors.dart';
import '../../models/notification_model.dart';

class NotificationActivityScreen extends ConsumerStatefulWidget {
  const NotificationActivityScreen({super.key});

  @override
  ConsumerState<NotificationActivityScreen> createState() =>
      _NotificationActivityScreenState();
}

class _NotificationActivityScreenState
    extends ConsumerState<NotificationActivityScreen> {
  static const _filters = <({String label, String? category})>[
    (label: 'All activity', category: null),
    (label: 'Orders', category: 'order'),
    (label: 'Payments', category: 'payment'),
    (label: 'Refunds', category: 'refund'),
    (label: 'Support', category: 'support'),
  ];

  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(notificationProvider);
    final uid = ref.watch(authProvider).user?.uid;
    final colors = AppColors.of(context);
    final unreadCount = provider.unreadActivityCountFor(uid);
    final filtered = provider.activity
        .where(
          (item) =>
              _selectedCategory == null || item.category == _selectedCategory,
        )
        .toList(growable: false);
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          RdxHeader(
            title: 'Business activity',
            subtitle: 'A live timeline of customer orders and requests',
            showBackButton: true,
            actions: [
              if (unreadCount > 0 && uid != null)
                TextButton.icon(
                  onPressed: () =>
                      ref.read(notificationProvider).markAllActivityRead(uid),
                  icon: const Icon(Icons.done_all),
                  label: Text(width < 420 ? 'Read all' : 'Mark all read'),
                ),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    Responsive.pageHorizontal(context),
                    context.h(8),
                    Responsive.pageHorizontal(context),
                    context.h(12),
                  ),
                  child: _ActivityOverview(
                    totalCount: provider.activity.length,
                    unreadCount: unreadCount,
                  ),
                ),
                SizedBox(
                  height: context.h(42),
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.pageHorizontal(context),
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => SizedBox(width: context.w(8)),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final selected = _selectedCategory == filter.category;
                      final count = filter.category == null
                          ? provider.activity.length
                          : provider.activity
                              .where((item) => item.category == filter.category)
                              .length;
                      return ChoiceChip(
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (_) => setState(
                          () => _selectedCategory = filter.category,
                        ),
                        avatar: selected
                            ? Icon(
                                Icons.check_rounded,
                                size: context.h(15),
                                color: AppColors.primary,
                              )
                            : null,
                        label: Text('${filter.label}  $count'),
                        labelStyle: AppTextStyles.body(context).copyWith(
                          color: selected
                              ? AppColors.primary
                              : colors.textSecondary,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        backgroundColor: colors.surface,
                        selectedColor: AppColors.primary.withValues(alpha: 0.1),
                        side: BorderSide(
                          color: selected ? AppColors.primary : colors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.h(22)),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(8),
                        ),
                      );
                    },
                  ),
                ),
                if (provider.activityErrorMessage != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      Responsive.pageHorizontal(context),
                      context.h(10),
                      Responsive.pageHorizontal(context),
                      0,
                    ),
                    child: _ActivityError(
                      message: provider.activityErrorMessage!,
                      onRetry: () =>
                          ref.read(notificationProvider).refreshAdminActivity(),
                    ),
                  ),
                SizedBox(height: context.h(10)),
                Expanded(
                  child: provider.isActivityLoading && provider.activity.isEmpty
                      ? const LoadingIndicator()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () => ref
                              .read(notificationProvider)
                              .refreshAdminActivity(),
                          child: filtered.isEmpty
                              ? _EmptyActivity(
                                  category: _selectedCategory,
                                  hasAnyActivity: provider.activity.isNotEmpty,
                                )
                              : ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.fromLTRB(
                                    Responsive.pageHorizontal(context),
                                    context.h(2),
                                    Responsive.pageHorizontal(context),
                                    context.h(24),
                                  ),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      SizedBox(height: context.h(10)),
                                  itemBuilder: (context, index) {
                                    final item = filtered[index];
                                    final isRead =
                                        uid == null || item.isReadBy(uid);
                                    return _ActivityCard(
                                      notification: item,
                                      isRead: isRead,
                                      onTap: () =>
                                          _openDetails(item, uid, isRead),
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetails(
    NotificationModel notification,
    String? uid,
    bool isRead,
  ) async {
    if (!isRead && uid != null) {
      await ref
          .read(notificationProvider)
          .markActivityRead(notification.id, uid);
    }
    if (!mounted) return;
    await showNotificationDetails(context, notification);
  }
}

class _ActivityOverview extends StatelessWidget {
  const _ActivityOverview({
    required this.totalCount,
    required this.unreadCount,
  });

  final int totalCount;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 480;
    final intro = Row(
      children: [
        Container(
          width: context.h(42),
          height: context.h(42),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(context.h(12)),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.notifications_active_outlined,
            color: AppColors.primary,
            size: context.h(21),
          ),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live activity',
                style: AppTextStyles.bodyLargeSemi(context)
                    .copyWith(color: colors.textPrimary),
              ),
              SizedBox(height: context.h(3)),
              Text(
                'The latest 50 events are shown',
                style: AppTextStyles.caption(context)
                    .copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
    final counts = Wrap(
      spacing: context.w(8),
      runSpacing: context.h(6),
      children: [
        _CountPill(
          label: 'Recent',
          value: totalCount,
          color: colors.textSecondary,
        ),
        _CountPill(
          label: 'Unread',
          value: unreadCount,
          color: unreadCount > 0 ? AppColors.primary : colors.textSecondary,
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(context.h(16)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(14)),
        border: Border.all(color: colors.border),
      ),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                intro,
                SizedBox(height: context.h(14)),
                counts,
              ],
            )
          : Row(
              children: [
                Expanded(child: intro),
                SizedBox(width: context.w(16)),
                counts,
              ],
            ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(11),
        vertical: context.h(7),
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(context.h(20)),
      ),
      child: Text(
        '$label  $value',
        style: AppTextStyles.caption(context).copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  final NotificationModel notification;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isNarrow = MediaQuery.sizeOf(context).width < 480;

    return Material(
      color:
          isRead ? colors.surface : AppColors.primary.withValues(alpha: 0.035),
      borderRadius: BorderRadius.circular(context.h(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.h(14)),
        child: Container(
          padding: EdgeInsets.all(isNarrow ? context.h(13) : context.h(16)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.h(14)),
            border: Border.all(
              color: isRead
                  ? colors.border
                  : AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: context.h(42),
                height: context.h(42),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(context.h(12)),
                ),
                alignment: Alignment.center,
                child: Icon(
                  notificationCategoryIcon(notification.category),
                  color: AppColors.primary,
                  size: context.h(20),
                ),
              ),
              SizedBox(width: context.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: context.w(8),
                      runSpacing: context.h(3),
                      children: [
                        Text(
                          notificationCategoryLabel(notification.category),
                          style: AppTextStyles.caption(context).copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (!isRead)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.w(7),
                              vertical: context.h(2),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(context.h(10)),
                            ),
                            child: Text(
                              'NEW',
                              style: AppTextStyles.caption(context).copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: context.h(5)),
                    Text(
                      notification.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLargeSemi(context)
                          .copyWith(color: colors.textPrimary),
                    ),
                    SizedBox(height: context.h(5)),
                    Text(
                      notification.message,
                      maxLines: isNarrow ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(context)
                          .copyWith(color: colors.textSecondary),
                    ),
                    SizedBox(height: context.h(8)),
                    Wrap(
                      spacing: context.w(14),
                      runSpacing: context.h(4),
                      children: [
                        if (notification.sourceId != null &&
                            notification.sourceId!.isNotEmpty)
                          _Metadata(
                            icon: Icons.tag_outlined,
                            text:
                                '${_referenceLabel(notification.category)} ${notification.sourceId}',
                          ),
                        _Metadata(
                          icon: Icons.access_time_rounded,
                          text: _formatDateTime(notification.createdAt),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.w(6)),
              Padding(
                padding: EdgeInsets.only(top: context.h(7)),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: colors.textMuted,
                  size: context.h(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _referenceLabel(String category) =>
      category == 'support' ? 'Request' : 'Order';

  static String _formatDateTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year} '
        '$hour:$minute $period';
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: context.h(13), color: colors.textMuted),
        SizedBox(width: context.w(4)),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context)
                .copyWith(color: colors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _ActivityError extends StatelessWidget {
  const _ActivityError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(8),
      ),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(context.h(9)),
        border: Border.all(color: colors.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.danger, size: context.h(17)),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body(context).copyWith(color: colors.danger),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity({
    required this.category,
    required this.hasAnyActivity,
  });

  final String? category;
  final bool hasAnyActivity;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final title =
        hasAnyActivity ? 'No matching activity' : 'You’re all caught up';
    final message = hasAnyActivity
        ? 'Try another activity filter.'
        : 'New customer orders, payments, refunds, and support requests will appear here.';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.pageHorizontal(context),
        vertical: context.h(48),
      ),
      children: [
        Center(
          child: Container(
            width: context.h(54),
            height: context.h(54),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              category == null
                  ? Icons.notifications_none_rounded
                  : notificationCategoryIcon(category!),
              color: colors.textMuted,
              size: context.h(26),
            ),
          ),
        ),
        SizedBox(height: context.h(14)),
        Center(
          child: Text(
            title,
            style: AppTextStyles.bodyLargeSemi(context)
                .copyWith(color: colors.textPrimary),
          ),
        ),
        SizedBox(height: context.h(6)),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.body(context).copyWith(color: colors.textMuted),
            ),
          ),
        ),
      ],
    );
  }
}
