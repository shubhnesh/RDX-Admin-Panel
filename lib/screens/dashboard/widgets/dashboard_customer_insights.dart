import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_empty.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_card_style.dart';

/// Customer / source insights — adapted from Zomato customer type + discovery.
/// Uses staff vs app and order type mix from real order data.
class DashboardCustomerInsights extends StatelessWidget {
  final DashboardStatsModel stats;

  const DashboardCustomerInsights({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final total = stats.totalOrders;
    final staff = stats.staffOrderCount;
    final app = stats.appOrderCount;

    if (total == 0) {
      return Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: context.h(360)),
        padding: EdgeInsets.fromLTRB(
          context.w(20),
          context.h(14),
          context.w(20),
          context.h(16),
        ),
        decoration: DashboardCardStyle.decoration(context),
        child: const Center(
          child: DashboardEmpty(
            icon: Icons.people_outline_rounded,
            title: 'No customer data available',
            subtitle:
                'Order-source insights will appear after orders are recorded.',
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: context.h(360)),
      padding: EdgeInsets.fromLTRB(
        context.w(20),
        context.h(14),
        context.w(20),
        context.h(16),
      ),
      decoration: DashboardCardStyle.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer source', style: DashboardCardStyle.title(context)),
          SizedBox(height: context.h(16)),
          Row(
            children: [
              SizedBox(
                width: context.w(110),
                height: context.h(110),
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: context.w(28),
                    sections: [
                      PieChartSectionData(
                        value: stats.orderSourceFractions['staff'] ?? 0,
                        color: AppColors.warning,
                        radius: context.w(22),
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: stats.orderSourceFractions['app'] ?? 0,
                        color: AppColors.info,
                        radius: context.w(22),
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: context.w(16)),
              Expanded(
                child: Column(
                  children: [
                    _legendRow(
                      context,
                      colors,
                      color: AppColors.warning,
                      label: 'Staff / POS',
                      count: staff,
                      pct: stats.staffOrderPercent,
                    ),
                    SizedBox(height: context.h(10)),
                    _legendRow(
                      context,
                      colors,
                      color: AppColors.info,
                      label: 'Customer app',
                      count: app,
                      pct: stats.appOrderPercent,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(16)),
          Divider(color: colors.border, height: context.h(1)),
          SizedBox(height: context.h(14)),
          Text('Service type', style: AppTextStyles.body(context)),
          SizedBox(height: context.h(10)),
          _miniBar(
            context,
            colors,
            'Dine-in',
            stats.dineInCount,
            stats.dineInPercent,
            stats.orderTypeFractions['dine_in'] ?? 0,
            AppColors.success,
          ),
          SizedBox(height: context.h(8)),
          _miniBar(
            context,
            colors,
            'Takeaway',
            stats.takeawayCount,
            stats.takeawayPercent,
            stats.orderTypeFractions['takeaway'] ?? 0,
            AppColors.success,
          ),
          SizedBox(height: context.h(8)),
          _miniBar(
            context,
            colors,
            'Delivery',
            stats.deliveryCount,
            stats.deliveryPercent,
            stats.orderTypeFractions['delivery'] ?? 0,
            AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _legendRow(
    BuildContext context,
    AppColorScheme colors, {
    required Color color,
    required String label,
    required int count,
    required double pct,
  }) {
    return Row(
      children: [
        Container(
          width: context.w(10),
          height: context.h(10),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: context.w(8)),
        Expanded(
          child: Text(label,
              style: AppTextStyles.bodySemi(context)),
        ),
        SizedBox(
          width: context.w(36),
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyLargeSemi(context),
          ),
        ),
        SizedBox(width: context.w(8)),
        SizedBox(
          width: context.w(40),
          child: Text(
            '${pct.toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: AppTextStyles.caption(context).copyWith(color: AppColors.success),
          ),
        ),
      ],
    );
  }

  Widget _miniBar(
    BuildContext context,
    AppColorScheme colors,
    String label,
    int value,
    double percent,
    double fraction,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: AppTextStyles.bodySemi(context)),
            ),
            Text(
              '$value',
              style: AppTextStyles.caption(context)
                  .copyWith(color: colors.textSecondary),
            ),
            SizedBox(width: context.w(4)),
            SizedBox(
              width: context.w(40),
              child: Text(
                '${percent.toStringAsFixed(0)}%',
                textAlign: TextAlign.right,
                style: AppTextStyles.caption(context).copyWith(color: AppColors.success),
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(4)),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: context.h(5),
            backgroundColor: colors.border.withValues(alpha: 0.35),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
