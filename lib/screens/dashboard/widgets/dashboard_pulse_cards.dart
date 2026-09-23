import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/formatters.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/widgets/reusable_widgets/stat_card.dart';

/// Top pulse strip: today's revenue, active orders, pending payment, stock, coupons.
class DashboardPulseCards extends StatelessWidget {
  final DashboardStatsModel stats;
  final ValueChanged<String>? onNavigate;

  const DashboardPulseCards({
    super.key,
    required this.stats,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final change = stats.revenueChangePercent;
    final changeUp = change >= 0;

    final cards = [
      _PulseTap(
        onTap: null,
        child: StatCard(
          label: 'TODAY\'S REVENUE',
          value: Formatters.currency(stats.todayRevenue, symbol: '₹'),
          subtitle:
              '${changeUp ? '+' : ''}${change.toStringAsFixed(0)}% vs yesterday',
          subtitleColor: changeUp ? AppColors.success : AppColors.danger,
          icon: Icons.attach_money_rounded,
        ),
      ),
      _PulseTap(
        onTap: () => onNavigate?.call('/live-orders'),
        child: StatCard(
          label: 'ACTIVE ORDERS',
          value: '${stats.activeOrdersCount}',
          subtitle: '${stats.todayOrderCount} orders today',
          subtitleColor: colors.textSecondary,
          icon: Icons.receipt_long_outlined,
        ),
      ),
      _PulseTap(
        onTap: () => onNavigate?.call('/live-orders'),
        child: StatCard(
          label: 'PENDING PAYMENT',
          value: '${stats.pendingPaymentCount}',
          subtitle: stats.pendingPaymentCount > 0 ? 'Needs settlement' : 'All clear',
          subtitleColor: stats.pendingPaymentCount > 0
              ? AppColors.warning
              : AppColors.success,
          icon: Icons.payments_outlined,
          accentColor: AppColors.warning,
        ),
      ),
      _PulseTap(
        onTap: () => onNavigate?.call('/inventory'),
        child: StatCard(
          label: 'STOCK ALERTS',
          value: '${stats.criticalStockCount + stats.lowStockCount}',
          subtitle: stats.criticalStockCount > 0
              ? '${stats.criticalStockCount} critical · ${stats.lowStockCount} low'
              : '${stats.lowStockCount} low',
          subtitleColor: stats.criticalStockCount > 0
              ? AppColors.danger
              : (stats.lowStockCount > 0
                  ? AppColors.warning
                  : AppColors.success),
          icon: Icons.inventory_2_outlined,
          accentColor: stats.criticalStockCount > 0
              ? AppColors.danger
              : AppColors.warning,
        ),
      ),
      _PulseTap(
        onTap: () => onNavigate?.call('/coupons'),
        child: StatCard(
          label: 'ACTIVE COUPONS',
          value: '${stats.activeCouponCount}',
          subtitle: '${stats.couponUsagesToday} uses today',
          subtitleColor: colors.textSecondary,
          icon: Icons.local_offer_outlined,
        ),
      ),
    ];

    final isNarrow = Responsive.isMobile(context);

    if (isNarrow) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) SizedBox(height: context.h(12)),
            cards[i],
          ],
        ],
      );
    }

    // Wide: wrap so 5 cards don't crush on mid-width screens.
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = context.w(14);
        final minCard = context.w(160);
        final count = (constraints.maxWidth / (minCard + gap)).floor().clamp(2, 5);
        final cardWidth =
            (constraints.maxWidth - gap * (count - 1)) / count;

        return Wrap(
          spacing: gap,
          runSpacing: context.h(12),
          children: [
            for (final card in cards)
              SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }
}

class _PulseTap extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PulseTap({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.h(14)),
        child: child,
      ),
    );
  }
}
