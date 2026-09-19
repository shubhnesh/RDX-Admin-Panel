import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/providers/live_orders_provider.dart';
import 'package:rdx_admin/screens/order/bill_settlement_screen.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/empty_state.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';

final orderDetailProvider =
    FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  if (orderId.trim().isEmpty) return null;

  return OrderService().fetchOrderById(orderId);
});

class OrderDetailsScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrder = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: Column(
        children: [
          RdxHeader(
            title: asyncOrder.when(
              data: (order) {
                if (order == null) return 'Order Detail';

                return 'Order #${_shortId(order.id)}';
              },
              loading: () => 'Order Detail',
              error: (_, __) => 'Order Detail',
            ),
            showBackButton: true,
          ),
          Expanded(
            child: asyncOrder.when(
              loading: () => const LoadingIndicator(),
              error: (error, _) => EmptyState(
                message: 'Failed to load order.\n$error',
              ),
              data: (order) {
                if (order == null) {
                  return const EmptyState(
                    message: 'Order not found.',
                  );
                }

                return _OrderDetailBody(order: order);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _shortId(String id) {
    if (id.length <= 4) return id;
    return id.substring(id.length - 4);
  }
}

// =============================================================================
// ORDER DETAIL BODY
// =============================================================================

class _OrderDetailBody extends ConsumerWidget {
  final OrderModel order;

  const _OrderDetailBody({
    required this.order,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;

    final narrow = width < 900;

    double subtotal = 0;

    for (final item in order.items) {
      subtotal += item.price * item.quantity;
    }

    final tax = (order.total - subtotal).clamp(
      0,
      double.infinity,
    );

    final taxPercent = subtotal > 0 ? (tax / subtotal) * 100 : 0.0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              context.w(20),
              context.h(12),
              context.w(20),
              context.h(20),
            ),
            child: narrow
                ? Column(
                    children: [
                      _ServiceAndCustomer(
                        order: order,
                      ),
                      SizedBox(height: context.h(14)),
                      _OrderItemsSection(
                        order: order,
                      ),
                      SizedBox(height: context.h(14)),
                      _KitchenNotes(
                        order: order,
                      ),
                      SizedBox(height: context.h(14)),
                      _PaymentSection(
                        order: order,
                      ),
                      SizedBox(height: context.h(14)),
                      _BillingSummary(
                        subtotal: subtotal,
                        tax: tax.toDouble(),
                        taxPercent: taxPercent,
                        total: order.total,
                      ),
                      SizedBox(height: context.h(14)),
                      _WorkflowSection(
                        order: order,
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _ServiceAndCustomer(
                              order: order,
                            ),
                            SizedBox(height: context.h(14)),
                            _OrderItemsSection(
                              order: order,
                            ),
                            SizedBox(height: context.h(14)),
                            _KitchenNotes(
                              order: order,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: context.w(16)),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _PaymentSection(
                              order: order,
                            ),
                            SizedBox(height: context.h(14)),
                            _BillingSummary(
                              subtotal: subtotal,
                              tax: tax.toDouble(),
                              taxPercent: taxPercent,
                              total: order.total,
                            ),
                            SizedBox(height: context.h(14)),
                            _WorkflowSection(
                              order: order,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        _BottomActionBar(
          order: order,
        ),
      ],
    );
  }
}

// =============================================================================
// SERVICE + CUSTOMER
// =============================================================================

class _ServiceAndCustomer extends StatelessWidget {
  final OrderModel order;

  const _ServiceAndCustomer({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return _Panel(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            context: context,
            title: 'SERVICE & CUSTOMER',
            icon: Icons.receipt_long_outlined,
          ),
          SizedBox(height: context.h(14)),
          Text(
            'SERVICE OPTION',
            style: AppTextStyles.bodySecondary(context).copyWith(
              color: colors.textMuted,
              letterSpacing: 0.6,
            ),
          ),
          SizedBox(height: context.h(7)),
          Row(
            children: [
              Expanded(
                child: _OptionTile(
                  context: context,
                  label: 'Eat In',
                  selected: order.orderType == OrderType.dineIn,
                ),
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                child: _OptionTile(
                  context: context,
                  label: 'To Go',
                  // selected: false,
                  selected: order.orderType == OrderType.takeaway,
                ),
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                child: _OptionTile(
                  context: context,
                  label: 'Delivery',
                  selected: order.orderType == OrderType.delivery,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(14)),
          Row(
            children: [
              Expanded(
                child: _InfoBlock(
                  context: context,
                  label: 'TABLE',
                  value: order.orderType == OrderType.dineIn
                      ? ((order.tableNumber?.trim().isNotEmpty ?? false)
                          ? 'Table ${order.tableNumber}'
                          : 'No Table / Counter')
                      : '—',
                ),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: _InfoBlock(
                  context: context,
                  label: 'ORDER TYPE',
                  value: _orderTypeLabel(order.orderType),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(14)),
          Divider(
            height: 1,
            color: colors.divider,
          ),
          SizedBox(height: context.h(14)),
          Row(
            children: [
              Container(
                width: context.h(30),
                height: context.h(30),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  size: context.h(16),
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName.trim().isEmpty
                          ? 'Walk-in Customer'
                          : order.customerName,
                      style: AppTextStyles.body(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (order.customerPhone.trim().isNotEmpty)
                      SizedBox(height: context.h(2)),
                    if (order.customerPhone.trim().isNotEmpty)
                      Text(
                        order.customerPhone,
                        style: AppTextStyles.caption(context).copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (order.orderType == OrderType.delivery &&
              order.deliveryAddress.trim().isNotEmpty) ...[
            SizedBox(height: context.h(12)),
            _InfoBlock(
              context: context,
              label: 'DELIVERY ADDRESS',
              value: order.deliveryAddress,
            ),
          ],
        ],
      ),
    );
  }

  String _orderTypeLabel(OrderType type) {
    switch (type) {
      case OrderType.dineIn:
        return 'Eat In';
      case OrderType.delivery:
        return 'Delivery';
      case OrderType.takeaway:
        return 'To Go';
    }
  }
}

// =============================================================================
// ORDER ITEMS
// =============================================================================

class _OrderItemsSection extends StatelessWidget {
  final OrderModel order;

  const _OrderItemsSection({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return _Panel(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionTitle(
                context: context,
                title: 'ORDER ITEMS',
                icon: Icons.restaurant_menu_outlined,
              ),
              const Spacer(),
              Text(
                '${order.items.length} Lines',
                style: AppTextStyles.label(context).copyWith(
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(12)),
          for (int index = 0; index < order.items.length; index++) ...[
            _OrderItemRow(
              item: order.items[index],
            ),
            if (index != order.items.length - 1)
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: context.h(10),
                ),
                child: Divider(
                  height: 1,
                  color: colors.divider,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final OrderItemModel item;

  const _OrderItemRow({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final amount = item.price * item.quantity;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: context.h(25),
          height: context.h(25),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(
              context.h(5),
            ),
            border: Border.all(
              color: colors.border,
            ),
          ),
          child: Text(
            '${item.quantity}',
            style: AppTextStyles.caption(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: context.w(10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: context.h(2)),
              if (item.spiceLevel != null || item.addOns.isNotEmpty)
                Text(
                  [
                    if (item.spiceLevel != null &&
                        item.spiceLevel!.trim().isNotEmpty)
                      item.spiceLevel!,
                    ...item.addOns,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              if (item.notes != null && item.notes!.trim().isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                    top: context.h(2),
                  ),
                  child: Text(
                    'Note: ${item.notes}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
                      color: colors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: context.w(10)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: AppTextStyles.body(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: context.h(2)),
            Text(
              '₹${item.price.toStringAsFixed(2)} each',
              style: AppTextStyles.caption(context).copyWith(
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// KITCHEN NOTES
// =============================================================================

class _KitchenNotes extends StatelessWidget {
  final OrderModel order;

  const _KitchenNotes({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    if (order.notes == null || order.notes!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return _Panel(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes_outlined,
                size: context.h(14),
                color: colors.textMuted,
              ),
              SizedBox(width: context.w(5)),
              Text(
                'KITCHEN NOTES',
                style: AppTextStyles.section(context).copyWith(
                  color: colors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(8)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(
              context.h(10),
            ),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(
                context.h(7),
              ),
            ),
            child: Text(
              order.notes!,
              style: AppTextStyles.bodySecondary(context).copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PAYMENT
// =============================================================================

class _PaymentSection extends ConsumerWidget {
  final OrderModel order;

  const _PaymentSection({
    required this.order,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    // final isPaid = order.paymentMethod != null;
    final isPaid = order.paymentStatus == PaymentStatus.paid;

    return _Panel(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionTitle(
                context: context,
                title: 'PAYMENT',
                icon: Icons.payments_outlined,
              ),
              const Spacer(),
              _PaymentStatusBadge(
                context: context,
                paid: isPaid,
              ),
            ],
          ),
          SizedBox(height: context.h(14)),
          if (isPaid)
            _PaidPayment(
              order: order,
            )
          else
            _UnpaidPayment(
              order: order,
            ),
        ],
      ),
    );
  }
}

class _PaidPayment extends StatelessWidget {
  final OrderModel order;

  const _PaidPayment({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        context.h(11),
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(
          context.h(8),
        ),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: context.h(32),
            height: context.h(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: 0.12,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: context.h(17),
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Completed',
                  style: AppTextStyles.body(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  order.paymentMethod!.label,
                  style: AppTextStyles.caption(context).copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${order.total.toStringAsFixed(2)}',
            style: AppTextStyles.body(context).copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnpaidPayment extends ConsumerWidget {
  final OrderModel order;

  const _UnpaidPayment({
    required this.order,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            context.h(11),
          ),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(
              context.h(8),
            ),
            border: Border.all(
              color: colors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.pending_outlined,
                size: context.h(17),
                color: colors.textMuted,
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                child: Text(
                  'Payment is pending',
                  style: AppTextStyles.bodySecondary(context).copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Text(
                '₹${order.total.toStringAsFixed(2)}',
                style: AppTextStyles.body(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.h(10)),
        SizedBox(
          width: double.infinity,
          child: RdxActionButton(
            label: 'Make Payment',
            leadingIcon: Icons.payments_outlined,
            isPrimary: true,
            onPressed: () => _openBillSettlement(
              context,
              ref,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openBillSettlement(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Always use the payment status received from the backend.
    // Do not open the settlement screen if the order is already paid.
    if (order.paymentStatus == PaymentStatus.paid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This order has already been paid.'),
        ),
      );

      ref.invalidate(
        orderDetailProvider(order.id),
      );

      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BillSettlementScreen(
          bill: BillSettlementData(
            orderNumber: order.id,

            // Keep the existing restaurant display value.
            restaurantName: 'RDX CORE RESTAURANT & BAR',

            orderType: _orderTypeLabel(
              order.orderType,
            ),

            tableNumber: order.tableNumber,

            billingMode: _orderTypeLabel(
              order.orderType,
            ),

            // These fields are not currently available
            // from OrderModel, so keep them empty.
            cashier: '',
            server: '',
            kitchenName: '',

            // BillSettlementData expects int?.
            sequence: null,

            // OrderModel does not currently expose covers.
            covers: 1,

            items: [
              for (final item in order.items)
                BillItemData(
                  name: item.name,
                  quantity: item.quantity,
                  amount: item.price * item.quantity,
                  modifiers: [
                    if (item.spiceLevel != null &&
                        item.spiceLevel!.trim().isNotEmpty)
                      item.spiceLevel!,
                    ...item.addOns,
                  ],
                ),
            ],

            // BillSettlementData expects String?,
            // while OrderModel stores PaymentMethod?.
            paymentMethod: order.paymentMethod?.label,

            cardLastFour: null,

            subtotal: _calculateSubtotal(),

            taxPercentage: _calculateTaxPercentage(),

            guestName: order.customerName,

            phoneNumber: order.customerPhone,

            sendDigitalReceipt: false,

            invoiceReference: order.id,

            // BillSettlementData requires a non-null DateTime.
            receiptDateTime: DateTime.now(),
          ),

          // The settlement screen uses this callback when it closes.
          // Returning normally lets this screen refresh its backend data.
          onClose: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );

    if (!context.mounted) {
      return;
    }

    // Re-fetch this order from Firestore so paymentStatus/paymentMethod
    // reflect the latest backend state.
    ref.invalidate(
      orderDetailProvider(order.id),
    );

    // Refresh Live Orders as well.
    await ref.read(liveOrdersProvider).load();
  }

  double _calculateSubtotal() {
    double subtotal = 0;

    for (final item in order.items) {
      subtotal += item.price * item.quantity;
    }

    return subtotal;
  }

  double _calculateTaxPercentage() {
    final subtotal = _calculateSubtotal();

    if (subtotal <= 0) {
      return 0.0;
    }

    final tax = (order.total - subtotal).clamp(
      0.0,
      double.infinity,
    );

    return (tax / subtotal) * 100;
  }

  String _orderTypeLabel(OrderType type) {
    switch (type) {
      case OrderType.dineIn:
        return 'Eat In';

      case OrderType.delivery:
        return 'Delivery';

      case OrderType.takeaway:
        return 'To Go';
    }
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  final BuildContext context;
  final bool paid;

  const _PaymentStatusBadge({
    required this.context,
    required this.paid,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(8),
        vertical: context.h(4),
      ),
      decoration: BoxDecoration(
        color: paid
            ? AppColors.primary.withValues(alpha: 0.10)
            : colors.surfaceVariant,
        borderRadius: BorderRadius.circular(
          context.h(6),
        ),
      ),
      child: Text(
        paid ? 'PAID' : 'UNPAID',
        style: AppTextStyles.label(context).copyWith(
          color: paid ? AppColors.primary : colors.textMuted,
        ),
      ),
    );
  }
}

// =============================================================================
// BILL SUMMARY
// =============================================================================

class _BillingSummary extends StatelessWidget {
  final double subtotal;
  final double tax;
  final double taxPercent;
  final double total;

  const _BillingSummary({
    required this.subtotal,
    required this.tax,
    required this.taxPercent,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return _Panel(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            context: context,
            title: 'BILL SUMMARY',
            icon: Icons.receipt_outlined,
          ),
          SizedBox(height: context.h(12)),
          _BillRow(
            context: context,
            label: 'Subtotal',
            value: '₹${subtotal.toStringAsFixed(2)}',
          ),
          SizedBox(height: context.h(7)),
          _BillRow(
            context: context,
            label: 'Tax & Surcharge (${taxPercent.toStringAsFixed(2)}%)',
            value: '₹${tax.toStringAsFixed(2)}',
          ),
          SizedBox(height: context.h(11)),
          Divider(
            height: 1,
            color: colors.divider,
          ),
          SizedBox(height: context.h(11)),
          Row(
            children: [
              Text(
                'Total Due',
                style: AppTextStyles.section(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: AppTextStyles.heading(context).copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final BuildContext context;
  final String label;
  final String value;

  const _BillRow({
    required this.context,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySecondary(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.body(context).copyWith(
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _WorkflowSection extends ConsumerWidget {
  final OrderModel order;

  const _WorkflowSection({
    required this.order,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextStatus = order.status.nextStatus;

    final buttonLabel = switch (order.status) {
      OrderStatus.pending => 'Move to Preparing',
      OrderStatus.preparing => 'Mark Ready',
      OrderStatus.ready => 'Mark Delivered',
      OrderStatus.delivered => 'Delivered',
      OrderStatus.cancelled => 'Cancelled',
    };

    return _Panel(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            context: context,
            title: 'WORKFLOW',
            icon: Icons.sync_alt_outlined,
          ),
          SizedBox(height: context.h(12)),

          // Order workflow action only.
          //
          // The current-stage row has intentionally been removed.
          // The workflow is responsible only for moving the order:
          // Pending -> Preparing -> Ready -> Delivered.
          Row(
            children: [
              Expanded(
                child: _WorkflowButton(
                  context: context,
                  label: buttonLabel,
                  icon: Icons.arrow_forward_outlined,
                  enabled: nextStatus != null,
                  onPressed: nextStatus == null
                      ? null
                      : () async {
                          try {
                            // Update the order state in the backend.
                            await OrderService().updateOrderStatus(
                              order.id,
                              nextStatus,
                            );

                            if (!context.mounted) return;

                            // Refresh this order's details from Firestore.
                            ref.invalidate(
                              orderDetailProvider(order.id),
                            );

                            // Refresh Live Orders as well.
                            await ref.read(liveOrdersProvider).load();

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Order moved to ${nextStatus.label}.',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to update status. $e',
                                ),
                              ),
                            );
                          }
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkflowButton extends StatelessWidget {
  final BuildContext context;
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onPressed;

  const _WorkflowButton({
    required this.context,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return RdxActionButton(
      label: label,
      leadingIcon: icon,
      isPrimary: enabled,
      onPressed: onPressed,
    );
  }
}

// =============================================================================
// BOTTOM ACTION BAR
// =============================================================================

class _BottomActionBar extends StatelessWidget {
  final OrderModel order;

  const _BottomActionBar({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          context.w(20),
          context.h(10),
          context.w(20),
          context.h(14),
        ),
        decoration: BoxDecoration(
          color: AppColors.of(context).surface,
          border: Border(
            top: BorderSide(
              color: AppColors.of(context).border,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: RdxActionButton(
                label: 'Print Bill & Receipt',
                leadingIcon: Icons.print_outlined,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Sending bill to printer…',
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: context.w(10)),
            Expanded(
              child: RdxActionButton.discard(
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// COMMON UI
// =============================================================================

class _Panel extends StatelessWidget {
  final BuildContext context;
  final Widget child;

  const _Panel({
    required this.context,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        context.h(14),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(
          context.h(10),
        ),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final BuildContext context;
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.context,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: context.h(14),
          color: colors.textMuted,
        ),
        SizedBox(width: context.w(5)),
        Text(
          title,
          style: AppTextStyles.section(context).copyWith(
            color: colors.textMuted,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final BuildContext context;
  final String label;
  final bool selected;

  const _OptionTile({
    required this.context,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        vertical: context.h(8),
        horizontal: context.w(8),
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : colors.surfaceVariant,
        borderRadius: BorderRadius.circular(
          context.h(7),
        ),
        border: Border.all(
          color: selected ? AppColors.primary : colors.border,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(context).copyWith(
          color: selected ? Colors.white : colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final BuildContext context;
  final String label;
  final String value;

  const _InfoBlock({
    required this.context,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyTertiary(context).copyWith(
            color: colors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: context.h(3)),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySecondary(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
