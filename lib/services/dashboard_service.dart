import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dashboard_stats_model.dart';
import '../models/activity_log_model.dart';
import '../models/order_model.dart';

class DashboardService {
  // Lazy getter (not a field initializer) so constructing DashboardService
  // never touches Firestore/Firebase — important while useMockData is true
  // and Firebase may not be configured at all yet.
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// While the app isn't wired up to real Firestore data yet, the dashboard
  /// renders from [_mockStats]/[_mockActivity] below instead of hitting
  /// Firestore. Flip this to `false` once real `orders` / `activity_logs`
  /// collections exist — fetchStats/fetchRecentActivity will then read
  /// live data exactly as before.
  static const bool useMockData = true;

  Future<DashboardStatsModel> fetchStats() async {
    if (useMockData) {
      // Simulate a small network delay so loading states still feel real.
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockStats;
    }

    final statsDoc = await _db.collection('dashboard').doc('stats').get();
    if (statsDoc.exists) {
      return DashboardStatsModel.fromJson(statsDoc.data()!);
    }

    final ordersSnap = await _db
        .collection('orders')
        .orderBy('created_at', descending: true)
        .limit(200)
        .get();

    final orders =
        ordersSnap.docs.map((d) => OrderModel.fromFirestore(d)).toList();

    final active = orders
        .where((o) =>
            o.status == OrderStatus.pending ||
            o.status == OrderStatus.preparing ||
            o.status == OrderStatus.ready)
        .length;
    final preparing =
        orders.where((o) => o.status == OrderStatus.preparing).length;
    final ready = orders.where((o) => o.status == OrderStatus.ready).length;

    final totalRevenue = orders.fold<double>(0, (sum, o) => sum + o.total);

    final Map<String, TopSellingItem> topMap = {};
    for (final o in orders) {
      for (final item in o.items) {
        final existing = topMap[item.name];
        if (existing == null) {
          topMap[item.name] = TopSellingItem(
            rank: 0,
            name: item.name,
            orders: item.quantity,
            revenue: item.price * item.quantity,
          );
        } else {
          topMap[item.name] = TopSellingItem(
            rank: 0,
            name: item.name,
            orders: existing.orders + item.quantity,
            revenue: existing.revenue + (item.price * item.quantity),
          );
        }
      }
    }
    final topList = topMap.values.toList()
      ..sort((a, b) => b.orders.compareTo(a.orders));
    final topSelling = topList.take(5).toList().asMap().entries.map((e) {
      return TopSellingItem(
        rank: e.key + 1,
        name: e.value.name,
        orders: e.value.orders,
        revenue: e.value.revenue,
      );
    }).toList();

    return DashboardStatsModel(
      totalRevenue: totalRevenue,
      revenueChangePercent: 0,
      activeOrders: active,
      preparingCount: preparing,
      enRouteCount: ready,
      tablesOccupiedPercent: 0,
      availableRiders: 0,
      totalRiders: 50,
      highDemand: active > 15,
      weeklyRevenue: List.filled(7, totalRevenue / 7),
      hourlyVolume: List.filled(12, 0),
      topSellingItems: topSelling,
    );
  }

  Future<List<ActivityLogModel>> fetchRecentActivity({int limit = 20}) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      return _mockActivity;
    }

    final snap = await _db
        .collection('activity_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => ActivityLogModel.fromFirestore(d)).toList();
  }

  Future<void> logActivity({
    required String actor,
    required String action,
    required String details,
  }) async {
    if (useMockData) return;
    await _db.collection('activity_logs').add({
      'actor': actor,
      'action': action,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════════════
  // MOCK DATA — mirrors the reference dashboard design so the Analytics
  // Performance line chart, Volume Trend bar chart, Top Selling list and
  // Recent Activity table all render with realistic values.
  // ═══════════════════════════════════════════════════════════════════

  static final DashboardStatsModel _mockStats = DashboardStatsModel(
    totalRevenue: 142504,
    revenueChangePercent: 12.3,
    activeOrders: 24,
    preparingCount: 12,
    enRouteCount: 12,
    tablesOccupiedPercent: 85,
    availableRiders: 12,
    totalRiders: 30,
    highDemand: true,
    // Mon..Sun weekly revenue — dips midweek, peaks Friday, tapers Sunday.
    weeklyRevenue: const [58, 42, 38, 64, 92, 70, 76],
    // 10AM..12AM in 2-hour steps — peaks at 8PM like the design.
    hourlyVolume: const [120, 180, 100, 240, 320, 450, 300, 150],
    topSellingItems: [
      TopSellingItem(
          rank: 1, name: 'RDX Signature Burger', orders: 142, revenue: 1846),
      TopSellingItem(rank: 2, name: 'Truffle Fries', orders: 98, revenue: 882),
      TopSellingItem(rank: 3, name: 'Neon Cola', orders: 85, revenue: 340),
      TopSellingItem(rank: 4, name: 'Spicy Wings', orders: 64, revenue: 608),
    ],
  );

  static final List<ActivityLogModel> _mockActivity = [
    ActivityLogModel(
      id: 'ORD-8924',
      actor: 'Customer',
      action: 'New order received',
      details: 'LIVE',
      timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
    ),
    ActivityLogModel(
      id: 'SYS-ALRT',
      actor: 'System',
      action: 'Rider shortage in Zone B',
      details: 'SYSTEM',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    ActivityLogModel(
      id: 'ORD-8919',
      actor: 'System',
      action: 'Order delivered',
      details: 'COMPLETED',
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
  ];
}
