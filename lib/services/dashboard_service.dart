import '../models/dashboard_stats_model.dart';

/// Pure aggregations over real order / inventory / coupon data.
/// No dummy numbers — pass live lists from providers/services.
class DashboardService {
  DashboardStatsModel buildStats({
    required List<DashboardOrderInput> todayOrders,
    required List<DashboardOrderInput> trendOrders,
    required int lowStockCount,
    required int criticalStockCount,
    required int activeCouponCount,
    required int couponUsagesToday,
    required int activeOrdersCount,
    required int pendingPaymentCount,
    List<String> criticalItemNames = const [],
    List<String> lowStockItemNames = const [],
    List<String> expiringCouponCodes = const [],
    // Restaurant's operating hours (24h), taken from Settings.
    // Volume trend is bucketed into 2-hour slots across this window.
    int openHour = 10,
    int closeHour = 22,
  }) {
    final paidToday = todayOrders.where((o) => o.isPaid).toList();
    final todayRevenue = paidToday.fold<double>(0, (s, o) => s + o.total);

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final yesterdayRevenue = trendOrders
        .where((o) =>
            o.isPaid &&
            !o.createdAt.isBefore(yesterdayStart) &&
            o.createdAt.isBefore(todayStart))
        .fold<double>(0, (s, o) => s + o.total);

    final dineIn = todayOrders.where((o) => o.orderType == 'dineIn').length;
    final takeaway =
        todayOrders.where((o) => o.orderType == 'takeaway').length;
    final delivery =
        todayOrders.where((o) => o.orderType == 'delivery').length;
    final staff = todayOrders.where((o) => o.orderSource == 'staff').length;
    final app = todayOrders.where((o) => o.orderSource == 'app').length;

    final hourly = _hourlyVolume(
      todayOrders,
      openHour: openHour,
      closeHour: closeHour,
    );
    final revenueTrend = _dailyRevenueSeries(trendOrders, days: _inferDays(trendOrders));
    final orderTrend = _dailyOrderCountSeries(trendOrders, days: _inferDays(trendOrders));
    final topSelling = _topSelling(todayOrders, limit: 4);

    final attention = _buildAttention(
      criticalStockCount: criticalStockCount,
      lowStockCount: lowStockCount,
      pendingPaymentCount: pendingPaymentCount,
      criticalItemNames: criticalItemNames,
      lowStockItemNames: lowStockItemNames,
      expiringCouponCodes: expiringCouponCodes,
    );

    return DashboardStatsModel(
      todayRevenue: todayRevenue,
      yesterdayRevenue: yesterdayRevenue,
      todayOrderCount: todayOrders.length,
      dineInCount: dineIn,
      takeawayCount: takeaway,
      deliveryCount: delivery,
      staffOrderCount: staff,
      appOrderCount: app,
      hourlyVolume: hourly.values,
      hourlyLabels: hourly.labels,
      hourlyRangeLabels: hourly.rangeLabels,
      revenueTrend: revenueTrend,
      orderCountTrend: orderTrend,
      topSellingItems: topSelling,
      attentionItems: attention,
      activeCouponCount: activeCouponCount,
      couponUsagesToday: couponUsagesToday,
      lowStockCount: lowStockCount,
      criticalStockCount: criticalStockCount,
      pendingPaymentCount: pendingPaymentCount,
      activeOrdersCount: activeOrdersCount,
    );
  }

  static int daysForPeriod(String period) {
    switch (period) {
      case 'Daily':
        return 7;
      case 'Weekly':
        return 14;
      case 'Monthly':
        return 30;
      default:
        return 7;
    }
  }

  int _inferDays(List<DashboardOrderInput> orders) {
    if (orders.isEmpty) return 7;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    var minDay = start;
    for (final o in orders) {
      final d = DateTime(o.createdAt.year, o.createdAt.month, o.createdAt.day);
      if (d.isBefore(minDay)) minDay = d;
    }
    return start.difference(minDay).inDays + 1;
  }

  ({List<double> values, List<String> labels, List<String> rangeLabels})
      _hourlyVolume(
    List<DashboardOrderInput> orders, {
    required int openHour,
    required int closeHour,
  }) {
    final slots = _twoHourSlots(openHour: openHour, closeHour: closeHour);
    final buckets = List<double>.filled(slots.length, 0);

    for (final o in orders) {
      final idx = _slotIndexForHour(o.createdAt.hour, slots);
      if (idx != -1) buckets[idx] += 1;
    }

    return (
      values: buckets,
      labels: slots.map(_formatHourLabel).toList(),
      rangeLabels: slots.map(_formatRangeLabel).toList(),
    );
  }

  /// Builds hour-of-day slot starts, 2 hours apart, from [openHour] up to
  /// (but not reaching) [closeHour]. Wraps past midnight when the
  /// restaurant closes after 12 AM (e.g. open 10AM, close 2AM).
  List<int> _twoHourSlots({required int openHour, required int closeHour}) {
    final open = openHour % 24;
    final close = closeHour % 24;
    final span = close > open ? close - open : (24 - open) + close;
    final slotCount = (span / 2).ceil().clamp(1, 12);
    return [for (var i = 0; i < slotCount; i++) (open + i * 2) % 24];
  }

  /// Finds which 2-hour slot [hour] falls into, wrapping past midnight.
  int _slotIndexForHour(int hour, List<int> slots) {
    for (var i = 0; i < slots.length; i++) {
      final start = slots[i];
      final end = (start + 2) % 24;
      final inRange =
          end > start ? (hour >= start && hour < end) : (hour >= start || hour < end);
      if (inRange) return i;
    }
    return -1;
  }

  /// Single point label for the chart axis, e.g. "10AM", "12PM".
  String _formatHourLabel(int hour24) {
    final period = hour24 >= 12 ? 'PM' : 'AM';
    var h = hour24 % 12;
    if (h == 0) h = 12;
    return '$h$period';
  }

  /// Full 2-hour range for the hover tooltip, e.g. "10AM-12PM", "12PM-2PM".
  String _formatRangeLabel(int startHour24) {
    final endHour24 = (startHour24 + 2) % 24;
    return '${_formatHourLabel(startHour24)}-${_formatHourLabel(endHour24)}';
  }

  List<DailyPoint> _dailyRevenueSeries(
    List<DashboardOrderInput> orders, {
    required int days,
  }) {
    final n = days.clamp(1, 90);
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: n - 1));

    final map = <DateTime, double>{};
    for (var i = 0; i < n; i++) {
      map[start.add(Duration(days: i))] = 0;
    }
    for (final o in orders) {
      if (!o.isPaid) continue;
      final day =
          DateTime(o.createdAt.year, o.createdAt.month, o.createdAt.day);
      if (map.containsKey(day)) {
        map[day] = map[day]! + o.total;
      }
    }
    final keys = map.keys.toList()..sort();
    return [for (final d in keys) DailyPoint(date: d, value: map[d]!)];
  }

  List<DailyPoint> _dailyOrderCountSeries(
    List<DashboardOrderInput> orders, {
    required int days,
  }) {
    final n = days.clamp(1, 90);
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: n - 1));

    final map = <DateTime, double>{};
    for (var i = 0; i < n; i++) {
      map[start.add(Duration(days: i))] = 0;
    }
    for (final o in orders) {
      final day =
          DateTime(o.createdAt.year, o.createdAt.month, o.createdAt.day);
      if (map.containsKey(day)) {
        map[day] = map[day]! + 1;
      }
    }
    final keys = map.keys.toList()..sort();
    return [for (final d in keys) DailyPoint(date: d, value: map[d]!)];
  }

  List<TopSellingItem> _topSelling(
    List<DashboardOrderInput> orders, {
    int limit = 5,
  }) {
    final byName = <String, ({int qty, double revenue})>{};
    for (final o in orders) {
      for (final line in o.items) {
        final prev = byName[line.name];
        byName[line.name] = (
          qty: (prev?.qty ?? 0) + line.quantity,
          revenue: (prev?.revenue ?? 0) + line.price * line.quantity,
        );
      }
    }
    final sorted = byName.entries.toList()
      ..sort((a, b) => b.value.qty.compareTo(a.value.qty));
    return [
      for (var i = 0; i < sorted.length && i < limit; i++)
        TopSellingItem(
          rank: i + 1,
          name: sorted[i].key,
          orders: sorted[i].value.qty,
          revenue: sorted[i].value.revenue,
        ),
    ];
  }

  List<AttentionItem> _buildAttention({
    required int criticalStockCount,
    required int lowStockCount,
    required int pendingPaymentCount,
    required List<String> criticalItemNames,
    required List<String> lowStockItemNames,
    required List<String> expiringCouponCodes,
  }) {
    final items = <AttentionItem>[];

    if (criticalStockCount > 0) {
      final names = criticalItemNames.take(3).join(', ');
      items.add(AttentionItem(
        kind: AttentionKind.criticalStock,
        severity: AttentionSeverity.critical,
        title:
            '$criticalStockCount item${criticalStockCount == 1 ? '' : 's'} critical',
        subtitle: names.isEmpty ? 'Below safe stock level' : names,
        route: '/inventory',
        filterHint: 'Critical',
      ));
    }

    if (lowStockCount > 0) {
      final names = lowStockItemNames.take(3).join(', ');
      items.add(AttentionItem(
        kind: AttentionKind.lowStock,
        severity: AttentionSeverity.warning,
        title:
            '$lowStockCount item${lowStockCount == 1 ? '' : 's'} low stock',
        subtitle: names.isEmpty ? 'Below minimum threshold' : names,
        route: '/inventory',
        filterHint: 'Low Stock',
      ));
    }

    if (pendingPaymentCount > 0) {
      items.add(AttentionItem(
        kind: AttentionKind.pendingPayment,
        severity: AttentionSeverity.warning,
        title:
            '$pendingPaymentCount order${pendingPaymentCount == 1 ? '' : 's'} pending payment',
        subtitle: 'Unpaid after kitchen flow',
        route: '/live-orders',
        filterHint: 'Unpaid',
      ));
    }

    if (expiringCouponCodes.isNotEmpty) {
      items.add(AttentionItem(
        kind: AttentionKind.expiringCoupon,
        severity: AttentionSeverity.info,
        title:
            '${expiringCouponCodes.length} coupon${expiringCouponCodes.length == 1 ? '' : 's'} expiring soon',
        subtitle: expiringCouponCodes.take(3).join(', '),
        route: '/coupons',
        filterHint: 'Active',
      ));
    }

    return items;
  }
}

/// Lightweight order shape for dashboard aggregations (mapped from OrderModel).
class DashboardOrderInput {
  final String id;
  final double total;
  final DateTime createdAt;
  final bool isPaid;
  final String orderType;
  final String orderSource;
  final List<DashboardLineItem> items;

  const DashboardOrderInput({
    required this.id,
    required this.total,
    required this.createdAt,
    required this.isPaid,
    required this.orderType,
    required this.orderSource,
    this.items = const [],
  });
}

class DashboardLineItem {
  final String name;
  final int quantity;
  final double price;

  const DashboardLineItem({
    required this.name,
    required this.quantity,
    required this.price,
  });
}
