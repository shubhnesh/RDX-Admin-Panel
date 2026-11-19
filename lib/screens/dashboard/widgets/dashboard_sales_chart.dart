import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/formatters.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_empty.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_card_style.dart';

/// Zomato-style Sales & Orders combined chart (last 7 days).
class DashboardSalesChart extends StatelessWidget {
  final DashboardStatsModel stats;

  const DashboardSalesChart({super.key, required this.stats});

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
  static List<DailyPoint> _lastSevenDays(List<DailyPoint> source) {
    final sorted = List<DailyPoint>.from(source)
      ..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.length <= 7) return sorted;
    return sorted.sublist(sorted.length - 7);
  }

  // Brand blue palette for this chart.
  Color get _salesColor => AppColors.secondary;
  Color get _ordersColor => AppColors.secondary.withValues(alpha: 0.35);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final sales = _lastSevenDays(stats.salesTrend);
    final orders = _lastSevenDays(stats.ordersTrend);
    final hasData =
        sales.any((p) => p.value > 0) || orders.any((p) => p.value > 0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.w(20),
        context.h(16),
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
                child: Text('Sales and orders',
                    style: DashboardCardStyle.title(context)),
              ),
              _legend(context, _salesColor, 'Net sales'),
              SizedBox(width: context.w(12)),
              _legend(context, _ordersColor, 'Orders'),
            ],
          ),
          if (hasData) ...[
            SizedBox(height: context.h(3)),
            Text('Daily sales and relative order volume over the last 7 days',
                style: DashboardCardStyle.description(context)),
          ],
          SizedBox(height: context.h(hasData ? 14 : 8)),
          SizedBox(
            height: context.h(220),
            child: Center(
              child: !hasData
                  ? const DashboardEmpty(
                      icon: Icons.bar_chart_rounded,
                      title: 'No sales data available',
                      subtitle:
                          'Daily results will appear after orders are recorded.',
                    )
                  : _chart(context, colors, sales, orders),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: context.w(8),
          height: context.h(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: context.w(5)),
        Text(
          label,
          style: AppTextStyles.caption(context)
              .copyWith(color: AppColors.of(context).textSecondary),
        ),
      ],
    );
  }

  Widget _chart(
    BuildContext context,
    AppColorScheme colors,
    List<DailyPoint> sales,
    List<DailyPoint> orders,
  ) {
    final maxSales = sales.isEmpty
        ? 1.0
        : sales.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final maxOrders = orders.isEmpty
        ? 1.0
        : orders.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final scale = maxOrders == 0 ? 1.0 : maxSales / maxOrders;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxSales > 0 ? maxSales : 1) * 1.2,
        minY: 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1E293B),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              // Show the real value for each bar (orders are drawn scaled).
              final i = group.x;
              final isSales = rodIndex == 0;
              final String text;
              if (isSales) {
                text =
                    'Net sales\n${Formatters.currency(sales[i].value, symbol: '₹')}';
              } else {
                final count = orders.length > i ? orders[i].value.round() : 0;
                text = 'Orders\n$count';
              }
              return BarTooltipItem(
                text,
                AppTextStyles.caption(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: colors.border.withValues(alpha: 0.45),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= sales.length) return const SizedBox.shrink();
                final isToday = i == sales.length - 1;
                final label =
                    isToday ? 'Today' : _dayNames[_toIst(sales[i].date).weekday - 1];
                return Padding(
                  padding: EdgeInsets.only(top: context.h(6)),
                  child: Text(
                    label,
                    style: AppTextStyles.caption(context).copyWith(
                      color: isToday ? colors.textPrimary : colors.textMuted,
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < sales.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: sales[i].value,
                  width: context.w(10),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      _salesColor.withValues(alpha: 0.6),
                      _salesColor,
                    ],
                  ),
                ),
                BarChartRodData(
                  toY: orders.length > i ? orders[i].value * scale : 0,
                  width: context.w(10),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      _salesColor.withValues(alpha: 0.2),
                      _salesColor.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}