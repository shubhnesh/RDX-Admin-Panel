import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/screens/order/bill_settlement_screen.dart';
import 'package:rdx_admin/widgets/dialogs/rdx_notice_dialog.dart';
import 'package:rdx_admin/services/table_config_service.dart';
import 'package:rdx_admin/widgets/dialogs/category_dialog.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/order_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_providers.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/buttons/rdx_toggle_button.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';
import '../../widgets/reusable_widgets/rdx_dropdown.dart';
import '../../widgets/reusable_widgets/rdx_text_field.dart';
import 'widgets/order_summary_widgets.dart';

/// Sentinel value as the first entry in the table dropdown.
/// Selecting it opens the set/edit total-tables dialog (same pattern as
/// create-category on the menu screen).
const String _kSetTableCountValue = '__set_table_count__';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _customerName = TextEditingController();
  final _customerPhone = TextEditingController();
  final _deliveryAddress = TextEditingController();
  final _orderNotes = TextEditingController();

  OrderType _orderType = OrderType.dineIn;
  bool _longDistanceFeeSelected = false;

  final _tableConfigService = TableConfigService();

  /// Total tables configured for the restaurant (`null` = not set yet).
  int? _totalTables;

  /// Selected table number as a string (e.g. `"4"`), or `null`.
  String? _selectedTable;

  @override
  void initState() {
    super.initState();
    _loadTableCount();
  }

  Future<void> _loadTableCount() async {
    try {
      final count = await _tableConfigService.fetchTableCount();
      if (!mounted) return;
      setState(() {
        _totalTables = count;
        if (_selectedTable != null && count != null) {
          final n = int.tryParse(_selectedTable!);
          if (n == null || n < 1 || n > count) {
            _selectedTable = null;
          }
        }
      });
    } catch (_) {
      // Leave null; user can still set count from the dropdown.
    }
  }

  /// Opens the set/edit total-tables dialog ([CategoryEntryDialog]) and
  /// persists via [TableConfigService] independently of form submission.
  Future<void> _openTableCountDialog() async {
    final result = await CategoryEntryDialog.show<int>(
      context,
      title: 'Set Total Tables',
      editTitle: 'Edit Total Tables',
      nameLabel: 'Total tables *',
      nameHint: 'Enter count',
      initialName: _totalTables?.toString(),
      saveButtonLabel: 'Done',
      onSave: (name, _) async {
        final n = int.tryParse(name.trim());
        if (n == null ||
            n < TableConfigService.minTables ||
            n > TableConfigService.maxTables) {
          throw FormatException(
            'Enter a number between ${TableConfigService.minTables} '
            'and ${TableConfigService.maxTables}.',
          );
        }
        // Persist independently of the checkout form.
        await _tableConfigService.saveTableCount(n);
        return n;
      },
    );

    if (result == null || !mounted) return;

    setState(() {
      _totalTables = result;
      if (_selectedTable != null) {
        final n = int.tryParse(_selectedTable!);
        if (n == null || n < 1 || n > result) {
          _selectedTable = null;
        }
      }
    });
  }

  @override
  void dispose() {
    _customerName.dispose();
    _customerPhone.dispose();
    _deliveryAddress.dispose();
    _orderNotes.dispose();
    super.dispose();
  }

  // ===========================================================================
  // PLACE ORDER
  // ===========================================================================

  Future<void> _placeOrder() async {
    // Validation only — no client-side money calculation.
    // All prices, taxes and fees are computed by createStaffOrder Cloud Function.
    final cart = ref.read(cartProvider);

    if (cart.isEmpty) {
      await _showNotice('Your order is empty. Please add items first.');
      return;
    }

    if (_orderType == OrderType.dineIn &&
        (_selectedTable == null || _selectedTable!.isEmpty)) {
      await _showNotice('Please select a table number.');
      return;
    }

    if (_orderType == OrderType.delivery &&
        _deliveryAddress.text.trim().isEmpty) {
      await _showNotice('Please enter a delivery address.');
      return;
    }

    // Map cart → clean payload (no prices).
    final cleanItems = <Map<String, dynamic>>[
      for (final line in cart)
        {
          'product_id': line.menuItem.id,
          'quantity': line.quantity,
          // Size is not yet stored on CartLineItem in admin; omit for now.
          'notes': line.notes,
          'spice_level': line.spiceLevel,
          'add_ons': line.addOns.map((a) => a.name).toList(),
        },
    ];

    final guestName = _customerName.text.trim().isEmpty
        ? 'Walk-in Customer'
        : _customerName.text.trim();
    final phoneNumber = _customerPhone.text.trim();
    final tableNumber = _orderType == OrderType.dineIn ? _selectedTable : null;
    final deliveryAddress =
        _orderType == OrderType.delivery ? _deliveryAddress.text.trim() : '';
    final orderNotes =
        _orderNotes.text.trim().isEmpty ? null : _orderNotes.text.trim();

    // Drive the Place Order button spinner via the existing controller.
    final controller = ref.read(placeOrderControllerProvider.notifier);

    try {
      final orderService = ref.read(orderServiceProvider);
      controller.state = const AsyncLoading();

      final created = await orderService.createStaffOrder(
        items: cleanItems,
        orderType: _orderType.name, // dineIn | takeaway | delivery
        tableNumber: tableNumber,
        customerName: guestName,
        customerPhone: phoneNumber,
        deliveryAddress: deliveryAddress,
        notes: orderNotes,
        applyLongDistanceFee:
            _orderType == OrderType.delivery && _longDistanceFeeSelected,
        // paymentMethod left null → order stays unpaid until settleOrder
      );

      controller.state = AsyncData(created.id);

      if (!mounted) return;

      if (created.id.isEmpty) {
        await _showNotice('Failed to place order. Please try again.');
        return;
      }

      // Prefer server-side item prices for the bill when available.
      final billItems = <BillItemData>[
        if (created.items.isNotEmpty)
          for (final item in created.items)
            BillItemData(
              name: item.name,
              quantity: item.quantity,
              amount: item.price * item.quantity,
              modifiers: [
                if (item.spiceLevel != null &&
                    item.spiceLevel!.trim().isNotEmpty)
                  'Spice: ${item.spiceLevel}',
                ...item.addOns,
                if (item.notes != null && item.notes!.trim().isNotEmpty)
                  'Note: ${item.notes}',
              ],
            )
        else
          // Fallback to cart display if CF returned empty items (shouldn't happen).
          for (final line in cart)
            BillItemData(
              name: line.menuItem.name,
              quantity: line.quantity,
              amount: line.subtotal,
              modifiers: [
                if (line.spiceLevel != null &&
                    line.spiceLevel!.trim().isNotEmpty)
                  'Spice: ${line.spiceLevel}',
                ...line.addOns.map((a) => a.displayLabel),
                if (line.notes != null && line.notes!.trim().isNotEmpty)
                  'Note: ${line.notes}',
              ],
            ),
      ];

      // Subtotal from server item lines (authoritative).
      final serverSubtotal = billItems.fold<double>(
        0,
        (sum, b) => sum + b.amount,
      );

      // Fee breakdown for receipt UI only. Amounts from settings/fees
      // via SettingsProvider (preview). Stored order.total is always from CF.
      final feeSettings = ref.read(settingsProvider);
      final isLateNightNow = _isWithinLateNightWindow(
        feeSettings.lateNightStart,
        feeSettings.lateNightEnd,
      );
      final lateNightFee = _orderType == OrderType.delivery &&
              feeSettings.lateNightDelivery &&
              isLateNightNow
          ? feeSettings.lateNightFee
          : 0.0;
      final longDistanceFee = _orderType == OrderType.delivery &&
              _longDistanceFeeSelected
          ? feeSettings.longDistanceFee
          : 0.0;

      ref.read(cartProvider.notifier).clear();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BillSettlementScreen(
            bill: BillSettlementData(
              orderNumber: created.id,
              restaurantName: 'RDX Fast Food',
              orderType: _orderType.label,
              tableNumber: tableNumber,
              billingMode: _orderType.label,
              cashier: 'Staff',
              server: 'Staff',
              kitchenName: 'Main Kitchen',
              sequence: null,
              covers: 1,
              items: billItems,
              paymentMethod: null,
              cardLastFour: null,
              subtotal: serverSubtotal,
              // GST is always applied — never gated by orderFeesEnabled.
              taxPercentage: feeSettings.gstPercent,
              lateNightFee: lateNightFee,
              longDistanceFee: longDistanceFee,
              guestName: guestName,
              phoneNumber: phoneNumber,
              deliveryAddress: deliveryAddress,
              sendDigitalReceipt: false,
              invoiceReference: created.id,
              receiptDateTime: DateTime.now(),
            ),
          ),
        ),
      );
    } catch (e) {
      controller.state = AsyncError(e, StackTrace.current);
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      await _showNotice(
        message.isNotEmpty
            ? message
            : 'Failed to place order. Please try again.',
      );
    }
  }

  /// Same notice-dialog pattern as [CreateCouponScreen].
  Future<void> _showNotice(String message) async {
    if (!mounted) return;
    await RdxNoticeDialog.show(context, message: message);
  }

  /// Matches Cloud Function late-night window (supports overnight, e.g. 22:00–06:00).
  bool _isWithinLateNightWindow(String startStr, String endStr) {
    int? toMinutes(String value) {
      final parts = value.trim().split(':');
      if (parts.length < 2) return null;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) return null;
      if (h < 0 || h > 23 || m < 0 || m > 59) return null;
      return h * 60 + m;
    }

    final start = toMinutes(startStr);
    final end = toMinutes(endStr);
    if (start == null || end == null) return false;
    final now = DateTime.now();
    final current = now.hour * 60 + now.minute;
    if (start > end) {
      return current >= start || current < end;
    }
    return current >= start && current < end;
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final cart = ref.watch(cartProvider);
    final subtotal = ref.watch(cartTotalProvider);
    final totalItems =
        cart.fold<int>(0, (count, line) => count + line.quantity);
    final settings = ref.watch(settingsProvider);
    // Preview only — authoritative totals come from createStaffOrder CF.
    // GST always. Late-night when settings toggle is ON and current time is
    // inside the late-night window. Long-distance only when staff enables
    // the optional toggle on this screen (delivery orders).
    final gstPercent = settings.gstPercent;
    final tax = subtotal * (gstPercent / 100);
    final isLateNightNow = _isWithinLateNightWindow(
      settings.lateNightStart,
      settings.lateNightEnd,
    );
    final lateNightFee = _orderType == OrderType.delivery &&
            settings.lateNightDelivery &&
            isLateNightNow
        ? settings.lateNightFee
        : 0.0;
    final longDistanceFee = _orderType == OrderType.delivery &&
            _longDistanceFeeSelected
        ? settings.longDistanceFee
        : 0.0;
    final deliveryFeePreview = _orderType == OrderType.delivery
        ? (settings.freeDeliveryAbove > 0 &&
                subtotal >= settings.freeDeliveryAbove
            ? 0.0
            : settings.deliveryFee)
        : 0.0;
    final total =
        subtotal + tax + deliveryFeePreview + lateNightFee + longDistanceFee;
    final placing = ref.watch(placeOrderControllerProvider).isLoading;
    final isNarrow = MediaQuery.sizeOf(context).width < 900;

    final emptyOrderMessage = Text(
      'No items in the order.',
      style: AppTextStyles.body(context).copyWith(
        color: colors.textSecondary,
      ),
    );
    final orderItems = LayoutBuilder(
      builder: (context, constraints) {
        final spacing = context.w(10);
        final maxCardWidth = context.w(280);
        final columns =
            (constraints.maxWidth / (maxCardWidth + spacing)).floor().clamp(
                  1,
                  3,
                );
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final cards = Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final line in cart)
              SizedBox(
                width: cardWidth,
                child: OrderSummaryItemCard(line: line),
              ),
          ],
        );
        final scrollView = SingleChildScrollView(child: cards);

        if (!isNarrow) return scrollView;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: context.h(360)),
          child: scrollView,
        );
      },
    );

    final orderSummary = OrderSummaryPanel(
      title: 'Order Summary',
      icon: Icons.receipt_long_outlined,
      itemCount: cart.length,
      expandedContent: isNarrow
          ? null
          : cart.isEmpty
              ? emptyOrderMessage
              : orderItems,
      children: [
        if (isNarrow) cart.isEmpty ? emptyOrderMessage : orderItems,
        Divider(
          color: colors.divider,
          height: context.h(20),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                'Total items',
                style: AppTextStyles.bodySecondary(context)
                    .copyWith(color: colors.textSecondary),
              ),
            ),
            Text(
              '$totalItems',
              style: AppTextStyles.bodySecondary(context)
                  .copyWith(color: colors.textPrimary),
            ),
          ],
        ),
        SizedBox(height: context.h(6)),
        _summaryAmountRow(context, colors, 'Subtotal', subtotal),
        SizedBox(height: context.h(6)),
        _summaryAmountRow(
          context,
          colors,
          'GST (${gstPercent.toStringAsFixed(0)}%)',
          tax,
        ),
        if (deliveryFeePreview > 0) ...[
          SizedBox(height: context.h(6)),
          _summaryAmountRow(
            context,
            colors,
            'Delivery fee',
            deliveryFeePreview,
          ),
        ],
        if (lateNightFee > 0) ...[
          SizedBox(height: context.h(6)),
          _summaryAmountRow(
            context,
            colors,
            'Late Night Delivery',
            lateNightFee,
          ),
        ],
        if (longDistanceFee > 0) ...[
          SizedBox(height: context.h(6)),
          _summaryAmountRow(
            context,
            colors,
            'Long Distance Fee',
            longDistanceFee,
          ),
        ],
        SizedBox(height: context.h(10)),
        Row(
          children: [
            Text(
              'Total',
              style: AppTextStyles.section(context).copyWith(
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '₹${total.toStringAsFixed(2)}',
              style: AppTextStyles.section(context).copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );

    final detailPanels = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panel(
          context,
          colors,
          title: 'Customer Details',
          icon: Icons.person_outline_rounded,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final stack = constraints.maxWidth < 400;
                final nameField = RdxTextField(
                  controller: _customerName,
                  maxLength: 20,
                  label: 'Customer Name',
                  hint: 'Enter customer name',
                );
                final phoneField = RdxTextField(
                  controller: _customerPhone,
                  maxLength: 10,
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  keyboardType: TextInputType.phone,
                );
                if (stack) {
                  return Column(
                    children: [
                      nameField,
                      SizedBox(height: context.h(14)),
                      phoneField,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: nameField),
                    SizedBox(width: context.w(14)),
                    Expanded(child: phoneField),
                  ],
                );
              },
            ),
          ],
        ),
        SizedBox(height: context.h(16)),
        _panel(
          context,
          colors,
          title: 'Order Type',
          icon: Icons.room_service_outlined,
          children: [
            RdxDropdown<OrderType>(
              label: 'Order Type *',
              value: _orderType,
              items: OrderType.values,
              labelBuilder: (type) => type.label,
              hint: 'Select order type',
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _orderType = value;
                  if (value != OrderType.dineIn) {
                    _selectedTable = null;
                  }
                  if (value != OrderType.delivery) {
                    _deliveryAddress.clear();
                    _longDistanceFeeSelected = false;
                  }
                });
              },
            ),
            if (_orderType == OrderType.dineIn) ...[
              SizedBox(height: context.h(14)),
              RdxDropdown<String>(
                label: 'Table Number *',
                value: _selectedTable,
                searchable: true,
                items: [
                  _kSetTableCountValue,
                  if (_totalTables != null)
                    for (var i = 1; i <= _totalTables!; i++) '$i',
                ],
                labelBuilder: (value) {
                  if (value == _kSetTableCountValue) {
                    return _totalTables == null
                        ? '+ Set table count'
                        : '+ Edit table count ($_totalTables)';
                  }
                  return 'Table $value';
                },
                hint: _totalTables == null
                    ? 'Set table count first'
                    : 'Select or search table',
                onChanged: (value) {
                  if (value == null) return;
                  if (value == _kSetTableCountValue) {
                    _openTableCountDialog();
                    return;
                  }
                  setState(() => _selectedTable = value);
                },
              ),
            ],
            if (_orderType == OrderType.delivery) ...[
              SizedBox(height: context.h(14)),
              RdxTextField(
                controller: _deliveryAddress,
                maxLength: 200,
                label: 'Delivery Address *',
                hint: 'Enter delivery address',
                maxLines: 3,
              ),
              // Optional fee — staff chooses per order on checkout (not a settings toggle).
              if (settings.longDistanceFee > 0) ...[
                SizedBox(height: context.h(14)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(12),
                    vertical: context.h(12),
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(context.h(8)),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.route_outlined,
                        size: context.h(18),
                        color: AppColors.primary,
                      ),
                      SizedBox(width: context.w(10)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Optional: Long distance fee',
                              style: AppTextStyles.bodySecondary(context)
                                  .copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: context.h(2)),
                            Text(
                              'Add ₹${settings.longDistanceFee == settings.longDistanceFee.roundToDouble() ? settings.longDistanceFee.toInt() : settings.longDistanceFee.toStringAsFixed(0)} for long-distance delivery',
                              style: AppTextStyles.caption(context).copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RdxToggleButton(
                        value: _longDistanceFeeSelected,
                        onChanged: (value) =>
                            setState(() => _longDistanceFeeSelected = value),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
        SizedBox(height: context.h(16)),
        _panel(
          context,
          colors,
          title: 'Order Notes',
          icon: Icons.sticky_note_2_outlined,
          children: [
            RdxTextField(
              controller: _orderNotes,
              maxLength: 40,
              label: 'Kitchen Notes',
              hint: 'Write any special instructions for your order',
              maxLines: 3,
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const RdxHeader(
            title: 'Checkout',
            showBackButton: true,
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: isNarrow
                  ? SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        context.w(20),
                        context.h(16),
                        context.w(20),
                        context.h(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          orderSummary,
                          SizedBox(height: context.h(16)),
                          detailPanels,
                        ],
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.w(20),
                        context.h(16),
                        context.w(20),
                        context.h(24),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.only(right: context.w(20)),
                              child: detailPanels,
                            ),
                          ),
                          VerticalDivider(
                            width: context.w(1),
                            thickness: context.h(1),
                            color: colors.border,
                          ),
                          SizedBox(width: context.w(20)),
                          SizedBox(
                            width: context.w(360).clamp(320.0, 400.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: orderSummary),
                                SizedBox(height: context.h(16)),
                                _actionButtons(
                                    context, cart.isNotEmpty, placing),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          if (isNarrow)
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.w(20),
                  context.h(10),
                  context.w(20),
                  context.h(14),
                ),
                child: _actionButtons(context, cart.isNotEmpty, placing),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionButtons(BuildContext context, bool hasItems, bool placing) {
    return Row(
      children: [
        Expanded(
          child: RdxActionButton.discard(
            enabled: !placing,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        SizedBox(width: context.w(10)),
        Expanded(
          child: RdxActionButton.save(
            isLoading: placing,
            enabled: hasItems,
            onPressed: _placeOrder,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SUMMARY AMOUNTS
  // ===========================================================================

  Widget _summaryAmountRow(
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

  // ===========================================================================
  // PANEL
  // ===========================================================================

  Widget _panel(
    BuildContext context,
    AppColorScheme colors, {
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? headerTrailing,
    Widget? expandedContent,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.h(14)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: context.h(18), color: AppColors.primary),
              SizedBox(width: context.w(8)),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.section(context).copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (headerTrailing != null) headerTrailing,
            ],
          ),
          SizedBox(height: context.h(16)),
          if (expandedContent != null) Expanded(child: expandedContent),
          ...children,
        ],
      ),
    );
  }
}
