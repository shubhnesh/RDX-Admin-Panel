/// Dashboard aggregates and chart series built from real module data.
class DashboardStatsModel {
  final double todayRevenue;
  final double yesterdayRevenue;
  final int todayOrderCount;
  final int dineInCount;
  final int takeawayCount;
  final int deliveryCount;
  final int staffOrderCount;
  final int appOrderCount;

  final List<double> hourlyVolume;
  final List<String> hourlyLabels;
  final List<String> hourlyRangeLabels;

  final List<DailyPoint> revenueTrend;
  final List<DailyPoint> orderCountTrend;

  final List<TopSellingItem> topSellingItems;
  final List<AttentionItem> attentionItems;

  final int activeCouponCount;
  final int couponUsagesToday;
  final int lowStockCount;
  final int criticalStockCount;
  final int pendingPaymentCount;
  final int activeOrdersCount;

  const DashboardStatsModel({
    required this.todayRevenue,
    this.yesterdayRevenue = 0,
    this.todayOrderCount = 0,
    this.dineInCount = 0,
    this.takeawayCount = 0,
    this.deliveryCount = 0,
    this.staffOrderCount = 0,
    this.appOrderCount = 0,
    this.hourlyVolume = const [],
    this.hourlyLabels = const [],
    this.hourlyRangeLabels = const [],
    this.revenueTrend = const [],
    this.orderCountTrend = const [],
    this.topSellingItems = const [],
    this.attentionItems = const [],
    this.activeCouponCount = 0,
    this.couponUsagesToday = 0,
    this.lowStockCount = 0,
    this.criticalStockCount = 0,
    this.pendingPaymentCount = 0,
    this.activeOrdersCount = 0,
  });

  double get revenueChangePercent {
    if (yesterdayRevenue <= 0) return todayRevenue > 0 ? 100.0 : 0.0;
    return ((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100;
  }

  DashboardStatsModel copyWith({
    double? todayRevenue,
    double? yesterdayRevenue,
    int? todayOrderCount,
    int? dineInCount,
    int? takeawayCount,
    int? deliveryCount,
    int? staffOrderCount,
    int? appOrderCount,
    List<double>? hourlyVolume,
    List<String>? hourlyLabels,
    List<String>? hourlyRangeLabels,
    List<DailyPoint>? revenueTrend,
    List<DailyPoint>? orderCountTrend,
    List<TopSellingItem>? topSellingItems,
    List<AttentionItem>? attentionItems,
    int? activeCouponCount,
    int? couponUsagesToday,
    int? lowStockCount,
    int? criticalStockCount,
    int? pendingPaymentCount,
    int? activeOrdersCount,
  }) {
    return DashboardStatsModel(
      todayRevenue: todayRevenue ?? this.todayRevenue,
      yesterdayRevenue: yesterdayRevenue ?? this.yesterdayRevenue,
      todayOrderCount: todayOrderCount ?? this.todayOrderCount,
      dineInCount: dineInCount ?? this.dineInCount,
      takeawayCount: takeawayCount ?? this.takeawayCount,
      deliveryCount: deliveryCount ?? this.deliveryCount,
      staffOrderCount: staffOrderCount ?? this.staffOrderCount,
      appOrderCount: appOrderCount ?? this.appOrderCount,
      hourlyVolume: hourlyVolume ?? this.hourlyVolume,
      hourlyLabels: hourlyLabels ?? this.hourlyLabels,
      hourlyRangeLabels: hourlyRangeLabels ?? this.hourlyRangeLabels,
      revenueTrend: revenueTrend ?? this.revenueTrend,
      orderCountTrend: orderCountTrend ?? this.orderCountTrend,
      topSellingItems: topSellingItems ?? this.topSellingItems,
      attentionItems: attentionItems ?? this.attentionItems,
      activeCouponCount: activeCouponCount ?? this.activeCouponCount,
      couponUsagesToday: couponUsagesToday ?? this.couponUsagesToday,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      criticalStockCount: criticalStockCount ?? this.criticalStockCount,
      pendingPaymentCount: pendingPaymentCount ?? this.pendingPaymentCount,
      activeOrdersCount: activeOrdersCount ?? this.activeOrdersCount,
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
