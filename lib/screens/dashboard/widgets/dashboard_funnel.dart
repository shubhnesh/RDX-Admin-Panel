import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_empty.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_card_style.dart';

/// Zomato-inspired funnel: stages with conversion % between steps.
class DashboardFunnel extends StatelessWidget {
  final DashboardStatsModel stats;

  const DashboardFunnel({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final total = stats.funnelTotal;

    final stages = [
      _Stage('Pending', stats.funnelPending, stats.funnelPendingPercent,
          stats.funnelFractions['pending'] ?? 0,
          const Color(0xFFFDE68A)),
      _Stage('Preparing', stats.funnelPreparing, stats.funnelPreparingPercent,
          stats.funnelFractions['preparing'] ?? 0,
          const Color(0xFFD97706)),
      _Stage('Ready', stats.funnelReady, stats.funnelReadyPercent,
          stats.funnelFractions['ready'] ?? 0,
          const Color(0xFF86EFAC)),
      _Stage('Delivered', stats.funnelDelivered, stats.funnelDeliveredPercent,
          stats.funnelFractions['delivered'] ?? 0,
          AppColors.success),
      _Stage('Cancelled', stats.funnelCancelled, stats.funnelCancelledPercent,
          stats.funnelFractions['cancelled'] ?? 0,
          AppColors.danger),
    ];
    final conversions = [
      stats.preparingFromPendingPercent,
      stats.readyFromPreparingPercent,
      stats.deliveredFromReadyPercent,
      stats.cancelledFromDeliveredPercent,
    ];

    return _shell(
      context,
      colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (total > 0) _header(context, colors, total),
          if (total == 0)
            SizedBox(
              height: context.h(300),
              child: const Center(
                child: DashboardEmpty(
                  icon: Icons.filter_alt_outlined,
                  title: 'No order data available',
                  subtitle:
                      'Order stages will appear after orders are recorded.',
                ),
              ),
            )
          else ...[
            SizedBox(height: context.h(18)),
            for (var i = 0; i < stages.length; i++) ...[
              if (i > 0) ...[
                _conversionChip(
                  context,
                  colors,
                  ratePercent: conversions[i - 1],
                ),
                SizedBox(height: context.h(6)),
              ],
              _stageBar(context, stages[i]),
              if (i < stages.length - 1) SizedBox(height: context.h(4)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _shell(BuildContext context, AppColorScheme colors,
      {required Widget child}) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: context.h(380)),
      padding: EdgeInsets.fromLTRB(
        context.w(22),
        context.h(16),
        context.w(22),
        context.h(18),
      ),
      decoration: DashboardCardStyle.decoration(context),
      child: child,
    );
  }

  Widget _header(BuildContext context, AppColorScheme colors, int total) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order funnel', style: DashboardCardStyle.title(context)),
              SizedBox(height: context.h(3)),
              Text('$total total orders during this period',
                  style: DashboardCardStyle.description(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _conversionChip(
    BuildContext context,
    AppColorScheme colors, {
    required double ratePercent,
  }) {
    return Row(
      children: [
        Icon(Icons.south_rounded, size: context.h(12), color: colors.textMuted),
        SizedBox(width: context.w(4)),
        Text(
          '${ratePercent.toStringAsFixed(0)}% of prior-stage count',
          style: AppTextStyles.caption(context).copyWith(color: colors.textMuted),
        ),
      ],
    );
  }

  Widget _stageBar(BuildContext context, _Stage stage) {
    // Visual funnel: later stages slightly narrower base
    final widthFactor = stage.fraction.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                stage.label,
                style: AppTextStyles.bodySemi(context),
              ),
            ),
            SizedBox(
              width: context.w(36),
              child: Text(
                '${stage.count}',
                textAlign: TextAlign.right,
                style: AppTextStyles.bodyLargeSemi(context),
              ),
            ),
            SizedBox(width: context.w(10)),
            SizedBox(
              width: context.w(40),
              child: Text(
                '${stage.percent.toStringAsFixed(0)}%',
                textAlign: TextAlign.right,
                style: AppTextStyles.caption(context).copyWith(color: AppColors.success),
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(7)),
        LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: constraints.maxWidth * widthFactor,
                height: context.h(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: stage.color,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Stage {
  final String label;
  final int count;
  final double percent;
  final double fraction;
  final Color color;
  const _Stage(
    this.label,
    this.count,
    this.percent,
    this.fraction,
    this.color,
  );
}
