import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';

/// Line (wave) chart: revenue trend for Daily / Weekly / Monthly window.
class DashboardRevenueChart extends StatelessWidget {
  final DashboardStatsModel stats;
  final String period;
  final ValueChanged<String> onPeriodChanged;

  const DashboardRevenueChart({
    super.key,
    required this.stats,
    required this.period,
    required this.onPeriodChanged,
  });

  static const _periods = ['Daily', 'Weekly', 'Monthly'];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final points = stats.revenueTrend;
    final spots = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();
    // A line needs at least two days with real revenue to show a trend —
    // a single non-zero point just looks like a stray dot, not a chart.
    final daysWithRevenue = points.where((p) => p.value > 0).length;
    final hasTrend = daysWithRevenue >= 2;

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
          Builder(builder: (context) {
            final narrow = MediaQuery.sizeOf(context).width < 700;
            final titleCol = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revenue trend',
                  style: AppTextStyles.heading(context),
                ),
                SizedBox(height: context.h(6)),
                Text(
                  'How daily revenue is moving — use period tabs to zoom.',
                  style: AppTextStyles.bodySecondary(context),
                ),
              ],
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titleCol,
                  SizedBox(height: context.h(12)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _periodTabs(context, colors),
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titleCol),
                _periodTabs(context, colors),
              ],
            );
          }),
          SizedBox(height: context.h(20)),
          SizedBox(
            height: context.h(200),
            child: !hasTrend
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.show_chart_rounded,
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
                          'Check back after a couple more days of orders.',
                          style: AppTextStyles.caption(context)
                              .copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _niceInterval(spots),
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: colors.border.withValues(alpha: 0.6),
                          strokeWidth: context.w(1),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: context.h(28),
                            interval: _bottomInterval(points.length),
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= points.length) {
                                return const SizedBox();
                              }
                              final d = points[i].date;
                              final label =
                                  '${d.day}/${d.month}';
                              return Padding(
                                padding: EdgeInsets.only(top: context.h(8)),
                                child: Text(
                                  label,
                                  style: AppTextStyles.bodySecondary(context)
                                      .copyWith(color: colors.textMuted),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => colors.surfaceVariant,
                          getTooltipItems: (touched) => touched
                              .map(
                                (t) => LineTooltipItem(
                                  '₹${t.y.toStringAsFixed(0)}',
                                  TextStyle(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: AppColors.primary,
                          barWidth: context.w(3),
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) {
                              if (index == spots.length - 1) {
                                return FlDotCirclePainter(
                                  radius: context.w(5),
                                  color: AppColors.primary,
                                  strokeWidth: context.w(3),
                                  strokeColor: colors.surface,
                                );
                              }
                              return FlDotCirclePainter(
                                radius: 0,
                                color: Colors.transparent,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primary.withValues(alpha: 0.35),
                                AppColors.primary.withValues(alpha: 0.02),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _periodTabs(BuildContext context, AppColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _periods.map((p) {
          final selected = period == p;
          return InkWell(
            onTap: () => onPeriodChanged(p),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(12),
                vertical: context.h(6),
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                p,
                style: AppTextStyles.label(context).copyWith(
                  color: selected ? Colors.white : colors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  double _niceInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 15;
    final max = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    if (max <= 0) return 15;
    return (max / 4).clamp(1, double.infinity);
  }

  double _bottomInterval(int length) {
    if (length <= 8) return 1;
    if (length <= 16) return 2;
    return 3;
  }
}
