import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';

/// Bar chart: today's order volume by hour.
class DashboardHourlyChart extends StatelessWidget {
  final DashboardStatsModel stats;

  const DashboardHourlyChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final values = stats.hourlyVolume;
    final labels = stats.hourlyLabels;
    final rangeLabels = stats.hourlyRangeLabels;

    final peakValue = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b);
    final maxY = peakValue > 0 ? peakValue * 1.15 : 1.0;
    final peakIndex = values.isEmpty ? -1 : values.indexOf(peakValue);
    final hasData = values.any((v) => v > 0);

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
                  'Volume Trend',
                  style: AppTextStyles.heading(context),
                ),
              ),
              Text(
                  'Today',
                  style: AppTextStyles.label(context).copyWith(color: AppColors.primary),
                ),
            ],
          ),
          SizedBox(height: context.h(6)),
          Text(
            'Orders by hour',
            style: AppTextStyles.bodySecondary(context),
          ),
          SizedBox(height: context.h(16)),
          SizedBox(
            height: context.h(160),
            child: !hasData
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
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
                          'Volume will appear here once orders come in.',
                          style: AppTextStyles.caption(context)
                              .copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxY,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
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
                            reservedSize: context.h(24),
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= labels.length) {
                                return const SizedBox();
                              }
                              return Padding(
                                padding: EdgeInsets.only(top: context.h(6)),
                                child: Text(
                                  labels[i],
                                  style: TextStyle(
                                    color: colors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => colors.textPrimary,
                          tooltipRoundedRadius: 8,
                          tooltipPadding: EdgeInsets.symmetric(
                            horizontal: context.w(10),
                            vertical: context.h(6),
                          ),
                          tooltipMargin: context.h(8),
                          fitInsideVertically: true,
                          fitInsideHorizontally: true,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final orders = rod.toY.round();
                            final label = groupIndex >= 0 &&
                                    groupIndex < rangeLabels.length
                                ? rangeLabels[groupIndex]
                                : '';
                            return BarTooltipItem(
                              '$orders order${orders == 1 ? '' : 's'}\n',
                              TextStyle(
                                color: colors.surface,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: label,
                                  style: TextStyle(
                                    color: colors.surface.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w400,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      barGroups: values.asMap().entries.map((e) {
                        final isPeak = e.key == peakIndex;
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value,
                              width: context.w(28),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(context.w(3)),
                              ),
                              color: isPeak
                                  ? AppColors.primary
                                  : AppColors.primary.withValues(alpha: 0.45),
                            ),
                          ],
                          // Tooltip only on hover / tap — never pinned.
                          showingTooltipIndicators: const [],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
