import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/screens/order/bill_settlement_screen.dart';
import 'package:rdx_admin/screens/order/widgets/live_order_card.dart';
import 'package:rdx_admin/widgets/buttons/stats_collapse_button.dart';
import 'package:rdx_admin/widgets/resuable_options/rdx_category_tabs.dart';
import 'package:rdx_admin/widgets/resuable_options/rdx_dropdown.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../core/utils/tax.dart';
import '../../models/order_model.dart';
import '../../providers/live_orders_provider.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/reusable_widgets/stat_card.dart';
import 'create_order_screen.dart';

/// Board source selected via the Live / App dropdown.
enum _BoardSource { live, app }

class LiveOrdersScreen extends ConsumerStatefulWidget {
  const LiveOrdersScreen({super.key});

  @override
  ConsumerState<LiveOrdersScreen> createState() => _LiveOrdersScreenState();
}

class _LiveOrdersScreenState extends ConsumerState<LiveOrdersScreen> {
  /// Live (walk-in / staff POS) or App (customer app). Default: Live.
  _BoardSource _boardSource = _BoardSource.live;

  /// Status filter within the selected source. 'All' shows the full board.
  String _selectedStatus = 'All';

  /// Horizontal scroll for the kanban board (All view).
  final ScrollController _boardScrollController = ScrollController();

  /// Column index whose order list is under the cursor, or null.
  /// When non-null, mouse wheel scrolls that list vertically and only that
  /// column's scrollbar is visible.
  /// When null, mouse wheel scrolls the board horizontally.
  int? _hoveredListColumnIndex;

  /// True while the pointer is over the horizontal kanban board area.
  bool _boardHovered = false;

  /// Whether the overview stat card row is hidden.
  bool _statsCollapsed = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      ref.read(liveOrdersProvider).load();
    });
  }

  @override
  void dispose() {
    _boardScrollController.dispose();
    super.dispose();
  }

  // CREATE ORDER

  Future<void> _openPlaceOrder() async {
    final placed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PlaceOrderScreen(),
      ),
    );

    if (!mounted) return;

    ref.read(liveOrdersProvider).load();

    if (placed == true) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('New order added to the queue.'),
      //   ),
      // );
    }
  }

  // ---------------------------------------------------------------------------
  // SOURCE + STATUS FILTERS
  // ---------------------------------------------------------------------------

  bool get _isLive => _boardSource == _BoardSource.live;

  /// Final-stage label for the selected source.
  String get _finalStageLabel => _isLive ? 'Served' : 'Delivered';

  /// Status chips shown beside the source dropdown (no Live/App chips).
  List<String> get _statusLabels => [
        'Preparing',
        'Out for Delivery',
        'Pending Payment',
        _finalStageLabel,
        'Cancelled',
      ];

  void _onSourceChanged(_BoardSource? source) {
    if (source == null || source == _boardSource) return;
    setState(() {
      _boardSource = source;
      // Reset filter when switching source so board shows full columns.
      _selectedStatus = 'All';
    });
  }

  void _onStatusSelected(String label) {
    if (_selectedStatus == label) {
      // Tapping the active chip again returns to the full board.
      setState(() => _selectedStatus = 'All');
      return;
    }
    setState(() => _selectedStatus = label);
  }

  /// Unpaid orders for the Pending Payment filter + stat, scoped to source.
  List<OrderModel> _getPendingPaymentOrders(
    LiveOrdersProvider provider,
  ) {
    final seenIds = <String>{};
    final result = <OrderModel>[];

    void addAll(Iterable<OrderModel> list) {
      for (final order in list) {
        if (order.paymentStatus == PaymentStatus.paid) continue;
        if (!seenIds.add(order.id)) continue;
        result.add(order);
      }
    }

    if (_isLive) {
      addAll(provider.readyWalkIn);
      addAll(provider.deliveredWalkIn);
    } else {
      addAll(provider.readyApp);
      addAll(provider.deliveredApp);
    }
    return result;
  }

  void _openPayment(OrderModel order) {
    final items = order.items.map((item) {
      final modifiers = <String>[
        if (item.spiceLevel != null && item.spiceLevel!.trim().isNotEmpty)
          'Spice: ${item.spiceLevel}',
        ...item.addOns,
        if (item.notes != null && item.notes!.trim().isNotEmpty)
          'Note: ${item.notes}',
      ];

      return BillItemData(
        name: item.name,
        quantity: item.quantity,
        amount: item.price * item.quantity,
        modifiers: modifiers,
      );
    }).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BillSettlementScreen(
          bill: BillSettlementData(
            orderNumber: order.id,
            restaurantName: 'RDX Fast Food',
            orderType: order.orderType.name,
            tableNumber: order.tableNumber,
            billingMode: order.orderType.name,
            cashier: 'Admin',
            server: 'Admin',
            kitchenName: 'Main Kitchen',
            sequence: null,
            covers: 1,
            items: items,
            paymentMethod: null,
            cardLastFour: null,
            subtotal: order.items.fold<double>(
              0,
              (sum, item) => sum + (item.price * item.quantity),
            ),
            taxPercentage: AppTax.gstPercentage,
            guestName: order.customerName.trim().isNotEmpty
                ? order.customerName
                : 'Walk-in Customer',
            phoneNumber: order.customerPhone,
            sendDigitalReceipt: false,
            invoiceReference: order.id,
            receiptDateTime: DateTime.now(),
          ),
        ),
      ),
    );
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final provider = ref.watch(liveOrdersProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: context.defaultScreenPadding(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row: title/subtitle + New Order ─────────────────
              Builder(
                builder: (context) {
                  final titleBlock = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Orders',
                        style: AppTextStyles.heading(context),
                      ),
                      SizedBox(height: context.h(4)),
                      Text(
                        'Track orders and create orders for customers',
                        style: AppTextStyles.bodySecondary(context).copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  );

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: titleBlock),
                      SizedBox(width: context.w(12)),
                      RdxActionButton(
                        label: 'New Order',
                        leadingIcon: Icons.add,
                        isPrimary: true,
                        onPressed: _openPlaceOrder,
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: context.h(20)),

              // ── Overview stats (4 cards only) ──────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: StatsCollapseButton(
                  collapsed: _statsCollapsed,
                  onPressed: () => setState(
                    () => _statsCollapsed = !_statsCollapsed,
                  ),
                ),
              ),
              SizedBox(height: context.h(8)),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _statsCollapsed
                    ? const SizedBox(width: double.infinity)
                    : _buildOverviewStats(provider),
              ),

              SizedBox(height: context.h(20)),

              // ── Source dropdown + status tabs ──────────────────────────
              // Dropdown replaces Live / App Orders tabs.
              // Status tabs adapt to source (Served vs Delivered).
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: context.w(120),
                    child: RdxDropdown<_BoardSource>(
                      value: _boardSource,
                      items: _BoardSource.values,
                      labelBuilder: (s) =>
                          s == _BoardSource.live ? 'Live' : 'App',
                      onChanged: _onSourceChanged,
                      isDense: true,
                    ),
                  ),
                  SizedBox(width: context.w(10)),
                  RdxCategoryTabs(
                    labels: _statusLabels,
                    selectedLabel: _selectedStatus,
                    onSelected: _onStatusSelected,
                  ),
                ],
              ),

              SizedBox(height: context.h(16)),

              // ── Orders board ───────────────────────────────────────────
              Expanded(
                child: provider.isLoading
                    ? const LoadingIndicator()
                    : _buildOrdersContent(provider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Four overview cards only — Total / Live / App / Pending Payment.
  /// Per-column counts live on the board headings, not here.
  Widget _buildOverviewStats(LiveOrdersProvider provider) {
    final totalOrders = provider.liveWalkIn.length +
        provider.preparingWalkIn.length +
        provider.readyWalkIn.length +
        provider.appOrdersActive.length +
        provider.delivered
            .where((o) => o.paymentStatus == PaymentStatus.paid)
            .length;

    final liveCount = provider.liveWalkIn.length;
    final appCount = provider.appOrdersActive.length;

    // Pending payment across both sources (ready + delivered unpaid).
    final seenIds = <String>{};
    var pendingPaymentCount = 0;
    for (final order in [
      ...provider.ready,
      ...provider.delivered,
    ]) {
      if (order.paymentStatus == PaymentStatus.paid) continue;
      if (!seenIds.add(order.id)) continue;
      pendingPaymentCount++;
    }

    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          final spacing = isNarrow ? context.w(6) : context.w(16);
          final minH = isNarrow ? context.h(62) : context.h(72);

          final cards = <Widget>[
            StatCard(
              label: 'Total Orders',
              value: '$totalOrders',
              icon: Icons.receipt_long_outlined,
              minHeight: minH,
            ),
            StatCard(
              label: 'Live Orders',
              value: '$liveCount',
              icon: Icons.star_outline_rounded,
              accentColor: const Color(0xFF5AC8FA),
              minHeight: minH,
            ),
            StatCard(
              label: 'App Orders',
              value: '$appCount',
              icon: Icons.phone_android_outlined,
              accentColor: const Color(0xFF7C5CFC),
              minHeight: minH,
            ),
            StatCard(
              label: 'Pending Payment',
              value: '$pendingPaymentCount',
              icon: Icons.payments_outlined,
              accentColor: const Color(0xFFE9A719),
              minHeight: minH,
            ),
          ];

          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i != cards.length - 1) SizedBox(width: spacing),
              ],
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ORDERS CONTENT
  // ---------------------------------------------------------------------------

  static const double _kColumnsBreakpoint = 900;
  static const double _kRowCardWidth = 280;

  // All-board columns per source: primary | Preparing | Out for Delivery | Final.
  static const int _kVisibleColumns = 4;

  Widget _buildColumnsBoard(
    List<_SectionData> sections, {
    required double maxWidth,
    required double maxHeight,
  }) {
    final gap = context.w(16);
    final columnWidth =
        (maxWidth - gap * (_kVisibleColumns - 1)) / _kVisibleColumns;

    final isFinalFilter =
        _selectedStatus == 'Served' || _selectedStatus == 'Delivered';
    final compactEmptyFinalBoard =
        isFinalFilter && sections.every((section) => section.orders.isEmpty);
    final boardHeight = compactEmptyFinalBoard
        ? context.h(220)
        : maxHeight.isFinite && maxHeight > 0
            ? maxHeight
            : context.h(520);

    final colors = AppColors.of(context);

    final showBoardScrollbar = _boardHovered && _hoveredListColumnIndex == null;

    final boardTheme = Theme.of(context).copyWith(
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStatePropertyAll(showBoardScrollbar ? 6.0 : 0.0),
        radius: const Radius.circular(8),
        thumbVisibility: WidgetStatePropertyAll(showBoardScrollbar),
        trackVisibility: const WidgetStatePropertyAll(false),
        thumbColor: WidgetStatePropertyAll(
          colors.textMuted.withValues(alpha: 0.35),
        ),
        trackColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );

    return Theme(
      data: boardTheme,
      child: MouseRegion(
        onEnter: (_) {
          if (!_boardHovered) setState(() => _boardHovered = true);
        },
        onExit: (_) {
          if (_boardHovered) {
            setState(() {
              _boardHovered = false;
              _hoveredListColumnIndex = null;
            });
          }
        },
        child: Listener(
          onPointerSignal: (signal) {
            if (signal is! PointerScrollEvent) return;
            if (_hoveredListColumnIndex != null) return;
            if (!_boardScrollController.hasClients) return;

            final pos = _boardScrollController.position;
            final delta = signal.scrollDelta.dy != 0
                ? signal.scrollDelta.dy
                : signal.scrollDelta.dx;
            final next = (pos.pixels + delta).clamp(
              pos.minScrollExtent,
              pos.maxScrollExtent,
            );
            if (next != pos.pixels) {
              _boardScrollController.jumpTo(next);
            }
          },
          child: Scrollbar(
            controller: _boardScrollController,
            thumbVisibility: showBoardScrollbar,
            trackVisibility: false,
            thickness: showBoardScrollbar ? 6 : 0,
            child: SingleChildScrollView(
              controller: _boardScrollController,
              scrollDirection: Axis.horizontal,
              primary: false,
              padding: EdgeInsets.only(bottom: context.h(12)),
              child: SizedBox(
                height: boardHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    for (int i = 0; i < sections.length; i++) ...[
                      SizedBox(
                        width: columnWidth,
                        height: boardHeight,
                        child: _buildColumnSection(sections[i], columnIndex: i),
                      ),
                      if (i != sections.length - 1) SizedBox(width: gap),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersContent(
    LiveOrdersProvider provider,
  ) {
    final sections = _buildVisibleSectionsData(provider);

    if (_selectedStatus != 'All') {
      if (sections.isEmpty) {
        return const SizedBox.shrink();
      }
      if (sections.length == 1) {
        return _buildSingleSectionGrid(sections.first);
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _kColumnsBreakpoint;
          if (!isWide) {
            return _buildRowsBoard(sections);
          }
          return _buildColumnsBoard(
            sections,
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight,
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _kColumnsBreakpoint;

        if (!isWide) {
          return _buildRowsBoard(sections);
        }

        return _buildColumnsBoard(
          sections,
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
        );
      },
    );
  }

  Widget _buildSingleSectionGrid(_SectionData data) {
    final isEmpty = data.orders.isEmpty;
    final gap = context.w(16);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - gap * (_kVisibleColumns - 1)) /
                _kVisibleColumns;

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            top: context.h(4),
            bottom: context.h(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(data),
              SizedBox(height: context.h(12)),
              if (isEmpty)
                SizedBox(
                  width: cardWidth,
                  child: _buildEmptySection(
                    emptyIcon: data.emptyIcon,
                    emptyText: data.emptyText,
                  ),
                )
              else
                Wrap(
                  spacing: gap,
                  runSpacing: context.h(12),
                  children: [
                    for (final order in data.orders)
                      SizedBox(
                        width: cardWidth,
                        child: LiveOrderCard(
                          order: order,
                          actionText: data.actionTextFor(order),
                          onAdvance: data.onAdvance,
                          secondaryActionText:
                              data.secondaryActionTextFor(order),
                          onSecondaryAction: data.secondaryOnAdvanceFor(order),
                          onTap: () => _openOrderDetail(order),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColumnSection(
    _SectionData data, {
    required int columnIndex,
  }) {
    final isEmpty = data.orders.isEmpty;
    final colors = AppColors.of(context);
    final listHovered = _hoveredListColumnIndex == columnIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(data),
        SizedBox(height: context.h(12)),
        if (isEmpty)
          _buildEmptySection(
            emptyIcon: data.emptyIcon,
            emptyText: data.emptyText,
          )
        else
          Expanded(
            child: MouseRegion(
              onEnter: (_) {
                if (_hoveredListColumnIndex != columnIndex) {
                  setState(() => _hoveredListColumnIndex = columnIndex);
                }
              },
              onExit: (_) {
                if (_hoveredListColumnIndex == columnIndex) {
                  setState(() => _hoveredListColumnIndex = null);
                }
              },
              child: Theme(
                data: Theme.of(context).copyWith(
                  scrollbarTheme: ScrollbarThemeData(
                    thickness: WidgetStatePropertyAll(listHovered ? 6.0 : 0.0),
                    radius: const Radius.circular(8),
                    thumbVisibility: WidgetStatePropertyAll(listHovered),
                    trackVisibility: const WidgetStatePropertyAll(false),
                    thumbColor: WidgetStatePropertyAll(
                      colors.textMuted.withValues(alpha: 0.35),
                    ),
                    trackColor:
                        const WidgetStatePropertyAll(Colors.transparent),
                  ),
                ),
                child: Scrollbar(
                  thumbVisibility: listHovered,
                  trackVisibility: false,
                  thickness: listHovered ? 6 : 0,
                  radius: const Radius.circular(8),
                  child: ListView.builder(
                    primary: false,
                    padding: EdgeInsets.only(bottom: context.h(4)),
                    itemCount: data.orders.length,
                    itemBuilder: (context, index) {
                      final order = data.orders[index];

                      return Padding(
                        padding: EdgeInsets.only(bottom: context.h(12)),
                        child: LiveOrderCard(
                          order: order,
                          actionText: data.actionTextFor(order),
                          onAdvance: data.onAdvance,
                          secondaryActionText:
                              data.secondaryActionTextFor(order),
                          onSecondaryAction: data.secondaryOnAdvanceFor(order),
                          onTap: () => _openOrderDetail(order),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRowsBoard(List<_SectionData> sections) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: context.h(4),
        bottom: context.h(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < sections.length; i++) ...[
            _buildRowSection(sections[i]),
            if (i < sections.length - 1) SizedBox(height: context.h(20)),
          ],
        ],
      ),
    );
  }

  Widget _buildRowSection(_SectionData data) {
    final isEmpty = data.orders.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(data),
        SizedBox(height: context.h(12)),
        if (isEmpty)
          _buildEmptySection(
            emptyIcon: data.emptyIcon,
            emptyText: data.emptyText,
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int index = 0; index < data.orders.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        right:
                            index == data.orders.length - 1 ? 0 : context.w(12),
                      ),
                      child: SizedBox(
                        width: context.w(_kRowCardWidth),
                        child: LiveOrderCard(
                          order: data.orders[index],
                          actionText: data.actionTextFor(data.orders[index]),
                          onAdvance: data.onAdvance,
                          secondaryActionText:
                              data.secondaryActionTextFor(data.orders[index]),
                          onSecondaryAction:
                              data.secondaryOnAdvanceFor(data.orders[index]),
                          onTap: () => _openOrderDetail(data.orders[index]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED HELPERS
  // ---------------------------------------------------------------------------

  void _openOrderDetail(OrderModel order) {
    Navigator.of(context).pushNamed(
      AppRoutes.orderDetail,
      arguments: order.id,
    );
  }

  Widget _sectionHeader(_SectionData data) {
    final count = data.orders.length;
    return Padding(
      padding: EdgeInsets.only(
        left: context.w(3),
        right: context.w(3),
      ),
      child: Row(
        children: [
          Container(
            width: context.w(7),
            height: context.h(7),
            decoration: BoxDecoration(
              color: data.color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: context.w(9)),
          Flexible(
            child: Text(
              '${data.title} ($count)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.section(context).copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VISIBLE SECTIONS — scoped to Live or App via [_boardSource]
  // ---------------------------------------------------------------------------
  //
  // Live board (All):
  //   LIVE ORDERS | PREPARING | OUT FOR DELIVERY | SERVED
  //
  // App board (All):
  //   APP ORDERS | PREPARING | OUT FOR DELIVERY | DELIVERED
  //
  // Pending Payment is filter-only (not a board column).
  // ---------------------------------------------------------------------------

  List<_SectionData> _buildVisibleSectionsData(
    LiveOrdersProvider provider,
  ) {
    final sections = <_SectionData>[];
    final isAll = _selectedStatus == 'All';

    if (_isLive) {
      // ── LIVE (walk-in / staff POS) ────────────────────────────────────
      if (isAll) {
        sections.add(
          _SectionData(
            title: 'LIVE ORDERS',
            color: const Color(0xFF5AC8FA),
            orders: provider.liveWalkIn,
            actionText: 'Start Preparing',
            onAdvance: provider.advanceStatus,
            showPayNow: true,
            onPayNow: _openPayment,
            emptyIcon: Icons.star_outline_rounded,
            emptyText: 'No orders',
          ),
        );
      }

      if (isAll || _selectedStatus == 'Preparing') {
        sections.add(
          _SectionData(
            title: 'PREPARING',
            color: const Color(0xFFE9A719),
            orders: provider.preparingWalkIn,
            actionText: 'Mark Ready',
            onAdvance: provider.advanceStatus,
            showPayNow: true,
            onPayNow: _openPayment,
            emptyIcon: Icons.access_time_rounded,
            emptyText: 'No orders preparing',
          ),
        );
      }

      if (isAll || _selectedStatus == 'Out for Delivery') {
        sections.add(
          _SectionData(
            title: 'OUT FOR DELIVERY',
            color: const Color(0xFF20B47A),
            orders: provider.readyWalkIn,
            actionText: null,
            onAdvance: provider.advanceStatus,
            usePerOrderAction: true,
            showPayNow: true,
            onPayNow: _openPayment,
            hideAdvanceUntilPaid: true,
            emptyIcon: Icons.delivery_dining_outlined,
            emptyText: 'No orders out for delivery',
          ),
        );
      }

      if (_selectedStatus == 'Pending Payment') {
        sections.add(
          _SectionData(
            title: 'PENDING PAYMENT',
            color: const Color(0xFFE9A719),
            orders: _getPendingPaymentOrders(provider),
            actionText: 'Pay Now',
            onAdvance: _openPayment,
            emptyIcon: Icons.payments_outlined,
            emptyText: 'No pending payments',
          ),
        );
      }

      // Final stage for Live = Served (paid delivered walk-in).
      if (isAll || _selectedStatus == 'Served') {
        final served = provider.deliveredWalkIn
            .where((o) => o.paymentStatus == PaymentStatus.paid)
            .toList();
        sections.add(
          _SectionData(
            title: 'SERVED',
            color: const Color(0xFF20B47A),
            orders: served,
            actionText: null,
            onAdvance: null,
            emptyIcon: Icons.room_service_outlined,
            emptyText: 'No served orders',
          ),
        );
      }

      if (_selectedStatus == 'Cancelled') {
        sections.add(
          _SectionData(
            title: 'CANCELLED',
            color: const Color(0xFFE05151),
            orders: provider.cancelledWalkIn,
            actionText: null,
            onAdvance: null,
            emptyIcon: Icons.cancel_outlined,
            emptyText: 'No cancelled orders',
          ),
        );
      }
    } else {
      // ── APP (customer app) ────────────────────────────────────────────
      if (isAll) {
        // Primary column: active app orders still in pending (new).
        sections.add(
          _SectionData(
            title: 'APP ORDERS',
            color: const Color(0xFF7C5CFC),
            orders: provider.liveApp,
            actionText: 'Start Preparing',
            onAdvance: provider.advanceStatus,
            showPayNow: true,
            onPayNow: _openPayment,
            emptyIcon: Icons.phone_android_outlined,
            emptyText: 'No orders',
          ),
        );
      }

      if (isAll || _selectedStatus == 'Preparing') {
        sections.add(
          _SectionData(
            title: 'PREPARING',
            color: const Color(0xFFE9A719),
            orders: provider.preparingApp,
            actionText: 'Mark Ready',
            onAdvance: provider.advanceStatus,
            showPayNow: true,
            onPayNow: _openPayment,
            emptyIcon: Icons.access_time_rounded,
            emptyText: 'No orders preparing',
          ),
        );
      }

      if (isAll || _selectedStatus == 'Out for Delivery') {
        sections.add(
          _SectionData(
            title: 'OUT FOR DELIVERY',
            color: const Color(0xFF20B47A),
            orders: provider.readyApp,
            actionText: null,
            onAdvance: provider.advanceStatus,
            usePerOrderAction: true,
            showPayNow: true,
            onPayNow: _openPayment,
            hideAdvanceUntilPaid: true,
            emptyIcon: Icons.delivery_dining_outlined,
            emptyText: 'No orders out for delivery',
          ),
        );
      }

      if (_selectedStatus == 'Pending Payment') {
        sections.add(
          _SectionData(
            title: 'PENDING PAYMENT',
            color: const Color(0xFFE9A719),
            orders: _getPendingPaymentOrders(provider),
            actionText: 'Pay Now',
            onAdvance: _openPayment,
            emptyIcon: Icons.payments_outlined,
            emptyText: 'No pending payments',
          ),
        );
      }

      // Final stage for App = Delivered (paid delivered app orders).
      if (isAll || _selectedStatus == 'Delivered') {
        final delivered = provider.deliveredApp
            .where((o) => o.paymentStatus == PaymentStatus.paid)
            .toList();
        sections.add(
          _SectionData(
            title: 'DELIVERED',
            color: const Color(0xFF20B47A),
            orders: delivered,
            actionText: null,
            onAdvance: null,
            emptyIcon: Icons.check_circle_outline,
            emptyText: 'No delivered orders',
          ),
        );
      }

      if (_selectedStatus == 'Cancelled') {
        sections.add(
          _SectionData(
            title: 'CANCELLED',
            color: const Color(0xFFE05151),
            orders: provider.cancelledApp,
            actionText: null,
            onAdvance: null,
            emptyIcon: Icons.cancel_outlined,
            emptyText: 'No cancelled orders',
          ),
        );
      }
    }

    return sections;
  }

  // ---------------------------------------------------------------------------
  // EMPTY SECTION
  // ---------------------------------------------------------------------------

  Widget _buildEmptySection({
    IconData? emptyIcon,
    String? emptyText,
  }) {
    return Container(
      width: double.infinity,
      height: context.h(170),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(
          context.h(12),
        ),
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.lightBorder,
          radius: 12,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emptyIcon != null) ...[
                Container(
                  width: context.w(42),
                  height: context.h(42),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1EA),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFD8C5),
                    ),
                  ),
                  child: Icon(
                    emptyIcon,
                    size: context.h(22),
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: context.h(12)),
              ],
              Text(
                emptyText ?? 'No orders',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary(context).copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SECTION DATA
// =============================================================================

class _SectionData {
  final String title;
  final Color color;
  final List<OrderModel> orders;
  final String? actionText;
  final ValueChanged<OrderModel>? onAdvance;
  final IconData? emptyIcon;
  final String? emptyText;

  final bool usePerOrderAction;
  final bool showPayNow;
  final ValueChanged<OrderModel>? onPayNow;
  final bool hideAdvanceUntilPaid;

  const _SectionData({
    required this.title,
    required this.color,
    required this.orders,
    this.actionText,
    this.onAdvance,
    this.emptyIcon,
    this.emptyText,
    this.usePerOrderAction = false,
    this.showPayNow = false,
    this.onPayNow,
    this.hideAdvanceUntilPaid = false,
  });

  String? actionTextFor(OrderModel order) {
    if (hideAdvanceUntilPaid && order.isUnpaid) return null;
    if (usePerOrderAction) {
      return order.boardAdvanceLabel;
    }
    return actionText;
  }

  String? secondaryActionTextFor(OrderModel order) {
    if (!showPayNow) return null;
    if (order.status != OrderStatus.delivered && order.isUnpaid) {
      return 'Pay Now';
    }
    return null;
  }

  ValueChanged<OrderModel>? secondaryOnAdvanceFor(OrderModel order) {
    if (secondaryActionTextFor(order) == null) return null;
    return onPayNow;
  }
}

// =============================================================================
// DASHED BORDER
// =============================================================================

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();

    final rect = Rect.fromLTWH(
      0.5,
      0.5,
      size.width - 1,
      size.height - 1,
    );

    path.addRRect(
      RRect.fromRectAndRadius(
        rect,
        Radius.circular(radius),
      ),
    );

    final pathMetrics = path.computeMetrics();

    const double dashLength = 6;
    const double gapLength = 5;

    for (final metric in pathMetrics) {
      double distance = 0;

      while (distance < metric.length) {
        final nextDistance = (distance + dashLength).clamp(
          0,
          metric.length,
        );

        final segment = metric.extractPath(
          distance,
          nextDistance.toDouble(),
        );

        canvas.drawPath(segment, paint);

        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _DashedBorderPainter oldDelegate,
  ) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
