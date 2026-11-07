import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_empty.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_card_style.dart';

/// Zomato "Orders by mealtime" with rich progress rows.
class DashboardMealtimeBreakdown extends StatelessWidget {
  final DashboardStatsModel stats;

  const DashboardMealtimeBreakdown({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final total = stats.totalMealtime;

    final items = [
      _Meal('Breakfast', '7:00–11:00', stats.breakfastCount,
          stats.breakfastPercent,
          stats.mealtimeFractions['breakfast'] ?? 0,
          const Color(0xFFFDE68A)),
      _Meal('Lunch', '11:00–16:00', stats.lunchCount, stats.lunchPercent,
          stats.mealtimeFractions['lunch'] ?? 0, const Color(0xFFD97706)),
      _Meal('Evening', '16:00–19:00', stats.eveningCount, stats.eveningPercent,
          stats.mealtimeFractions['evening'] ?? 0, AppColors.primary),
      _Meal(
          'Dinner', '19:00–23:00', stats.dinnerCount, stats.dinnerPercent,
          stats.mealtimeFractions['dinner'] ?? 0, const Color(0xFF93C5FD)),
      _Meal('Late night', '23:00–7:00', stats.lateNightCount,
          stats.lateNightPercent,
          stats.mealtimeFractions['late_night'] ?? 0,
          const Color(0xFF1D4ED8)),
    ];

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: context.h(400)),
      padding: EdgeInsets.fromLTRB(
        context.w(22),
        context.h(16),
        context.w(22),
        context.h(16),
      ),
      decoration: DashboardCardStyle.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Orders by mealtime',
                    style: DashboardCardStyle.title(context)),
              ),
            ],
          ),
          if (total > 0) ...[
            SizedBox(height: context.h(4)),
            Text(
              '$total orders across all mealtimes',
              style: DashboardCardStyle.description(context),
            ),
          ],
          if (total == 0)
            SizedBox(
              height: context.h(300),
              child: const Center(
                child: DashboardEmpty(
                  icon: Icons.schedule_rounded,
                  title: 'No order data available',
                  subtitle:
                      'Mealtime totals will appear after orders are recorded.',
                ),
              ),
            )
          else ...[
            SizedBox(height: context.h(16)),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(height: context.h(12)),
              _row(context, colors, items[i]),
            ],
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, AppColorScheme colors, _Meal item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: AppTextStyles.body(context)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${item.count}',
              style: AppTextStyles.body(context)
                  .copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(width: context.w(8)),
            SizedBox(
              width: context.w(40),
              child: Text(
                '${item.percent.toStringAsFixed(0)}%',
                textAlign: TextAlign.right,
                style: AppTextStyles.caption(context).copyWith(
                  color: const Color(0xFF16A34A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(2)),
        Text(
          item.time,
          style: AppTextStyles.caption(context)
              .copyWith(color: colors.textMuted),
        ),
        SizedBox(height: context.h(7)),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            children: [
              Container(
                height: context.h(6),
                color: colors.border.withValues(alpha: 0.35),
              ),
              FractionallySizedBox(
                widthFactor: item.fraction.clamp(0.0, 1.0),
                child: Container(
                  height: context.h(6),
                  color: item.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Meal {
  final String label;
  final String time;
  final int count;
  final double percent;
  final double fraction;
  final Color color;
  const _Meal(
    this.label,
    this.time,
    this.count,
    this.percent,
    this.fraction,
    this.color,
  );
}
