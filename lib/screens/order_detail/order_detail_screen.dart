import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/order_detail_provider.dart';
import '../../services/order_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rdx_header.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrderDetailProvider(
        OrderService(),
        orderId,
      )..load(),
      child: const _OrderDetailBody(),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderDetailProvider>();

    final order = provider.order;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: RdxHeader(
        title: order == null ? 'Order Detail' : 'Order #RDX-${order.id}',
        showBack: true,
      ),
      body: provider.isLoading || order == null
          ? const LoadingIndicator()
          : _OrderDetailContent(
              order: order,
              provider: provider,
            ),
    );
  }
}

class _OrderDetailContent extends StatelessWidget {
  final OrderModel order;
  final OrderDetailProvider provider;

  const _OrderDetailContent({
    required this.order,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;

        if (compact) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _OrderHeader(order: order),
                const SizedBox(height: 12),
                _CustomerCard(order: order),
                const SizedBox(height: 12),
                _OrderItemsCard(order: order),
                const SizedBox(height: 12),
                _DeliveryCard(order: order),
                const SizedBox(height: 12),
                _TimelineCard(order: order),
                const SizedBox(height: 12),
                _StatusCard(
                  order: order,
                  provider: provider,
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  14,
                  18,
                  12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OrderHeader(order: order),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              _CustomerCard(order: order),
                              const SizedBox(height: 12),
                              _OrderItemsCard(order: order),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              _DeliveryCard(order: order),
                              const SizedBox(height: 12),
                              _TimelineCard(order: order),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _BottomActionBar(
              order: order,
              provider: provider,
            ),
          ],
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/* HEADER                                                                     */
/* -------------------------------------------------------------------------- */

class _OrderHeader extends StatelessWidget {
  final OrderModel order;

  const _OrderHeader({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Order #RDX-${order.id}',
                    style: const TextStyle(
                      color: Color(0xFFE8E8E8),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 7),
                  _SmallStatusBadge(
                    status: order.status,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Placed at ${_formatTime(order.createdAt)} • Delivery order',
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
        _HeaderButton(
          icon: Icons.print_outlined,
          label: 'Print',
          onTap: () {},
        ),
        const SizedBox(width: 7),
        _HeaderButton(
          icon: Icons.support_agent_outlined,
          label: 'Support',
          onTap: () {},
        ),
      ],
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: const Color(0xFF343434),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 11,
              color: const Color(0xFFB8B8B8),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFB8B8B8),
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* CUSTOMER                                                                  */
/* -------------------------------------------------------------------------- */

class _CustomerCard extends StatelessWidget {
  final OrderModel order;

  const _CustomerCard({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      title: 'CUSTOMER DETAILS',
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF383838),
                  ),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF8E8E8E),
                  size: 16,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName,
                      style: const TextStyle(
                        color: Color(0xFFE2E2E2),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      order.customerPhone,
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
              _CircleAction(
                icon: Icons.phone_outlined,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AddressRow(
            address: order.deliveryAddress,
          ),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final String address;

  const _AddressRow({
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 13,
          color: Color(0xFF777777),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            address,
            style: const TextStyle(
              color: Color(0xFF929292),
              fontSize: 8,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleAction({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 27,
        height: 27,
        decoration: BoxDecoration(
          color: const Color(0xFF191919),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF343434),
          ),
        ),
        child: Icon(
          icon,
          size: 12,
          color: const Color(0xFFAAAAAA),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* ORDER ITEMS                                                                */
/* -------------------------------------------------------------------------- */

class _OrderItemsCard extends StatelessWidget {
  final OrderModel order;

  const _OrderItemsCard({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    double subtotal = 0;

    for (final item in order.items) {
      subtotal += item.price * item.quantity;
    }

    final tax =
        order.total > subtotal ? order.total - subtotal : subtotal * .05;

    return _DarkCard(
      title: 'ORDER ITEMS',
      trailing: '${order.items.length} ITEMS',
      child: Column(
        children: [
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                children: [
                  Container(
                    width: 25,
                    height: 25,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF202020),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${item.quantity}x',
                      style: const TextStyle(
                        color: Color(0xFFBBBBBB),
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD2D2D2),
                        fontSize: 9,
                      ),
                    ),
                  ),
                  Text(
                    '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(
            height: 1,
            color: Color(0xFF292929),
          ),
          const SizedBox(height: 10),
          _PriceRow(
            label: 'Subtotal',
            value: '₹${subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 7),
          _PriceRow(
            label: 'Tax & Fees',
            value: '₹${tax.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          _PriceRow(
            label: 'Total',
            value: '₹${order.total.toStringAsFixed(2)}',
            strong: true,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _PriceRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: strong ? const Color(0xFFD7D7D7) : const Color(0xFF777777),
              fontSize: strong ? 9 : 8,
              fontWeight: strong ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: strong ? const Color(0xFFE5E5E5) : const Color(0xFF999999),
            fontSize: strong ? 10 : 8,
            fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/* DELIVERY                                                                  */
/* -------------------------------------------------------------------------- */

class _DeliveryCard extends StatelessWidget {
  final OrderModel order;

  const _DeliveryCard({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: const Color(0xFF2A2A2A),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MapGridPainter(),
            ),
          ),
          Positioned(
            top: 9,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xCC101010),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: const Color(0xFF292929),
                ),
              ),
              child: const Text(
                'DELIVERY LOCATION',
                style: TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 7,
                  letterSpacing: .5,
                ),
              ),
            ),
          ),
          Positioned(
            top: 82,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFFB91936),
                  size: 30,
                ),
                const SizedBox(height: 3),
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB91936),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xEE101010),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF333333),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFF146BC2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delivery_dining_outlined,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RIDER ASSIGNED',
                          style: TextStyle(
                            color: Color(0xFF6B6B6B),
                            fontSize: 6.5,
                            letterSpacing: .4,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Marcus T.  (3.2 mi away)',
                          style: TextStyle(
                            color: Color(0xFFD7D7D7),
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF20282A)
      ..strokeWidth = .6
      ..style = PaintingStyle.stroke;

    final secondaryPaint = Paint()
      ..color = const Color(0xFF171D1E)
      ..strokeWidth = .5;

    for (double x = -size.height; x < size.width + size.height; x += 28) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }

    for (double x = 0; x < size.width; x += 48) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        secondaryPaint,
      );
    }

    for (double y = 0; y < size.height; y += 34) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        secondaryPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

/* -------------------------------------------------------------------------- */
/* TIMELINE                                                                  */
/* -------------------------------------------------------------------------- */

class _TimelineCard extends StatelessWidget {
  final OrderModel order;

  const _TimelineCard({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      title: 'LOGISTICS TIMELINE',
      child: Column(
        children: [
          _TimelineStep(
            title: 'Order Confirmed',
            subtitle: _formatTime(order.createdAt),
            completed: true,
            active: order.status != OrderStatus.pending,
          ),
          _TimelineStep(
            title: 'Preparing Food',
            subtitle: order.status == OrderStatus.preparing
                ? 'In kitchen · Est. 10m remaining'
                : 'Kitchen preparation',
            completed: order.status == OrderStatus.ready ||
                order.status == OrderStatus.delivered,
            active: order.status == OrderStatus.preparing,
          ),
          _TimelineStep(
            title: 'Rider Pickup',
            subtitle: order.status == OrderStatus.ready
                ? 'Ready for pickup'
                : 'Pending',
            completed: order.status == OrderStatus.delivered,
            active: order.status == OrderStatus.ready,
            last: true,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool completed;
  final bool active;
  final bool last;

  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.completed,
    required this.active,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active || completed
                        ? const Color(0xFFE31B3F)
                        : const Color(0xFF343434),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: const Color(0xFF303030),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: active || completed
                        ? const Color(0xFFDADADA)
                        : const Color(0xFF707070),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: active
                        ? const Color(0xFFB8B8B8)
                        : const Color(0xFF5E5E5E),
                    fontSize: 7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* STATUS                                                                    */
/* -------------------------------------------------------------------------- */

class _StatusCard extends StatelessWidget {
  final OrderModel order;
  final OrderDetailProvider provider;

  const _StatusCard({
    required this.order,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      title: 'ORDER STATUS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SmallStatusBadge(
            status: order.status,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: OrderStatus.values
                .where(
                  (status) => status != OrderStatus.cancelled,
                )
                .map(
                  (status) => _StatusButton(
                    label: status.label,
                    active: status == order.status,
                    onTap: () {
                      provider.updateStatus(status);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {
              provider.updateStatus(
                OrderStatus.cancelled,
              );
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 25),
            ),
            child: const Text(
              'Cancel Order',
              style: TextStyle(
                color: Color(0xFFCE3048),
                fontSize: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 25,
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF8F1028) : const Color(0xFF151515),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: active ? const Color(0xFFB51A35) : const Color(0xFF353535),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF9A9A9A),
            fontSize: 7.5,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* BOTTOM ACTION BAR                                                         */
/* -------------------------------------------------------------------------- */

class _BottomActionBar extends StatelessWidget {
  final OrderModel order;
  final OrderDetailProvider provider;

  const _BottomActionBar({
    required this.order,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 57,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D0D),
        border: Border(
          top: BorderSide(
            color: Color(0xFF292929),
          ),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'QUICK ACTIONS',
            style: TextStyle(
              color: Color(0xFF656565),
              fontSize: 6.5,
              fontWeight: FontWeight.w600,
              letterSpacing: .45,
            ),
          ),
          const SizedBox(width: 14),
          _QuickAction(
            icon: Icons.schedule_outlined,
            title: 'Delay',
            subtitle: '5m',
            onTap: () {},
          ),
          const SizedBox(width: 7),
          _QuickAction(
            icon: Icons.notifications_none_outlined,
            title: 'Notify',
            subtitle: 'Rider',
            onTap: () {},
          ),
          const Spacer(),
          _BottomButton(
            label: 'Contact Customer',
            icon: Icons.phone_outlined,
            onTap: () {},
          ),
          const SizedBox(width: 7),
          _BottomButton(
            label: 'Mark Ready',
            icon: Icons.check_circle_outline,
            onTap: () {
              provider.updateStatus(
                OrderStatus.ready,
              );
            },
          ),
          const SizedBox(width: 7),
          _BottomButton(
            label: 'Dispatch Rider',
            icon: Icons.delivery_dining_outlined,
            primary: true,
            onTap: () {
              provider.updateStatus(
                OrderStatus.delivered,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: const Color(0xFF303030),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 10,
              color: const Color(0xFF888888),
            ),
            const SizedBox(width: 5),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 6.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 6,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  const _BottomButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: primary ? const Color(0xFFBD1534) : const Color(0xFF161616),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: primary ? const Color(0xFFD22645) : const Color(0xFF353535),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 11,
              color: primary ? Colors.white : const Color(0xFFAAAAAA),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: primary ? Colors.white : const Color(0xFFBDBDBD),
                fontSize: 7.5,
                fontWeight: primary ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* COMMON CARD                                                               */
/* -------------------------------------------------------------------------- */

class _DarkCard extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget child;

  const _DarkCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: const Color(0xFF292929),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .4,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 6.5,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* STATUS BADGE                                                              */
/* -------------------------------------------------------------------------- */

class _SmallStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _SmallStatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;

    switch (status) {
      case OrderStatus.pending:
        color = const Color(0xFFE3A326);
        break;
      case OrderStatus.preparing:
        color = const Color(0xFFE3A326);
        break;
      case OrderStatus.ready:
        color = const Color(0xFF27B879);
        break;
      case OrderStatus.delivered:
        color = const Color(0xFF3B8DFF);
        break;
      case OrderStatus.cancelled:
        color = const Color(0xFFD8324E);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: color.withOpacity(.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status.label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 6,
              fontWeight: FontWeight.w600,
              letterSpacing: .25,
            ),
          ),
        ],
      ),
    );
  }
}
