import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rdx_admin/screens/order/bill_settlement_screen.dart';
import 'package:rdx_admin/screens/order/place_order_screen.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';

import '../../models/cart_item_model.dart';
import '../../models/order_model.dart';

import '../../providers/cart_provider.dart';
import '../../providers/order_providers.dart';

import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';
import '../../widgets/resuable_options/rdx_dropdown.dart';
import '../../widgets/resuable_options/rdx_text_field.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _customerName = TextEditingController();
  final _customerPhone = TextEditingController();
  final _tableNumber = TextEditingController();
  final _deliveryAddress = TextEditingController();
  final _orderNotes = TextEditingController();

  OrderType _orderType = OrderType.dineIn;

  /// Current restaurant tax rate.
  ///
  /// Keep this in one place so checkout, bill settlement and
  /// order details can follow the same calculation.
  static const double _taxPercentage = 8.0;

  @override
  void dispose() {
    _customerName.dispose();
    _customerPhone.dispose();
    _tableNumber.dispose();
    _deliveryAddress.dispose();
    _orderNotes.dispose();

    super.dispose();
  }

  // ===========================================================================
  // PLACE ORDER
  // ===========================================================================

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cart = ref.read(cartProvider);

    if (cart.isEmpty) {
      _showMessage(
        'Your order is empty. Please add items first.',
      );
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

      /// Payment must remain unpaid until the admin actually
      /// completes payment from the settlement screen.
      paymentStatus: PaymentStatus.unpaid,

      paymentMethod: null,

      /// Store the final amount due.
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

      tableNumber:
          _orderType == OrderType.dineIn ? _tableNumber.text.trim() : null,
    );

    try {
      final newOrderId =
          await ref.read(placeOrderControllerProvider.notifier).submit(order);

      if (!mounted) {
        return;
      }

      if (newOrderId == null || newOrderId.isEmpty) {
        _showMessage(
          'Failed to place order. Please try again.',
        );
        return;
      }

      // -----------------------------------------------------------------------
      // Prepare bill data BEFORE clearing the cart.
      // -----------------------------------------------------------------------

      final billItems = <BillItemData>[
        for (final line in cart)
          BillItemData(
            name: line.menuItem.name,
            quantity: line.quantity,
            amount: line.subtotal,
            modifiers: [
              if (line.spiceLevel != null && line.spiceLevel!.trim().isNotEmpty)
                'Spice: ${line.spiceLevel}',
              ...line.addOns.map(
                (addOn) => addOn.displayLabel,
              ),
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
          _orderType == OrderType.dineIn ? _tableNumber.text.trim() : null;

      // -----------------------------------------------------------------------
      // Firestore order has successfully been created.
      // Now it is safe to clear the cart.
      // -----------------------------------------------------------------------

      ref.read(cartProvider.notifier).clear();

      if (!mounted) {
        return;
      }

      // -----------------------------------------------------------------------
      // Open Bill Settlement.
      // -----------------------------------------------------------------------

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

              /// Payment has NOT been completed yet.
              paymentMethod: null,

              cardLastFour: null,

              /// Correct subtotal.
              subtotal: subtotal,

              /// Correct tax percentage.
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
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to place order. Please try again.',
      );
    }
  }

  // ===========================================================================
  // EDIT ORDER
  // ===========================================================================

  void _editOrder() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const PlaceOrderScreen(),
      ),
    );
  }

  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
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
                    // ---------------------------------------------------------
                    // ORDER SUMMARY
                    // ---------------------------------------------------------

                    _buildOrderSummary(
                      context,
                      colors,
                      cart,
                      subtotal,
                      tax,
                      total,
                    ),

                    SizedBox(
                      height: context.h(16),
                    ),

                    // ---------------------------------------------------------
                    // CUSTOMER DETAILS
                    // ---------------------------------------------------------

                    _panel(
                      context,
                      colors,
                      'Customer Details',
                      [
                        RdxTextField(
                          controller: _customerName,
                          label: 'Customer Name (Optional)',
                          hint: 'Enter customer name',
                        ),
                        SizedBox(
                          height: context.h(14),
                        ),
                        RdxTextField(
                          controller: _customerPhone,
                          label: 'Phone Number (Optional)',
                          hint: 'Enter phone number',
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),

                    SizedBox(
                      height: context.h(16),
                    ),

                    // ---------------------------------------------------------
                    // ORDER TYPE
                    // ---------------------------------------------------------

                    _panel(
                      context,
                      colors,
                      'Order Type',
                      [
                        RdxDropdown<OrderType>(
                          label: 'Order Type',
                          value: _orderType,
                          items: OrderType.values,
                          labelBuilder: (type) => type.label,
                          hint: 'Select order type',
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              _orderType = value;

                              // Clear fields that are no longer
                              // relevant to the selected order type.
                              if (value != OrderType.dineIn) {
                                _tableNumber.clear();
                              }

                              if (value != OrderType.delivery) {
                                _deliveryAddress.clear();
                              }
                            });
                          },
                        ),

                        // -----------------------------------------------------
                        // TABLE NUMBER
                        // -----------------------------------------------------

                        if (_orderType == OrderType.dineIn) ...[
                          SizedBox(
                            height: context.h(14),
                          ),
                          RdxTextField(
                            controller: _tableNumber,
                            label: 'Table Number *',
                            hint: 'e.g. T-04',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }

                              return null;
                            },
                          ),
                        ],

                        // -----------------------------------------------------
                        // DELIVERY ADDRESS
                        // -----------------------------------------------------

                        if (_orderType == OrderType.delivery) ...[
                          SizedBox(
                            height: context.h(14),
                          ),
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

                    SizedBox(
                      height: context.h(16),
                    ),

                    // ---------------------------------------------------------
                    // ORDER NOTES
                    // ---------------------------------------------------------

                    _panel(
                      context,
                      colors,
                      'Order Notes',
                      [
                        RdxTextField(
                          controller: _orderNotes,
                          label: 'Kitchen Notes (Optional)',
                          hint: 'e.g. Fries extra crispy, no onions',
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // PLACE ORDER BUTTON
          // -------------------------------------------------------------------

          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(20),
                context.h(10),
                context.w(20),
                context.h(14),
              ),
              child: RdxActionButton.save(
                isLoading: placing,
                onPressed: cart.isEmpty ? null : _placeOrder,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ORDER SUMMARY
  // ===========================================================================

  Widget _buildOrderSummary(
    BuildContext context,
    AppColorScheme colors,
    List<CartLineItem> cart,
    double subtotal,
    double tax,
    double total,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        context.h(14),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(
          context.h(8),
        ),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------------------
          // HEADER
          // -------------------------------------------------------------------

          Row(
            children: [
              Expanded(
                child: Text(
                  'Order Summary',
                  style: AppTextStyles.section(context).copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              TextButton.icon(
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
                  Icons.edit,
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
            ],
          ),

          SizedBox(
            height: context.h(14),
          ),

          // -------------------------------------------------------------------
          // ITEMS
          // -------------------------------------------------------------------

          if (cart.isEmpty)
            Text(
              'No items in the order.',
              style: AppTextStyles.body(context).copyWith(
                color: colors.textSecondary,
              ),
            )
          else
            for (final line in cart)
              _buildSummaryItem(
                context,
                colors,
                line,
              ),

          // -------------------------------------------------------------------
          // BILL BREAKDOWN
          // -------------------------------------------------------------------

          Divider(
            color: colors.divider,
            height: context.h(20),
          ),

          _summaryAmountRow(
            context,
            colors,
            'Subtotal',
            subtotal,
          ),

          SizedBox(
            height: context.h(6),
          ),

          _summaryAmountRow(
            context,
            colors,
            'Tax (${_taxPercentage.toStringAsFixed(0)}%)',
            tax,
          ),

          SizedBox(
            height: context.h(10),
          ),

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
      padding: EdgeInsets.only(
        bottom: context.h(12),
      ),
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
              SizedBox(
                width: context.w(12),
              ),
              Text(
                '₹${line.subtotal.toStringAsFixed(2)}',
                style: AppTextStyles.body(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(
            height: context.h(4),
          ),
          Text(
            '₹${line.unitPrice.toStringAsFixed(2)} each',
            style: AppTextStyles.body(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
          // if (line.spiceLevel != null &&
          //     line.spiceLevel!.trim().isNotEmpty) ...[
          //   SizedBox(
          //     height: context.h(3),
          //   ),
          //   Text(
          //     'Spice: ${line.spiceLevel}',
          //     style: AppTextStyles.caption(context).copyWith(
          //       color: colors.textSecondary,
          //     ),
          //   ),
          // ],
          // if (line.addOns.isNotEmpty) ...[
          //   SizedBox(
          //     height: context.h(3),
          //   ),
          //   Text(
          //     'Add-ons: ${line.addOns.map((a) => a.displayLabel).join(', ')}',
          //     style: AppTextStyles.caption(context).copyWith(
          //       color: colors.textSecondary,
          //     ),
          //   ),
          // ],
          // if (line.notes != null && line.notes!.trim().isNotEmpty) ...[
          //   SizedBox(
          //     height: context.h(3),
          //   ),
          //   Text(
          //     'Note: ${line.notes}',
          //     style: AppTextStyles.bodyTertiary(context).copyWith(
          //       color: colors.textSecondary,
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }

  // ===========================================================================
  // SUMMARY AMOUNT ROW
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
  // COMMON PANEL
  // ===========================================================================

  Widget _panel(
    BuildContext context,
    AppColorScheme colors,
    String title,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        context.h(14),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(
          context.h(8),
        ),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.section(context).copyWith(
              color: colors.textPrimary,
            ),
          ),
          SizedBox(
            height: context.h(14),
          ),
          ...children,
        ],
      ),
    );
  }
}
