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
///
/// Typography (STYLE_GUIDE):
/// - Label → bodySemi (emphasized label)
/// - Value → h2 (page-level number weight for KPIs)
/// - Change % / "vs. prev" → caption
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
        accent: DashboardCardStyle.salesAccent,
      ),
      _KpiCard(
        label: 'Orders delivered',
        value: '${stats.ordersDelivered}',
        changePercent: stats.ordersChangePercent,
        sparkline: stats.ordersSparkline,
        accent: DashboardCardStyle.ordersAccent,
      ),
      _KpiCard(
        label: 'Average order value',
        value: Formatters.currency(stats.averageOrderValue, symbol: '₹'),
        changePercent: stats.aovChangePercent,
        sparkline: stats.aovSparkline,
        accent: DashboardCardStyle.averageOrderValueAccent,
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
      padding: EdgeInsets.all(context.w(20)),
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
    final hasSpark = sparkline.any((v) => v > 0);

    return Container(
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
          // Label + change badge
          Row(
            children: [
              Container(
                width: context.w(8),
                height: context.h(8),
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodySemi(context).copyWith(
                    color: colors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: context.w(6)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(7),
                  vertical: context.h(2),
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      up
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: context.h(13),
                      color: accent,
                    ),
                    SizedBox(width: context.w(2)),
                    Text(
                      '${up ? '+' : ''}${changePercent.toStringAsFixed(0)}%',
                      style: AppTextStyles.caption(context).copyWith(
                        color: accent,
                      ),
                    ),
                    SizedBox(width: context.w(3)),
                    Text(
                      'vs. prev',
                      style: AppTextStyles.caption(context).copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(10)),
          Text(
            value,
            style: AppTextStyles.h2(context).copyWith(
              letterSpacing: -0.4,
            ),
          ),
          if (hasSpark) ...[
            SizedBox(height: context.h(12)),
            SizedBox(
              height: context.h(42),
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
                        color: accent.withValues(alpha: 0.08),
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
