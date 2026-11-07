import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/providers/dashboard_provider.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_attention_panel.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_aov_trend.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_customer_insights.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_funnel.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_kpi_cards.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_mealtime_breakdown.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_offers_summary.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_sales_chart.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_section.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_service_quality.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_top_selling.dart';
import 'package:rdx_admin/widgets/reusable_widgets/loading_indicator.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_category_tabs.dart';

/// Dashboard arranged as sections (Sales, Attention, Funnel, Customers,
/// Service, Offers). Sections are plain headings over cards.
class DashboardScreen extends ConsumerStatefulWidget {
  final ValueChanged<String>? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const _periods = ['Today', 'Yesterday', 'Last 7 days'];

  void _log(String message) {
    if (kDebugMode) debugPrint('[DashboardScreen] $message');
  }

  @override
  void initState() {
    super.initState();
    _log('Dashboard screen initialized.');
    Future.microtask(_loadInitial);
  }

  Future<void> _loadInitial() async {
    _log('Initial dashboard load requested.');
    if (!mounted) {
      _log('Initial load skipped; dashboard screen is no longer mounted.');
      return;
    }
    await ref.read(dashboardProvider).load();
    _log('Initial dashboard load finished.');
  }

  Future<void> _refreshDashboard(DashboardProvider provider) async {
    _log('Pull-to-refresh requested.');
    await provider.load();
    _log('Pull-to-refresh finished.');
  }

  Future<void> _retryLoad(DashboardProvider provider) async {
    _log('Retry requested from dashboard error state.');
    await provider.load();
    _log('Dashboard retry finished.');
  }

  Future<void> _selectPeriod(DashboardProvider provider, String period) async {
    _log('Period filter selected: $period.');
    await provider.setPeriod(period);
    _log('Period filter update finished: $period.');
  }

  void _navigate(String route) {
    _log('Dashboard navigation requested: $route.');
    widget.onNavigate?.call(route);
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(dashboardProvider);
    final colors = AppColors.of(context);
    final media = MediaQuery.of(context);
    final widthScale = (media.size.width / 1024).clamp(0.88, 1.0);
    final textScaler = _DashboardTextScaler(media.textScaler, widthScale);

    return MediaQuery(
      data: media.copyWith(textScaler: textScaler),
      child: Scaffold(
        backgroundColor: colors.background,
        body: provider.stats == null
            ? provider.errorMessage == null
                ? const LoadingIndicator()
                : _errorBody(provider)
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => _refreshDashboard(provider),
                child: Builder(
                  builder: (context) {
                    final pagePad = context.defaultScreenPadding();
                    final bottomPad = pagePad.bottom +
                        (Responsive.useBottomNav(context) ? context.h(12) : 0);

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              pagePad.left,
                              pagePad.top,
                              pagePad.right,
                              0,
                            ),
                            child: MediaQuery(
                              data: media,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _header(colors),
                                  SizedBox(height: context.h(12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _DashboardFilterDelegate(
                            extent: 52,
                            backgroundColor: colors.background,
                            horizontalPadding: pagePad.left,
                            child: MediaQuery(
                              data: media,
                              child: _periodChips(provider, colors),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            pagePad.left,
                            0,
                            pagePad.right,
                            bottomPad,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              SizedBox(height: context.h(12)),

                              // Sales
                              DashboardSection(
                                title: 'Sales',
                                icon: Icons.insights_rounded,
                                subtitle:
                                    'Revenue, order volume and average order value',
                                periodLabel: provider.stats!.periodLabel,
                                children: [
                                  DashboardKpiCards(
                                    stats: provider.stats!,
                                  ),
                                  DashboardSalesChart(
                                    stats: provider.stats!,
                                  ),
                                  _twoCol(
                                    DashboardAovTrend(
                                      stats: provider.stats!,
                                    ),
                                    DashboardMealtimeBreakdown(
                                      stats: provider.stats!,
                                    ),
                                    matchedHeight: 460,
                                  ),
                                ],
                              ),

                              // Customers + Service quality
                              DashboardSection(
                                title: 'Customers & Service quality',
                                icon: Icons.groups_rounded,
                                subtitle:
                                    'Customer sources, order types and service performance',
                                periodLabel: provider.stats!.periodLabel,
                                children: [
                                  _sectionRow(
                                    DashboardCustomerInsights(
                                      stats: provider.stats!,
                                    ),
                                    DashboardServiceQuality(
                                      stats: provider.stats!,
                                      onNavigate: _navigate,
                                    ),
                                  ),
                                ],
                              ),

                              // Needs attention
                              DashboardSection(
                                title: 'Needs attention',
                                icon: Icons.priority_high_rounded,
                                subtitle: 'Stock, payment and coupon issues',
                                children: [
                                  DashboardAttentionPanel(
                                    items: provider.stats!.attentionItems,
                                    onItemTap: (item) {
                                      if (item.route != null) {
                                        _navigate(item.route!);
                                      }
                                    },
                                  ),
                                ],
                              ),

                              // Funnel
                              DashboardSection(
                                title: 'Funnel',
                                icon: Icons.filter_alt_rounded,
                                subtitle: 'Order volume by fulfilment status',
                                periodLabel: provider.stats!.periodLabel,
                                children: [
                                  _twoCol(
                                    DashboardFunnel(
                                      stats: provider.stats!,
                                    ),
                                    DashboardTopSelling(
                                      items: provider.stats!.topSellingItems,
                                    ),
                                    matchedHeight: 420,
                                  ),
                                ],
                              ),

                              // Offers
                              DashboardSection(
                                title: 'Offers',
                                icon: Icons.local_offer_rounded,
                                subtitle:
                                    'Active coupons and redemption activity',
                                actionLabel: 'Manage',
                                onAction: () => _navigate('/coupons'),
                                children: [
                                  DashboardOffersSummary(
                                    stats: provider.stats!,
                                  ),
                                ],
                              ),
                            ]),
                          ),
                        ),
                      ],
                    );
                  },
                ),
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
            provider.errorMessage!,
            style: AppTextStyles.body(context),
          ),
          SizedBox(height: context.h(12)),
          TextButton(
            onPressed: () => _retryLoad(provider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _header(AppColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Insights',
                style: AppTextStyles.heading(context),
              ),
              SizedBox(height: context.h(4)),
              Text(
                'Performance overview',
                style: AppTextStyles.bodySecondary(context)
                    .copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
        SizedBox(width: context.w(12)),
        _iconBtn(
          colors,
          Icons.notifications_outlined,
          () => _navigate('/notifications'),
        ),
        SizedBox(width: context.w(8)),
        _iconBtn(
          colors,
          Icons.settings_outlined,
          () => _navigate('/settings'),
        ),
      ],
    );
  }

  Widget _iconBtn(AppColorScheme colors, IconData icon, VoidCallback onTap) {
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.all(context.h(9)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Icon(icon, size: context.h(19), color: colors.textSecondary),
        ),
      ),
    );
  }

  Widget _periodChips(DashboardProvider provider, AppColorScheme colors) {
    return RdxCategoryTabs(
      labels: _periods,
      selectedLabel: provider.selectedPeriod,
      onSelected: (p) => _selectPeriod(provider, p),
      expand: false,
    );
  }

  /// Two sections in one row on wide screens; stacked otherwise.
  Widget _sectionRow(Widget left, Widget right) {
    if (Responsive.isNarrow(context)) {
      return Column(
        children: [
          left,
          SizedBox(height: context.h(16)),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        SizedBox(width: context.w(16)),
        Expanded(child: right),
      ],
    );
  }

  Widget _twoCol(Widget a, Widget b, {double? matchedHeight}) {
    final isNarrow = !Responsive.isDesktop(context);
    if (isNarrow) {
      return Column(
        children: [
          a,
          SizedBox(height: context.h(12)),
          b,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: matchedHeight == null
              ? a
              : SizedBox(height: context.h(matchedHeight), child: a),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: matchedHeight == null
              ? b
              : SizedBox(height: context.h(matchedHeight), child: b),
        ),
      ],
    );
  }
}

class _DashboardFilterDelegate extends SliverPersistentHeaderDelegate {
  final double extent;
  final Color backgroundColor;
  final double horizontalPadding;
  final Widget child;

  const _DashboardFilterDelegate({
    required this.extent,
    required this.backgroundColor,
    required this.horizontalPadding,
    required this.child,
  });

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: backgroundColor,
      elevation: overlapsContent || shrinkOffset > 0 ? 1.5 : 0,
      shadowColor: Colors.black26,
      child: Container(
        height: extent,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: overlapsContent || shrinkOffset > 0
                  ? AppColors.of(context).border
                  : Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DashboardFilterDelegate oldDelegate) =>
      extent != oldDelegate.extent ||
      backgroundColor != oldDelegate.backgroundColor ||
      horizontalPadding != oldDelegate.horizontalPadding ||
      child != oldDelegate.child;
}

class _DashboardTextScaler extends TextScaler {
  final TextScaler parent;
  final double widthScale;

  const _DashboardTextScaler(this.parent, this.widthScale);

  @override
  double scale(double fontSize) => parent.scale(fontSize * widthScale);

  @override
  double get textScaleFactor => scale(1);

  @override
  bool operator ==(Object other) =>
      other is _DashboardTextScaler &&
      other.parent == parent &&
      other.widthScale == widthScale;

  @override
  int get hashCode => Object.hash(parent, widthScale);
}
