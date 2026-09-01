class DashboardStatsModel {
  final double totalRevenue;
  final double revenueChangePercent;
  final int activeOrders;
  final int preparingCount;
  final int enRouteCount;
  final double tablesOccupiedPercent;
  final int availableRiders;
  final int totalRiders;
  final bool highDemand;
  final List<double> weeklyRevenue;
  final List<double> hourlyVolume;
  final List<TopSellingItem> topSellingItems;

  DashboardStatsModel({
    required this.totalRevenue,
    this.revenueChangePercent = 0,
    required this.activeOrders,
    this.preparingCount = 0,
    this.enRouteCount = 0,
    this.tablesOccupiedPercent = 0,
    this.availableRiders = 0,
    this.totalRiders = 50,
    this.highDemand = false,
    this.weeklyRevenue = const [0, 0, 0, 0, 0, 0, 0],
    this.hourlyVolume = const [0, 0, 0, 0, 0, 0, 0, 0],
    this.topSellingItems = const [],
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      revenueChangePercent:
          (json['revenue_change_percent'] as num?)?.toDouble() ?? 0,
      activeOrders: json['active_orders'] as int? ?? 0,
      preparingCount: json['preparing_count'] as int? ?? 0,
      enRouteCount: json['en_route_count'] as int? ?? 0,
      tablesOccupiedPercent:
          (json['tables_occupied_percent'] as num?)?.toDouble() ?? 0,
      availableRiders: json['available_riders'] as int? ?? 0,
      totalRiders: json['total_riders'] as int? ?? 50,
      highDemand: json['high_demand'] as bool? ?? false,
      weeklyRevenue: (json['weekly_revenue'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          List.filled(7, 0.0),
      hourlyVolume: (json['hourly_volume'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          List.filled(12, 0.0),
      topSellingItems: (json['top_selling_items'] as List?)
              ?.map(
                  (e) => TopSellingItem.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'total_revenue': totalRevenue,
        'revenue_change_percent': revenueChangePercent,
        'active_orders': activeOrders,
        'preparing_count': preparingCount,
        'en_route_count': enRouteCount,
        'tables_occupied_percent': tablesOccupiedPercent,
        'available_riders': availableRiders,
        'total_riders': totalRiders,
        'high_demand': highDemand,
        'weekly_revenue': weeklyRevenue,
        'hourly_volume': hourlyVolume,
        'top_selling_items': topSellingItems.map((e) => e.toJson()).toList(),
      };
}

class TopSellingItem {
  final int rank;
  final String name;
  final int orders;
  final double revenue;

  TopSellingItem({
    required this.rank,
    required this.name,
    required this.orders,
    required this.revenue,
  });

  factory TopSellingItem.fromJson(Map<String, dynamic> json) => TopSellingItem(
        rank: json['rank'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        orders: json['orders'] as int? ?? 0,
        revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'name': name,
        'orders': orders,
        'revenue': revenue,
      };
}
