import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/order_model.dart';
import 'package:rdx_admin/providers/order_providers.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';

class BillSettlementData {
  final String orderNumber;
  final String restaurantName;
  final String orderType;
  final String? tableNumber;
  final String billingMode;
  final String cashier;
  final String server;
  final String kitchenName;
  final int? sequence;
  final int covers;
  final List<BillItemData> items;
  final String? paymentMethod;
  final String? cardLastFour;
  final double subtotal;
  final double taxPercentage;
  final String guestName;
  final String phoneNumber;
  final bool sendDigitalReceipt;
  final String invoiceReference;
  final DateTime receiptDateTime;

  BillSettlementData({
    required this.orderNumber,
    required this.restaurantName,
    required this.orderType,
    this.tableNumber,
    required this.billingMode,
    required this.cashier,
    required this.server,
    required this.kitchenName,
    this.sequence,
    required this.covers,
    required this.items,
    this.paymentMethod,
    this.cardLastFour,
    required this.subtotal,
    required this.taxPercentage,
    required this.guestName,
    required this.phoneNumber,
    required this.sendDigitalReceipt,
    required this.invoiceReference,
    required this.receiptDateTime,
  });

  double get taxAmount => subtotal * taxPercentage / 100;

  double get total => subtotal + taxAmount;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
}

class BillItemData {
  final String name;
  final int quantity;
  final double amount;
  final List<String> modifiers;

  const BillItemData({
    required this.name,
    required this.quantity,
    required this.amount,
    this.modifiers = const [],
  });
}

class BillSettlementScreen extends ConsumerStatefulWidget {
  final BillSettlementData bill;

  /// Pass this from the Live Orders screen if you want
  /// Close to explicitly navigate back to that screen.
  final VoidCallback? onClose;

  const BillSettlementScreen({
    super.key,
    required this.bill,
    this.onClose,
  });

  @override
  ConsumerState<BillSettlementScreen> createState() =>
      _BillSettlementScreenState();
}

class _BillSettlementScreenState extends ConsumerState<BillSettlementScreen> {
  String? _selectedPayment;
  bool _sendDigitalReceipt = false;
  bool _isSettling = false;

  final TextEditingController _guestController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _selectedPayment = widget.bill.paymentMethod;
    _sendDigitalReceipt = widget.bill.sendDigitalReceipt;

    _guestController.text = widget.bill.guestName;
    _phoneController.text = widget.bill.phoneNumber;
  }

  @override
  void dispose() {
    _guestController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _close() {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }

    // Navigator.of(context).pop();
    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  }

  void _printBill() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Print request is not configured yet.',
        ),
      ),
    );
  }

  Future<void> _markPaidAndComplete() async {
    // Prevent multiple settlement requests.
    if (_isSettling) {
      return;
    }

    final selectedPayment = _selectedPayment;

    // Payment method is mandatory.
    if (selectedPayment == null || selectedPayment.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a payment method.',
          ),
        ),
      );
      return;
    }

    final paymentMethod = _paymentMethodFromLabel(
      selectedPayment,
    );

    setState(() {
      _isSettling = true;
    });

    try {
      await ref.read(orderServiceProvider).settleOrder(
            orderId: widget.bill.orderNumber,
            paymentMethod: paymentMethod,
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment recorded and order completed.',
          ),
        ),
      );

      // Order is now:
      // payment_status = paid
      // payment_method = selected method
      // status = delivered
      //
      // Therefore it will leave Live Orders automatically.
      _close();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to complete payment. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSettling = false;
        });
      }
    }
  }

  PaymentMethod _paymentMethodFromLabel(String label) {
    switch (label.trim()) {
      case 'Cash':
        return PaymentMethod.cash;

      case 'Card':
        return PaymentMethod.card;

      case 'UPI':
        return PaymentMethod.upi;

      case 'Online':
        return PaymentMethod.online;

      case 'Split':
        return PaymentMethod.split;

      default:
        throw ArgumentError(
          'Unsupported payment method: $label',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bill = widget.bill;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _SettlementHeader(
              bill: bill,
              onBack: _close,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      context.w(8),
                      context.h(5),
                      context.w(8),
                      context.h(8),
                    ),
                    child: _SettlementBody(
                      bill: bill,
                      selectedPayment: _selectedPayment,
                      sendDigitalReceipt: _sendDigitalReceipt,
                      guestController: _guestController,
                      phoneController: _phoneController,
                      onPaymentChanged: (value) {
                        setState(() {
                          _selectedPayment = value;
                        });
                      },
                      onDigitalReceiptChanged: (value) {
                        setState(() {
                          _sendDigitalReceipt = value;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            _BottomActions(
              onPrint: _printBill,
              onComplete: _markPaidAndComplete,
              onClose: _close,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HEADER
// ============================================================================

class _SettlementHeader extends StatelessWidget {
  final BillSettlementData bill;
  final VoidCallback onBack;

  const _SettlementHeader({
    required this.bill,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(8),
        context.h(6),
        context.w(8),
        context.h(5),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(
              context.h(5),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(4),
                vertical: context.h(3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new,
                    size: context.h(8),
                    color: colors.textSecondary,
                  ),
                  SizedBox(width: context.w(3)),
                  Text(
                    'Back to Live Orders',
                    style: AppTextStyles.caption(context).copyWith(
                      fontSize: context.h(8),
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: context.w(10)),
          Container(
            width: 1,
            height: context.h(22),
            color: colors.border,
          ),
          SizedBox(width: context.w(9)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bill & Receipt Settlement',
                  style: AppTextStyles.heading(context).copyWith(
                    fontSize: context.h(13),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: context.h(1)),
                Text(
                  'Order #${bill.orderNumber}  •  ${bill.restaurantName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: context.h(7),
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _HeaderPill(
            icon: Icons.local_offer_outlined,
            text: '#${bill.orderNumber}',
            highlighted: true,
          ),
          SizedBox(width: context.w(4)),
          _HeaderPill(
            icon: Icons.table_restaurant_outlined,
            text: '${bill.orderType} • ${bill.tableNumber}',
          ),
          SizedBox(width: context.w(4)),
          _StatusPill(
            text: 'UNPAID',
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool highlighted;

  const _HeaderPill({
    required this.icon,
    required this.text,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(7),
        vertical: context.h(5),
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primary.withValues(alpha: 0.12)
            : colors.surfaceVariant,
        borderRadius: BorderRadius.circular(
          context.h(6),
        ),
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.55)
              : colors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: context.h(8),
            color: highlighted ? AppColors.primary : colors.textSecondary,
          ),
          SizedBox(width: context.w(3)),
          Text(
            text,
            style: AppTextStyles.caption(context).copyWith(
              fontSize: context.h(7),
              color: highlighted ? AppColors.primary : colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;

  const _StatusPill({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(7),
        vertical: context.h(5),
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(
          context.h(6),
        ),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption(context).copyWith(
          fontSize: context.h(6.5),
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ============================================================================
// MAIN BODY
// ============================================================================
class _SettlementBody extends StatelessWidget {
  final BillSettlementData bill;
  final String? selectedPayment;
  final bool sendDigitalReceipt;
  final TextEditingController guestController;
  final TextEditingController phoneController;
  final ValueChanged<String> onPaymentChanged;
  final ValueChanged<bool> onDigitalReceiptChanged;

  const _SettlementBody({
    required this.bill,
    required this.selectedPayment,
    required this.sendDigitalReceipt,
    required this.guestController,
    required this.phoneController,
    required this.onPaymentChanged,
    required this.onDigitalReceiptChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 56,
          child: Column(
            children: [
              _OrderInformationCard(
                bill: bill,
              ),
              SizedBox(height: context.h(7)),
              _PaymentCard(
                selectedPayment: selectedPayment,
                total: bill.total,
                cardLastFour: bill.cardLastFour,
                onPaymentChanged: onPaymentChanged,
              ),
              SizedBox(height: context.h(7)),
              _BillingCalculationCard(
                bill: bill,
              ),
              SizedBox(height: context.h(7)),
              _CustomerDetailsCard(
                guestController: guestController,
                phoneController: phoneController,
                sendDigitalReceipt: sendDigitalReceipt,
                onDigitalReceiptChanged: onDigitalReceiptChanged,
              ),
            ],
          ),
        ),
        SizedBox(width: context.w(7)),
        Expanded(
          flex: 44,
          child: Column(
            children: [
              _KitchenInformationCard(
                bill: bill,
              ),
              SizedBox(height: context.h(7)),
              _ReceiptPreview(
                bill: bill,
                selectedPayment: selectedPayment,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// ORDER INFORMATION
// ============================================================================
class _OrderInformationCard extends StatelessWidget {
  final BillSettlementData bill;

  const _OrderInformationCard({
    required this.bill,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return _SettlementCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(5),
                  vertical: context.h(3),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    context.h(5),
                  ),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  '♟  CREATED LOCALLY BY STAFF',
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: context.h(6),
                    color: Colors.orange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDateTime(bill.receiptDateTime),
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: context.h(6.5),
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(8)),
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  label: 'ORDER TYPE',
                  value: bill.orderType,
                ),
              ),
              Expanded(
                child: _InfoItem(
                  label: 'BILLING MODE',
                  value: bill.billingMode,
                ),
              ),
              Expanded(
                child: _InfoItem(
                  label: 'TABLE',
                  value: bill.tableNumber ?? '—',
                ),
              ),
              Expanded(
                child: _InfoItem(
                  label: 'CASHIER',
                  value: bill.cashier,
                ),
              ),
              Expanded(
                child: _InfoItem(
                  label: 'SERVING',
                  value: '${bill.server}\n(Waiter)',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime dateTime) {
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';

  return '${dateTime.day.toString().padLeft(2, '0')} '
      '${_monthName(dateTime.month)} '
      '${dateTime.year}, '
      '$hour:$minute $period';
}

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return months[month - 1];
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(5),
      ),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: colors.border,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption(context).copyWith(
              fontSize: context.h(5.5),
              color: colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: context.h(2)),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(
              fontSize: context.h(7),
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PAYMENT
// ============================================================================

class _PaymentCard extends StatelessWidget {
  final String? selectedPayment;
  final double total;
  final String? cardLastFour;
  final ValueChanged<String> onPaymentChanged;

  const _PaymentCard({
    required this.selectedPayment,
    required this.total,
    required this.onPaymentChanged,
    this.cardLastFour,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return _SettlementCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Payment Method',
                style: AppTextStyles.section(context).copyWith(
                  fontSize: context.h(11),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'TAP OR KEY F1-F4',
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: context.h(5.5),
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(7)),
          Row(
            children: [
              Expanded(
                child: _PaymentMethod(
                  title: 'Cash',
                  subtitle: '₹${total.toStringAsFixed(2)} / CHANGE',
                  icon: Icons.payments_outlined,
                  selected: selectedPayment == 'Cash',
                  onTap: () => onPaymentChanged('Cash'),
                ),
              ),
              SizedBox(width: context.w(4)),
              Expanded(
                child: _PaymentMethod(
                  title: 'Credit / Debit',
                  subtitle: 'CARD TERMINAL',
                  icon: Icons.credit_card_outlined,
                  selected: selectedPayment == 'Card',
                  onTap: () => onPaymentChanged('Card'),
                ),
              ),
              SizedBox(width: context.w(4)),
              Expanded(
                child: _PaymentMethod(
                  title: 'UPI / QR',
                  subtitle: 'INSTANT SCAN',
                  icon: Icons.qr_code_scanner,
                  selected: selectedPayment == 'UPI',
                  onTap: () => onPaymentChanged('UPI'),
                ),
              ),
              SizedBox(width: context.w(4)),
              Expanded(
                child: _PaymentMethod(
                  title: 'Split Bill',
                  subtitle: 'CUSTOM BILL',
                  icon: Icons.call_split,
                  selected: selectedPayment == 'Split',
                  onTap: () => onPaymentChanged('Split'),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(5)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(7),
              vertical: context.h(5),
            ),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(
                context.h(5),
              ),
              border: Border.all(
                color: colors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: context.h(8),
                  color: Colors.orange,
                ),
                SizedBox(width: context.w(4)),
                Expanded(
                  child: Text(
                    selectedPayment == 'Card'
                        ? 'Card Number Ready: Swipe For ₹${total.toStringAsFixed(2)}'
                        : 'Payment method selected: $selectedPayment',
                    style: AppTextStyles.caption(context).copyWith(
                      fontSize: context.h(6),
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  'Online',
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: context.h(6),
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
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

class _PaymentMethod extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethod({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        context.h(7),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: context.h(61),
        padding: EdgeInsets.all(
          context.h(5),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: context.h(13),
              color: selected ? Colors.white : colors.textPrimary,
            ),
            SizedBox(height: context.h(3)),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                fontSize: context.h(7),
                color: selected ? Colors.white : colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: context.h(1)),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                fontSize: context.h(5.5),
                color: selected
                    ? Colors.white.withValues(alpha: 0.85)
                    : colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BILLING CALCULATION
// ============================================================================

class _BillingCalculationCard extends StatelessWidget {
  final BillSettlementData bill;

  const _BillingCalculationCard({
    required this.bill,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return _SettlementCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Billing Computation',
                style: AppTextStyles.section(context).copyWith(
                  fontSize: context.h(11),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'CURRENCY: USD (\$)',
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: context.h(5.5),
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(5)),
          Divider(
            height: 1,
            color: colors.divider,
          ),
          SizedBox(height: context.h(5)),
          _BillingRow(
            label:
                'Subtotal (${bill.items.length} Items, ${bill.totalQuantity} Units)',
            value: '\$${bill.subtotal.toStringAsFixed(2)}',
          ),
          SizedBox(height: context.h(4)),
          _BillingRow(
            label:
                'State Dining Tax (${bill.taxPercentage.toStringAsFixed(0)}%)',
            value: '\$${bill.taxAmount.toStringAsFixed(2)}',
          ),
          SizedBox(height: context.h(5)),
          Row(
            children: [
              Text(
                'Tax :',
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: context.h(7),
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(width: context.w(6)),
              _TaxChip(
                label: 'CGST 0%',
                value: '+\$0.00',
              ),
              SizedBox(width: context.w(4)),
              _TaxChip(
                label: 'SGST 0%',
                value: '+\$0.00',
              ),
              SizedBox(width: context.w(4)),
              _TaxChip(
                label: 'IGST ${bill.taxPercentage.toStringAsFixed(0)}%',
                value: '+\$${bill.taxAmount.toStringAsFixed(2)}',
              ),
            ],
          ),
          SizedBox(height: context.h(8)),
          Divider(
            height: 1,
            color: colors.divider,
          ),
          SizedBox(height: context.h(7)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL AMOUNT DUE',
                    style: AppTextStyles.label(context).copyWith(
                      fontSize: context.h(7),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: context.h(1)),
                  Text(
                    'Includes of Taxes & Tips',
                    style: AppTextStyles.caption(context).copyWith(
                      fontSize: context.h(5.5),
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '\$${bill.total.toStringAsFixed(2)}',
                style: AppTextStyles.heading(context).copyWith(
                  fontSize: context.h(22),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillingRow extends StatelessWidget {
  final String label;
  final String value;

  const _BillingRow({
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
            style: AppTextStyles.caption(context).copyWith(
              fontSize: context.h(7),
              color: colors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.caption(context).copyWith(
            fontSize: context.h(7),
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TaxChip extends StatelessWidget {
  final String label;
  final String value;

  const _TaxChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(4),
          vertical: context.h(4),
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(
            context.h(5),
          ),
          border: Border.all(
            color: colors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: context.h(5.5),
                  color: colors.textMuted,
                ),
              ),
            ),
            SizedBox(width: context.w(2)),
            Text(
              value,
              style: AppTextStyles.caption(context).copyWith(
                fontSize: context.h(5.5),
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CUSTOMER
// ============================================================================

class _CustomerDetailsCard extends StatelessWidget {
  final TextEditingController guestController;
  final TextEditingController phoneController;
  final bool sendDigitalReceipt;
  final ValueChanged<bool> onDigitalReceiptChanged;

  const _CustomerDetailsCard({
    required this.guestController,
    required this.phoneController,
    required this.sendDigitalReceipt,
    required this.onDigitalReceiptChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return _SettlementCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: context.h(10),
                color: colors.textPrimary,
              ),
              SizedBox(width: context.w(4)),
              Text(
                'Customer Details',
                style: AppTextStyles.section(context).copyWith(
                  fontSize: context.h(10),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'OPTIONAL FOR WALK-IN',
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: context.h(5.5),
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(5)),
          Row(
            children: [
              Expanded(
                child: _CustomerField(
                  label: 'GUEST NAME',
                  controller: guestController,
                ),
              ),
              SizedBox(width: context.w(6)),
              Expanded(
                child: _CustomerField(
                  label: 'PHONE / SMS RECEIPT',
                  controller: phoneController,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(5)),
          InkWell(
            onTap: () {
              onDigitalReceiptChanged(
                !sendDigitalReceipt,
              );
            },
            child: Row(
              children: [
                SizedBox(
                  width: context.h(12),
                  height: context.h(12),
                  child: Checkbox(
                    value: sendDigitalReceipt,
                    onChanged: (value) {
                      onDigitalReceiptChanged(
                        value ?? false,
                      );
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                SizedBox(width: context.w(4)),
                Text(
                  'Send digital receipt and SMS guest to RDX Loyalty program.',
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: context.h(6),
                    color: colors.textSecondary,
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

class _CustomerField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _CustomerField({
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption(context).copyWith(
            fontSize: context.h(5.5),
            color: colors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: context.h(2)),
        SizedBox(
          height: context.h(25),
          child: TextField(
            controller: controller,
            style: AppTextStyles.caption(context).copyWith(
              fontSize: context.h(7),
              color: colors.textPrimary,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.background,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.w(6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  context.h(5),
                ),
                borderSide: BorderSide(
                  color: colors.border,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  context.h(5),
                ),
                borderSide: BorderSide(
                  color: colors.border,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// KITCHEN
// ============================================================================

class _KitchenInformationCard extends StatelessWidget {
  final BillSettlementData bill;

  const _KitchenInformationCard({
    required this.bill,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return _SettlementCard(
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(
              context.h(7),
            ),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(
                context.h(7),
              ),
            ),
            child: Icon(
              Icons.restaurant,
              size: context.h(11),
              color: colors.textPrimary,
            ),
          ),
          SizedBox(width: context.w(6)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.kitchenName,
                  style: AppTextStyles.label(context).copyWith(
                    fontSize: context.h(8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: context.h(1)),
                Text(
                  '${bill.restaurantName}\n• SEQUENCE: ${bill.sequence}',
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: context.h(5.5),
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'COVERS: ${bill.covers}',
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: context.h(6),
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: context.h(3)),
              Container(
                width: context.h(22),
                height: context.h(22),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(
                    context.h(5),
                  ),
                ),
                child: Icon(
                  Icons.sync,
                  size: context.h(10),
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// RECEIPT
// ============================================================================

class _ReceiptPreview extends StatelessWidget {
  final BillSettlementData bill;
  final String? selectedPayment;

  const _ReceiptPreview({
    required this.bill,
    required this.selectedPayment,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        context.h(9),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          context.h(6),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: context.h(8),
            offset: Offset(
              0,
              context.h(2),
            ),
            color: Colors.black.withValues(alpha: 0.25),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: context.h(22),
                  height: context.h(22),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restaurant,
                    size: context.h(11),
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: context.h(4)),
                Text(
                  bill.restaurantName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.h(9),
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  '154 Grand Central Blvd, Suite 400\n'
                  'Phoenix, 85004, United States\n'
                  'Tel: +1 (555) 000-0070',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.h(5.5),
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(7)),
          _ReceiptDivider(),
          SizedBox(height: context.h(5)),
          _ReceiptInfoRow(
            leftLabel: 'Order:',
            leftValue: '#${bill.orderNumber}',
            rightLabel: 'Invoice:',
            rightValue: bill.invoiceReference,
          ),
          _ReceiptInfoRow(
            leftLabel: 'Table:',
            leftValue: bill.tableNumber ?? '',
            rightLabel: 'Server:',
            rightValue: bill.server,
          ),
          _ReceiptInfoRow(
            leftLabel: 'Time:',
            leftValue: _formatDateTime(bill.receiptDateTime),
            rightLabel: '',
            rightValue: '',
          ),
          SizedBox(height: context.h(5)),
          _ReceiptDivider(),
          SizedBox(height: context.h(5)),
          Row(
            children: [
              Expanded(
                child: Text(
                  'QTY • ITEM DESCRIPTION',
                  style: TextStyle(
                    fontSize: context.h(5.5),
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'AMOUNT',
                style: TextStyle(
                  fontSize: context.h(5.5),
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(5)),
          ...bill.items.map(
            (item) => _ReceiptItem(
              item: item,
            ),
          ),
          SizedBox(height: context.h(5)),
          _ReceiptDivider(),
          SizedBox(height: context.h(5)),
          _ReceiptMoneyRow(
            label: 'Subtotal',
            value: '\$${bill.subtotal.toStringAsFixed(2)}',
          ),
          SizedBox(height: context.h(3)),
          _ReceiptMoneyRow(
            label:
                'State Dining Tax (${bill.taxPercentage.toStringAsFixed(0)}%)',
            value: '\$${bill.taxAmount.toStringAsFixed(2)}',
          ),
          SizedBox(height: context.h(4)),
          Row(
            children: [
              Expanded(
                child: Text(
                  'TOTAL PAYABLE:',
                  style: TextStyle(
                    fontSize: context.h(7),
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '\$${bill.total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: context.h(9),
                  color: Colors.black87,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(6)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(
              context.h(6),
            ),
            decoration: BoxDecoration(
              color: const Color(0xffeef2f4),
              borderRadius: BorderRadius.circular(
                context.h(4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // 'Payment: ${selectedPayment.toUpperCase()}',
                  'Payment: ${(selectedPayment ?? 'Not selected').toUpperCase()}',
                  style: TextStyle(
                    fontSize: context.h(6),
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bill.cardLastFour == null
                            ? 'Auth Code: 934781'
                            : 'VISA (ending in ${bill.cardLastFour})',
                        style: TextStyle(
                          fontSize: context.h(5.5),
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    Text(
                      'APPROVED',
                      style: TextStyle(
                        fontSize: context.h(5.5),
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(8)),
          Center(
            child: Column(
              children: [
                Text(
                  'Thank you for dining at RDX!',
                  style: TextStyle(
                    fontSize: context.h(7),
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  'Please visit again soon.',
                  style: TextStyle(
                    fontSize: context.h(5.5),
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: context.h(7)),
                Container(
                  width: context.h(48),
                  height: context.h(48),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black87,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.qr_code_2,
                    size: context.h(42),
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: context.h(4)),
                Text(
                  'Scan for  •  WiFi  •  Menu  •  Reviews  •  Rewards',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.h(4.5),
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(7)),
          _ReceiptDivider(),
          SizedBox(height: context.h(4)),
          Center(
            child: Text(
              '• AUTO-CUTS PAPER ON FINISH SERVER: KEEP FOR DIRECT',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.h(4.5),
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptItem extends StatelessWidget {
  final BillItemData item;

  const _ReceiptItem({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: context.h(5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.quantity}x ${item.name}',
                  style: TextStyle(
                    fontSize: context.h(6.5),
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.modifiers.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      top: context.h(2),
                      left: context.w(7),
                    ),
                    child: Text(
                      '• ${item.modifiers.join(', ')}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.h(5),
                        color: Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '\$${item.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: context.h(6.5),
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptMoneyRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptMoneyRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: context.h(6),
              color: Colors.black54,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: context.h(6),
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReceiptInfoRow extends StatelessWidget {
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  const _ReceiptInfoRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: context.h(2),
      ),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: leftLabel.isEmpty ? '' : '$leftLabel ',
                    style: TextStyle(
                      fontSize: context.h(5),
                      color: Colors.black54,
                    ),
                  ),
                  TextSpan(
                    text: leftValue,
                    style: TextStyle(
                      fontSize: context.h(5),
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (rightLabel.isNotEmpty)
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$rightLabel ',
                    style: TextStyle(
                      fontSize: context.h(5),
                      color: Colors.black54,
                    ),
                  ),
                  TextSpan(
                    text: rightValue,
                    style: TextStyle(
                      fontSize: context.h(5),
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
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

class _ReceiptDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        '---------------------------------------------',
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(
          fontSize: context.h(4),
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}

// ============================================================================
// BOTTOM ACTIONS
// ============================================================================

class _BottomActions extends StatelessWidget {
  final VoidCallback onPrint;
  final VoidCallback onComplete;
  final VoidCallback onClose;

  const _BottomActions({
    required this.onPrint,
    required this.onComplete,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(8),
        context.h(5),
        context.w(8),
        context.h(7),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.border,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: RdxActionButton(
                  label: 'Print Bill & Receipt',
                  isPrimary: true,
                  onPressed: onPrint,
                ),
              ),
              SizedBox(width: context.w(5)),
              Expanded(
                child: RdxActionButton(
                  label: 'Mark Paid & Complete',
                  isPrimary: true,
                  onPressed: onComplete,
                ),
              ),
              SizedBox(width: context.w(5)),
              SizedBox(
                width: context.w(35),
                child: RdxActionButton(
                  label: '',
                  isPrimary: false,
                  onPressed: onPrint,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(5)),
          SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(
                context.h(6),
              ),
              child: Container(
                height: context.h(30),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(
                    context.h(6),
                  ),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chevron_left,
                      size: context.h(11),
                      color: colors.textPrimary,
                    ),
                    SizedBox(width: context.w(3)),
                    Text(
                      'Close',
                      style: AppTextStyles.label(context).copyWith(
                        fontSize: context.h(8),
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// REUSABLE CARD
// ============================================================================

class _SettlementCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _SettlementCard({
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: padding ??
          EdgeInsets.all(
            context.h(9),
          ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(
          context.h(7),
        ),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: child,
    );
  }
}
