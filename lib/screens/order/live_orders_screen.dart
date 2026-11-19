import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/screens/order/bill_settlement_screen.dart';
import 'package:rdx_admin/screens/order/widgets/live_order_card.dart';
import 'package:rdx_admin/widgets/buttons/stats_collapse_button.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_category_tabs.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_dropdown.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/order_model.dart';
import '../../providers/live_orders_provider.dart';
import '../../widgets/buttons/rdx_header_action_button.dart';
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
  void _log(String message) {
    if (kDebugMode) debugPrint('[LiveOrdersScreen] $message');
  }

  /// Live (walk-in / staff POS) or App (customer app). Default: Live.
  _BoardSource _boardSource = _BoardSource.live;

  /// Status filter within the selected source. 'All' shows the full board.
  String _selectedStatus = 'All';

  /// Horizontal scroll for the kanban board (All view).
  final ScrollController _boardScrollController = ScrollController();

  /// Vertical scroll controllers for the order lists inside each board column.
  final Map<int, ScrollController> _columnScrollControllers = {};

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
    for (final controller in _columnScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // CREATE ORDER

  Future<void> _openPlaceOrder() async {
    final placed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PlaceOrderScreen()
      )
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
        _isLive ? 'Ready' : 'Out for Delivery',
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

  Future<void> _openPayment(OrderModel order) async {
    _log('Payment flow opened from live orders (order: ${order.id}).');
    final items = order.items.map((item) {
      final modifiers = <String>[
        if (item.size != null && item.size!.trim().isNotEmpty)
          'Size: ${item.size}',
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
        modifiers: modifiers
      );
    }).toList();

    _log('Opening bill settlement screen (order: ${order.id}).');
    await Navigator.of(context).push(
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
            subtotal: order.itemTotal > 0
                ? order.itemTotal
                : order.items.fold<double>(
                    0,
                    (sum, item) => sum + (item.price * item.quantity)
                  ),
            // Snapshot from the order only — never live settings.
            taxPercentage: order.gstPercent,
            lateNightFee: order.lateNightFee,
            longDistanceFee: order.longDistanceFee,
            guestName: order.customerName.trim().isNotEmpty
                ? order.customerName
                : 'Walk-in Customer',
            phoneNumber: order.customerPhone,
            deliveryAddress: order.deliveryAddress,
            sendDigitalReceipt: false,
            invoiceReference: order.id,
            receiptDateTime: DateTime.now()
          ),
          onClose: () => Navigator.of(context).pop(),
          onSettled: ref.read(liveOrdersProvider).applyOrderUpdate
        )
      )
    );
  }

  Future<void> _advanceOrder(OrderModel order) async {
    _log(
      'Status action handling started (order: ${order.id}, '
      '${order.status.name} -> ${order.status.nextStatus?.name ?? 'unchanged'}).'
    );
    try {
      await ref.read(liveOrdersProvider).advanceStatus(order);
      _log('Status action handling completed (order: ${order.id}).');
    } catch (error) {
      _log(
        'Status action handling failed '
        '(order: ${order.id}, ${error.runtimeType}): $error'
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update order status. $error'),
          behavior: SnackBarBehavior.floating
        )
      );
    }
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isLoading =
        ref.watch(liveOrdersProvider.select((provider) => provider.isLoading));
    final loadError = ref.watch(
      liveOrdersProvider.select((provider) => provider.errorMessage)
    );

    final pagePad = context.defaultScreenPadding();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Title + New Order + stats (scrolls away) ───────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  pagePad.left,
                  pagePad.top,
                  pagePad.right,
                  0
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
                                'Live Orders',
                                style: AppTextStyles.h2(context)
                              ),
                              SizedBox(height: context.h(4)),
                              Text(
                                'Track orders and create orders for customers',
                                style: AppTextStyles.body(context)
                                    .copyWith(color: colors.textSecondary)
                              ),
                            ]
                          )
                        ),
                        SizedBox(width: context.w(12)),
                        RdxHeaderActionButton(
                          label: 'New Order',
                          onPressed: _openPlaceOrder
                        ),
                      ]
                    ),
                    SizedBox(height: context.h(20)),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StatsCollapseButton(
                        collapsed: _statsCollapsed,
                        onPressed: () => setState(
                          () => _statsCollapsed = !_statsCollapsed
                        )
                      )
                    ),
                    SizedBox(height: context.h(8)),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: _statsCollapsed
                          ? const SizedBox(width: double.infinity)
                          : Consumer(
                              builder: (context, ref, _) {
                                final stats = ref.watch(
                                  liveOrdersProvider.select(
                                    (provider) => provider.overviewStats
                                  )
                                );
                                return _buildOverviewStats(stats);
                              }
                            )
                    ),
                    SizedBox(height: context.h(12)),
                  ]
                )
              )
            ),

            // ── Pinned filters (always stay) ───────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _LiveOrdersFiltersHeader(
                background: colors.background,
                horizontalPad: pagePad.left,
                child: Row(
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
                        isDense: true
                      )
                    ),
                    SizedBox(width: context.w(10)),
                    Expanded(
                      child: RdxCategoryTabs(
                        labels: _statusLabels,
                        selectedLabel: _selectedStatus,
                        onSelected: _onStatusSelected,
                        expand: false
                      )
                    ),
                  ]
                )
              )
            ),

            if (loadError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    pagePad.left,
                    context.h(8),
                    pagePad.right,
                    0
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(12),
                      vertical: context.h(8)
                    ),
                    decoration: BoxDecoration(
                      color: colors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(context.h(8))
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          size: context.h(18),
                          color: colors.warning
                        ),
                        SizedBox(width: context.w(8)),
                        Expanded(
                          child: Text(
                            loadError,
                            style: AppTextStyles.body(context)
                          )
                        ),
                        TextButton(
                          onPressed: () => ref.read(liveOrdersProvider).load(),
                          child: const Text('Retry')
                        ),
                      ]
                    )
                  )
                )
              ),

            // ── Board ──────────────────────────────────────────────────────
            if (isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingIndicator()
              )
            else
              _buildBoardSliver(pagePad),
          ]
        )
      )
    );
  }

  Widget _buildBoardSliver(EdgeInsets pagePad) {
    final sections = _buildVisibleSectionsData();

    // Single-status filtered view
    if (_selectedStatus != 'All') {
      if (sections.isEmpty) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }
      if (sections.length == 1) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              pagePad.left,
              context.h(12),
              pagePad.right,
              pagePad.bottom
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < _kColumnsBreakpoint) {
                  return _buildRowSection(
                    sections.first,
                    sectionWidth: constraints.maxWidth
                  );
                }
                return _buildSingleSectionList(sections.first);
              }
            )
          )
        );
      }
    }

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.crossAxisExtent < _kColumnsBreakpoint;

        if (isNarrow) {
          // Small screen → vertical stack, fixed-width sections,
          // outer CustomScrollView owns the scroll → header hides immediately
          return SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                pagePad.left,
                context.h(12),
                pagePad.right,
                pagePad.bottom
              ),
              child: _buildRowsBoard(
                sections,
                maxWidth:
                    constraints.crossAxisExtent - pagePad.left - pagePad.right
              )
            )
          );
        }

        // Keep the board viewport finite so each status list scrolls locally.
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              pagePad.left,
              context.h(12),
              pagePad.right,
              pagePad.bottom
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                return _buildColumnsBoard(
                  sections,
                  maxWidth: c.maxWidth,
                  maxHeight: context.h(600)
                );
              }
            )
          )
        );
      }
    );
  }

  /// Four overview cards only — Total / Live / App / Pending Payment.
  /// Per-column counts live on the board headings, not here.
  Widget _buildOverviewStats(
    ({
      int totalOrders,
      int liveCount,
      int appCount,
      int pendingPaymentCount,
    }) stats
  ) {
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
              value: '${stats.totalOrders}',
              icon: Icons.receipt_long_outlined,
              minHeight: minH
            ),
            StatCard(
              label: 'Live Orders',
              value: '${stats.liveCount}',
              icon: Icons.star_outline_rounded,
              accentColor: AppColors.info,
              minHeight: minH
            ),
            StatCard(
              label: 'App Orders',
              value: '${stats.appCount}',
              icon: Icons.phone_android_outlined,
              accentColor: AppColors.accent,
              minHeight: minH
            ),
            StatCard(
              label: 'Pending Payment',
              value: '${stats.pendingPaymentCount}',
              icon: Icons.payments_outlined,
              accentColor: AppColors.warning,
              minHeight: minH
            ),
          ];

          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i != cards.length - 1) SizedBox(width: spacing),
              ],
            ]
          );
        }
      )
    );
  }

  // ---------------------------------------------------------------------------
  // ORDERS CONTENT
  // ---------------------------------------------------------------------------

  static const double _kColumnsBreakpoint = 900;

  // All-board columns per source: primary | Preparing | Out for Delivery | Final.
  static const int _kVisibleColumns = 4;

  Widget _buildColumnsBoard(
    List<_SectionData> sections, {
    required double maxWidth,
    required double maxHeight,
  }) {
    final gap = context.w(12).clamp(8.0, 16.0);
    final count = sections.isEmpty ? _kVisibleColumns : sections.length;
    // Same idea as stat cards: share the row evenly when there is room;
    // otherwise keep a readable min width and scroll horizontally.
    final minCol = context.w(200).clamp(160.0, 240.0);
    final equalWidth = (maxWidth - gap * (count - 1)) / count;
    final columnWidth = equalWidth >= minCol ? equalWidth : minCol;

    final isFinalFilter =
        _selectedStatus == 'Served' || _selectedStatus == 'Delivered';
    final provider = ref.read(liveOrdersProvider);
    final compactEmptyFinalBoard = isFinalFilter &&
        sections.every(
          (section) => provider
              .orderIdsFor(
                statuses: section.statuses,
                source: section.source,
                paymentStatus: section.paymentStatus
              )
              .isEmpty
        );
    final boardHeight = compactEmptyFinalBoard
        ? context.h(220)
        : maxHeight.isFinite && maxHeight > 0
            ? maxHeight.clamp(0.0, context.h(600)).toDouble()
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
          colors.textMuted.withValues(alpha: 0.35)
        ),
        trackColor: const WidgetStatePropertyAll(Colors.transparent)
      )
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
              pos.maxScrollExtent
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
                        child: _buildColumnSection(sections[i], columnIndex: i)
                      ),
                      if (i != sections.length - 1) SizedBox(width: gap),
                    ],
                  ]
                )
              )
            )
          )
        )
      )
    );
  }

  Widget _watchSectionOrders(
    _SectionData data,
    Widget Function(List<String> orderIds) builder
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final orderIds = ref.watch(
          liveOrdersProvider.select(
            (provider) => provider.orderIdsFor(
              statuses: data.statuses,
              source: data.source,
              paymentStatus: data.paymentStatus
            )
          )
        );
        return builder(orderIds);
      }
    );
  }

  Widget _buildOrderCard(_SectionData data, String orderId) {
    return Consumer(
      key: ValueKey(orderId),
      builder: (context, ref, _) {
        final order = ref.watch(
          liveOrdersProvider.select((provider) => provider.orderById(orderId))
        );
        if (order == null) return const SizedBox.shrink();

        return LiveOrderCard(
          order: order,
          actionText: data.actionTextFor(order),
          onAdvance: data.onAdvance,
          secondaryActionText: data.secondaryActionTextFor(order),
          onSecondaryAction: data.secondaryOnAdvanceFor(order),
          onTap: () => _openOrderDetail(order)
        );
      }
    );
  }

  Widget _buildSingleSectionList(_SectionData data) {
    return _watchSectionOrders(
      data,
      (orderIds) => _buildSingleSectionListContent(data, orderIds)
    );
  }

  Widget _buildSingleSectionListContent(
    _SectionData data,
    List<String> orderIds
  ) {
    final isEmpty = orderIds.isEmpty;
    final listController = _columnScrollControllers.putIfAbsent(
      0,
      ScrollController.new
    );

    return SizedBox(
      height: context.h(600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(data, orderIds.length),
          SizedBox(height: context.h(12)),
          if (isEmpty)
            _buildEmptySection(
              emptyIcon: data.emptyIcon,
              emptyText: data.emptyText
            )
          else
            Expanded(
              child: Scrollbar(
                controller: listController,
                child: ListView.builder(
                  controller: listController,
                  primary: false,
                  padding: EdgeInsets.only(bottom: context.h(4)),
                  itemCount: orderIds.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: context.h(12)),
                      child: _buildOrderCard(data, orderIds[index])
                    );
                  }
                )
              )
            ),
        ]
      )
    );
  }

  Widget _buildColumnSection(
    _SectionData data, {
    required int columnIndex,
  }) {
    return _watchSectionOrders(
      data,
      (orderIds) => _buildColumnSectionContent(
        data,
        orderIds,
        columnIndex: columnIndex
      )
    );
  }

  Widget _buildColumnSectionContent(
    _SectionData data,
    List<String> orderIds, {
    required int columnIndex,
  }) {
    final isEmpty = orderIds.isEmpty;
    final colors = AppColors.of(context);
    final listController = _columnScrollControllers.putIfAbsent(
      columnIndex,
      ScrollController.new
    );
    final listHovered = _hoveredListColumnIndex == columnIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(data, orderIds.length),
        SizedBox(height: context.h(12)),
        if (isEmpty)
          _buildEmptySection(
            emptyIcon: data.emptyIcon,
            emptyText: data.emptyText
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
                      colors.textMuted.withValues(alpha: 0.35)
                    ),
                    trackColor:
                        const WidgetStatePropertyAll(Colors.transparent)
                  )
                ),
                child: Scrollbar(
                  controller: listController,
                  thumbVisibility: listHovered,
                  trackVisibility: false,
                  thickness: listHovered ? 6 : 0,
                  radius: const Radius.circular(8),
                  child: ListView.builder(
                    controller: listController,
                    primary: false,
                    padding: EdgeInsets.only(bottom: context.h(4)),
                    itemCount: orderIds.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: context.h(12)),
                        child: _buildOrderCard(data, orderIds[index])
                      );
                    }
                  )
                )
              )
            )
          ),
      ]
    );
  }

  Widget _buildRowsBoard(
    List<_SectionData> sections, {
    required double maxWidth,
  }) {
    final sectionWidth = maxWidth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < sections.length; i++) ...[
          _buildRowSection(sections[i], sectionWidth: sectionWidth),
          if (i < sections.length - 1) SizedBox(height: context.h(20)),
        ],
      ]
    );
  }

  Widget _buildRowSection(
    _SectionData data, {
    required double sectionWidth,
  }) {
    return _watchSectionOrders(
      data,
      (orderIds) => _buildRowSectionContent(
        data,
        orderIds,
        sectionWidth: sectionWidth
      )
    );
  }

  Widget _buildRowSectionContent(
    _SectionData data,
    List<String> orderIds, {
    required double sectionWidth,
  }) {
    final isEmpty = orderIds.isEmpty;
    // One width shared by the header, the empty state and every order card,
    // so the empty state never stretches wider than a card.
    final cardWidth = sectionWidth.clamp(0.0, context.w(360)).toDouble();
    return SizedBox(
      width: cardWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(data, orderIds.length),
          SizedBox(height: context.h(12)),
          if (isEmpty)
            SizedBox(
              width: cardWidth,
              child: _buildEmptySection(
                emptyIcon: data.emptyIcon,
                emptyText: data.emptyText
              )
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int index = 0; index < orderIds.length; index++)
                      Padding(
                        padding: EdgeInsets.only(
                          right:
                              index == orderIds.length - 1 ? 0 : context.w(12)
                        ),
                        child: SizedBox(
                          width: cardWidth,
                          child: _buildOrderCard(data, orderIds[index])
                        )
                      ),
                  ]
                )
              )
            ),
        ]
      )
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED HELPERS
  // ---------------------------------------------------------------------------

  void _openOrderDetail(OrderModel order) {
    Navigator.of(context).pushNamed(
      AppRoutes.orderDetail,
      arguments: order.id
    );
  }

  Widget _sectionHeader(_SectionData data, int count) {
    return Padding(
      padding: EdgeInsets.only(
        left: context.w(3),
        right: context.w(3)
      ),
      child: Row(
        children: [
          Container(
            width: context.w(7),
            height: context.h(7),
            decoration: BoxDecoration(
              color: data.color,
              shape: BoxShape.circle
            )
          ),
          SizedBox(width: context.w(9)),
          Flexible(
            child: Text(
              '${data.title} ($count)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyLargeSemi(context).copyWith(
                color: AppColors.primary
              )
            )
          ),
        ]
      )
    );
  }

  // ---------------------------------------------------------------------------
  // VISIBLE SECTIONS — scoped to Live or App via [_boardSource]
  // ---------------------------------------------------------------------------
  //
  // Live board (All):
  //   LIVE ORDERS | PREPARING | READY | SERVED
  //
  // App board (All):
  //   APP ORDERS | PREPARING | OUT FOR DELIVERY | DELIVERED
  //
  // Pending Payment is filter-only (not a board column).
  //
  // Column accent colours come from AppColors tokens:
  //   info = new/live, accent = app, warning = preparing / pending payment,
  //   success = ready / final stage, danger = cancelled.
  // ---------------------------------------------------------------------------

  List<_SectionData> _buildVisibleSectionsData() {
    final sections = <_SectionData>[];
    final isAll = _selectedStatus == 'All';
    final source = _isLive ? OrderSource.staff : OrderSource.app;
    final readyLabel = _isLive ? 'Ready' : 'Out for Delivery';

    if (_isLive) {
      // ── LIVE (walk-in / staff POS) ────────────────────────────────────
      if (isAll) {
        sections.add(
          _SectionData(
            title: 'LIVE ORDERS',
            color: AppColors.info,
            statuses: const [OrderStatus.pending],
            source: source,
            actionText: 'Start Preparing',
            onAdvance: _advanceOrder,
            showPayNow: true,
            onPayNow: _openPayment,
            emptyIcon: Icons.star_outline_rounded,
            emptyText: 'No orders'
          )
        );
      }

      if (isAll || _selectedStatus == 'Preparing') {
        sections.add(
          _SectionData(
            title: 'PREPARING',
            color: AppColors.warning,
            statuses: const [OrderStatus.preparing],
            source: source,
            actionText: 'Mark Ready',
            onAdvance: _advanceOrder,
            showPayNow: true,
            onPayNow: _openPayment,
            emptyIcon: Icons.access_time_rounded,
            emptyText: 'No orders preparing'
          )
        );
      }

      if (isAll || _selectedStatus == readyLabel) {
        sections.add(
          _SectionData(
            title: 'READY',
            color: AppColors.success,
            statuses: const [OrderStatus.ready],
            source: source,
            actionText: null,
            onAdvance: _advanceOrder,
            usePerOrderAction: true,
            showPayNow: true,
            onPayNow: _openPayment,
            hideAdvanceUntilPaid: true,
            emptyIcon: Icons.check_circle_outline,
            emptyText: 'No orders ready'
          )
        );
      }

      if (_selectedStatus == 'Pending Payment') {
        sections.add(
          _SectionData(
            title: 'PENDING PAYMENT',
            color: AppColors.warning,
            statuses: const [OrderStatus.ready, OrderStatus.delivered],
            source: source,
            paymentStatus: PaymentStatus.unpaid,
            actionText: 'Pay Now',
            onAdvance: _openPayment,
            emptyIcon: Icons.payments_outlined,
            emptyText: 'No pending payments'
          )
        );
      }

      // Final stage for Live = Served (paid delivered walk-in).
      if (isAll || _selectedStatus == 'Served') {
        sections.add(
          _SectionData(
            title: 'SERVED',
            color: AppColors.success,
            statuses: const [OrderStatus.delivered],
            source: source,
            paymentStatus: PaymentStatus.paid,
            actionText: null,
            onAdvance: null,
            emptyIcon: Icons.room_service_outlined,
            emptyText: 'No served orders'
          )
        );
      }

      if (_selectedStatus == 'Cancelled') {
        sections.add(
          _SectionData(
            title: 'CANCELLED',
            color: AppColors.danger,
            statuses: const [OrderStatus.cancelled],
            source: source,
            actionText: null,
            onAdvance: null,
            emptyIcon: Icons.cancel_outlined,
            emptyText: 'No cancelled orders'
          )
        );
      }
    } else {
      // ── APP (customer app) ────────────────────────────────────────────
      if (isAll) {
        // Primary column: active app orders still in pending (new).
        sections.add(
          _SectionData(
            title: 'APP ORDERS',
            color: AppColors.accent,
            statuses: const [OrderStatus.pending],
            source: source,
            actionText: 'Start Preparing',
            onAdvance: _advanceOrder,
            showPayNow: true,
            onPayNow: _openPayment,
            emptyIcon: Icons.phone_android_outlined,
            emptyText: 'No orders'
          )
        );
      }

      if (isAll || _selectedStatus == 'Preparing') {
        sections.add(
          _SectionData(
            title: 'PREPARING',
            color: AppColors.warning,
            statuses: const [OrderStatus.preparing],
            source: source,
            actionText: 'Mark Ready',
            onAdvance: _advanceOrder,
            showPayNow: true,
            onPayNow: _openPayment,
            emptyIcon: Icons.access_time_rounded,
            emptyText: 'No orders preparing'
          )
        );
      }

      if (isAll || _selectedStatus == 'Out for Delivery') {
        sections.add(
          _SectionData(
            title: 'OUT FOR DELIVERY',
            color: AppColors.success,
            statuses: const [OrderStatus.ready],
            source: source,
            actionText: null,
            onAdvance: _advanceOrder,
            usePerOrderAction: true,
            showPayNow: true,
            onPayNow: _openPayment,
            hideAdvanceUntilPaid: true,
            emptyIcon: Icons.delivery_dining_outlined,
            emptyText: 'No orders out for delivery'
          )
        );
      }

      if (_selectedStatus == 'Pending Payment') {
        sections.add(
          _SectionData(
            title: 'PENDING PAYMENT',
            color: AppColors.warning,
            statuses: const [OrderStatus.ready, OrderStatus.delivered],
            source: source,
            paymentStatus: PaymentStatus.unpaid,
            actionText: 'Pay Now',
            onAdvance: _openPayment,
            emptyIcon: Icons.payments_outlined,
            emptyText: 'No pending payments'
          )
        );
      }

      // Final stage for App = Delivered (paid delivered app orders).
      if (isAll || _selectedStatus == 'Delivered') {
        sections.add(
          _SectionData(
            title: 'DELIVERED',
            color: AppColors.success,
            statuses: const [OrderStatus.delivered],
            source: source,
            paymentStatus: PaymentStatus.paid,
            actionText: null,
            onAdvance: null,
            emptyIcon: Icons.check_circle_outline,
            emptyText: 'No delivered orders'
          )
        );
      }

      if (_selectedStatus == 'Cancelled') {
        sections.add(
          _SectionData(
            title: 'CANCELLED',
            color: AppColors.danger,
            statuses: const [OrderStatus.cancelled],
            source: source,
            actionText: null,
            onAdvance: null,
            emptyIcon: Icons.cancel_outlined,
            emptyText: 'No cancelled orders'
          )
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
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      height: context.h(170),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(
          context.h(12)
        )
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: colors.border,
          radius: 12
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
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25)
                    )
                  ),
                  child: Icon(
                    emptyIcon,
                    size: context.h(22),
                    color: AppColors.primary
                  )
                ),
                SizedBox(height: context.h(12)),
              ],
              Text(
                emptyText ?? 'No orders',
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context).copyWith(
                  color: colors.textMuted
                )
              ),
            ]
          )
        )
      )
    );
  }
}

// =============================================================================
// SECTION DATA
// =============================================================================

class _SectionData {
  final String title;
  final Color color;
  final List<OrderStatus> statuses;
  final OrderSource source;
  final PaymentStatus? paymentStatus;
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
    required this.statuses,
    required this.source,
    this.paymentStatus,
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
      size.height - 1
    );

    path.addRRect(
      RRect.fromRectAndRadius(
        rect,
        Radius.circular(radius)
      )
    );

    final pathMetrics = path.computeMetrics();

    const double dashLength = 6;
    const double gapLength = 5;

    for (final metric in pathMetrics) {
      double distance = 0;

      while (distance < metric.length) {
        final nextDistance = (distance + dashLength).clamp(
          0,
          metric.length
        );

        final segment = metric.extractPath(
          distance,
          nextDistance.toDouble()
        );

        canvas.drawPath(segment, paint);

        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _DashedBorderPainter oldDelegate
  ) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

/// Pinned filter strip: source dropdown + status chips.
/// Stays fixed at the top while title/stats scroll away.
class _LiveOrdersFiltersHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color background;
  final double horizontalPad;

  _LiveOrdersFiltersHeader({
    required this.child,
    required this.background,
    required this.horizontalPad,
  });

  // Fixed strip height (filters only).
  static const double _height = 56;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent
  ) {
    return Material(
      color: background,
      elevation: overlapsContent || shrinkOffset > 0 ? 1.5 : 0,
      shadowColor: AppColors.black.withValues(alpha: 0.15),
      child: Container(
        height: _height,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: horizontalPad),
        decoration: BoxDecoration(
          color: background,
          border: Border(
            bottom: BorderSide(
              color: overlapsContent || shrinkOffset > 0
                  ? AppColors.of(context).border
                  : Colors.transparent,
              width: 1
            )
          )
        ),
        child: child
      )
    );
  }

  @override
  bool shouldRebuild(covariant _LiveOrdersFiltersHeader oldDelegate) {
    return child != oldDelegate.child ||
        background != oldDelegate.background ||
        horizontalPad != oldDelegate.horizontalPad;
  }
}