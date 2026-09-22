import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/screens/order/bill_settlement_screen.dart';
import 'package:rdx_admin/screens/order/widgets/live_order_card.dart';
import 'package:rdx_admin/widgets/buttons/stats_collapse_button.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/order_model.dart';
import '../../providers/live_orders_provider.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/reusable_widgets/stat_card.dart';
import '../../widgets/resuable_options/rdx_category_tabs.dart';
import 'create_order_screen.dart';

class LiveOrdersScreen extends ConsumerStatefulWidget {
  const LiveOrdersScreen({super.key});

  @override
  ConsumerState<LiveOrdersScreen> createState() => _LiveOrdersScreenState();
}

class _LiveOrdersScreenState extends ConsumerState<LiveOrdersScreen> {
  String _selectedStatus = 'All';

  /// Whether the stat card row is hidden, giving the order board below more
  /// vertical room. Toggled by [StatsCollapseButton].
  bool _statsCollapsed = false;

  /// Horizontal scroll for the kanban board (All view).
  final ScrollController _boardScrollController = ScrollController();

  /// Column index whose order list is under the cursor, or null.
  /// When non-null, mouse wheel scrolls that list vertically and only that
  /// column's scrollbar is visible.
  /// When null, mouse wheel scrolls the board horizontally.
  int? _hoveredListColumnIndex;

  /// True while the pointer is over the horizontal kanban board area.
  bool _boardHovered = false;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New order added to the queue.'),
        ),
      );
    }
  }

  // STATUS FILTER

  List<String> get _statusLabels => const [
        'Live',
        'App Orders',
        'Preparing',
        'Ready',
        'Pending Payment',
        'Delivered',
      ];

  void _onStatusSelected(String label) {
    if (_selectedStatus == label) return;

    setState(() {
      _selectedStatus = label;
    });
  }

  /// Unpaid orders after kitchen flow (status == delivered).
  /// Shown under PENDING PAYMENT until settled; then they move to DELIVERED.
  List<OrderModel> _getPendingPaymentOrders(
    LiveOrdersProvider provider,
  ) {
    final seenIds = <String>{};

    return provider.delivered.where((order) {
      if (order.paymentStatus == PaymentStatus.paid) {
        return false;
      }

      if (!seenIds.add(order.id)) {
        return false;
      }

      return true;
    }).toList();
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
            taxPercentage: 0,
            guestName: order.customerName?.trim().isNotEmpty == true
                ? order.customerName!
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

    final totalOrders = provider.live.length +
        provider.preparing.length +
        provider.ready.length +
        provider.delivered.length;

    final pendingPaymentOrders = _getPendingPaymentOrders(provider);

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
                  final narrow = MediaQuery.sizeOf(context).width < 900;

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

                  if (narrow) {
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
                  }

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

              // ── Stats collapse toggle ──────────────────────────────────
              // Sits above the stat row's left edge; collapsing hides the
              // row entirely so the order board below gets more vertical space.
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

              // ── Stats ──────────────────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _statsCollapsed
                    ? const SizedBox(width: double.infinity)
                    : _buildSummaryStats(
                        provider: provider,
                        totalOrders: totalOrders,
                        pendingPaymentCount: pendingPaymentOrders.length,
                        appOrdersCount: provider.appOrders.length,
                      ),
              ),

              SizedBox(height: context.h(20)),

              // ── Status tabs ────────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: RdxCategoryTabs(
                  expand: false,
                  labels: _statusLabels,
                  allLabel: 'All',
                  selectedLabel: _selectedStatus,
                  onSelected: _onStatusSelected,
                ),
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

  Widget _buildSummaryStats({
    required LiveOrdersProvider provider,
    required int totalOrders,
    required int pendingPaymentCount,
    required int appOrdersCount,
  }) {
    final deliveredPaidCount = provider.delivered
        .where(
          (order) => order.paymentStatus == PaymentStatus.paid,
        )
        .length;
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          final spacing = isNarrow ? context.w(6) : context.w(16);

          final cards = <Widget>[
            StatCard(
              label: 'Total Orders',
              value: '$totalOrders',
              icon: Icons.receipt_long_outlined,
              minHeight: isNarrow ? context.h(62) : context.h(72),
            ),
            StatCard(
              label: 'Live Orders',
              value: '${provider.live.length}',
              icon: Icons.star_outline_rounded,
              accentColor: const Color(0xFF5AC8FA), // light blue
              minHeight: isNarrow ? context.h(62) : context.h(72),
            ),
            StatCard(
              label: 'App Orders',
              value: '$appOrdersCount',
              icon: Icons.phone_android_outlined,
              accentColor: const Color(0xFF7C5CFC),
              minHeight: isNarrow ? context.h(62) : context.h(72),
            ),
            StatCard(
              label: 'Preparing',
              value: '${provider.preparing.length}',
              icon: Icons.access_time_rounded, // or Icons.schedule_outlined
              accentColor: const Color(0xFFE9A719),
              minHeight: isNarrow ? context.h(62) : context.h(72),
            ),
            StatCard(
              label: 'Ready',
              value: '${provider.ready.length}',
              icon: Icons.check_rounded, // or Icons.check
              accentColor: const Color(0xFF20B47A),
              minHeight: isNarrow ? context.h(62) : context.h(72),
            ),
            StatCard(
              label: 'Pending Payment',
              value: '$pendingPaymentCount',
              icon: Icons.payments_outlined, // cash / payments style
              accentColor: const Color(0xFFE9A719),
              minHeight: isNarrow ? context.h(62) : context.h(72),
            ),
            StatCard(
              label: 'Delivered',
              value: '$deliveredPaidCount',
              icon: Icons.check_circle_outline,
              accentColor: const Color(0xFF20B47A),
              minHeight: isNarrow ? context.h(62) : context.h(72),
            ),
          ];

          return Row(
            children: [
              for (int index = 0; index < cards.length; index++) ...[
                Expanded(
                  child: cards[index],
                ),
                if (index != cards.length - 1) SizedBox(width: spacing),
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
  //
  // RESPONSIVE BOARD
  //
  // Wide screens (>= _kColumnsBreakpoint):
  //   Each state is a COLUMN, laid out side by side in a Row.
  //   Cards inside a column are stacked VERTICALLY and scroll independently.
  //
  // As the screen shrinks below the breakpoint:
  //   Each state becomes a ROW, stacked vertically one under another.
  //   Cards inside a row are laid out HORIZONTALLY and scroll sideways.
  // ---------------------------------------------------------------------------

  static const double _kColumnsBreakpoint = 900;
  static const double _kRowCardWidth = 280;

  // ---------------------------------------------------------------------------
  // WIDE LAYOUT — states as columns, cards stacked vertically
  // ---------------------------------------------------------------------------
  //
  // Column width is always computed as if all board states were visible, so a single filtered-in section keeps
  // the same "normal" card width as the All view instead of stretching to
  // fill the row when fewer sections are shown.
  // ---------------------------------------------------------------------------

  // All-board columns: Live / App / Preparing / Ready / Pending Payment.
  // Delivered is NOT on the All board — only via the "Delivered" filter chip.
  static const int _kTotalColumns = 5;
  static const int _kVisibleColumns = 5;

  Widget _buildColumnsBoard(
    List<_SectionData> sections, {
    required double maxWidth,
    required double maxHeight,
  }) {
    final gap = context.w(16);
    // 5 columns fill the width; the 6th is outside and scrollable into view.
    final columnWidth =
        (maxWidth - gap * (_kVisibleColumns - 1)) / _kVisibleColumns;

    // Bounded height is required so each column's Expanded + ListView works
    // inside a horizontal scroll view.
    final boardHeight =
        maxHeight.isFinite && maxHeight > 0 ? maxHeight : context.h(520);

    final colors = AppColors.of(context);

    // Board horizontal scrollbar only while the pointer is over the board
    // and not inside a specific column list.
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
            // Convert vertical mouse-wheel / trackpad to horizontal board scroll
            // when the cursor is NOT over a column's order list.
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

    // A specific status filter always yields a single section — grid layout.
    if (_selectedStatus != 'All') {
      if (sections.isEmpty) {
        return const SizedBox.shrink();
      }
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

  // ---------------------------------------------------------------------------
  // SINGLE-SECTION GRID — used when a specific status filter is selected
  // ---------------------------------------------------------------------------
  //
  // Card width matches the board's per-column width (maxWidth split across
  // _kTotalColumns, same gap), so a row here naturally holds as many cards
  // as the "All" board has columns — currently 4 — without hardcoding a
  // card count.
  // ---------------------------------------------------------------------------

  Widget _buildSingleSectionGrid(_SectionData data) {
    final isEmpty = data.orders.isEmpty;
    // Same gap as _buildColumnsBoard (the "All" view) so the card width
    // comes out pixel-identical between the two — otherwise switching
    // tabs visibly resized the cards.
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
          // Empty columns do not capture wheel — board scrolls horizontally.
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
                    // Fully hide when this column is not under the cursor.
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
          // IntrinsicHeight sizes this row to whatever its tallest card
          // actually needs, instead of forcing every card into a fixed
          // 208px box regardless of how little content it has — that fixed
          // height was leaving empty space at the bottom of shorter cards.
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
          Text(
            data.title,
            style: AppTextStyles.section(context).copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VISIBLE SECTIONS (data only — layout decides how to render them)
  // ---------------------------------------------------------------------------
  //
  // Flow after Ready (type + payment aware):
  //   "Out for delivery" → status = delivered
  //   unpaid  → PENDING PAYMENT (board column on All)
  //   paid    → DELIVERED (only when the "Delivered" chip is selected)
  // ---------------------------------------------------------------------------

  List<_SectionData> _buildVisibleSectionsData(
    LiveOrdersProvider provider,
  ) {
    final sections = <_SectionData>[];

    // Restaurant (staff) workflow columns — exclude app-sourced orders so
    // POS and customer-app queues stay separate.
    List<OrderModel> staffOnly(List<OrderModel> list) =>
        list.where((o) => o.orderSource == OrderSource.staff).toList();

    if (_selectedStatus == 'All' || _selectedStatus == 'Live') {
      sections.add(
        _SectionData(
          title: 'LIVE ORDERS',
          color: const Color(0xFF5AC8FA),
          orders: staffOnly(provider.live),
          actionText: 'Start Preparing',
          onAdvance: provider.advanceStatus,
        ),
      );
    }

    // App orders sit directly beside Live Orders on the board.
    if (_selectedStatus == 'All' || _selectedStatus == 'App Orders') {
      sections.add(
        _SectionData(
          title: 'APP ORDERS',
          color: const Color(0xFF7C5CFC),
          orders: provider.appOrders,
          actionText: null,
          onAdvance: provider.advanceStatus,
          emptyIcon: Icons.phone_android_outlined,
          emptyText: 'No app orders',
          usePerOrderAction: true,
        ),
      );
    }

    if (_selectedStatus == 'All' || _selectedStatus == 'Preparing') {
      sections.add(
        _SectionData(
          title: 'PREPARING',
          color: const Color(0xFFE9A719),
          orders: staffOnly(provider.preparing),
          actionText: 'Mark Ready',
          onAdvance: provider.advanceStatus,
        ),
      );
    }

    // Ready: action depends on type + payment (OrderModel.boardAdvanceLabel).
    // Delivery → "Out for delivery"; walk-in paid → "Mark Completed";
    // walk-in unpaid → "Serve Order".
    if (_selectedStatus == 'All' || _selectedStatus == 'Ready') {
      sections.add(
        _SectionData(
          title: 'READY',
          color: const Color(0xFF20B47A),
          orders: staffOnly(provider.ready),
          actionText: null,
          onAdvance: provider.advanceStatus,
          usePerOrderAction: true,
        ),
      );
    }

    // After Ready advance → status becomes delivered.
    // Unpaid (pay-at-end) → stay here until Pay Now.
    // Prepaid (already paid) skip this column; only under Delivered chip.
    if (_selectedStatus == 'All' || _selectedStatus == 'Pending Payment') {
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

    // Delivered is chip-only — not shown on the All board.
    // Only paid + status delivered orders appear here.
    if (_selectedStatus == 'Delivered') {
      sections.add(
        _SectionData(
          title: 'DELIVERED',
          color: const Color(0xFF20B47A),
          orders: staffOnly(
            provider.delivered
                .where(
                  (order) => order.paymentStatus == PaymentStatus.paid,
                )
                .toList(),
          ),
          actionText: null,
          onAdvance: null,
          emptyIcon: Icons.delivery_dining_outlined,
          emptyText: 'No delivered orders',
        ),
      );
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
//
// Plain data for one order state (LIVE / PREPARING / READY / DELIVERING).
// Kept separate from the widgets so the same data can be rendered either as
// a column (wide screens) or a row (narrow screens) without duplication.

class _SectionData {
  final String title;
  final Color color;
  final List<OrderModel> orders;
  final String? actionText;
  final ValueChanged<OrderModel>? onAdvance;
  final IconData? emptyIcon;
  final String? emptyText;

  /// When true (e.g. App Orders with mixed statuses), each card uses
  /// [OrderStatus.advanceActionLabel] instead of the section-level [actionText].
  final bool usePerOrderAction;

  const _SectionData({
    required this.title,
    required this.color,
    required this.orders,
    this.actionText,
    this.onAdvance,
    this.emptyIcon,
    this.emptyText,
    this.usePerOrderAction = false,
  });

  String? actionTextFor(OrderModel order) {
    if (usePerOrderAction) {
      // Type + payment aware label (delivery vs walk-in, prepaid vs unpaid).
      return order.boardAdvanceLabel;
    }
    return actionText;
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
