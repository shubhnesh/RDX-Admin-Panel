import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/providers/coupon_provider.dart';
import 'package:rdx_admin/providers/dashboard_provider.dart';
import 'package:rdx_admin/providers/inventory_provider.dart';
import 'package:rdx_admin/providers/live_orders_provider.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_attention_panel.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_hourly_chart.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_order_mix.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_pulse_cards.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_revenue_chart.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_top_selling.dart';
import 'package:rdx_admin/widgets/reusable_widgets/loading_indicator.dart';
import 'package:rdx_admin/widgets/resuable_options/rdx_search_bar.dart';

/// Real-data dashboard: revenue/charts from orders, pulse from live modules.
class DashboardScreen extends ConsumerStatefulWidget {
  final ValueChanged<String>? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dashboardProvider).load());
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(dashboardProvider);
    final colors = AppColors.of(context);

    // Instant reflection when operational modules change.
    ref.listen(liveOrdersProvider, (_, __) {
      ref.read(dashboardProvider).refreshOperational();
    });
    ref.listen(inventoryProvider, (_, __) {
      ref.read(dashboardProvider).refreshOperational();
    });
    ref.listen(couponProvider, (_, __) {
      ref.read(dashboardProvider).refreshOperational();
    });

    return Scaffold(
      backgroundColor: colors.background,
      body: provider.isLoading && provider.stats == null
          ? const LoadingIndicator()
          : provider.stats == null
              ? _errorBody(provider)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: provider.load,
                  child: ListView(
                    padding: Responsive.pagePadding(
                      context,
                      top: context.h(14),
                      bottom: context.h(24),
                    ),
                    children: [
                      _buildTopBar(colors),
                      SizedBox(height: context.h(20)),
                      DashboardPulseCards(
                        stats: provider.stats!,
                        onNavigate: widget.onNavigate,
                      ),
                      SizedBox(height: context.h(20)),
                      DashboardRevenueChart(
                        stats: provider.stats!,
                        period: provider.chartPeriod,
                        onPeriodChanged: provider.setChartPeriod,
                      ),
                      SizedBox(height: context.h(20)),
                      _buildAttentionAndVolumeRow(provider),
                      SizedBox(height: context.h(20)),
                      _buildMiddleRow(provider),
                    ],
                  ),
                ),
    );
  }

  Widget _errorBody(DashboardProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            provider.errorMessage ?? 'Nothing to show',
            style: AppTextStyles.body(context),
          ),
          SizedBox(height: context.h(12)),
          TextButton(
            onPressed: provider.load,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(AppColorScheme colors) {
    return RdxSearchToolbar(
      hintText: 'Search orders, items..',
      actions: [
        _plainIconBtn(
          colors,
          icon: Icons.notifications_outlined,
          badge: true,
          onTap: () => widget.onNavigate?.call('/notifications'),
        ),
        _plainIconBtn(
          colors,
          icon: Icons.settings_outlined,
          onTap: () => widget.onNavigate?.call('/settings'),
        ),
      ],
    );
  }

  Widget _plainIconBtn(
    AppColorScheme colors, {
    required IconData icon,
    bool badge = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: EdgeInsets.all(context.h(6)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: context.h(25), color: colors.textSecondary),
            if (badge)
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  width: context.w(7),
                  height: context.h(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.background,
                      width: context.w(1),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttentionAndVolumeRow(DashboardProvider provider) {
    final stats = provider.stats!;
    final isNarrow = !Responsive.isDesktop(context);

    final attention = DashboardAttentionPanel(
      items: stats.attentionItems,
      onItemTap: (item) {
        if (item.route != null) {
          widget.onNavigate?.call(item.route!);
        }
      },
    );
    final volume = DashboardHourlyChart(stats: stats);

    if (isNarrow) {
      return Column(
        children: [
          attention,
          SizedBox(height: context.h(16)),
          volume,
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: attention),
          SizedBox(width: context.w(16)),
          Expanded(child: volume),
        ],
      ),
    );
  }

  Widget _buildMiddleRow(DashboardProvider provider) {
    final stats = provider.stats!;
    final isNarrow = !Responsive.isDesktop(context);

    final topSelling = DashboardTopSelling(items: stats.topSellingItems);
    final orderMix = DashboardOrderMix(stats: stats);

    if (isNarrow) {
      return Column(
        children: [
          topSelling,
          SizedBox(height: context.h(16)),
          orderMix,
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: topSelling),
          SizedBox(width: context.w(16)),
          Expanded(child: orderMix),
        ],
      ),
    );
  }
}
