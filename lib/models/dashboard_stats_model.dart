/// Fresh dashboard aggregates driven by real order / inventory / coupon data.
/// Designed around the high-value concepts from the Zomato partner screenshots.
class DashboardStatsModel {
  // ── Sales KPIs ──────────────────────────────────────────────
  final double netSales;
  final double previousNetSales;
  final int ordersDelivered;
  final int previousOrdersDelivered;
  final int totalOrders;
  final double averageOrderValue;
  final double previousAov;
  final double salesChangePercent;
  final double ordersChangePercent;
  final double aovChangePercent;

  // Mini sparkline points (last 7 days) for the 3 KPI cards
  final List<double> salesSparkline;
  final List<double> ordersSparkline;
  final List<double> aovSparkline;

  // ── Charts ──────────────────────────────────────────────────
  final List<DailyPoint> salesTrend;       // daily net sales
  final List<DailyPoint> ordersTrend;      // daily order count
  final List<DailyPoint> aovTrend;         // daily AOV

  // ── Mealtime ────────────────────────────────────────────────
  final int breakfastCount;
  final int lunchCount;
  final int eveningCount;
  final int dinnerCount;
  final int lateNightCount;
  final int totalMealtime;
  final double breakfastPercent;
  final double lunchPercent;
  final double eveningPercent;
  final double dinnerPercent;
  final double lateNightPercent;
  final Map<String, double> mealtimeFractions;

  // ── Simplified funnel (order pipeline) ──────────────────────
  final int funnelPending;
  final int funnelPreparing;
  final int funnelReady;
  final int funnelDelivered;
  final int funnelCancelled;
  final int funnelTotal;
  final double funnelPendingPercent;
  final double funnelPreparingPercent;
  final double funnelReadyPercent;
  final double funnelDeliveredPercent;
  final double funnelCancelledPercent;
  final Map<String, double> funnelFractions;
  final double preparingFromPendingPercent;
  final double readyFromPreparingPercent;
  final double deliveredFromReadyPercent;
  final double cancelledFromDeliveredPercent;
  final double cancellationRatePercent;
  final double deliveryRatePercent;

  // ── Order mix ───────────────────────────────────────────────
  final int dineInCount;
  final int takeawayCount;
  final int deliveryCount;
  final int staffOrderCount;
  final int appOrderCount;
  final int orderTypeTotal;
  final int orderSourceTotal;
  final double dineInPercent;
  final double takeawayPercent;
  final double deliveryPercent;
  final double staffOrderPercent;
  final double appOrderPercent;
  final Map<String, double> orderTypeFractions;
  final Map<String, double> orderSourceFractions;

  // ── Top selling ─────────────────────────────────────────────
  final List<TopSellingItem> topSellingItems;

  // ── Service / Attention ─────────────────────────────────────
  final int activeOrdersCount;
  final int pendingPaymentCount;
  final int lowStockCount;
  final int criticalStockCount;
  final int stockAlertCount;
  final int activeCouponCount;
  final int couponUsagesCount;
  final List<AttentionItem> attentionItems;

  // ── Period label ────────────────────────────────────────────
  final String periodLabel; // "Today", "Yesterday", "Last 7 days"

  const DashboardStatsModel({
    this.netSales = 0,
    this.previousNetSales = 0,
    this.ordersDelivered = 0,
    this.previousOrdersDelivered = 0,
    this.totalOrders = 0,
    this.averageOrderValue = 0,
    this.previousAov = 0,
    this.salesChangePercent = 0,
    this.ordersChangePercent = 0,
    this.aovChangePercent = 0,
    this.salesSparkline = const [],
    this.ordersSparkline = const [],
    this.aovSparkline = const [],
    this.salesTrend = const [],
    this.ordersTrend = const [],
    this.aovTrend = const [],
    this.breakfastCount = 0,
    this.lunchCount = 0,
    this.eveningCount = 0,
    this.dinnerCount = 0,
    this.lateNightCount = 0,
    this.totalMealtime = 0,
    this.breakfastPercent = 0,
    this.lunchPercent = 0,
    this.eveningPercent = 0,
    this.dinnerPercent = 0,
    this.lateNightPercent = 0,
    this.mealtimeFractions = const {},
    this.funnelPending = 0,
    this.funnelPreparing = 0,
    this.funnelReady = 0,
    this.funnelDelivered = 0,
    this.funnelCancelled = 0,
    this.funnelTotal = 0,
    this.funnelPendingPercent = 0,
    this.funnelPreparingPercent = 0,
    this.funnelReadyPercent = 0,
    this.funnelDeliveredPercent = 0,
    this.funnelCancelledPercent = 0,
    this.funnelFractions = const {},
    this.preparingFromPendingPercent = 0,
    this.readyFromPreparingPercent = 0,
    this.deliveredFromReadyPercent = 0,
    this.cancelledFromDeliveredPercent = 0,
    this.cancellationRatePercent = 0,
    this.deliveryRatePercent = 0,
    this.dineInCount = 0,
    this.takeawayCount = 0,
    this.deliveryCount = 0,
    this.staffOrderCount = 0,
    this.appOrderCount = 0,
    this.orderTypeTotal = 0,
    this.orderSourceTotal = 0,
    this.dineInPercent = 0,
    this.takeawayPercent = 0,
    this.deliveryPercent = 0,
    this.staffOrderPercent = 0,
    this.appOrderPercent = 0,
    this.orderTypeFractions = const {},
    this.orderSourceFractions = const {},
    this.topSellingItems = const [],
    this.activeOrdersCount = 0,
    this.pendingPaymentCount = 0,
    this.lowStockCount = 0,
    this.criticalStockCount = 0,
    this.stockAlertCount = 0,
    this.activeCouponCount = 0,
    this.couponUsagesCount = 0,
    this.attentionItems = const [],
    this.periodLabel = 'Today',
  });

  // ── Compatibility aliases (old dashboard API) ─────────────────
  // Keeps any leftover widgets that still use the previous names compiling.
  double get todayRevenue => netSales;
  double get yesterdayRevenue => previousNetSales;
  int get todayOrderCount => ordersDelivered;
  int get yesterdayOrderCount => previousOrdersDelivered;
  double get revenueChangePercent => salesChangePercent;
  double get orderChangePercent => ordersChangePercent;
  List<DailyPoint> get revenueTrend => salesTrend;
  List<DailyPoint> get orderCountTrend => ordersTrend;
  int get totalMealtimeOrders => totalMealtime;

  /// Legacy hourly fields — mapped from mealtime buckets so old charts work.
  List<double> get hourlyVolume => [
        breakfastCount.toDouble(),
        lunchCount.toDouble(),
        eveningCount.toDouble(),
        dinnerCount.toDouble(),
        lateNightCount.toDouble(),
      ];
  List<String> get hourlyLabels =>
      const ['BF', 'Lunch', 'Eve', 'Dinner', 'Late'];
  List<String> get hourlyRangeLabels => const [
        '7–11',
        '11–16',
        '16–19',
        '19–23',
        '23–7',
      ];


  DashboardStatsModel copyWith({
    double? netSales,
    double? previousNetSales,
    int? ordersDelivered,
    int? previousOrdersDelivered,
    int? totalOrders,
    double? averageOrderValue,
    double? previousAov,
    double? salesChangePercent,
    double? ordersChangePercent,
    double? aovChangePercent,
    List<double>? salesSparkline,
    List<double>? ordersSparkline,
    List<double>? aovSparkline,
    List<DailyPoint>? salesTrend,
    List<DailyPoint>? ordersTrend,
    List<DailyPoint>? aovTrend,
    int? breakfastCount,
    int? lunchCount,
    int? eveningCount,
    int? dinnerCount,
    int? lateNightCount,
    int? totalMealtime,
    double? breakfastPercent,
    double? lunchPercent,
    double? eveningPercent,
    double? dinnerPercent,
    double? lateNightPercent,
    Map<String, double>? mealtimeFractions,
    int? funnelPending,
    int? funnelPreparing,
    int? funnelReady,
    int? funnelDelivered,
    int? funnelCancelled,
    int? funnelTotal,
    double? funnelPendingPercent,
    double? funnelPreparingPercent,
    double? funnelReadyPercent,
    double? funnelDeliveredPercent,
    double? funnelCancelledPercent,
    Map<String, double>? funnelFractions,
    double? preparingFromPendingPercent,
    double? readyFromPreparingPercent,
    double? deliveredFromReadyPercent,
    double? cancelledFromDeliveredPercent,
    double? cancellationRatePercent,
    double? deliveryRatePercent,
    int? dineInCount,
    int? takeawayCount,
    int? deliveryCount,
    int? staffOrderCount,
    int? appOrderCount,
    int? orderTypeTotal,
    int? orderSourceTotal,
    double? dineInPercent,
    double? takeawayPercent,
    double? deliveryPercent,
    double? staffOrderPercent,
    double? appOrderPercent,
    Map<String, double>? orderTypeFractions,
    Map<String, double>? orderSourceFractions,
    List<TopSellingItem>? topSellingItems,
    int? activeOrdersCount,
    int? pendingPaymentCount,
    int? lowStockCount,
    int? criticalStockCount,
    int? stockAlertCount,
    int? activeCouponCount,
    int? couponUsagesCount,
    List<AttentionItem>? attentionItems,
    String? periodLabel,
  }) {
    return DashboardStatsModel(
      netSales: netSales ?? this.netSales,
      previousNetSales: previousNetSales ?? this.previousNetSales,
      ordersDelivered: ordersDelivered ?? this.ordersDelivered,
      previousOrdersDelivered:
          previousOrdersDelivered ?? this.previousOrdersDelivered,
      totalOrders: totalOrders ?? this.totalOrders,
      averageOrderValue: averageOrderValue ?? this.averageOrderValue,
      previousAov: previousAov ?? this.previousAov,
      salesChangePercent: salesChangePercent ?? this.salesChangePercent,
      ordersChangePercent: ordersChangePercent ?? this.ordersChangePercent,
      aovChangePercent: aovChangePercent ?? this.aovChangePercent,
      salesSparkline: salesSparkline ?? this.salesSparkline,
      ordersSparkline: ordersSparkline ?? this.ordersSparkline,
      aovSparkline: aovSparkline ?? this.aovSparkline,
      salesTrend: salesTrend ?? this.salesTrend,
      ordersTrend: ordersTrend ?? this.ordersTrend,
      aovTrend: aovTrend ?? this.aovTrend,
      breakfastCount: breakfastCount ?? this.breakfastCount,
      lunchCount: lunchCount ?? this.lunchCount,
      eveningCount: eveningCount ?? this.eveningCount,
      dinnerCount: dinnerCount ?? this.dinnerCount,
      lateNightCount: lateNightCount ?? this.lateNightCount,
      totalMealtime: totalMealtime ?? this.totalMealtime,
      breakfastPercent: breakfastPercent ?? this.breakfastPercent,
      lunchPercent: lunchPercent ?? this.lunchPercent,
      eveningPercent: eveningPercent ?? this.eveningPercent,
      dinnerPercent: dinnerPercent ?? this.dinnerPercent,
      lateNightPercent: lateNightPercent ?? this.lateNightPercent,
      mealtimeFractions: mealtimeFractions ?? this.mealtimeFractions,
      funnelPending: funnelPending ?? this.funnelPending,
      funnelPreparing: funnelPreparing ?? this.funnelPreparing,
      funnelReady: funnelReady ?? this.funnelReady,
      funnelDelivered: funnelDelivered ?? this.funnelDelivered,
      funnelCancelled: funnelCancelled ?? this.funnelCancelled,
      funnelTotal: funnelTotal ?? this.funnelTotal,
      funnelPendingPercent: funnelPendingPercent ?? this.funnelPendingPercent,
      funnelPreparingPercent:
          funnelPreparingPercent ?? this.funnelPreparingPercent,
      funnelReadyPercent: funnelReadyPercent ?? this.funnelReadyPercent,
      funnelDeliveredPercent:
          funnelDeliveredPercent ?? this.funnelDeliveredPercent,
      funnelCancelledPercent:
          funnelCancelledPercent ?? this.funnelCancelledPercent,
      funnelFractions: funnelFractions ?? this.funnelFractions,
      preparingFromPendingPercent:
          preparingFromPendingPercent ?? this.preparingFromPendingPercent,
      readyFromPreparingPercent:
          readyFromPreparingPercent ?? this.readyFromPreparingPercent,
      deliveredFromReadyPercent:
          deliveredFromReadyPercent ?? this.deliveredFromReadyPercent,
      cancelledFromDeliveredPercent:
          cancelledFromDeliveredPercent ?? this.cancelledFromDeliveredPercent,
      cancellationRatePercent:
          cancellationRatePercent ?? this.cancellationRatePercent,
      deliveryRatePercent: deliveryRatePercent ?? this.deliveryRatePercent,
      dineInCount: dineInCount ?? this.dineInCount,
      takeawayCount: takeawayCount ?? this.takeawayCount,
      deliveryCount: deliveryCount ?? this.deliveryCount,
      staffOrderCount: staffOrderCount ?? this.staffOrderCount,
      appOrderCount: appOrderCount ?? this.appOrderCount,
      orderTypeTotal: orderTypeTotal ?? this.orderTypeTotal,
      orderSourceTotal: orderSourceTotal ?? this.orderSourceTotal,
      dineInPercent: dineInPercent ?? this.dineInPercent,
      takeawayPercent: takeawayPercent ?? this.takeawayPercent,
      deliveryPercent: deliveryPercent ?? this.deliveryPercent,
      staffOrderPercent: staffOrderPercent ?? this.staffOrderPercent,
      appOrderPercent: appOrderPercent ?? this.appOrderPercent,
      orderTypeFractions: orderTypeFractions ?? this.orderTypeFractions,
      orderSourceFractions: orderSourceFractions ?? this.orderSourceFractions,
      topSellingItems: topSellingItems ?? this.topSellingItems,
      activeOrdersCount: activeOrdersCount ?? this.activeOrdersCount,
      pendingPaymentCount: pendingPaymentCount ?? this.pendingPaymentCount,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      criticalStockCount: criticalStockCount ?? this.criticalStockCount,
      stockAlertCount: stockAlertCount ?? this.stockAlertCount,
      activeCouponCount: activeCouponCount ?? this.activeCouponCount,
      couponUsagesCount: couponUsagesCount ?? this.couponUsagesCount,
      attentionItems: attentionItems ?? this.attentionItems,
      periodLabel: periodLabel ?? this.periodLabel,
    );
  }
}

class DailyPoint {
  final DateTime date;
  final double value;
  const DailyPoint({required this.date, required this.value});
}

class TopSellingItem {
  final int rank;
  final String name;
  final int orders;
  final double revenue;
  const TopSellingItem({
    required this.rank,
    required this.name,
    required this.orders,
    required this.revenue,
  });
}

enum AttentionSeverity { critical, warning, info }

enum AttentionKind {
  criticalStock,
  lowStock,
  pendingPayment,
  expiringCoupon,
  unavailableMenu,
}

class AttentionItem {
  final AttentionKind kind;
  final AttentionSeverity severity;
  final String title;
  final String subtitle;
  final String? route;
  final String? filterHint;

  const AttentionItem({
    required this.kind,
    required this.severity,
    required this.title,
    required this.subtitle,
    this.route,
    this.filterHint,
  });
}

// ---------------------------------------------------------------------------
// Cloud Function mapping (getDashboardStats)
// ---------------------------------------------------------------------------

extension DashboardStatsModelCloudX on DashboardStatsModel {
  /// Builds stats exclusively from the `getDashboardStats` Cloud Function.
  static DashboardStatsModel fromCloud(Map<String, dynamic> json) {
    double d(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    int i(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    double p(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    Map<String, double> numberMap(dynamic value) {
      if (value is! Map) return const {};
      return value.map(
        (key, entry) => MapEntry(key.toString(), p(entry)),
      );
    }

    List<double> doubles(dynamic v) {
      if (v is! List) return const [];
      return v.map((e) => d(e)).toList();
    }

    List<DailyPoint> daily(dynamic v) {
      if (v is! List) return const [];
      return v.whereType<Map>().map((raw) {
        final m = Map<String, dynamic>.from(raw);
        final dateRaw = m['date'];
        final date = dateRaw is String
            ? (DateTime.tryParse(dateRaw) ?? DateTime.now())
            : DateTime.now();
        return DailyPoint(date: date.toLocal(), value: d(m['value']));
      }).toList();
    }

    List<TopSellingItem> top(dynamic v) {
      if (v is! List) return const [];
      final out = <TopSellingItem>[];
      for (var idx = 0; idx < v.length; idx++) {
        final raw = v[idx];
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final rank = i(m['rank']);
        out.add(TopSellingItem(
          rank: rank == 0 ? idx + 1 : rank,
          name: m['name']?.toString() ?? '',
          orders: i(m['orders']),
          revenue: d(m['revenue']),
        ));
      }
      return out;
    }

    List<AttentionItem> attention(dynamic v) {
      if (v is! List) return const [];
      return v.whereType<Map>().map((raw) {
        final m = Map<String, dynamic>.from(raw);
        return AttentionItem(
          kind: _parseAttentionKind(m['kind']?.toString()),
          severity: _parseAttentionSeverity(m['severity']?.toString()),
          title: m['title']?.toString() ?? '',
          subtitle: m['subtitle']?.toString() ?? '',
          route: m['route']?.toString(),
          filterHint:
              m['filter_hint']?.toString() ?? m['filterHint']?.toString(),
        );
      }).toList();
    }

    return DashboardStatsModel(
      netSales: d(json['net_sales']),
      previousNetSales: d(json['previous_net_sales']),
      ordersDelivered: i(json['orders_delivered']),
      previousOrdersDelivered: i(json['previous_orders_delivered']),
      totalOrders: i(json['orders_count']),
      averageOrderValue: d(json['average_order_value']),
      previousAov: d(json['previous_aov']),
      salesChangePercent: p(json['sales_change_percent']),
      ordersChangePercent: p(json['orders_change_percent']),
      aovChangePercent: p(json['aov_change_percent']),
      salesSparkline: doubles(json['sales_sparkline']),
      ordersSparkline: doubles(json['orders_sparkline']),
      aovSparkline: doubles(json['aov_sparkline']),
      salesTrend: daily(json['sales_trend']),
      ordersTrend: daily(json['orders_trend']),
      aovTrend: daily(json['aov_trend']),
      breakfastCount: i(json['breakfast_count']),
      lunchCount: i(json['lunch_count']),
      eveningCount: i(json['evening_count']),
      dinnerCount: i(json['dinner_count']),
      lateNightCount: i(json['late_night_count']),
      totalMealtime: i(json['mealtime_total']),
      breakfastPercent: p((json['mealtime_pct'] as Map?)?['breakfast']),
      lunchPercent: p((json['mealtime_pct'] as Map?)?['lunch']),
      eveningPercent: p((json['mealtime_pct'] as Map?)?['evening']),
      dinnerPercent: p((json['mealtime_pct'] as Map?)?['dinner']),
      lateNightPercent: p((json['mealtime_pct'] as Map?)?['late_night']),
      mealtimeFractions: numberMap(json['mealtime_fraction']),
      funnelPending: i(json['funnel_pending']),
      funnelPreparing: i(json['funnel_preparing']),
      funnelReady: i(json['funnel_ready']),
      funnelDelivered: i(json['funnel_delivered']),
      funnelCancelled: i(json['funnel_cancelled']),
      funnelTotal: i(json['funnel_total']),
      funnelPendingPercent: p((json['funnel_pct'] as Map?)?['pending']),
      funnelPreparingPercent: p((json['funnel_pct'] as Map?)?['preparing']),
      funnelReadyPercent: p((json['funnel_pct'] as Map?)?['ready']),
      funnelDeliveredPercent: p((json['funnel_pct'] as Map?)?['delivered']),
      funnelCancelledPercent: p((json['funnel_pct'] as Map?)?['cancelled']),
      funnelFractions: numberMap(json['funnel_fraction']),
      preparingFromPendingPercent:
          p((json['funnel_conversion_pct'] as Map?)?['preparing_from_pending']),
      readyFromPreparingPercent:
          p((json['funnel_conversion_pct'] as Map?)?['ready_from_preparing']),
      deliveredFromReadyPercent:
          p((json['funnel_conversion_pct'] as Map?)?['delivered_from_ready']),
      cancelledFromDeliveredPercent: p(
          (json['funnel_conversion_pct'] as Map?)?['cancelled_from_delivered']),
      cancellationRatePercent: p(json['cancellation_rate_pct']),
      deliveryRatePercent: p(json['delivery_rate_pct']),
      dineInCount: i(json['dine_in_count']),
      takeawayCount: i(json['takeaway_count']),
      deliveryCount: i(json['delivery_count']),
      staffOrderCount: i(json['staff_order_count']),
      appOrderCount: i(json['app_order_count']),
      orderTypeTotal: i(json['order_type_total']),
      orderSourceTotal: i(json['order_source_total']),
      dineInPercent: p((json['order_type_pct'] as Map?)?['dine_in']),
      takeawayPercent: p((json['order_type_pct'] as Map?)?['takeaway']),
      deliveryPercent: p((json['order_type_pct'] as Map?)?['delivery']),
      staffOrderPercent: p((json['order_source_pct'] as Map?)?['staff']),
      appOrderPercent: p((json['order_source_pct'] as Map?)?['app']),
      orderTypeFractions: numberMap(json['order_type_fraction']),
      orderSourceFractions: numberMap(json['order_source_fraction']),
      topSellingItems: top(json['top_selling_items']),
      activeOrdersCount: i(json['active_orders_count']),
      pendingPaymentCount: i(json['pending_payment_count']),
      lowStockCount: i(json['low_stock_count']),
      criticalStockCount: i(json['critical_stock_count']),
      stockAlertCount: i(json['stock_alert_count']),
      activeCouponCount: i(json['active_coupon_count']),
      couponUsagesCount: i(json['coupon_usages_count']),
      attentionItems: attention(json['attention_items']),
      periodLabel: json['period_label']?.toString() ?? 'Today',
    );
  }
}

AttentionKind _parseAttentionKind(String? value) {
  switch (value) {
    case 'criticalStock':
      return AttentionKind.criticalStock;
    case 'lowStock':
      return AttentionKind.lowStock;
    case 'pendingPayment':
      return AttentionKind.pendingPayment;
    case 'expiringCoupon':
      return AttentionKind.expiringCoupon;
    case 'unavailableMenu':
      return AttentionKind.unavailableMenu;
    default:
      return AttentionKind.lowStock;
  }
}

AttentionSeverity _parseAttentionSeverity(String? value) {
  switch (value) {
    case 'critical':
      return AttentionSeverity.critical;
    case 'info':
      return AttentionSeverity.info;
    default:
      return AttentionSeverity.warning;
  }
}

/// Prefer this entry point from services.
DashboardStatsModel dashboardStatsFromCloud(Map<String, dynamic> json) =>
    DashboardStatsModelCloudX.fromCloud(json);
