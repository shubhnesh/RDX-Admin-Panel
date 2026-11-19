import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/order_model.dart';
import 'package:rdx_admin/providers/order_providers.dart';
import 'package:rdx_admin/providers/settings_provider.dart';
import 'package:rdx_admin/widgets/dialogs/rdx_notice_dialog.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/buttons/rdx_toggle_button.dart';
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
  final String deliveryAddress;
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
    this.deliveryAddress = '',
    required this.sendDigitalReceipt,
    required this.invoiceReference,
    required this.receiptDateTime,
  });

  BillSettlementData withFees({
    required double lateNightFee,
    required double longDistanceFee,
  }) {
    return BillSettlementData(
      orderNumber: orderNumber,
      restaurantName: restaurantName,
      orderType: orderType,
      tableNumber: tableNumber,
      billingMode: billingMode,
      cashier: cashier,
      server: server,
      kitchenName: kitchenName,
      sequence: sequence,
      covers: covers,
      items: items,
      paymentMethod: paymentMethod,
      cardLastFour: cardLastFour,
      subtotal: subtotal,
      taxPercentage: taxPercentage,
      lateNightFee: lateNightFee,
      longDistanceFee: longDistanceFee,
      guestName: guestName,
      phoneNumber: phoneNumber,
      deliveryAddress: deliveryAddress,
      sendDigitalReceipt: sendDigitalReceipt,
      invoiceReference: invoiceReference,
      receiptDateTime: receiptDateTime
    );
  }

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
  final ValueChanged<OrderModel>? onSettled;

  const BillSettlementScreen({
    super.key,
    required this.bill,
    this.onClose,
    this.onSettled,
  });

  @override
  ConsumerState<BillSettlementScreen> createState() =>
      _BillSettlementScreenState();
}

class _BillSettlementScreenState extends ConsumerState<BillSettlementScreen> {
  String? _selectedPayment;
  bool _isSettling = false;

  /// Per-order fee toggles — staff decide at settlement, not from global settings.
  bool _applyLateNightFee = false;
  bool _applyLongDistanceFee = false;

  @override
  void initState() {
    super.initState();
    _selectedPayment = widget.bill.paymentMethod;
    // Pre-check if the order already carried these fees from create time.
    _applyLateNightFee = widget.bill.lateNightFee > 0;
    _applyLongDistanceFee = widget.bill.longDistanceFee > 0;
  }

  /// Bill snapshot with the fees the staff toggled on this screen.
  BillSettlementData get _effectiveBill {
    final settings = ref.read(settingsProvider);
    final lateNight = _applyLateNightFee
        ? (widget.bill.lateNightFee > 0
            ? widget.bill.lateNightFee
            : settings.lateNightFee)
        : 0.0;
    final longDistance = _applyLongDistanceFee
        ? (widget.bill.longDistanceFee > 0
            ? widget.bill.longDistanceFee
            : settings.longDistanceFee)
        : 0.0;
    return widget.bill.withFees(
      lateNightFee: lateNight,
      longDistanceFee: longDistance
    );
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

    // Map UI labels → Cloud Function values (cash | upi | card only).
    final method = _paymentMethodString(selected);
    if (method == null) {
      await _showNotice('Unsupported payment method. Use Cash, UPI or Card.');
      return;
    }

    setState(() => _isSettling = true);

    try {
      // Secure path — marks paid + applies optional per-order fees server-side.
      final settledOrder = await ref.read(orderServiceProvider).settleOrder(
            orderId: widget.bill.orderNumber,
            paymentMethod: method,
            applyLateNightFee: _applyLateNightFee,
            applyLongDistanceFee: _applyLongDistanceFee
          );
      widget.onSettled?.call(settledOrder);

      if (!mounted) return;
      _close();
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      await _showNotice(
        message.isNotEmpty
            ? message
            : 'Failed to complete payment. Please try again.'
      );
    } finally {
      if (mounted) setState(() => _isSettling = false);
    }
  }

  /// Converts the payment tile label to the string expected by settleOrder.
  String? _paymentMethodString(String label) {
    switch (label.trim().toLowerCase()) {
      case 'cash':
        return 'cash';
      case 'card':
      case 'credit / debit':
        return 'card';
      case 'upi':
      case 'upi / qr':
        return 'upi';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final settings = ref.watch(settingsProvider);
    final bill = _effectiveBill;
    final narrow = MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const RdxHeader(
            title: 'Bill & Receipt settlement',
            showBackButton: true
          ),
          Expanded(
            child: narrow
                ? SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      context.w(20),
                      context.h(12),
                      context.w(20),
                      context.h(24)
                    ),
                    child: Column(
                      children: [
                        _ServiceCustomerPanel(bill: bill),
                        SizedBox(height: context.h(14)),
                        _PaymentMethodPanel(
                          selected: _selectedPayment,
                          total: bill.total,
                          onSelected: (v) =>
                              setState(() => _selectedPayment = v)
                        ),
                        SizedBox(height: context.h(14)),
                        _ExtraFeesPanel(
                          applyLateNight: _applyLateNightFee,
                          applyLongDistance: _applyLongDistanceFee,
                          lateNightAmount: settings.lateNightFee > 0
                              ? settings.lateNightFee
                              : widget.bill.lateNightFee,
                          longDistanceAmount: settings.longDistanceFee > 0
                              ? settings.longDistanceFee
                              : widget.bill.longDistanceFee,
                          enabled: !_isSettling,
                          onLateNightChanged: (v) =>
                              setState(() => _applyLateNightFee = v),
                          onLongDistanceChanged: (v) =>
                              setState(() => _applyLongDistanceFee = v)
                        ),
                        SizedBox(height: context.h(14)),
                        _BillingPanel(bill: bill),
                        SizedBox(height: context.h(14)),
                        SizedBox(
                          height: context.h(420),
                          child: _ReceiptPanel(
                            bill: bill,
                            selectedPayment: _selectedPayment
                          )
                        ),
                        SizedBox(height: context.h(14)),
                        _actionButtons(context),
                      ]
                    )
                  )
                : Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.w(20),
                      context.h(12),
                      context.w(20),
                      context.h(16)
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.only(right: context.w(18)),
                            child: Column(
                              children: [
                                _ServiceCustomerPanel(bill: bill),
                                SizedBox(height: context.h(14)),
                                _PaymentMethodPanel(
                                  selected: _selectedPayment,
                                  total: bill.total,
                                  onSelected: (v) =>
                                      setState(() => _selectedPayment = v)
                                ),
                                SizedBox(height: context.h(14)),
                                _ExtraFeesPanel(
                                  applyLateNight: _applyLateNightFee,
                                  applyLongDistance: _applyLongDistanceFee,
                                  lateNightAmount: settings.lateNightFee > 0
                                      ? settings.lateNightFee
                                      : widget.bill.lateNightFee,
                                  longDistanceAmount:
                                      settings.longDistanceFee > 0
                                          ? settings.longDistanceFee
                                          : widget.bill.longDistanceFee,
                                  enabled: !_isSettling,
                                  onLateNightChanged: (v) =>
                                      setState(() => _applyLateNightFee = v),
                                  onLongDistanceChanged: (v) => setState(
                                      () => _applyLongDistanceFee = v)
                                ),
                                SizedBox(height: context.h(14)),
                                _BillingPanel(bill: bill),
                              ]
                            )
                          )
                        ),
                        VerticalDivider(
                          width: context.w(1),
                          thickness: 1,
                          color: colors.border
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
                                    selectedPayment: _selectedPayment
                                  )
                                ),
                                SizedBox(height: context.h(12)),
                                _actionButtons(context),
                              ]
                            )
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
          enabled: !_isSettling && hasPayment,
          onPressed: _printBill
        ),
        SizedBox(height: context.h(10)),
        RdxActionButton(
          label: _isSettling ? 'Processing…' : 'Mark paid & complete',
          leadingIcon: Icons.check_circle_outline,
          isPrimary: true,
          enabled: !_isSettling && hasPayment,
          onPressed: _markPaidAndComplete
        ),
        SizedBox(height: context.h(10)),
        RdxActionButton(
          label: 'Close',
          isPrimary: false,
          enabled: !_isSettling,
          onPressed: _close
        ),
      ]
    );
  }
}

class _ServiceCustomerPanel extends StatelessWidget {
  final BillSettlementData bill;

  const _ServiceCustomerPanel({required this.bill});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final customerName = bill.guestName.trim().isEmpty
        ? 'Walk-in customer'
        : bill.guestName.trim();
    final isDineIn = bill.orderType.toLowerCase().contains('dine') ||
        bill.orderType.toLowerCase().contains('eat');
    final hasTable = bill.tableNumber?.trim().isNotEmpty ?? false;
    final hasPhone = bill.phoneNumber.trim().isNotEmpty;
    final hasAddress = bill.deliveryAddress.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.h(14)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(color: colors.border)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: context.h(18),
                color: AppColors.primary
              ),
              SizedBox(width: context.w(8)),
              Text(
                'Service & customer',
                style: AppTextStyles.bodyLargeSemi(context).copyWith(
                  color: colors.textPrimary
                )
              ),
            ]
          ),
          SizedBox(height: context.h(16)),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 400;
              final orderIdField = _serviceInfoField(
                context,
                colors,
                'Order ID',
                bill.orderNumber
              );
              final serviceField = _serviceInfoField(
                context,
                colors,
                'Service option',
                bill.orderType
              );
              final orderTimeField = _serviceInfoField(
                context,
                colors,
                'Order Time',
                _formatOrderTime(bill.receiptDateTime)
              );
              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    orderIdField,
                    SizedBox(height: context.h(14)),
                    serviceField,
                    SizedBox(height: context.h(14)),
                    orderTimeField,
                  ]
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: orderIdField),
                  SizedBox(width: context.w(14)),
                  Expanded(child: serviceField),
                  SizedBox(width: context.w(14)),
                  Expanded(child: orderTimeField),
                ]
              );
            }
          ),
          SizedBox(height: context.h(16)),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 400;
              final table = _serviceInfoField(
                context,
                colors,
                'Table',
                hasTable
                    ? 'Table ${bill.tableNumber!.trim()}'
                    : 'No table / counter'
              );
              final customer = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _serviceInfoField(
                      context,
                      colors,
                      'Customer',
                      customerName
                    )
                  ),
                  if (hasPhone) ...[
                    SizedBox(width: context.w(12)),
                    Expanded(
                      child: _serviceInfoField(
                        context,
                        colors,
                        'Mobile number',
                        bill.phoneNumber.trim()
                      )
                    ),
                  ],
                ]
              );

              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isDineIn) ...[
                      table,
                      SizedBox(height: context.h(14)),
                    ],
                    customer,
                  ]
                );
              }
              if (!isDineIn) return customer;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: table),
                  SizedBox(width: context.w(14)),
                  Expanded(child: customer),
                ]
              );
            }
          ),
          if (hasAddress) ...[
            SizedBox(height: context.h(14)),
            _serviceInfoField(
              context,
              colors,
              'Delivery address',
              bill.deliveryAddress.trim()
            ),
          ],
        ]
      )
    );
  }

  Widget _serviceInfoField(
    BuildContext context,
    AppColorScheme colors,
    String label,
    String value
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body(context).copyWith(
            color: colors.textMuted
          )
        ),
        SizedBox(height: context.h(6)),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500
          )
        ),
      ]
    );
  }

  String _formatOrderTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final year = (dateTime.year % 100).toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day ${_monthName(dateTime.month)} $year · $hour:$minute';
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
        icon: Icons.payments_outlined
      ),
      _Method(
        id: 'Card',
        title: 'Credit / Debit',
        // subtitle: 'Credit / Debit',
        icon: Icons.credit_card_outlined
      ),
      _Method(
        id: 'UPI',
        title: 'UPI / QR',
        // subtitle: 'Instant scan',
        icon: Icons.qr_code_scanner
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.h(14)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(color: colors.border)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment_outlined,
                size: context.h(18),
                color: AppColors.primary
              ),
              SizedBox(width: context.w(8)),
              Text(
                'Payment method',
                style: AppTextStyles.bodyLargeSemi(context).copyWith(
                  color: colors.textPrimary
                )
              ),
            ]
          ),
          SizedBox(height: context.h(14)),
          Wrap(
            spacing: context.w(10),
            runSpacing: context.h(10),
            children: [
              for (final method in methods)
                _methodTile(context, colors, method),
            ]
          ),
        ]
      )
    );
  }

  Widget _methodTile(BuildContext context, AppColorScheme colors, _Method m) {
    final isSelected = selected == m.id;

    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.15)
          : colors.surface,
      borderRadius: BorderRadius.circular(context.h(10)),
      child: InkWell(
        onTap: () => onSelected(m.id),
        borderRadius: BorderRadius.circular(context.h(10)),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(14),
            vertical: context.h(12)
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.h(10)),
            border: Border.all(
                color: isSelected ? AppColors.primary : colors.border)
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                m.icon,
                size: context.h(18),
                color: isSelected ? AppColors.primary : colors.textSecondary
              ),
              SizedBox(width: context.w(8)),
              Text(
                m.title,
                style: AppTextStyles.bodySemi(context).copyWith(
                  color: isSelected ? colors.primary : colors.textSecondary
                )
              ),
            ]
          )
        )
      )
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
// EXTRA FEES (per-order toggles at settlement)
// =============================================================================

/// Staff choose Late Night / Long Distance fees on this bill only.
/// Amounts come from settings (or from the order if already set).
class _ExtraFeesPanel extends StatelessWidget {
  final bool applyLateNight;
  final bool applyLongDistance;
  final double lateNightAmount;
  final double longDistanceAmount;
  final bool enabled;
  final ValueChanged<bool> onLateNightChanged;
  final ValueChanged<bool> onLongDistanceChanged;

  const _ExtraFeesPanel({
    required this.applyLateNight,
    required this.applyLongDistance,
    required this.lateNightAmount,
    required this.longDistanceAmount,
    required this.enabled,
    required this.onLateNightChanged,
    required this.onLongDistanceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.h(14)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(color: colors.border)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                size: context.h(18),
                color: AppColors.primary
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                child: Text(
                  'Extra fees for this order',
                  style: AppTextStyles.bodyLargeSemi(context).copyWith(
                    color: colors.textPrimary
                  )
                )
              ),
            ]
          ),
          SizedBox(height: context.h(6)),
          Text(
            'Turn on only if this order needs the fee. Applied at settlement.',
            style: AppTextStyles.caption(context).copyWith(
              color: colors.textSecondary
            )
          ),
          SizedBox(height: context.h(12)),
          _feeToggleRow(
            context,
            colors,
            title: 'Late Night Delivery',
            amount: lateNightAmount,
            value: applyLateNight,
            onChanged: enabled ? onLateNightChanged : null
          ),
          SizedBox(height: context.h(8)),
          _feeToggleRow(
            context,
            colors,
            title: 'Long Distance Fee',
            amount: longDistanceAmount,
            value: applyLongDistance,
            onChanged: enabled ? onLongDistanceChanged : null
          ),
        ]
      )
    );
  }

  Widget _feeToggleRow(
    BuildContext context,
    AppColorScheme colors, {
    required String title,
    required double amount,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final amountLabel = amount > 0
        ? '₹${amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2)}'
        : 'Not configured';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(12),
        vertical: context.h(10)
      ),
      decoration: BoxDecoration(
        color: value
            ? AppColors.primary.withValues(alpha: 0.08)
            : colors.surfaceVariant,
        borderRadius: BorderRadius.circular(context.h(8))
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600
                  )
                ),
                SizedBox(height: context.h(2)),
                Text(
                  amountLabel,
                  style: AppTextStyles.caption(context).copyWith(
                    color: amount > 0 ? AppColors.primary : colors.textMuted
                  )
                ),
              ]
            )
          ),
          IgnorePointer(
            ignoring: onChanged == null,
            child: RdxToggleButton(
              value: value,
              onChanged: onChanged ?? (_) {}
            )
          ),
        ]
      )
    );
  }
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
        border: Border.all(color: colors.border)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                size: context.h(18),
                color: AppColors.primary
              ),
              SizedBox(width: context.w(8)),
              Text(
                'Billing summary',
                style: AppTextStyles.bodyLargeSemi(context).copyWith(
                  color: colors.textPrimary
                )
              ),
            ]
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
                        style: AppTextStyles.body(context).copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w500
                        )
                      ),
                      if (item.modifiers.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: context.h(2)),
                          child: Text(
                            item.modifiers.join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(context).copyWith(
                              color: colors.textSecondary
                            )
                          )
                        ),
                    ]
                  )
                ),
                Text(
                  '₹${item.amount.toStringAsFixed(2)}',
                  style: AppTextStyles.body(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600
                  )
                ),
              ]
            ),
            SizedBox(height: context.h(10)),
          ],
          Divider(height: 1, color: colors.divider),
          SizedBox(height: context.h(10)),
          _amountRow(
            context,
            colors,
            'Subtotal (${bill.items.length} items)',
            bill.subtotal
          ),
          SizedBox(height: context.h(6)),
          _amountRow(
            context,
            colors,
            'GST (${bill.taxPercentage.toStringAsFixed(0)}%)',
            bill.taxAmount
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
              vertical: context.h(12)
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(context.h(8))
            ),
            child: Row(
              children: [
                Text(
                  'Total due',
                  style: AppTextStyles.bodyLargeSemi(context).copyWith(
                    color: colors.textPrimary
                  )
                ),
                const Spacer(),
                Text(
                  '₹${bill.total.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyLargeSemi(context).copyWith(
                    color: AppColors.primary
                    )
                ),
              ]
            )
          ),
        ]
      )
    );
  }

  Widget _amountRow(
    BuildContext context,
    AppColorScheme colors,
    String label,
    double amount
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body(context).copyWith(
              color: colors.textSecondary
            )
          )
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: AppTextStyles.body(context).copyWith(
            color: colors.textPrimary
          )
        ),
      ]
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
        border: Border.all(color: colors.border)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(14),
              context.h(12),
              context.w(14),
              context.h(10)
            ),
            child: Row(
              children: [
                Text(
                  'Receipt',
                  style: AppTextStyles.bodyLargeSemi(context).copyWith(
                    color: colors.textPrimary
                  )
                )
              ]
            )
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
                      shape: BoxShape.circle
                    ),
                    child: Icon(
                      Icons.restaurant,
                      size: context.h(22),
                      color: colors.surface
                    )
                  ),
                  SizedBox(height: context.h(8)),
                  Text(
                    bill.restaurantName,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLargeSemi(context).copyWith(
                      color: colors.textPrimary
                      )
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    _formatFullDate(bill.receiptDateTime),
                    style: AppTextStyles.caption(context).copyWith(
                      color: colors.textSecondary
                    )
                  ),
                  SizedBox(height: context.h(14)),
                  Divider(height: 1, color: colors.border),
                  SizedBox(height: context.h(10)),
                  _receiptInfoRow(
                    context,
                    colors,
                    'Order ID',
                    '#${_shortId(bill.orderNumber)}'
                  ),
                  _receiptInfoRow(
                    context,
                    colors,
                    'Table No.',
                    bill.tableNumber?.trim().isNotEmpty == true
                        ? bill.tableNumber!
                        : '—'
                  ),
                  if (bill.guestName.trim().isNotEmpty &&
                      bill.guestName.trim().toLowerCase() != 'walk-in customer')
                    _receiptInfoRow(
                      context,
                      colors,
                      'Guest',
                      bill.guestName
                    ),
                  SizedBox(height: context.h(10)),
                  Divider(height: 1, color: colors.border),
                  SizedBox(height: context.h(10)),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Item',
                          style: AppTextStyles.bodySemi(context).copyWith(
                            color: colors.textMuted
                            )
                        )
                      ),
                      Text(
                        'Amount',
                        style: AppTextStyles.bodySemi(context).copyWith(
                          color: colors.textMuted
                          )
                      ),
                    ]
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
                                AppTextStyles.body(context).copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600
                            )
                          )
                        ),
                        Text(
                          '₹${item.amount.toStringAsFixed(2)}',
                          style: AppTextStyles.body(context).copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600
                          )
                        ),
                      ]
                    ),
                    if (item.modifiers.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          top: context.h(2),
                          left: context.w(12)
                        ),
                        child: Text(
                          item.modifiers.join(', '),
                          style: AppTextStyles.caption(context).copyWith(
                            color: colors.textSecondary
                          )
                        )
                      ),
                    SizedBox(height: context.h(8)),
                  ],
                  Divider(height: 1, color: colors.border),
                  SizedBox(height: context.h(8)),
                  _receiptMoneyRow(
                    context,
                    colors,
                    'Subtotal',
                    bill.subtotal
                  ),
                  SizedBox(height: context.h(4)),
                  _receiptMoneyRow(
                    context,
                    colors,
                    'GST (${bill.taxPercentage.toStringAsFixed(0)}%)',
                    bill.taxAmount
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
                      vertical: context.h(10)
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(context.h(8))
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Total',
                          style: AppTextStyles.bodySemi(context).copyWith(
                            color: colors.textPrimary
                            )
                        ),
                        const Spacer(),
                        Text(
                          '₹${bill.total.toStringAsFixed(2)}',
                          style: AppTextStyles.bodyLargeSemi(context).copyWith(
                            color: colors.textPrimary
                            )
                        ),
                      ]
                    )
                  ),
                  SizedBox(height: context.h(12)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(context.h(10)),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(context.h(8))
                    ),
                    child: Text(
                      'Payment: ${(selectedPayment ?? 'Not selected')}',
                      style: AppTextStyles.bodySemi(context).copyWith(
                        color: colors.textPrimary
                        )
                    )
                  ),
                  SizedBox(height: context.h(16)),
                  Text(
                    'Thank you for dining with us!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySemi(context).copyWith(
                      color: colors.textPrimary
                      )
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    'Please visit again soon.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySemi(context).copyWith(
                      color: colors.textSecondary
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

  Widget _receiptInfoRow(
    BuildContext context,
    AppColorScheme colors,
    String label,
    String value
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySemi(context).copyWith(
              color: colors.textSecondary
            )
          )
        ),
        Text(
          value,
          style: AppTextStyles.body(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600
          )
        ),
      ]
    );
  }

  Widget _receiptMoneyRow(
    BuildContext context,
    AppColorScheme colors,
    String label,
    double amount
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySemi(context).copyWith(
              color: colors.textSecondary
            )
          )
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: AppTextStyles.body(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600
          )
        ),
      ]
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
