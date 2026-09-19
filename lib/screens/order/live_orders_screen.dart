import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/screens/order/widgets/live_order_card.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/order_model.dart';
import '../../providers/live_orders_provider.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/reusable_widgets/stat_card.dart';
import '../../widgets/resuable_options/rdx_category_tabs.dart';
import 'place_order_screen.dart';

class LiveOrdersScreen extends ConsumerStatefulWidget {
  const LiveOrdersScreen({super.key});

  @override
  ConsumerState<LiveOrdersScreen> createState() => _LiveOrdersScreenState();
}

class _LiveOrdersScreenState extends ConsumerState<LiveOrdersScreen> {
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      ref.read(liveOrdersProvider).load();
    });
  }

  // ---------------------------------------------------------------------------
  // CREATE ORDER
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // STATUS FILTER
  // ---------------------------------------------------------------------------

  List<String> get _statusLabels =>
      const ['New', 'Preparing', 'Ready', 'Delivered'];

  void _onStatusSelected(String label) {
    if (_selectedStatus == label) return;

    setState(() {
      _selectedStatus = label;
    });
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final provider = ref.watch(liveOrdersProvider);

    final totalOrders = provider.pending.length +
        provider.preparing.length +
        provider.ready.length +
        provider.delivered.length;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: Responsive.pagePadding(
            context,
            top: context.h(14),
            bottom: context.h(0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------------------
              // HEADER
              // ----------------------------------------------------------------

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

                  final tabs = RdxCategoryTabs(
                    expand: false,
                    labels: _statusLabels,
                    allLabel: 'All',
                    selectedLabel: _selectedStatus,
                    onSelected: _onStatusSelected,
                  );

                  if (narrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: titleBlock,
                            ),
                            SizedBox(width: context.w(12)),
                            RdxActionButton(
                              label: 'New Order',
                              leadingIcon: Icons.add,
                              isPrimary: true,
                              onPressed: _openPlaceOrder,
                            ),
                          ],
                        ),
                        SizedBox(height: context.h(12)),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: tabs,
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: titleBlock,
                      ),
                      SizedBox(width: context.w(18)),
                      tabs,
                      SizedBox(width: context.w(18)),
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

              SizedBox(height: context.h(16)),

              // ----------------------------------------------------------------
              // SUMMARY STAT CARDS
              // ----------------------------------------------------------------

              _buildSummaryStats(
                provider: provider,
                totalOrders: totalOrders,
              ),

              SizedBox(height: context.h(20)),

              // ----------------------------------------------------------------
              // ORDERS
              // ----------------------------------------------------------------

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
  }) {
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          final spacing = isNarrow ? context.w(6) : context.w(16);

          final cards = <Widget>[
            StatCard(
              label: 'Total Orders',
              value: '$totalOrders orders',
              icon: Icons.receipt_long_outlined,
              minHeight: isNarrow ? context.h(62) : context.h(72),
            ),
            StatCard(
              label: 'New Orders',
              value: '${provider.pending.length}',
              icon: Icons.fiber_new_outlined,
              accentColor: const Color(0xFFE51B3E),
              minHeight: isNarrow ? context.h(62) : context.h(72),
            ),
            StatCard(
              label: 'Preparing',
              value: '${provider.preparing.length}',
              icon: Icons.restaurant_outlined,
              accentColor: const Color(0xFFE9A719),
              minHeight: isNarrow ? context.h(62) : context.h(72),
            ),
            StatCard(
              label: 'Ready',
              value: '${provider.ready.length}',
              icon: Icons.check_circle_outline,
              accentColor: const Color(0xFF20B47A),
              minHeight: isNarrow ? context.h(62) : context.h(72),
            ),
            StatCard(
              label: 'Delivered',
              value: '${provider.delivered.length}',
              icon: Icons.check_circle_outline,
              accentColor: const Color(0xFF20B47A),
              minHeight: isNarrow ? context.h(62) : context.h(72),
            ),
          ];

          return Row(
            children: [
              Expanded(child: cards[0]),
              SizedBox(width: spacing),
              Expanded(child: cards[1]),
              SizedBox(width: spacing),
              Expanded(child: cards[2]),
              SizedBox(width: spacing),
              Expanded(child: cards[3]),
              SizedBox(width: spacing),
              Expanded(child: cards[4]),
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

  Widget _buildOrdersContent(
    LiveOrdersProvider provider,
  ) {
    final sections = _buildVisibleSectionsData(provider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _kColumnsBreakpoint;

        return isWide
            ? _buildColumnsBoard(sections)
            : _buildRowsBoard(sections);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // WIDE LAYOUT — states as columns, cards stacked vertically
  // ---------------------------------------------------------------------------

  Widget _buildColumnsBoard(List<_SectionData> sections) {
    final gap = context.w(16);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < sections.length; i++) ...[
          Expanded(child: _buildColumnSection(sections[i])),
          if (i != sections.length - 1) SizedBox(width: gap),
        ],
      ],
    );
  }

  Widget _buildColumnSection(_SectionData data) {
    final isEmpty = data.orders.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(data),
        SizedBox(height: context.h(12)),
        if (isEmpty)
          // Keep the empty-state box at its normal compact height —
          // don't stretch it to fill the column.
          _buildEmptySection(
            emptyIcon: data.emptyIcon,
            emptyText: data.emptyText,
          )
        else
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: context.h(4)),
              itemCount: data.orders.length,
              itemBuilder: (context, index) {
                final order = data.orders[index];

                return Padding(
                  padding: EdgeInsets.only(bottom: context.h(12)),
                  child: LiveOrderCard(
                    order: order,
                    actionText: data.actionText,
                    onAdvance: data.onAdvance,
                    onTap: () => _openOrderDetail(order),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // NARROW LAYOUT — states as rows, cards scroll horizontally
  // ---------------------------------------------------------------------------

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
                          actionText: data.actionText,
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
          // const Spacer(),
          // Container(
          //   constraints: BoxConstraints(
          //     minWidth: context.w(21),
          //     minHeight: context.h(21),
          //   ),
          //   padding: EdgeInsets.symmetric(
          //     horizontal: context.w(6),
          //   ),
          //   alignment: Alignment.center,
          //   decoration: BoxDecoration(
          //     color: AppColors.lightSurface,
          //     borderRadius: BorderRadius.circular(context.h(15)),
          //     border: Border.all(
          //       color: AppColors.lightBorder,
          //       width: context.h(3),
          //     ),
          //   ),
          //   child: Text(
          //     '${data.orders.length}',
          //     style: AppTextStyles.bodySecondary(context),
          //   ),
          // ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VISIBLE SECTIONS (data only — layout decides how to render them)
  // ---------------------------------------------------------------------------

  List<_SectionData> _buildVisibleSectionsData(
    LiveOrdersProvider provider,
  ) {
    final sections = <_SectionData>[];

    if (_selectedStatus == 'All' || _selectedStatus == 'New') {
      sections.add(
        _SectionData(
          title: 'NEW ORDERS',
          color: const Color(0xFFE51B3E),
          orders: provider.pending,
          actionText: 'Start Preparing',
          onAdvance: provider.advanceStatus,
        ),
      );
    }

    if (_selectedStatus == 'All' || _selectedStatus == 'Preparing') {
      sections.add(
        _SectionData(
          title: 'PREPARING',
          color: const Color(0xFFE9A719),
          orders: provider.preparing,
          actionText: 'Mark Ready',
          onAdvance: provider.advanceStatus,
        ),
      );
    }

    if (_selectedStatus == 'All' || _selectedStatus == 'Ready') {
      sections.add(
        _SectionData(
          title: 'READY',
          color: const Color(0xFF20B47A),
          orders: provider.ready,
          actionText: 'Mark Delivered',
          onAdvance: provider.advanceStatus,
        ),
      );
    }

    /*
     * Delivering is intentionally kept only in All,
     * exactly as in your current implementation.
     */
    if (_selectedStatus == 'All' || _selectedStatus == 'Delivered') {
      sections.add(
        _SectionData(
          title: 'DELIVERED',
          color: const Color(0xFF31568E),
          orders: provider.delivered,
          actionText: null,
          onAdvance: null,
          emptyIcon: Icons.delivery_dining_outlined,
          emptyText: 'No active deliveries',
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
// Plain data for one order state (NEW / PREPARING / READY / DELIVERING).
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

  const _SectionData({
    required this.title,
    required this.color,
    required this.orders,
    this.actionText,
    this.onAdvance,
    this.emptyIcon,
    this.emptyText,
  });
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
