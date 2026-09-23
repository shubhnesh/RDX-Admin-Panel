import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';

/// Simple comparison bars: order type + staff vs app.
class DashboardOrderMix extends StatelessWidget {
  final DashboardStatsModel stats;

  const DashboardOrderMix({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final typeTotal =
        (stats.dineInCount + stats.takeawayCount + stats.deliveryCount)
            .clamp(1, 1 << 30);
    final sourceTotal =
        (stats.staffOrderCount + stats.appOrderCount).clamp(1, 1 << 30);
    final hasOrders = stats.todayOrderCount > 0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(20),
        context.h(18),
        context.w(20),
        context.h(16),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order mix',
                  style: AppTextStyles.heading(context),
                ),
              ),
              Text(
                'Today',
                style: AppTextStyles.label(context).copyWith(color: AppColors.primary),
              ),
            ],
          ),
          SizedBox(height: context.h(8)),
          if (!hasOrders)
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.h(20)),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      size: context.h(28),
                      color: colors.textMuted,
                    ),
                    SizedBox(height: context.h(8)),
                    Text(
                      'Not enough data yet',
                      style: AppTextStyles.bodySecondary(context)
                          .copyWith(color: colors.textSecondary),
                    ),
                    SizedBox(height: context.h(4)),
                    Text(
                      'The mix will show up once orders come in.',
                      style: AppTextStyles.caption(context)
                          .copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else ...[
          Text(
            'By service type',
            style: AppTextStyles.bodySecondary(context)
          ),
          SizedBox(height: context.h(8)),
          _bar(
            context,
            colors,
            label: 'Dine-in',
            value: stats.dineInCount,
            total: typeTotal,
            color: AppColors.primary,
          ),
          SizedBox(height: context.h(8)),
          _bar(
            context,
            colors,
            label: 'Takeaway',
            value: stats.takeawayCount,
            total: typeTotal,
            color: const Color(0xFF7C5CFC),
          ),
          SizedBox(height: context.h(8)),
          _bar(
            context,
            colors,
            label: 'Delivery',
            value: stats.deliveryCount,
            total: typeTotal,
            color: const Color(0xFF20B47A),
          ),
          SizedBox(height: context.h(16)),
          Text(
            'By source',
            style: AppTextStyles.bodySecondary(context).copyWith(
              color: colors.textMuted,
            ),
          ),
          SizedBox(height: context.h(8)),
          _bar(
            context,
            colors,
            label: 'Staff (POS)',
            value: stats.staffOrderCount,
            total: sourceTotal,
            color: const Color(0xFF5AC8FA),
          ),
          SizedBox(height: context.h(8)),
          _bar(
            context,
            colors,
            label: 'App',
            value: stats.appOrderCount,
            total: sourceTotal,
            color: const Color(0xFFE9A719),
          ),
          ],
        ],
      ),
    );
  }

  Widget _bar(
    BuildContext context,
    AppColorScheme colors, {
    required String label,
    required int value,
    required int total,
    required Color color,
  }) {
    final pct = total == 0 ? 0.0 : value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.label(context).copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            Text(
              '$value',
              style: AppTextStyles.label(context).copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(4)),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: colors.border,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
