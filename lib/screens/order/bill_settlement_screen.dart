import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/order_model.dart';
import 'package:rdx_admin/providers/order_providers.dart';
import 'package:rdx_admin/widgets/dialogs/rdx_notice_dialog.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_header.dart';

// =============================================================================
// DATA (public API — keep stable for callers)
// =============================================================================

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
  final double lateNightFee;
  final double longDistanceFee;
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
    this.lateNightFee = 0,
    this.longDistanceFee = 0,
    required this.guestName,
    required this.phoneNumber,
    required this.sendDigitalReceipt,
    required this.invoiceReference,
    required this.receiptDateTime,
  });

  double get taxAmount => subtotal * taxPercentage / 100;

  double get total => subtotal + taxAmount + lateNightFee + longDistanceFee;

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

// =============================================================================
// SCREEN
// =============================================================================

class BillSettlementScreen extends ConsumerStatefulWidget {
  final BillSettlementData bill;
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
  bool _isSettling = false;

  @override
  void initState() {
    super.initState();
    _selectedPayment = widget.bill.paymentMethod;
  }

  void _close() {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _showNotice(String message) async {
    if (!mounted) return;
    await RdxNoticeDialog.show(context, message: message);
  }

  void _printBill() {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(content: Text('Sending bill to printer…')),
    // );
  }

  Future<void> _markPaidAndComplete() async {
    if (_isSettling) return;

    final selected = _selectedPayment;
    if (selected == null || selected.trim().isEmpty) {
      await _showNotice('Please select a payment method.');
      return;
    }

    setState(() => _isSettling = true);

    try {
      await ref.read(orderServiceProvider).updatePaymentStatus(
            orderId: widget.bill.orderNumber,
            paymentMethod: _paymentMethodFromLabel(selected),
          );

      if (!mounted) return;

      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Payment recorded and order completed.')),
      // );
      _close();
    } catch (_) {
      if (!mounted) return;
      await _showNotice('Failed to complete payment. Please try again.');
    } finally {
      if (mounted) setState(() => _isSettling = false);
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
        throw ArgumentError('Unsupported payment method: $label');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bill = widget.bill;
    final narrow = MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const RdxHeader(
            title: 'Bill & Receipt settlement',
            showBackButton: true,
          ),
          Expanded(
            child: narrow
                ? SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      context.w(20),
                      context.h(12),
                      context.w(20),
                      context.h(24),
                    ),
                    child: Column(
                      children: [
                        _OrderMetaBar(bill: bill),
                        SizedBox(height: context.h(14)),
                        _PaymentMethodPanel(
                          selected: _selectedPayment,
                          total: bill.total,
                          onSelected: (v) =>
                              setState(() => _selectedPayment = v),
                        ),
                        SizedBox(height: context.h(14)),
                        _BillingPanel(bill: bill),
                        SizedBox(height: context.h(14)),
                        SizedBox(
                          height: context.h(420),
                          child: _ReceiptPanel(
                            bill: bill,
                            selectedPayment: _selectedPayment,
                          ),
                        ),
                        SizedBox(height: context.h(14)),
                        _actionButtons(context),
                      ],
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.w(20),
                      context.h(12),
                      context.w(20),
                      context.h(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.only(right: context.w(18)),
                            child: Column(
                              children: [
                                _OrderMetaBar(bill: bill),
                                SizedBox(height: context.h(14)),
                                _PaymentMethodPanel(
                                  selected: _selectedPayment,
                                  total: bill.total,
                                  onSelected: (v) =>
                                      setState(() => _selectedPayment = v),
                                ),
                                SizedBox(height: context.h(14)),
                                _BillingPanel(bill: bill),
                              ],
                            ),
                          ),
                        ),
                        VerticalDivider(
                          width: context.w(1),
                          thickness: 1,
                          color: colors.border,
                        ),
                        // Right column — receipt + actions (like create menu preview)
                        SizedBox(
                          width: context.w(340),
                          child: Padding(
                            padding: EdgeInsets.only(left: context.w(18)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _ReceiptPanel(
                                    bill: bill,
                                    selectedPayment: _selectedPayment,
                                  ),
                                ),
                                SizedBox(height: context.h(12)),
                                _actionButtons(context),
                              ],
                            ),
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

  /// Stacked under the receipt (desktop right column / mobile below receipt).
  Widget _actionButtons(BuildContext context) {
    final hasPayment =
        _selectedPayment != null && _selectedPayment!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RdxActionButton(
          label: 'Print bill & receipt',
          leadingIcon: Icons.print_outlined,
          isPrimary: true,
          // Print only after a payment method is chosen
          onPressed: (_isSettling || !hasPayment) ? null : _printBill,
        ),
        SizedBox(height: context.h(10)),
        RdxActionButton(
          label: _isSettling ? 'Processing…' : 'Mark paid & complete',
          leadingIcon: Icons.check_circle_outline,
          isPrimary: true,
          onPressed: (_isSettling || !hasPayment) ? null : _markPaidAndComplete,
        ),
        SizedBox(height: context.h(10)),
        RdxActionButton(
          label: 'Close',
          isPrimary: false,
          onPressed: _isSettling ? null : _close,
        ),
      ],
    );
  }
}

// =============================================================================
// ORDER META BAR
// =============================================================================

class _OrderMetaBar extends StatelessWidget {
  final BillSettlementData bill;

  const _OrderMetaBar({required this.bill});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.h(14)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order id — same label/value style as order type below
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _metaItem(
                  context,
                  colors,
                  'Order ID',
                  bill.orderNumber,
                ),
              ),
              _pill(
                context,
                colors,
                label: bill.paymentMethod != null ? 'Paid' : 'Unpaid',
                color: bill.paymentMethod != null
                    ? const Color(0xFF20B47A)
                    : const Color(0xFFE9A719),
              ),
            ],
          ),
          SizedBox(height: context.h(14)),
          Divider(height: 1, color: colors.divider),
          SizedBox(height: context.h(12)),
          LayoutBuilder(
            builder: (context, c) {
              final stack = c.maxWidth < 420;
              final items = [
                _metaItem(context, colors, 'Order type', bill.orderType),
                _metaItem(
                  context,
                  colors,
                  'Table',
                  bill.tableNumber?.trim().isNotEmpty == true
                      ? bill.tableNumber!
                      : '—',
                ),
                _metaItem(
                  context,
                  colors,
                  'Time',
                  _formatTime(bill.receiptDateTime),
                ),
              ];
              if (stack) {
                return Column(
                  children: [
                    for (int i = 0; i < items.length; i++) ...[
                      items[i],
                      if (i < items.length - 1) SizedBox(height: context.h(10)),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    Expanded(child: items[i]),
                    if (i < items.length - 1) SizedBox(width: context.w(12)),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _metaItem(
    BuildContext context,
    AppColorScheme colors,
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label(context).copyWith(
            color: colors.textMuted,
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

  Widget _pill(
    BuildContext context,
    AppColorScheme colors, {
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(5),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(context.h(20)),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(context).copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// dd mmm yy · hh:mm
  String _formatTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final yy = (dt.year % 100).toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$d ${_month(dt.month)} $yy · $h:$m';
  }

  String _month(int m) {
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
    return months[m - 1];
  }
}

// =============================================================================
// PAYMENT METHOD
// =============================================================================

class _PaymentMethodPanel extends StatelessWidget {
  final String? selected;
  final double total;
  final ValueChanged<String> onSelected;

  const _PaymentMethodPanel({
    required this.selected,
    required this.total,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final methods = [
      _Method(
        id: 'Cash',
        title: 'Cash',
        // subtitle: '',
        icon: Icons.payments_outlined,
      ),
      _Method(
        id: 'Card',
        title: 'Credit / Debit',
        // subtitle: 'Credit / Debit',
        icon: Icons.credit_card_outlined,
      ),
      _Method(
        id: 'UPI',
        title: 'UPI / QR',
        // subtitle: 'Instant scan',
        icon: Icons.qr_code_scanner,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.h(14)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment_outlined,
                size: context.h(18),
                color: AppColors.primary,
              ),
              SizedBox(width: context.w(8)),
              Text(
                'Payment method',
                style: AppTextStyles.section(context).copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(14)),
          LayoutBuilder(
            builder: (context, c) {
              final stack = c.maxWidth < 420;
              if (stack) {
                return Column(
                  children: [
                    for (int i = 0; i < methods.length; i++) ...[
                      _methodTile(context, colors, methods[i]),
                      if (i < methods.length - 1)
                        SizedBox(height: context.h(8)),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (int i = 0; i < methods.length; i++) ...[
                    Expanded(child: _methodTile(context, colors, methods[i])),
                    if (i < methods.length - 1) SizedBox(width: context.w(8)),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _methodTile(BuildContext context, AppColorScheme colors, _Method m) {
    final isSelected = selected == m.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelected(m.id),
        borderRadius: BorderRadius.circular(context.h(10)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: context.w(10),
            vertical: context.h(14),
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(context.h(10)),
            border: Border.all(
              color: isSelected ? AppColors.primary : colors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                m.icon,
                size: context.h(22),
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textPrimary.withAlpha(90),
              ),
              SizedBox(height: context.h(8)),
              Text(
                m.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.label(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Method {
  final String id;
  final String title;
  // final String subtitle;
  final IconData icon;

  const _Method({
    required this.id,
    required this.title,
    // required this.subtitle,
    required this.icon,
  });
}

// =============================================================================
// BILLING
// =============================================================================

class _BillingPanel extends StatelessWidget {
  final BillSettlementData bill;

  const _BillingPanel({required this.bill});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.h(14)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                size: context.h(18),
                color: AppColors.primary,
              ),
              SizedBox(width: context.w(8)),
              Text(
                'Billing summary',
                style: AppTextStyles.section(context).copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(14)),
          // Items list
          for (final item in bill.items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.quantity}× ${item.name}',
                        style: AppTextStyles.bodySecondary(context).copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.modifiers.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: context.h(2)),
                          child: Text(
                            item.modifiers.join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(context).copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '₹${item.amount.toStringAsFixed(2)}',
                  style: AppTextStyles.bodySecondary(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(10)),
          ],
          Divider(height: 1, color: colors.divider),
          SizedBox(height: context.h(10)),
          _amountRow(
            context,
            colors,
            'Subtotal (${bill.items.length} items)',
            bill.subtotal,
          ),
          SizedBox(height: context.h(6)),
          _amountRow(
            context,
            colors,
            'GST (${bill.taxPercentage.toStringAsFixed(0)}%)',
            bill.taxAmount,
          ),
          if (bill.lateNightFee > 0) ...[
            SizedBox(height: context.h(6)),
            _amountRow(
                context, colors, 'Late Night Delivery', bill.lateNightFee),
          ],
          if (bill.longDistanceFee > 0) ...[
            SizedBox(height: context.h(6)),
            _amountRow(
                context, colors, 'Long Distance Fee', bill.longDistanceFee),
          ],
          SizedBox(height: context.h(12)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: context.w(12),
              vertical: context.h(12),
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(context.h(8)),
            ),
            child: Row(
              children: [
                Text(
                  'Total due',
                  style: AppTextStyles.section(context).copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${bill.total.toStringAsFixed(2)}',
                  style: AppTextStyles.section(context).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(
    BuildContext context,
    AppColorScheme colors,
    String label,
    double amount,
  ) {
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
          '₹${amount.toStringAsFixed(2)}',
          style: AppTextStyles.bodySecondary(context).copyWith(
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// RECEIPT PREVIEW
// =============================================================================

class _ReceiptPanel extends StatelessWidget {
  final BillSettlementData bill;
  final String? selectedPayment;

  const _ReceiptPanel({
    required this.bill,
    required this.selectedPayment,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(14),
              context.h(12),
              context.w(14),
              context.h(10),
            ),
            child: Row(
              children: [
                Text(
                  'Receipt',
                  style: AppTextStyles.section(context).copyWith(
                    color: colors.textPrimary,
                  ),
                )
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(context.w(16)),
              child: Column(
                children: [
                  // Restaurant header
                  Container(
                    width: context.h(44),
                    height: context.h(44),
                    decoration: BoxDecoration(
                      color: colors.textPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.restaurant,
                      size: context.h(22),
                      color: colors.surface,
                    ),
                  ),
                  SizedBox(height: context.h(8)),
                  Text(
                    bill.restaurantName,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.section(context).copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    _formatFullDate(bill.receiptDateTime),
                    style: AppTextStyles.bodyTertiary(context).copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  SizedBox(height: context.h(14)),
                  Divider(height: 1, color: colors.border),
                  SizedBox(height: context.h(10)),
                  _receiptInfoRow(
                    context,
                    colors,
                    'Order ID',
                    '#${_shortId(bill.orderNumber)}',
                  ),
                  _receiptInfoRow(
                    context,
                    colors,
                    'Table No.',
                    bill.tableNumber?.trim().isNotEmpty == true
                        ? bill.tableNumber!
                        : '—',
                  ),
                  if (bill.guestName.trim().isNotEmpty &&
                      bill.guestName.trim().toLowerCase() != 'walk-in customer')
                    _receiptInfoRow(
                      context,
                      colors,
                      'Guest',
                      bill.guestName,
                    ),
                  SizedBox(height: context.h(10)),
                  Divider(height: 1, color: colors.border),
                  SizedBox(height: context.h(10)),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Item',
                          style: AppTextStyles.label(context).copyWith(
                            color: colors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'Amount',
                        style: AppTextStyles.label(context).copyWith(
                          color: colors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.h(8)),
                  for (final item in bill.items) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity}× ${item.name}',
                            style:
                                AppTextStyles.bodySecondary(context).copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '₹${item.amount.toStringAsFixed(2)}',
                          style: AppTextStyles.bodySecondary(context).copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (item.modifiers.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          top: context.h(2),
                          left: context.w(12),
                        ),
                        child: Text(
                          item.modifiers.join(', '),
                          style: AppTextStyles.caption(context).copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    SizedBox(height: context.h(8)),
                  ],
                  Divider(height: 1, color: colors.border),
                  SizedBox(height: context.h(8)),
                  _receiptMoneyRow(
                    context,
                    colors,
                    'Subtotal',
                    bill.subtotal,
                  ),
                  SizedBox(height: context.h(4)),
                  _receiptMoneyRow(
                    context,
                    colors,
                    'GST (${bill.taxPercentage.toStringAsFixed(0)}%)',
                    bill.taxAmount,
                  ),
                  if (bill.lateNightFee > 0) ...[
                    SizedBox(height: context.h(4)),
                    _receiptMoneyRow(context, colors, 'Late Night Delivery',
                        bill.lateNightFee),
                  ],
                  if (bill.longDistanceFee > 0) ...[
                    SizedBox(height: context.h(4)),
                    _receiptMoneyRow(context, colors, 'Long Distance Fee',
                        bill.longDistanceFee),
                  ],
                  SizedBox(height: context.h(10)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(10),
                      vertical: context.h(10),
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(context.h(8)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Total',
                          style: AppTextStyles.label(context).copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₹${bill.total.toStringAsFixed(2)}',
                          style: AppTextStyles.section(context).copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.h(12)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(context.h(10)),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(context.h(8)),
                    ),
                    child: Text(
                      'Payment: ${(selectedPayment ?? 'Not selected')}',
                      style: AppTextStyles.label(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: context.h(16)),
                  Text(
                    'Thank you for dining with us!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label(context).copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    'Please visit again soon.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label(context).copyWith(
                      color: colors.textSecondary,
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

  Widget _receiptInfoRow(
    BuildContext context,
    AppColorScheme colors,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.label(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodySecondary(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _receiptMoneyRow(
    BuildContext context,
    AppColorScheme colors,
    String label,
    double amount,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.label(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: AppTextStyles.bodySecondary(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return id.substring(id.length - 8);
  }

  String _formatFullDate(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'PM' : 'AM';
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m $p';
  }
}
