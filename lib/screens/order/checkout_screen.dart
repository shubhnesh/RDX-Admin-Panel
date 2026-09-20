import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/screens/order/bill_settlement_screen.dart';
import 'package:rdx_admin/screens/order/place_order_screen.dart';
import 'package:rdx_admin/services/table_config_service.dart';
import 'package:rdx_admin/widgets/dialogs/category_dialog.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/order_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_providers.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';
import '../../widgets/resuable_options/rdx_dropdown.dart';
import '../../widgets/resuable_options/rdx_text_field.dart';

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

  static const double _taxPercentage = 8.0;

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
      saveButtonLabel: 'Save',
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
    if (!_formKey.currentState!.validate()) return;

    final cart = ref.read(cartProvider);

    if (cart.isEmpty) {
      _showMessage('Your order is empty. Please add items first.');
      return;
    }

    if (_orderType == OrderType.dineIn &&
        (_selectedTable == null || _selectedTable!.isEmpty)) {
      _showMessage('Please select a table number.');
      return;
    }

    final subtotal = ref.read(cartTotalProvider);
    final tax = subtotal * (_taxPercentage / 100);
    final total = subtotal + tax;

    final order = OrderModel(
      id: '',
      customerName: _customerName.text.trim(),
      customerPhone: _customerPhone.text.trim(),
      deliveryAddress:
          _orderType == OrderType.delivery ? _deliveryAddress.text.trim() : '',
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.unpaid,
      paymentMethod: null,
      total: total,
      createdAt: DateTime.now(),
      items: [
        for (final line in cart)
          OrderItemModel(
            name: line.menuItem.name,
            quantity: line.quantity,
            price: line.unitPrice,
            spiceLevel: line.spiceLevel,
            addOns: line.addOns.map((addOn) => addOn.displayLabel).toList(),
            notes: line.notes,
          ),
      ],
      notes: _orderNotes.text.trim().isEmpty ? null : _orderNotes.text.trim(),
      orderType: _orderType,
      tableNumber: _orderType == OrderType.dineIn ? _selectedTable : null,
    );

    try {
      final newOrderId =
          await ref.read(placeOrderControllerProvider.notifier).submit(order);

      if (!mounted) return;

      if (newOrderId == null || newOrderId.isEmpty) {
        _showMessage('Failed to place order. Please try again.');
        return;
      }

      final billItems = <BillItemData>[
        for (final line in cart)
          BillItemData(
            name: line.menuItem.name,
            quantity: line.quantity,
            amount: line.subtotal,
            modifiers: [
              if (line.spiceLevel != null && line.spiceLevel!.trim().isNotEmpty)
                'Spice: ${line.spiceLevel}',
              ...line.addOns.map((addOn) => addOn.displayLabel),
              if (line.notes != null && line.notes!.trim().isNotEmpty)
                'Note: ${line.notes}',
            ],
          ),
      ];

      final guestName = _customerName.text.trim().isEmpty
          ? 'Walk-in Customer'
          : _customerName.text.trim();

      final phoneNumber = _customerPhone.text.trim();
      final tableNumber =
          _orderType == OrderType.dineIn ? _selectedTable : null;

      ref.read(cartProvider.notifier).clear();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BillSettlementScreen(
            bill: BillSettlementData(
              orderNumber: newOrderId,
              restaurantName: 'RDX Restaurant',
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
              subtotal: subtotal,
              taxPercentage: _taxPercentage,
              guestName: guestName,
              phoneNumber: phoneNumber,
              sendDigitalReceipt: false,
              invoiceReference: newOrderId,
              receiptDateTime: DateTime.now(),
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Failed to place order. Please try again.');
    }
  }

  void _editOrder() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const PlaceOrderScreen(),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final cart = ref.watch(cartProvider);
    final subtotal = ref.watch(cartTotalProvider);
    final tax = subtotal * (_taxPercentage / 100);
    final total = subtotal + tax;
    final placing = ref.watch(placeOrderControllerProvider).isLoading;

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
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  context.w(20),
                  context.h(16),
                  context.w(20),
                  context.h(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Order Summary ────────────────────────────────────
                    _panel(
                      context,
                      colors,
                      title: 'Order Summary',
                      icon: Icons.receipt_long_outlined,
                      headerTrailing: TextButton.icon(
                        onPressed: _editOrder,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.w(8),
                            vertical: context.h(6),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          Icons.edit_outlined,
                          size: context.h(18),
                          color: AppColors.primary,
                        ),
                        label: Text(
                          'Edit Order',
                          style: AppTextStyles.label(context).copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      children: [
                        if (cart.isEmpty)
                          Text(
                            'No items in the order.',
                            style: AppTextStyles.body(context).copyWith(
                              color: colors.textSecondary,
                            ),
                          )
                        else
                          for (final line in cart)
                            _buildSummaryItem(context, colors, line),
                        Divider(
                          color: colors.divider,
                          height: context.h(20),
                        ),
                        _summaryAmountRow(
                            context, colors, 'Subtotal', subtotal),
                        SizedBox(height: context.h(6)),
                        _summaryAmountRow(
                          context,
                          colors,
                          'Tax (${_taxPercentage.toStringAsFixed(0)}%)',
                          tax,
                        ),
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
                    ),

                    SizedBox(height: context.h(16)),

                    // ── Customer Details ─────────────────────────────────
                    _panel(
                      context,
                      colors,
                      title: 'Customer Details',
                      icon: Icons.person_outline_rounded,
                      children: [
                        LayoutBuilder(
                          builder: (context, c) {
                            final stack = c.maxWidth < 400;
                            final nameField = RdxTextField(
                              controller: _customerName,
                              label: 'Customer Name',
                              hint: 'Enter customer name',
                            );
                            final phoneField = RdxTextField(
                              controller: _customerPhone,
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

                    // ── Order Type ───────────────────────────────────────
                    _panel(
                      context,
                      colors,
                      title: 'Order Type',
                      icon: Icons.room_service_outlined,
                      children: [
                        RdxDropdown<OrderType>(
                          label: 'Order Type',
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
                              }
                            });
                          },
                        ),

                        // Table number — same sentinel pattern as
                        // create-category on the menu screen.
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
                            label: 'Delivery Address *',
                            hint: 'Enter delivery address',
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),

                    SizedBox(height: context.h(16)),

                    // ── Order Notes ──────────────────────────────────────
                    _panel(
                      context,
                      colors,
                      title: 'Order Notes',
                      icon: Icons.sticky_note_2_outlined,
                      children: [
                        RdxTextField(
                          controller: _orderNotes,
                          label: 'Kitchen Notes',
                          hint: 'Write any special instructions for your order',
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom actions (fixed width, not expanded) ───────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(20),
                context.h(10),
                context.w(20),
                context.h(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  RdxActionButton.save(
                    isLoading: placing,
                    onPressed: cart.isEmpty ? null : _placeOrder,
                  ),
                  SizedBox(width: context.w(10)),
                  RdxActionButton.discard(
                    onPressed: placing ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SUMMARY ITEM
  // ===========================================================================

  Widget _buildSummaryItem(
    BuildContext context,
    AppColorScheme colors,
    CartLineItem line,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${line.quantity}x ${line.menuItem.name}',
                  style: AppTextStyles.body(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: context.w(12)),
              Text(
                '₹${line.subtotal.toStringAsFixed(2)}',
                style: AppTextStyles.body(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(4)),
          Text(
            '₹${line.unitPrice.toStringAsFixed(2)} each',
            style: AppTextStyles.body(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

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
          ...children,
        ],
      ),
    );
  }
}