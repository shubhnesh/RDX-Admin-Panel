import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_empty.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_card_style.dart';

/// Adapted from Zomato Service quality: cancelled %, unpaid, stock health.
class DashboardServiceQuality extends StatelessWidget {
  final DashboardStatsModel stats;
  final ValueChanged<String>? onNavigate;

  const DashboardServiceQuality({
    super.key,
    required this.stats,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final total = stats.funnelTotal;
    final cancelledPct = stats.cancellationRatePercent;
    final deliveredPct = stats.deliveryRatePercent;
    final stockIssues = stats.stockAlertCount;

    final hasData =
        total > 0 || stockIssues > 0 || stats.pendingPaymentCount > 0;

    return _shell(
      context,
      colors,
      child: Column(
        mainAxisAlignment:
            hasData ? MainAxisAlignment.start : MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (hasData)
                Expanded(
                  child: Text('Service quality',
                      style: DashboardCardStyle.title(context)),
                ),
            ],
          ),
          if (!hasData)
            SizedBox(
              height: context.h(280),
              child: const Center(
                child: DashboardEmpty(
                  icon: Icons.verified_user_outlined,
                  title: 'No service data available',
                  subtitle:
                      'Service metrics will appear after orders are recorded.',
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _metricTile(
                          context,
                          colors,
                          label: 'Cancellation rate',
                          value: '${cancelledPct.toStringAsFixed(0)}%',
                          hint: '${stats.funnelCancelled} of $total',
                          color: cancelledPct > 10
                              ? AppColors.danger
                              : const Color(0xFF22C55E),
                          icon: Icons.cancel_outlined,
                        ),
                      ),
                      SizedBox(width: context.w(10)),
                      Expanded(
                        child: _metricTile(
                          context,
                          colors,
                          label: 'Delivery rate',
                          value: '${deliveredPct.toStringAsFixed(0)}%',
                          hint: '${stats.funnelDelivered} of $total',
                          color: const Color(0xFF22C55E),
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _metricTile(
                          context,
                          colors,
                          label: 'Pending payments',
                          value: '${stats.pendingPaymentCount}',
                          hint: stats.pendingPaymentCount > 0
                              ? 'Needs settlement'
                              : 'All clear',
                          color: stats.pendingPaymentCount > 0
                              ? AppColors.warning
                              : const Color(0xFF22C55E),
                          icon: Icons.payments_outlined,
                          onTap: () => onNavigate?.call('/live-orders'),
                        ),
                      ),
                      SizedBox(width: context.w(10)),
                      Expanded(
                        child: _metricTile(
                          context,
                          colors,
                          label: 'Stock alerts',
                          value: '$stockIssues',
                          hint: stats.criticalStockCount > 0
                              ? '${stats.criticalStockCount} critical'
                              : 'Healthy',
                          color: stats.criticalStockCount > 0
                              ? AppColors.danger
                              : (stats.lowStockCount > 0
                                  ? AppColors.warning
                                  : const Color(0xFF22C55E)),
                          icon: Icons.inventory_2_outlined,
                          onTap: () => onNavigate?.call('/inventory'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _shell(BuildContext context, AppColorScheme colors,
      {required Widget child}) {
    return Container(
      width: double.infinity,
      height: context.h(360),
      padding: EdgeInsets.fromLTRB(
        context.w(20),
        context.h(16),
        context.w(20),
        context.h(16),
      ),
      decoration: DashboardCardStyle.decoration(context),
      child: child,
    );
  }

  Widget _metricTile(
    BuildContext context,
    AppColorScheme colors, {
    required String label,
    required String value,
    required String hint,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final tile = Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.w(12),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.caption(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(8)),
          Text(
            value,
            style: AppTextStyles.heading(context).copyWith(
              fontSize: context.h(20),
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: context.h(2)),
          Text(
            hint,
            style: AppTextStyles.caption(context)
                .copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
    if (onTap == null) return tile;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: tile,
      ),
    );
  }
}
