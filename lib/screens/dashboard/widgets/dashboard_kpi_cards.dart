import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/formatters.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_empty.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_card_style.dart';

/// Zomato Sales-style KPI strip: Net sales · Orders delivered · AOV
class DashboardKpiCards extends StatelessWidget {
  final DashboardStatsModel stats;

  const DashboardKpiCards({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final hasAny = stats.netSales > 0 ||
        stats.ordersDelivered > 0 ||
        stats.averageOrderValue > 0;

    if (!hasAny) {
      return _cardShell(
        context,
        child: const DashboardEmpty(
          icon: Icons.show_chart_rounded,
          title: 'No sales data available',
          subtitle: 'Sales metrics will appear after orders are recorded.',
        ),
      );
    }

    final cards = [
      _KpiCard(
        label: 'Net sales',
        value: Formatters.currency(stats.netSales, symbol: '₹'),
        changePercent: stats.salesChangePercent,
        sparkline: stats.salesSparkline,
        accent: AppColors.primary,
      ),
      _KpiCard(
        label: 'Orders delivered',
        value: '${stats.ordersDelivered}',
        changePercent: stats.ordersChangePercent,
        sparkline: stats.ordersSparkline,
        accent: const Color(0xFF22C55E),
      ),
      _KpiCard(
        label: 'Average order value',
        value: Formatters.currency(stats.averageOrderValue, symbol: '₹'),
        changePercent: stats.aovChangePercent,
        sparkline: stats.aovSparkline,
        accent: const Color(0xFFF59E0B),
      ),
    ];

    // Keep KPI cards in the same row on tablet+; wrap on very small phones.
    return Responsive.adaptiveStatGrid(
      context: context,
      children: cards,
      maxColumns: 3,
      spacing: context.w(14),
      runSpacing: context.h(12),
    );
  }

  Widget _cardShell(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.w(16)),
      decoration: DashboardCardStyle.decoration(context),
      child: child,
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final double changePercent;
  final List<double> sparkline;
  final Color accent;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.changePercent,
    required this.sparkline,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final up = changePercent >= 0;
    final changeColor = up ? const Color(0xFF22C55E) : AppColors.danger;
    final hasSpark = sparkline.any((v) => v > 0);

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(16),
        context.w(16),
        context.h(14),
      ),
      decoration: DashboardCardStyle.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: context.w(8),
                height: context.h(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: context.w(8)),
              Text(
                label,
                style: AppTextStyles.label(context).copyWith(
                  color: colors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(10)),
          Text(
            value,
            style: AppTextStyles.heading(context).copyWith(
              fontSize: context.h(24),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          SizedBox(height: context.h(6)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(8),
              vertical: context.h(3),
            ),
            decoration: BoxDecoration(
              color: changeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: context.h(14),
                  color: changeColor,
                ),
                SizedBox(width: context.w(3)),
                Text(
                  '${up ? '+' : ''}${changePercent.toStringAsFixed(0)}%',
                  style: AppTextStyles.caption(context).copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: context.w(4)),
                Text(
                  'vs. previous period',
                  style: AppTextStyles.caption(context)
                      .copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          if (hasSpark) ...[
            SizedBox(height: context.h(14)),
            SizedBox(
              height: context.h(36),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  minY: 0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < sparkline.length; i++)
                          FlSpot(i.toDouble(), sparkline[i]),
                      ],
                      isCurved: false,
                      color: accent,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF334155).withValues(alpha: 0.06),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
