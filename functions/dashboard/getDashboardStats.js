/**
 * getDashboardStats — server-side dashboard aggregations.
 *
 * Client must never recompute sales / funnel / mealtime / trends from raw
 * orders. This callable is the single source of truth.
 *
 * Request:
 *   { period: "today" | "yesterday" | "last_7_days" }
 *
 * Response matches Flutter DashboardStatsModel field names (snake_case).
 */

const functions = require("firebase-functions");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const { requireRestaurantUser } = require("../auth/roles");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// ── Helpers ───────────────────────────────────────────────────────────────

/** Start of local calendar day (device TZ is not available on server —
 *  use Asia/Kolkata for restaurant ops). */
function startOfDayIST(date = new Date()) {
  // Convert to IST offset +05:30
  const istMs = date.getTime() + (5 * 60 + 30) * 60 * 1000;
  const ist = new Date(istMs);
  const y = ist.getUTCFullYear();
  const m = ist.getUTCMonth();
  const d = ist.getUTCDate();
  // Midnight IST as UTC instant
  return new Date(Date.UTC(y, m, d) - (5 * 60 + 30) * 60 * 1000);
}

function addDays(d, n) {
  const x = new Date(d.getTime());
  x.setTime(x.getTime() + n * 24 * 60 * 60 * 1000);
  return x;
}

function toDate(value) {
  if (!value) return null;
  if (value.toDate) return value.toDate();
  if (value instanceof Date) return value;
  if (typeof value === "string") {
    const p = Date.parse(value);
    return Number.isFinite(p) ? new Date(p) : null;
  }
  if (typeof value === "number") return new Date(value);
  return null;
}

function num(v, fallback = 0) {
  if (typeof v === "number" && Number.isFinite(v)) return v;
  if (typeof v === "string") {
    const n = Number(v);
    return Number.isFinite(n) ? n : fallback;
  }
  return fallback;
}

function round2(n) {
  return Math.round((n + Number.EPSILON) * 100) / 100;
}

function pctChange(current, previous) {
  if (previous <= 0) return current > 0 ? 100 : 0;
  return round2(((current - previous) / previous) * 100);
}

function safePct(part, whole) {
  if (!whole || whole <= 0) return 0;
  return round2((part / whole) * 100);
}

function safeRatio(part, whole) {
  if (!whole || whole <= 0) return 0;
  return part / whole;
}

function dayKey(d) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

function mealBucket(hour) {
  if (hour >= 7 && hour < 11) return "breakfast";
  if (hour >= 11 && hour < 16) return "lunch";
  if (hour >= 16 && hour < 19) return "evening";
  if (hour >= 19 && hour < 23) return "dinner";
  return "late_night";
}

function normalizeStatus(s) {
  const v = String(s || "pending").toLowerCase();
  if (["pending", "preparing", "ready", "delivered", "cancelled"].includes(v)) {
    return v;
  }
  return "delivered";
}

function normalizeOrderType(t) {
  const v = String(t || "dineIn");
  if (v === "dine_in") return "dineIn";
  if (v === "take_away") return "takeaway";
  return v;
}

function normalizeSource(s) {
  const v = String(s || "staff").toLowerCase();
  if (["app", "customer", "mobile", "customer_app"].includes(v)) return "app";
  return "staff";
}

// ── Period windows ────────────────────────────────────────────────────────

function resolveWindows(period) {
  const todayStart = startOfDayIST(new Date());
  const tomorrow = addDays(todayStart, 1);

  if (period === "yesterday") {
    const yStart = addDays(todayStart, -1);
    return {
      label: "Yesterday",
      periodStart: yStart,
      periodEnd: todayStart,
      previousStart: addDays(yStart, -1),
      previousEnd: yStart,
      trendStart: addDays(todayStart, -13),
      trendEnd: tomorrow,
    };
  }

  if (period === "last_7_days") {
    const from = addDays(todayStart, -6);
    return {
      label: "Last 7 days",
      periodStart: from,
      periodEnd: tomorrow,
      previousStart: addDays(from, -7),
      previousEnd: from,
      trendStart: addDays(todayStart, -13),
      trendEnd: tomorrow,
    };
  }

  // today (default)
  return {
    label: "Today",
    periodStart: todayStart,
    periodEnd: tomorrow,
    previousStart: addDays(todayStart, -1),
    previousEnd: todayStart,
    trendStart: addDays(todayStart, -13),
    trendEnd: tomorrow,
  };
}

// ── Fetchers ──────────────────────────────────────────────────────────────

async function fetchOrdersInRange(start, end) {
  const snap = await db
    .collection("orders")
    .where("created_at", ">=", admin.firestore.Timestamp.fromDate(start))
    .where("created_at", "<", admin.firestore.Timestamp.fromDate(end))
    .get();

  return snap.docs.map((doc) => {
    const d = doc.data() || {};
    const created = toDate(d.created_at) || new Date(0);
    const items = Array.isArray(d.items)
      ? d.items.map((line) => ({
          name: String(line?.name || "").trim() || "Item",
          quantity: Math.max(0, Math.floor(num(line?.quantity, 1))),
          price: num(line?.price, 0),
        }))
      : [];
    return {
      id: doc.id,
      total: num(d.total, 0),
      createdAt: created,
      isPaid: String(d.payment_status || "").toLowerCase() === "paid",
      couponCode: String(d.coupon_code || "").trim(),
      offerId: String(d.offer_id || "").trim(),
      orderType: normalizeOrderType(d.order_type),
      orderSource: normalizeSource(d.order_source),
      status: normalizeStatus(d.status),
      items,
    };
  });
}

async function fetchInventoryAlerts() {
  const snap = await db.collection("inventory").get();
  let low = 0;
  let critical = 0;
  const lowNames = [];
  const criticalNames = [];

  for (const doc of snap.docs) {
    const d = doc.data() || {};
    const qty = num(d.quantity, 0);
    const minReq =
      num(d.min_required, 0) || num(d.low_stock_threshold, 0);
    const name = String(d.name || doc.id);

    if (qty <= 0 || (minReq > 0 && qty < minReq * 0.25)) {
      critical += 1;
      if (criticalNames.length < 5) criticalNames.push(name);
    } else if (minReq > 0 && qty < minReq) {
      low += 1;
      if (lowNames.length < 5) lowNames.push(name);
    }
  }

  return { low, critical, lowNames, criticalNames };
}

async function fetchCouponStats() {
  const snap = await db.collection("coupons").get();
  const now = new Date();
  const inThreeDays = addDays(now, 3);
  let active = 0;
  const expiring = [];

  for (const doc of snap.docs) {
    const d = doc.data() || {};
    const status = String(d.status || "").toLowerCase();
    const end = toDate(d.end_date);
    const start = toDate(d.start_date);
    let effective = status;
    if (!effective && end && start) {
      if (end <= now) effective = "expired";
      else if (start > now) effective = "scheduled";
      else effective = "active";
    }

    if (effective === "active") {
      active += 1;
      if (end && end >= now && end <= inThreeDays) {
        const code = String(d.code || doc.id).toUpperCase();
        if (expiring.length < 5) expiring.push(code);
      }
    }
  }

  return { active, expiring };
}

async function fetchLiveOperational() {
  const snap = await db
    .collection("orders")
    .where("status", "in", ["pending", "preparing", "ready"])
    .get();

  let active = 0;
  let pendingPayment = 0;

  // Also count unpaid delivered from a wider recent window
  const weekAgo = addDays(startOfDayIST(new Date()), -7);
  const deliveredSnap = await db
    .collection("orders")
    .where("status", "==", "delivered")
    .where("created_at", ">=", admin.firestore.Timestamp.fromDate(weekAgo))
    .get();

  for (const doc of snap.docs) {
    active += 1;
    const d = doc.data() || {};
    if (String(d.payment_status || "").toLowerCase() !== "paid") {
      // unpaid while still in kitchen flow — counted separately below
    }
  }

  for (const doc of deliveredSnap.docs) {
    const d = doc.data() || {};
    if (String(d.payment_status || "").toLowerCase() !== "paid") {
      pendingPayment += 1;
    }
  }

  // Active = live kitchen statuses
  return { activeOrdersCount: active, pendingPaymentCount: pendingPayment };
}

// ── Aggregations ──────────────────────────────────────────────────────────

function filterRange(orders, start, end) {
  return orders.filter((o) => o.createdAt >= start && o.createdAt < end);
}

function buildDailySeries(orders, start, days, valueFn) {
  const points = [];
  for (let i = 0; i < days; i++) {
    const day = addDays(start, i);
    const next = addDays(day, 1);
    const dayOrders = orders.filter(
      (o) => o.createdAt >= day && o.createdAt < next
    );
    points.push({
      date: day.toISOString(),
      value: round2(dayOrders.reduce((s, o) => s + valueFn(o), 0)),
    });
  }
  return points;
}

function buildDailyAov(orders, start, days) {
  const points = [];
  for (let i = 0; i < days; i++) {
    const day = addDays(start, i);
    const next = addDays(day, 1);
    const paid = orders.filter(
      (o) => o.isPaid && o.createdAt >= day && o.createdAt < next
    );
    const rev = paid.reduce((s, o) => s + o.total, 0);
    points.push({
      date: day.toISOString(),
      value: paid.length === 0 ? 0 : round2(rev / paid.length),
    });
  }
  return points;
}

function buildSparklines(orders, start, days) {
  const sales = [];
  const orderCounts = [];
  const aovs = [];
  for (let i = 0; i < days; i++) {
    const day = addDays(start, i);
    const next = addDays(day, 1);
    const dayOrders = orders.filter(
      (o) => o.createdAt >= day && o.createdAt < next
    );
    const paid = dayOrders.filter((o) => o.isPaid);
    const rev = paid.reduce((s, o) => s + o.total, 0);
    sales.push(round2(rev));
    orderCounts.push(dayOrders.length);
    aovs.push(paid.length === 0 ? 0 : round2(rev / paid.length));
  }
  return { sales, orders: orderCounts, aov: aovs };
}

function topSelling(orders, limit = 5) {
  const byName = new Map();
  for (const o of orders) {
    for (const line of o.items) {
      const prev = byName.get(line.name) || { qty: 0, revenue: 0 };
      byName.set(line.name, {
        qty: prev.qty + line.quantity,
        revenue: prev.revenue + line.price * line.quantity,
      });
    }
  }
  return [...byName.entries()]
    .sort((a, b) => b[1].qty - a[1].qty)
    .slice(0, limit)
    .map(([name, v], i) => ({
      rank: i + 1,
      name,
      orders: v.qty,
      revenue: round2(v.revenue),
    }));
}

function buildAttention({
  criticalStockCount,
  lowStockCount,
  pendingPaymentCount,
  criticalItemNames,
  lowStockItemNames,
  expiringCouponCodes,
}) {
  const items = [];
  if (criticalStockCount > 0) {
    items.push({
      kind: "criticalStock",
      severity: "critical",
      title: `${criticalStockCount} item${criticalStockCount === 1 ? "" : "s"} critical`,
      subtitle: criticalItemNames.slice(0, 3).join(", ") || "Below safe stock level",
      route: "/inventory",
      filter_hint: "Critical",
    });
  }
  if (lowStockCount > 0) {
    items.push({
      kind: "lowStock",
      severity: "warning",
      title: `${lowStockCount} item${lowStockCount === 1 ? "" : "s"} low stock`,
      subtitle: lowStockItemNames.slice(0, 3).join(", ") || "Below minimum threshold",
      route: "/inventory",
      filter_hint: "Low Stock",
    });
  }
  if (pendingPaymentCount > 0) {
    items.push({
      kind: "pendingPayment",
      severity: "warning",
      title: `${pendingPaymentCount} order${pendingPaymentCount === 1 ? "" : "s"} pending payment`,
      subtitle: "Unpaid after kitchen flow",
      route: "/live-orders",
      filter_hint: "Unpaid",
    });
  }
  if (expiringCouponCodes.length > 0) {
    items.push({
      kind: "expiringCoupon",
      severity: "info",
      title: `${expiringCouponCodes.length} coupon${expiringCouponCodes.length === 1 ? "" : "s"} expiring soon`,
      subtitle: expiringCouponCodes.slice(0, 3).join(", "),
      route: "/coupons",
      filter_hint: "Active",
    });
  }
  return items;
}

function aggregatePeriod(orders) {
  const paid = orders.filter((o) => o.isPaid);
  const netSales = round2(paid.reduce((s, o) => s + o.total, 0));
  const ordersCount = orders.length;
  const aov = paid.length === 0 ? 0 : round2(netSales / paid.length);

  let breakfast = 0,
    lunch = 0,
    evening = 0,
    dinner = 0,
    lateNight = 0;
  let pending = 0,
    preparing = 0,
    ready = 0,
    delivered = 0,
    cancelled = 0;
  let dineIn = 0,
    takeaway = 0,
    delivery = 0;
  let staff = 0,
    app = 0;

  for (const o of orders) {
    const bucket = mealBucket(o.createdAt.getHours());
    if (bucket === "breakfast") breakfast++;
    else if (bucket === "lunch") lunch++;
    else if (bucket === "evening") evening++;
    else if (bucket === "dinner") dinner++;
    else lateNight++;

    switch (o.status) {
      case "pending":
        pending++;
        break;
      case "preparing":
        preparing++;
        break;
      case "ready":
        ready++;
        break;
      case "cancelled":
        cancelled++;
        break;
      default:
        delivered++;
    }

    if (o.orderType === "takeaway") takeaway++;
    else if (o.orderType === "delivery") delivery++;
    else dineIn++;

    if (o.orderSource === "app") app++;
    else staff++;
  }

  const mealTotal = breakfast + lunch + evening + dinner + lateNight;
  const funnelTotal = pending + preparing + ready + delivered + cancelled;

  return {
    netSales,
    ordersCount,
    deliveredCount: delivered,
    aov,
    paidCount: paid.length,
    breakfast,
    lunch,
    evening,
    dinner,
    lateNight,
    mealTotal,
    pending,
    preparing,
    ready,
    delivered,
    cancelled,
    funnelTotal,
    dineIn,
    takeaway,
    delivery,
    staff,
    app,
    topSelling: topSelling(orders, 5),
    // Precise percentage breakdowns for UI
    mealtime_pct: {
      breakfast: safePct(breakfast, mealTotal),
      lunch: safePct(lunch, mealTotal),
      evening: safePct(evening, mealTotal),
      dinner: safePct(dinner, mealTotal),
      late_night: safePct(lateNight, mealTotal),
    },
    mealtime_fraction: {
      breakfast: safeRatio(breakfast, mealTotal),
      lunch: safeRatio(lunch, mealTotal),
      evening: safeRatio(evening, mealTotal),
      dinner: safeRatio(dinner, mealTotal),
      late_night: safeRatio(lateNight, mealTotal),
    },
    funnel_pct: {
      pending: safePct(pending, funnelTotal),
      preparing: safePct(preparing, funnelTotal),
      ready: safePct(ready, funnelTotal),
      delivered: safePct(delivered, funnelTotal),
      cancelled: safePct(cancelled, funnelTotal),
    },
    funnel_fraction: {
      pending: safeRatio(pending, funnelTotal),
      preparing: safeRatio(preparing, funnelTotal),
      ready: safeRatio(ready, funnelTotal),
      delivered: safeRatio(delivered, funnelTotal),
      cancelled: safeRatio(cancelled, funnelTotal),
    },
    funnel_conversion_pct: {
      preparing_from_pending: safePct(preparing, pending),
      ready_from_preparing: safePct(ready, preparing),
      delivered_from_ready: safePct(delivered, ready),
      cancelled_from_delivered: safePct(cancelled, delivered),
    },
    funnelTotal,
    mealtimeTotal: mealTotal,
    orderTypeTotal: dineIn + takeaway + delivery,
    orderSourceTotal: staff + app,
    order_type_pct: {
      dine_in: safePct(dineIn, ordersCount),
      takeaway: safePct(takeaway, ordersCount),
      delivery: safePct(delivery, ordersCount),
    },
    order_type_fraction: {
      dine_in: safeRatio(dineIn, ordersCount),
      takeaway: safeRatio(takeaway, ordersCount),
      delivery: safeRatio(delivery, ordersCount),
    },
    order_source_pct: {
      staff: safePct(staff, ordersCount),
      app: safePct(app, ordersCount),
    },
    order_source_fraction: {
      staff: safeRatio(staff, ordersCount),
      app: safeRatio(app, ordersCount),
    },
    cancellation_rate_pct: safePct(cancelled, funnelTotal),
    delivery_rate_pct: safePct(delivered, funnelTotal),
  };
}

// ── Callable ──────────────────────────────────────────────────────────────

async function runDashboardTask(name, task) {
  const startedAt = Date.now();
  logger.info("Dashboard data task started", { task: name });
  try {
    const result = await task();
    logger.info("Dashboard data task completed", {
      task: name,
      duration_ms: Date.now() - startedAt,
      record_count: Array.isArray(result) ? result.length : null,
    });
    return result;
  } catch (error) {
    logger.error("Dashboard data task failed", {
      task: name,
      duration_ms: Date.now() - startedAt,
      error_code: error.code || null,
      error_type: error.name || "Error",
      error_message: error.message || String(error),
    });
    throw error;
  }
}

// APP: ADMIN APP — dashboard metrics for restaurant operators.
exports.getDashboardStats = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    const startedAt = Date.now();
    const periodRaw = String(data?.period || "today").toLowerCase().trim();
    let period = "today";

    logger.info("Dashboard stats request received", {
      authenticated: Boolean(context.auth),
      requested_period: periodRaw,
    });

    try {
      const { role } = requireRestaurantUser(context);
      logger.info("Dashboard authorization passed", { role });

      period =
        periodRaw === "yesterday"
          ? "yesterday"
          : periodRaw === "last_7_days" || periodRaw === "last 7 days"
            ? "last_7_days"
            : "today";

      const windows = resolveWindows(period);

      // Fetch once for full trend window; slice client-side ranges in memory.
      const [allTrendOrders, inventory, coupons, liveOps] = await Promise.all([
        runDashboardTask(
          "trend orders query",
          () => fetchOrdersInRange(windows.trendStart, windows.trendEnd),
        ),
        runDashboardTask("inventory alerts query", fetchInventoryAlerts),
        runDashboardTask("coupon stats query", fetchCouponStats),
        runDashboardTask("live operations queries", fetchLiveOperational),
      ]);

      const periodOrders = filterRange(
        allTrendOrders,
        windows.periodStart,
        windows.periodEnd
      );
      const previousOrders = filterRange(
        allTrendOrders,
        windows.previousStart,
        windows.previousEnd
      );

      // Last 7 days of trend for charts (ending yesterday or including today)
      const sparkStart = addDays(startOfDayIST(new Date()), -6);
      const spark = buildSparklines(allTrendOrders, sparkStart, 7);
      const salesTrend = buildDailySeries(
        allTrendOrders,
        sparkStart,
        7,
        (o) => (o.isPaid ? o.total : 0)
      );
      const ordersTrend = buildDailySeries(
        allTrendOrders,
        sparkStart,
        7,
        () => 1
      );
      const aovTrend = buildDailyAov(allTrendOrders, sparkStart, 7);

      const current = aggregatePeriod(periodOrders);
      const previous = aggregatePeriod(previousOrders);

      const attention = buildAttention({
        criticalStockCount: inventory.critical,
        lowStockCount: inventory.low,
        pendingPaymentCount: liveOps.pendingPaymentCount,
        criticalItemNames: inventory.criticalNames,
        lowStockItemNames: inventory.lowNames,
        expiringCouponCodes: coupons.expiring,
      });
      const couponUsagesCount = periodOrders.filter(
        (order) => order.couponCode.length > 0 || order.offerId.length > 0
      ).length;
      const stockAlertCount = inventory.critical + inventory.low;

      const response = {
        period: period,
        period_label: windows.label,
        generated_at: new Date().toISOString(),

        // KPIs
        net_sales: current.netSales,
        previous_net_sales: previous.netSales,
        sales_change_percent: pctChange(current.netSales, previous.netSales),
        orders_delivered: current.deliveredCount,
        previous_orders_delivered: previous.deliveredCount,
        orders_count: current.ordersCount,
        orders_change_percent: pctChange(
          current.deliveredCount,
          previous.deliveredCount
        ),
        average_order_value: current.aov,
        previous_aov: previous.aov,
        aov_change_percent: pctChange(current.aov, previous.aov),

        // Sparklines (7 days)
        sales_sparkline: spark.sales,
        orders_sparkline: spark.orders,
        aov_sparkline: spark.aov,

        // Trends
        sales_trend: salesTrend,
        orders_trend: ordersTrend,
        aov_trend: aovTrend,

        // Mealtime
        breakfast_count: current.breakfast,
        lunch_count: current.lunch,
        evening_count: current.evening,
        dinner_count: current.dinner,
        late_night_count: current.lateNight,
        mealtime_total: current.mealTotal,
        mealtime_pct: current.mealtime_pct,
        mealtime_fraction: current.mealtime_fraction,

        // Funnel
        funnel_pending: current.pending,
        funnel_preparing: current.preparing,
        funnel_ready: current.ready,
        funnel_delivered: current.delivered,
        funnel_cancelled: current.cancelled,
        funnel_total: current.funnelTotal,
        funnel_pct: current.funnel_pct,
        funnel_fraction: current.funnel_fraction,
        funnel_conversion_pct: current.funnel_conversion_pct,
        cancellation_rate_pct: current.cancellation_rate_pct,
        delivery_rate_pct: current.delivery_rate_pct,
        order_type_total: current.orderTypeTotal,
        order_source_total: current.orderSourceTotal,

        // Mix
        dine_in_count: current.dineIn,
        takeaway_count: current.takeaway,
        delivery_count: current.delivery,
        staff_order_count: current.staff,
        app_order_count: current.app,
        order_type_pct: current.order_type_pct,
        order_type_fraction: current.order_type_fraction,
        order_source_pct: current.order_source_pct,
        order_source_fraction: current.order_source_fraction,

        top_selling_items: current.topSelling,

        // Operational
        active_orders_count: liveOps.activeOrdersCount,
        pending_payment_count: liveOps.pendingPaymentCount,
        low_stock_count: inventory.low,
        critical_stock_count: inventory.critical,
        stock_alert_count: stockAlertCount,
        active_coupon_count: coupons.active,
        coupon_usages_count: couponUsagesCount,
        attention_items: attention,
      };

      logger.info("Dashboard stats request completed", {
        period,
        duration_ms: Date.now() - startedAt,
        trend_order_count: allTrendOrders.length,
        period_order_count: periodOrders.length,
        inventory_low_count: inventory.low,
        inventory_critical_count: inventory.critical,
        active_coupon_count: coupons.active,
        active_order_count: liveOps.activeOrdersCount,
      });
      return response;
    } catch (error) {
      logger.error("Dashboard stats request failed", {
        period,
        duration_ms: Date.now() - startedAt,
        error_code: error.code || null,
        error_type: error.name || "Error",
        error_message: error.message || String(error),
      });
      throw error;
    }
  });
