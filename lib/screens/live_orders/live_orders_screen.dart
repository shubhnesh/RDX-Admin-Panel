import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdx_admin/widgets/rdx_search_bar.dart';
import '../../core/router/app_router.dart';
import '../../models/order_model.dart';
import '../../providers/live_orders_provider.dart';
import '../../widgets/loading_indicator.dart';

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
      backgroundColor: const Color(0xFF0B0506),
      // appBar: const RdxHeader(
      //   title: 'Live Orders',
      // ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          bottom: false,
          child: RdxSearchToolbar(
            hintText: 'Search orders...',
            onChanged: (value) {
              // Search/filter logic here.
            },
          ),
        ),
      ),
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
        padding: const EdgeInsets.fromLTRB(
          22,
          18,
          22,
          24,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < sections.length; i++) ...[
              SizedBox(
                width: 320,
                child: sections[i],
              ),
              if (i != sections.length - 1) const SizedBox(width: 18),
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
          padding: const EdgeInsets.only(
            left: 3,
            right: 3,
            bottom: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFD7D2D2),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              Container(
                constraints: const BoxConstraints(
                  minWidth: 21,
                  minHeight: 21,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF252021),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: const Color(0xFF30292A),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Color(0xFF999191),
                    fontSize: 9,
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
            height: 170,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0809),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: const Color(0xFF4A292F),
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
                          color: const Color(0xFF171011),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF302022),
                          ),
                        ),
                        child: Icon(
                          emptyIcon,
                          size: 22,
                          color: const Color(0xFF625658),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      emptyText ?? 'No orders',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF62595B),
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
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
