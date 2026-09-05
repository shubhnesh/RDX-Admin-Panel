import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/order_model.dart';
import '../../providers/live_orders_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rdx_header.dart';

class LiveOrdersScreen extends StatefulWidget {
  const LiveOrdersScreen({super.key});

  @override
  State<LiveOrdersScreen> createState() => _LiveOrdersScreenState();
}

class _LiveOrdersScreenState extends State<LiveOrdersScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(
      () => context.read<LiveOrdersProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveOrdersProvider>();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: const RdxHeader(title: 'Live Orders'),
      body:
          provider.isLoading ? const LoadingIndicator() : _buildBoard(provider),
    );
  }

  // ===========================================================================
  // LIVE ORDERS BOARD
  // ===========================================================================
  //
  // Every section gets ONE separate column.
  //
  // The entire board is horizontally scrollable.
  //
  // This means you can add:
  //
  // NEW ORDERS
  // PREPARING
  // READY
  // DELIVERING
  // CANCELLED
  // PICKUP
  // SCHEDULED
  // etc.
  //
  // without creating another row.
  // ===========================================================================

  Widget _buildBoard(LiveOrdersProvider provider) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = context.w(44);
    final sectionGap = context.w(18);
    final availableSectionWidth =
        (screenWidth - horizontalPadding - sectionGap * 3) / 4;
    final sectionWidth = availableSectionWidth.clamp(
      context.w(220),
      context.w(320),
    );
    final List<Widget> sections = [
      _buildSection(
        title: 'NEW ORDERS',
        count: provider.pending.length,
        color: const Color(0xFFE51B3E),
        orders: provider.pending,
        actionText: 'Start Preparing',
        onAdvance: provider.advanceStatus,
      ),
      _buildSection(
        title: 'PREPARING',
        count: provider.preparing.length,
        color: const Color(0xFFE9A719),
        orders: provider.preparing,
        actionText: 'Mark Ready',
        onAdvance: provider.advanceStatus,
      ),
      _buildSection(
        title: 'READY',
        count: provider.ready.length,
        color: const Color(0xFF20B47A),
        orders: provider.ready,
        actionText: null,
        onAdvance: provider.advanceStatus,
      ),
      _buildSection(
        title: 'DELIVERING',
        count: 0,
        color: const Color(0xFF31568E),
        orders: const <OrderModel>[],
        actionText: null,
        onAdvance: provider.advanceStatus,
        emptyIcon: Icons.delivery_dining_outlined,
        emptyText: 'No active deliveries',
      ),
    ];

    return Scrollbar(
      thumbVisibility: true,
      notificationPredicate: (notification) {
        return notification.depth == 0;
      },
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          context.w(22),
          context.h(18),
          context.w(22),
          context.h(24),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < sections.length; i++) ...[
              SizedBox(
                width: sectionWidth,
                child: sections[i],
              ),
              if (i != sections.length - 1) SizedBox(width: sectionGap),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SINGLE GENERIC SECTION
  // ===========================================================================
  //
  // This is the ONLY section builder.
  //
  // Every section uses exactly the same UI.
  //
  // Data exists:
  //     -> normal rounded order cards
  //
  // No data:
  //     -> rounded dashed empty card
  //
  // ===========================================================================

  Widget _buildSection({
    required String title,
    required int count,
    required Color color,
    required List<OrderModel> orders,
    required String? actionText,
    required ValueChanged<OrderModel> onAdvance,
    IconData? emptyIcon,
    String? emptyText,
  }) {
    final bool isEmpty = orders.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // =====================================================================
        // SECTION HEADER
        // =====================================================================

        Padding(
          padding: EdgeInsets.only(
            left: context.w(3),
            right: context.w(3),
            bottom: context.h(12),
          ),
          child: Row(
            children: [
              Container(
                width: context.w(7),
                height: context.h(7),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: context.w(9)),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.lightTextPrimary,
                  fontSize: context.h(12),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              Container(
                constraints: BoxConstraints(
                  minWidth: context.w(21),
                  minHeight: context.h(21),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(6),
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(context.h(11)),
                  border: Border.all(
                    color: AppColors.lightBorder,
                    width: context.h(1),
                  ),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: AppColors.lightTextSecondary,
                    fontSize: context.h(9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // =====================================================================
        // EMPTY SECTION
        // =====================================================================

        if (isEmpty)
          Container(
            width: double.infinity,
            height: context.h(170),
            decoration: BoxDecoration(
              color: AppColors.lightSurface,
              borderRadius: BorderRadius.circular(context.h(12)),
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
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1EA),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFD8C5),
                          ),
                        ),
                        child: Icon(
                          emptyIcon,
                          size: 22,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      emptyText ?? 'No orders',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.lightTextMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )

        // =====================================================================
        // POPULATED SECTION
        // =====================================================================

        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final order in orders)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: _buildOrderCard(
                    order: order,
                    actionText: actionText,
                    onAdvance: onAdvance,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  // ===========================================================================
  // ORDER CARD
  // ===========================================================================

  Widget _buildOrderCard({
    required OrderModel order,
    required String? actionText,
    required ValueChanged<OrderModel> onAdvance,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF302B2B),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          // onTap: () {
          //   Navigator.of(context).pushNamed(
          //     AppRoutes.orderDetail,
          //     arguments: order.id,
          //   );
          // },
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.orderDetail,
            arguments: order,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              14,
              13,
              14,
              13,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =============================================================
                // ORDER ID + TIME
                // =============================================================

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        '#RDX-${order.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE0DCDC),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.schedule_outlined,
                      size: 12,
                      color: Color(0xFF777070),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatOrderTime(order.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF888080),
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // =============================================================
                // ITEMS
                // =============================================================

                Text(
                  order.items.isEmpty
                      ? 'Order'
                      : order.items
                          .map(
                            (item) => '${item.quantity}x ${item.name}',
                          )
                          .join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD7D1D1),
                    fontSize: 11,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 6),

                // =============================================================
                // CUSTOMER
                // =============================================================

                Text(
                  'Customer: ${order.customerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF858080),
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 12),

                // =============================================================
                // HORIZONTAL DIVIDER
                // =============================================================

                Container(
                  height: 1,
                  color: const Color(0xFF292525),
                ),

                const SizedBox(height: 11),

                // =============================================================
                // BOTTOM ROW
                // =============================================================

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252020),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: const Color(0xFF302A2A),
                        ),
                      ),
                      child: Text(
                        '${order.items.length} '
                        '${order.items.length == 1 ? 'Item' : 'Items'}',
                        style: const TextStyle(
                          color: Color(0xFFA69D9D),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (actionText != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(5),
                          onTap: () {
                            onAdvance(order);
                          },
                          child: Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF214D9B),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              actionText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TIME
  // ===========================================================================

  String _formatOrderTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;

    final minute = dateTime.minute.toString().padLeft(2, '0');

    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
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

    final PathMetrics metrics = path.computeMetrics();

    const double dashLength = 6;
    const double gapLength = 5;

    for (final metric in metrics) {
      double distance = 0;

      while (distance < metric.length) {
        final double nextDistance = (distance + dashLength).clamp(
          0,
          metric.length,
        );

        final Path segment = metric.extractPath(
          distance,
          nextDistance.toDouble(),
        );

        canvas.drawPath(
          segment,
          paint,
        );

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
