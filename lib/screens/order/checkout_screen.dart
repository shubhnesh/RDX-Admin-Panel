import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  @override
  void dispose() {
    _customerName.dispose();
    _customerPhone.dispose();
    _tableNumber.dispose();
    _deliveryAddress.dispose();
    _orderNotes.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final total = ref.read(cartTotalProvider);

    final order = OrderModel(
      id: '',
      customerName: _customerName.text.trim(),
      customerPhone: _customerPhone.text.trim(),
      deliveryAddress: _orderType == OrderType.delivery ? _deliveryAddress.text.trim() : '',
      status: OrderStatus.pending,
      total: total,
      createdAt: DateTime.now(),
      items: [
        for (final line in cart)
          OrderItemModel(
            name: line.menuItem.name,
            quantity: line.quantity,
            price: line.unitPrice,
            spiceLevel: line.spiceLevel,
            addOns: line.addOns.map((a) => a.displayLabel).toList(),
            notes: line.notes,
          ),
      ],
      notes: _orderNotes.text.trim().isEmpty ? null : _orderNotes.text.trim(),
      orderType: _orderType,
      tableNumber: _orderType == OrderType.dineIn ? _tableNumber.text.trim() : null,
      paymentMethod: _paymentMethod,
    );

    final success = await ref.read(placeOrderControllerProvider.notifier).submit(order);
    if (!mounted) return;

    if (success) {
      ref.read(cartProvider.notifier).clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully.')),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to place order. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final placing = ref.watch(placeOrderControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const RdxHeader(title: 'Checkout', showBackButton: true),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(context.w(20), context.h(16), context.w(20), context.h(28)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _panel(context, colors, 'Order Summary', [
                      for (final line in cart)
                        Padding(
                          padding: EdgeInsets.only(bottom: context.h(6)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${line.quantity}x ${line.menuItem.name}',
                                  style: AppTextStyles.body(context).copyWith(color: colors.textPrimary),
                                ),
                              ),
                              Text('₹${line.subtotal.toStringAsFixed(0)}',
                                  style: AppTextStyles.body(context).copyWith(color: colors.textPrimary)),
                            ],
                          ),
                        ),
                      Divider(color: colors.divider, height: context.h(20)),
                      Row(
                        children: [
                          Text('Total',
                              style: AppTextStyles.section(context).copyWith(color: colors.textPrimary)),
                          const Spacer(),
                          Text('₹${total.toStringAsFixed(0)}',
                              style: AppTextStyles.section(context).copyWith(color: colors.textPrimary)),
                        ],
                      ),
                    ]),
                    SizedBox(height: context.h(16)),
                    _panel(context, colors, 'Customer Details', [
                      RdxTextField(
                        controller: _customerName,
                        label: 'Customer Name *',
                        hint: 'Enter customer name',
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: context.h(14)),
                      RdxTextField(
                        controller: _customerPhone,
                        label: 'Phone Number *',
                        hint: 'Enter phone number',
                        keyboardType: TextInputType.phone,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ]),
                    SizedBox(height: context.h(16)),
                    _panel(context, colors, 'Order Type', [
                      Wrap(
                        spacing: context.w(8),
                        runSpacing: context.h(8),
                        children: [
                          for (final type in OrderType.values)
                            ChoiceChip(
                              label: Text(type.label),
                              selected: _orderType == type,
                              onSelected: (_) => setState(() => _orderType = type),
                              selectedColor: AppColors.primary.withValues(alpha: 0.15),
                              side: BorderSide(
                                color: _orderType == type ? AppColors.primary : colors.border,
                              ),
                              labelStyle: AppTextStyles.label(context).copyWith(
                                color: _orderType == type ? AppColors.primary : colors.textPrimary,
                              ),
                              backgroundColor: colors.surfaceVariant,
                            ),
                        ],
                      ),
                      if (_orderType == OrderType.dineIn) ...[
                        SizedBox(height: context.h(14)),
                        RdxTextField(
                          controller: _tableNumber,
                          label: 'Table Number *',
                          hint: 'e.g. T-04',
                          validator: (v) =>
                              _orderType == OrderType.dineIn && (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                        ),
                      ],
                      if (_orderType == OrderType.delivery) ...[
                        SizedBox(height: context.h(14)),
                        RdxTextField(
                          controller: _deliveryAddress,
                          label: 'Delivery Address *',
                          hint: 'Enter delivery address',
                          maxLines: 3,
                          validator: (v) =>
                              _orderType == OrderType.delivery && (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                        ),
                      ],
                    ]),
                    SizedBox(height: context.h(16)),
                    _panel(context, colors, 'Payment', [
                      RdxDropdown<PaymentMethod>(
                        label: 'Payment Method',
                        value: _paymentMethod,
                        items: PaymentMethod.values,
                        labelBuilder: (m) => m.label,
                        hint: 'Select payment method',
                        onChanged: (value) {
                          if (value != null) setState(() => _paymentMethod = value);
                        },
                      ),
                      SizedBox(height: context.h(14)),
                      RdxTextField(
                        controller: _orderNotes,
                        label: 'Order Notes',
                        hint: 'Any overall instructions for this order',
                        maxLines: 3,
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(context.w(20), context.h(10), context.w(20), context.h(14)),
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

  Widget _panel(BuildContext context, AppColorScheme colors, String title, List<Widget> children) {
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
          Text(title, style: AppTextStyles.section(context).copyWith(color: colors.textPrimary)),
          SizedBox(height: context.h(14)),
          ...children,
        ],
      ),
    );
  }
}
