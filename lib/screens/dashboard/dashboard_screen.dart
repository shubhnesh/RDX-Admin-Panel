//dashboard_screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/formatters.dart';
import '../../models/dashboard_stats_model.dart';
import '../../models/activity_log_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rdx_search_bar.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<String> onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _chartPeriod = 'Weekly'; // Daily | Weekly | Monthly

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<DashboardProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: provider.isLoading
          ? const LoadingIndicator()
          : provider.stats == null
              ? const SizedBox()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: provider.load,
                  child: ListView(
                    padding: context.defaultScreenPadding(),
                    children: [
                      _buildTopBar(colors),
                      SizedBox(height: context.h(20)),
                      _buildStatCards(provider.stats!, colors),
                      SizedBox(height: context.h(20)),
                      _buildAnalyticsCard(provider.stats!, colors),
                      SizedBox(height: context.h(20)),
                      _buildMiddleRow(provider.stats!, colors),
                      SizedBox(height: context.h(20)),
                      _buildRecentActivity(provider.recentActivity, colors),
                    ],
                  ),
                ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TOP BAR — search + notifications + settings
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTopBar(AppColorScheme colors) {
    return RdxSearchToolbar(
      hintText: 'Search orders, items..',
      actions: [
        _plainIconBtn(colors,
            icon: Icons.notifications_outlined,
            badge: true,
            onTap: () => widget.onNavigate('/notifications')),
        _plainIconBtn(
          colors,
          icon: Icons.settings_outlined,
          onTap: () => widget.onNavigate('/settings'),
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
            Icon(icon, size: context.h(21), color: colors.textSecondary),
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

  Widget _buildStatCards(DashboardStatsModel s, AppColorScheme colors) {
    final isNarrow = Responsive.isMobile(context);
    final cards = [
      _StatCardData(
        label: 'TOTAL REVENUE',
        value: Formatters.currency(s.totalRevenue, symbol: '\$'),
        subtitle: '+${s.revenueChangePercent}% today',
        subtitleColor: AppColors.success,
        icon: Icons.attach_money_rounded,
        iconBg: AppColors.primary.withValues(alpha: 0.15),
        iconColor: AppColors.primary,
      ),
      _StatCardData(
        label: 'ACTIVE ORDERS',
        value: '${s.activeOrders}',
        subtitle: '${s.preparingCount} preparing, ${s.enRouteCount} en route',
        subtitleColor: colors.textSecondary,
        icon: Icons.receipt_long_outlined,
        iconBg: AppColors.info.withValues(alpha: 0.15),
        iconColor: AppColors.info,
      ),
      _StatCardData(
        label: 'TABLES OCCUPIED',
        value: '${s.tablesOccupiedPercent.toStringAsFixed(0)}%',
        subtitle: null,
        progress: s.tablesOccupiedPercent / 100,
        icon: Icons.table_restaurant_outlined,
        iconBg: AppColors.warning.withValues(alpha: 0.15),
        iconColor: AppColors.warning,
      ),
      _StatCardData(
        label: 'AVAILABLE RIDERS',
        value: '${s.availableRiders}/${s.totalRiders}',
        subtitle: s.highDemand ? 'High demand' : 'Normal',
        subtitleColor: s.highDemand ? AppColors.warning : AppColors.success,
        subtitleIcon: s.highDemand
            ? Icons.warning_amber_rounded
            : Icons.check_circle_outline,
        icon: Icons.delivery_dining_outlined,
        iconBg: AppColors.success.withValues(alpha: 0.15),
        iconColor: AppColors.success,
      ),
    ];

    if (isNarrow) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) SizedBox(height: context.h(12)),
            _statCard(cards[i]),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) SizedBox(width: context.w(14)),
          Expanded(child: _statCard(cards[i])),
        ],
      ],
    );
  }

  Widget _statCard(_StatCardData d) {
    return StatCard(
      label: d.label,
      value: d.value,
      icon: d.icon,
      accentColor: d.iconColor,
      subtitle: d.subtitle,
      subtitleColor: d.subtitleColor,
      subtitleIcon: d.subtitleIcon,
      progress: d.progress,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ANALYTICS PERFORMANCE (line chart)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildAnalyticsCard(DashboardStatsModel s, AppColorScheme colors) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final spots = s.weeklyRevenue
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analytics Performance',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: context.h(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: context.h(4)),
                    Text(
                      "Real-time insight into your restaurant's ecosystem.",
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: context.h(12),
                      ),
                    ),
                  ],
                ),
              ),
              _periodTabs(colors),
            ],
          ),
          SizedBox(height: context.h(20)),
          SizedBox(
            height: context.h(200),
            child: LineChart(
              LineChartData(
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 15,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: colors.border.withOpacity(0.6),
                    strokeWidth: context.w(1),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: context.h(28),
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= days.length) return const SizedBox();
                        return Padding(
                          padding: EdgeInsets.only(top: context.h(8)),
                          child: Text(
                            days[i],
                            style: TextStyle(
                                color: colors.textMuted,
                                fontSize: context.h(11)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => colors.surfaceVariant,
                    getTooltipItems: (touched) => touched
                        .map(
                          (t) => LineTooltipItem(
                            t.y.toStringAsFixed(0),
                            TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: context.h(12),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.primary,
                    barWidth: context.w(3),
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        if (index == spots.length - 1) {
                          return FlDotCirclePainter(
                            radius: context.w(5),
                            color: AppColors.primary,
                            strokeWidth: context.w(3),
                            strokeColor: colors.surface,
                          );
                        }
                        return FlDotCirclePainter(
                          radius: 0,
                          color: Colors.transparent,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.35),
                          AppColors.primary.withOpacity(0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodTabs(AppColorScheme colors) {
    const periods = ['Daily', 'Weekly', 'Monthly'];
    return Container(
      padding: EdgeInsets.all(context.w(3)),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: periods.map((p) {
          final selected = _chartPeriod == p;
          return GestureDetector(
            onTap: () => setState(() => _chartPeriod = p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.symmetric(
                horizontal: context.w(12),
                vertical: context.h(6),
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                p,
                style: TextStyle(
                  color: selected ? Colors.white : colors.textSecondary,
                  fontSize: context.h(12),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MIDDLE ROW — Volume Trend + Top Selling
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildMiddleRow(DashboardStatsModel s, AppColorScheme colors) {
    final isNarrow = !Responsive.isDesktop(context);

    if (isNarrow) {
      return Column(
        children: [
          _buildVolumeTrend(s, colors),
          SizedBox(height: context.h(16)),
          _buildTopSelling(s, colors),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildVolumeTrend(s, colors)),
        SizedBox(width: context.w(16)),
        Expanded(flex: 2, child: _buildTopSelling(s, colors)),
      ],
    );
  }

  Widget _buildVolumeTrend(DashboardStatsModel s, AppColorScheme colors) {
    const labels = ['10AM', '12PM', '2PM', '4PM', '6PM', '8PM', '10PM', '12AM'];
    final peakValue = s.hourlyVolume.reduce((a, b) => a > b ? a : b);
    final maxY = peakValue > 0 ? peakValue * 1.15 : 1.0;
    final peakIndex = s.hourlyVolume.indexOf(peakValue);

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
              Text(
                'Volume Trend',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: context.h(15),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(10),
                  vertical: context.h(5),
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Today',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: context.h(12),
                      ),
                    ),
                    SizedBox(width: context.w(4)),
                    Icon(Icons.keyboard_arrow_down,
                        size: 16, color: colors.textMuted),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(16)),
          SizedBox(
            height: context.h(160),
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 3,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: colors.border.withOpacity(0.55),
                    strokeWidth: context.w(1),
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
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
                                fontSize: context.h(10)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colors.surfaceVariant,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        rod.toY.toStringAsFixed(0),
                        TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: context.h(12),
                        ),
                      );
                    },
                  ),
                ),
                barGroups: s.hourlyVolume.asMap().entries.map((e) {
                  final isPeak = e.key == peakIndex;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        width: context.w(30),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(context.w(3)),
                        ),
                        color: isPeak
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.45),
                      ),
                    ],
                    showingTooltipIndicators: isPeak ? [0] : [],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSelling(DashboardStatsModel s, AppColorScheme colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(20),
        context.h(18),
        context.w(20),
        context.h(12),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Selling Items',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: context.h(15),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: context.h(14)),
          for (final item in s.topSellingItems) ...[
            _topItemRow(item, colors),
            if (item != s.topSellingItems.last)
              Divider(height: context.h(20), color: colors.divider),
          ],
        ],
      ),
    );
  }

  Widget _topItemRow(TopSellingItem item, AppColorScheme colors) {
    return Row(
      children: [
        Container(
          width: context.w(28),
          height: context.h(28),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: item.rank == 1
                ? AppColors.primary.withOpacity(0.15)
                : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${item.rank}',
            style: TextStyle(
              color: item.rank == 1 ? AppColors.primary : colors.textSecondary,
              fontSize: context.h(13),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: context.h(13),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${item.orders} Orders',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: context.h(11),
                ),
              ),
            ],
          ),
        ),
        Text(
          '\$${item.revenue.toStringAsFixed(0)}',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: context.h(13),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // RECENT ACTIVITY TABLE
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildRecentActivity(
      List<ActivityLogModel> logs, AppColorScheme colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(20),
        context.h(18),
        context.w(20),
        context.h(8),
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
              Text(
                'Recent Activity',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: context.h(15),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: context.w(8)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'VIEW ALL',
                  style: TextStyle(
                      fontSize: context.h(12),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(8)),
          // Header row
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.h(8)),
            child: Row(
              children: [
                _colHeader(colors, 'ID', flex: 2),
                _colHeader(colors, 'TIME', flex: 2),
                _colHeader(colors, 'EVENT', flex: 4),
                _colHeader(colors, 'STATUS/ROLE', flex: 2),
                SizedBox(width: context.w(36)),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          for (final log in logs) _activityRow(log, colors),
        ],
      ),
    );
  }

  Widget _colHeader(AppColorScheme colors, String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          color: colors.textMuted,
          fontSize: context.h(11),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Recent Activity status pill — LIVE (new order), SYSTEM (system alert),
  /// COMPLETED (delivered), plus fallbacks for pending/alert wording.
  Widget _activityRow(ActivityLogModel log, AppColorScheme colors) {
    final status = log.details.toUpperCase();
    Color badgeBg;
    Color badgeFg;
    switch (status) {
      case 'LIVE':
      case 'PENDING':
        badgeBg = AppColors.danger.withOpacity(0.15);
        badgeFg = AppColors.danger;
        break;
      case 'SYSTEM':
        badgeBg = colors.surfaceVariant;
        badgeFg = colors.textSecondary;
        break;
      case 'ALERT':
        badgeBg = AppColors.warning.withOpacity(0.15);
        badgeFg = AppColors.warning;
        break;
      case 'COMPLETED':
        badgeBg = AppColors.success.withOpacity(0.15);
        badgeFg = AppColors.success;
        break;
      default:
        badgeBg = colors.surfaceVariant;
        badgeFg = colors.textSecondary;
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: context.h(12)),
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: colors.divider.withOpacity(0.6))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '#${log.id}',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: context.h(13),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              Formatters.timeAgo(log.timestamp),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: context.h(12),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              log.action,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: context.h(13),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(8),
                  vertical: context.h(4),
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: badgeFg,
                    fontSize: context.h(10),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: context.w(36),
            child: IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.more_vert,
                size: context.h(18),
                color: colors.textMuted,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Local data holder for stat cards ───────────────────────────────

class _StatCardData {
  final String label;
  final String value;
  final String? subtitle;
  final Color? subtitleColor;
  final IconData? subtitleIcon;
  final double? progress;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _StatCardData({
    required this.label,
    required this.value,
    this.subtitle,
    this.subtitleColor,
    this.subtitleIcon,
    this.progress,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
}
