import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/formatters.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_empty.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_card_style.dart';

/// Zomato-style Average Order Value trend (last 7 days).
class DashboardAovTrend extends StatelessWidget {
  final DashboardStatsModel stats;

  const DashboardAovTrend({super.key, required this.stats});

  static const List<String> _dayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// Server sends IST-midnight timestamps (UTC ISO strings). Always read the
  /// calendar day in IST so the weekday label is right on any device timezone.
  static DateTime _toIst(DateTime d) =>
      d.toUtc().add(const Duration(hours: 5, minutes: 30));

  /// Sorted oldest -> newest, limited to the last 7 days.
  List<DailyPoint> _lastSevenDays() {
    final sorted = List<DailyPoint>.from(stats.aovTrend)
      ..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.length <= 7) return sorted;
    return sorted.sublist(sorted.length - 7);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final points = _lastSevenDays();
    final hasData = points.any((p) => p.value > 0);
    final maxValue = points.isEmpty
        ? 0.0
        : points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.2;
    final current = stats.averageOrderValue;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: context.h(400)),
      padding: EdgeInsets.fromLTRB(
        context.w(20),
        context.h(14),
        context.w(20),
        context.h(14),
      ),
      decoration: DashboardCardStyle.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Average order value',
                    style: DashboardCardStyle.title(context)),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Formatters.currency(current, symbol: '₹'),
                    style: AppTextStyles.h2(context)
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
          if (hasData) ...[
            SizedBox(height: context.h(2)),
            Text('Daily average order value over the last 7 days',
                style: DashboardCardStyle.description(context)),
          ],
          SizedBox(height: context.h(hasData ? 12 : 8)),
          // Fixed-height area; content is centered vertically inside it so the
          // graph sits in the middle of the card.
          SizedBox(
            height: context.h(300),
            child: Center(
              child: !hasData
                  ? const DashboardEmpty(
                      icon: Icons.trending_up_rounded,
                      title: 'No order value data available',
                      subtitle:
                          'Daily averages will appear after orders are recorded.',
                    )
                  : SizedBox(
                      height: context.h(220),
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: (points.length - 1).toDouble(),
                          maxY: maxY,
                          minY: 0,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (v) => FlLine(
                              color: colors.border.withValues(alpha: 0.4),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  // Only draw labels on whole-number positions.
                                  if (value != value.roundToDouble()) {
                                    return const SizedBox.shrink();
                                  }
                                  final i = value.toInt();
                                  if (i < 0 || i >= points.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final isToday = i == points.length - 1;
                                  final label = isToday
                                      ? 'Today'
                                      : _dayNames[
                                          _toIst(points[i].date).weekday - 1];
                                  return Padding(
                                    padding: EdgeInsets.only(top: context.h(6)),
                                    child: Text(
                                      label,
                                      style: AppTextStyles.caption(context)
                                          .copyWith(
                                        color: isToday
                                            ? colors.textPrimary
                                            : colors.textMuted,
                                        fontWeight: isToday
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (var i = 0; i < points.length; i++)
                                  FlSpot(i.toDouble(), points[i].value),
                              ],
                              isCurved: false,
                              color: const Color(0xFF334155),
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (s, p, b, i) =>
                                    FlDotCirclePainter(
                                  radius: 3,
                                  color: DashboardCardStyle
                                      .averageOrderValueAccent,
                                  strokeWidth: 1,
                                  strokeColor: AppColors.white,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF334155)
                                    .withValues(alpha: 0.08),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}