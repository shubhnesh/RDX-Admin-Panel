// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:rdx_admin/screens/order_details/order_details_screen.dart';

// import '../../core/theme/app_colors.dart';
// import '../../core/theme/text_styles.dart';
// import '../../core/utils/responsive_size.dart';
// import '../../models/order_model.dart';
// import '../../providers/cart_provider.dart';
// import '../../providers/order_providers.dart';
// import '../../widgets/buttons/rdx_action_button.dart';
// import '../../widgets/reusable_widgets/rdx_header.dart';
// import '../../widgets/resuable_options/rdx_dropdown.dart';
// import '../../widgets/resuable_options/rdx_text_field.dart';

// class CheckoutScreen extends ConsumerStatefulWidget {
//   const CheckoutScreen({super.key});

//   @override
//   ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
// }

// class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _customerName = TextEditingController();
//   final _customerPhone = TextEditingController();
//   final _tableNumber = TextEditingController();
//   final _deliveryAddress = TextEditingController();
//   final _orderNotes = TextEditingController();

//   OrderType _orderType = OrderType.dineIn;
//   PaymentMethod _paymentMethod = PaymentMethod.cash;

//   @override
//   void dispose() {
//     _customerName.dispose();
//     _customerPhone.dispose();
//     _tableNumber.dispose();
//     _deliveryAddress.dispose();
//     _orderNotes.dispose();
//     super.dispose();
//   }

//   Future<void> _placeOrder() async {
//     if (!_formKey.currentState!.validate()) return;

//     final cart = ref.read(cartProvider);
//     if (cart.isEmpty) return;

//     final total = ref.read(cartTotalProvider);

//     final order = OrderModel(
//       id: '',
//       customerName: _customerName.text.trim(),
//       customerPhone: _customerPhone.text.trim(),
//       deliveryAddress:
//           _orderType == OrderType.delivery ? _deliveryAddress.text.trim() : '',
//       status: OrderStatus.pending,
//       total: total,
//       createdAt: DateTime.now(),
//       items: [
//         for (final line in cart)
//           OrderItemModel(
//             name: line.menuItem.name,
//             quantity: line.quantity,
//             price: line.unitPrice,
//             spiceLevel: line.spiceLevel,
//             addOns: line.addOns.map((a) => a.displayLabel).toList(),
//             notes: line.notes,
//           ),
//       ],
//       notes: _orderNotes.text.trim().isEmpty ? null : _orderNotes.text.trim(),
//       orderType: _orderType,
//       tableNumber:
//           _orderType == OrderType.dineIn ? _tableNumber.text.trim() : null,
//       paymentMethod: _paymentMethod,
//     );

//     // final success = await ref.read(placeOrderControllerProvider.notifier).submit(order);
//     // if (!mounted) return;

//     // if (success) {
//     //   ref.read(cartProvider.notifier).clear();
//     //   ScaffoldMessenger.of(context).showSnackBar(
//     //     const SnackBar(content: Text('Order placed successfully.')),
//     //   );
//     //   Navigator.of(context).pop(true);
//     // } else {
//     //   ScaffoldMessenger.of(context).showSnackBar(
//     //     const SnackBar(content: Text('Failed to place order. Please try again.')),
//     //   );
//     // }

//     // inside _placeOrder, replace the success handling

//     final success =
//         await ref.read(placeOrderControllerProvider.notifier).submit(order);
//     if (!mounted) return;

//     final newOrderId =
//         await ref.read(placeOrderControllerProvider.notifier).submit(order);

//     if (!mounted) return;

//     if (newOrderId != null && newOrderId.isNotEmpty) {
//       ref.read(cartProvider.notifier).clear();

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Order placed successfully.')),
//       );

//       // Navigate to the real Bill / Order Details screen with the server ID
//       Navigator.of(context).pushReplacement(
//         MaterialPageRoute(
//           builder: (_) => OrderDetailsScreen(orderId: newOrderId),
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//             content: Text('Failed to place order. Please try again.')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);
//     final cart = ref.watch(cartProvider);
//     final total = ref.watch(cartTotalProvider);
//     final placing = ref.watch(placeOrderControllerProvider).isLoading;

//     return Scaffold(
//       backgroundColor: colors.background,
//       body: Column(
//         children: [
//           const RdxHeader(title: 'Checkout', showBackButton: true),
//           Expanded(
//             child: Form(
//               key: _formKey,
//               child: SingleChildScrollView(
//                 padding: EdgeInsets.fromLTRB(
//                     context.w(20), context.h(16), context.w(20), context.h(28)),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _panel(context, colors, 'Order Summary', [
//                       for (final line in cart)
//                         Padding(
//                           padding: EdgeInsets.only(bottom: context.h(6)),
//                           child: Row(
//                             children: [
//                               Expanded(
//                                 child: Text(
//                                   '${line.quantity}x ${line.menuItem.name}',
//                                   style: AppTextStyles.body(context)
//                                       .copyWith(color: colors.textPrimary),
//                                 ),
//                               ),
//                               Text('₹${line.subtotal.toStringAsFixed(0)}',
//                                   style: AppTextStyles.body(context)
//                                       .copyWith(color: colors.textPrimary)),
//                             ],
//                           ),
//                         ),
//                       Divider(color: colors.divider, height: context.h(20)),
//                       Row(
//                         children: [
//                           Text('Total',
//                               style: AppTextStyles.section(context)
//                                   .copyWith(color: colors.textPrimary)),
//                           const Spacer(),
//                           Text('₹${total.toStringAsFixed(0)}',
//                               style: AppTextStyles.section(context)
//                                   .copyWith(color: colors.textPrimary)),
//                         ],
//                       ),
//                     ]),
//                     SizedBox(height: context.h(16)),
//                     _panel(context, colors, 'Customer Details', [
//                       RdxTextField(
//                         controller: _customerName,
//                         label: 'Customer Name *',
//                         hint: 'Enter customer name',
//                         validator: (v) =>
//                             v == null || v.trim().isEmpty ? 'Required' : null,
//                       ),
//                       SizedBox(height: context.h(14)),
//                       RdxTextField(
//                         controller: _customerPhone,
//                         label: 'Phone Number *',
//                         hint: 'Enter phone number',
//                         keyboardType: TextInputType.phone,
//                         validator: (v) =>
//                             v == null || v.trim().isEmpty ? 'Required' : null,
//                       ),
//                     ]),
//                     SizedBox(height: context.h(16)),
//                     _panel(context, colors, 'Order Type', [
//                       Wrap(
//                         spacing: context.w(8),
//                         runSpacing: context.h(8),
//                         children: [
//                           for (final type in OrderType.values)
//                             ChoiceChip(
//                               label: Text(type.label),
//                               selected: _orderType == type,
//                               onSelected: (_) =>
//                                   setState(() => _orderType = type),
//                               selectedColor:
//                                   AppColors.primary.withValues(alpha: 0.15),
//                               side: BorderSide(
//                                 color: _orderType == type
//                                     ? AppColors.primary
//                                     : colors.border,
//                               ),
//                               labelStyle: AppTextStyles.label(context).copyWith(
//                                 color: _orderType == type
//                                     ? AppColors.primary
//                                     : colors.textPrimary,
//                               ),
//                               backgroundColor: colors.surfaceVariant,
//                             ),
//                         ],
//                       ),
//                       if (_orderType == OrderType.dineIn) ...[
//                         SizedBox(height: context.h(14)),
//                         RdxTextField(
//                           controller: _tableNumber,
//                           label: 'Table Number *',
//                           hint: 'e.g. T-04',
//                           validator: (v) => _orderType == OrderType.dineIn &&
//                                   (v == null || v.trim().isEmpty)
//                               ? 'Required'
//                               : null,
//                         ),
//                       ],
//                       if (_orderType == OrderType.delivery) ...[
//                         SizedBox(height: context.h(14)),
//                         RdxTextField(
//                           controller: _deliveryAddress,
//                           label: 'Delivery Address *',
//                           hint: 'Enter delivery address',
//                           maxLines: 3,
//                           validator: (v) => _orderType == OrderType.delivery &&
//                                   (v == null || v.trim().isEmpty)
//                               ? 'Required'
//                               : null,
//                         ),
//                       ],
//                     ]),
//                     SizedBox(height: context.h(16)),
//                     _panel(context, colors, 'Payment', [
//                       RdxDropdown<PaymentMethod>(
//                         label: 'Payment Method',
//                         value: _paymentMethod,
//                         items: PaymentMethod.values,
//                         labelBuilder: (m) => m.label,
//                         hint: 'Select payment method',
//                         onChanged: (value) {
//                           if (value != null)
//                             setState(() => _paymentMethod = value);
//                         },
//                       ),
//                       SizedBox(height: context.h(14)),
//                       RdxTextField(
//                         controller: _orderNotes,
//                         label: 'Order Notes',
//                         hint: 'Any overall instructions for this order',
//                         maxLines: 3,
//                       ),
//                     ]),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           SafeArea(
//             top: false,
//             child: Padding(
//               padding: EdgeInsets.fromLTRB(
//                   context.w(20), context.h(10), context.w(20), context.h(14)),
//               child: RdxActionButton.save(
//                 isLoading: placing,
//                 onPressed: cart.isEmpty ? null : _placeOrder,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _panel(BuildContext context, AppColorScheme colors, String title,
//       List<Widget> children) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(context.h(14)),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(context.h(8)),
//         border: Border.all(color: colors.border),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title,
//               style: AppTextStyles.section(context)
//                   .copyWith(color: colors.textPrimary)),
//           SizedBox(height: context.h(14)),
//           ...children,
//         ],
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:rdx_admin/screens/order/bill_settlement_screen.dart';
// import 'package:rdx_admin/screens/order/place_order_screen.dart';
// import '../../core/theme/app_colors.dart';
// import '../../core/theme/text_styles.dart';
// import '../../core/utils/responsive_size.dart';
// import '../../models/order_model.dart';
// import '../../providers/cart_provider.dart';
// import '../../providers/order_providers.dart';
// import '../../widgets/buttons/rdx_action_button.dart';
// import '../../widgets/reusable_widgets/rdx_header.dart';
// import '../../widgets/resuable_options/rdx_dropdown.dart';
// import '../../widgets/resuable_options/rdx_text_field.dart';

// class CheckoutScreen extends ConsumerStatefulWidget {
//   const CheckoutScreen({super.key});

//   @override
//   ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
// }

// class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
//   final _formKey = GlobalKey<FormState>();

//   final _customerName = TextEditingController();
//   final _customerPhone = TextEditingController();
//   final _tableNumber = TextEditingController();
//   final _deliveryAddress = TextEditingController();
//   final _orderNotes = TextEditingController();

//   OrderType _orderType = OrderType.dineIn;
//   // PaymentMethod _paymentMethod = PaymentMethod.cash;

//   @override
//   void dispose() {
//     _customerName.dispose();
//     _customerPhone.dispose();
//     _tableNumber.dispose();
//     _deliveryAddress.dispose();
//     _orderNotes.dispose();
//     super.dispose();
//   }

//   // Future<void> _placeOrder() async {
//   //   if (!_formKey.currentState!.validate()) return;

//   //   final cart = ref.read(cartProvider);

//   //   if (cart.isEmpty) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(
//   //         content: Text('Your order is empty. Please add items first.'),
//   //       ),
//   //     );
//   //     return;
//   //   }

//   //   final total = ref.read(cartTotalProvider);

//   //   final order = OrderModel(
//   //     id: '',
//   //     customerName: _customerName.text.trim(),
//   //     customerPhone: _customerPhone.text.trim(),
//   //     deliveryAddress:
//   //         _orderType == OrderType.delivery ? _deliveryAddress.text.trim() : '',
//   //     status: OrderStatus.pending,
//   //     total: total,
//   //     createdAt: DateTime.now(),
//   //     items: [
//   //       for (final line in cart)
//   //         OrderItemModel(
//   //           name: line.menuItem.name,
//   //           quantity: line.quantity,
//   //           price: line.unitPrice,
//   //           spiceLevel: line.spiceLevel,
//   //           addOns: line.addOns.map((a) => a.displayLabel).toList(),
//   //           notes: line.notes,
//   //         ),
//   //     ],
//   //     notes: _orderNotes.text.trim().isEmpty ? null : _orderNotes.text.trim(),
//   //     orderType: _orderType,
//   //     tableNumber:
//   //         _orderType == OrderType.dineIn ? _tableNumber.text.trim() : null,
//   //     paymentMethod: _paymentMethod,
//   //   );

//   //   // Submit the order only once.
//   //   final newOrderId =
//   //       await ref.read(placeOrderControllerProvider.notifier).submit(order);

//   //   if (!mounted) return;

//   //   if (newOrderId != null && newOrderId.isNotEmpty) {
//   //     ref.read(cartProvider.notifier).clear();

//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(
//   //         content: Text('Order placed successfully.'),
//   //       ),
//   //     );

//   //     Navigator.of(context).pushReplacement(
//   //       MaterialPageRoute(
//   //         builder: (_) => OrderDetailsScreen(
//   //           orderId: newOrderId,
//   //         ),
//   //       ),
//   //     );
//   //   } else {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(
//   //         content: Text(
//   //           'Failed to place order. Please try again.',
//   //         ),
//   //       ),
//   //     );
//   //   }
//   // }

//   // Future<void> _placeOrder() async {
//   //   if (!_formKey.currentState!.validate()) return;

//   //   final cart = ref.read(cartProvider);

//   //   if (cart.isEmpty) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(
//   //         content: Text('Your order is empty. Please add items first.'),
//   //       ),
//   //     );
//   //     return;
//   //   }

//   //   final total = ref.read(cartTotalProvider);

//   //   final order = OrderModel(
//   //     id: '',
//   //     customerName: _customerName.text.trim(),
//   //     customerPhone: _customerPhone.text.trim(),
//   //     deliveryAddress:
//   //         _orderType == OrderType.delivery ? _deliveryAddress.text.trim() : '',
//   //     status: OrderStatus.pending,
//   //     total: total,
//   //     createdAt: DateTime.now(),

//   //     items: [
//   //       for (final line in cart)
//   //         OrderItemModel(
//   //           name: line.menuItem.name,
//   //           quantity: line.quantity,
//   //           price: line.unitPrice,
//   //           spiceLevel: line.spiceLevel,
//   //           addOns: line.addOns.map((addOn) => addOn.displayLabel).toList(),
//   //           notes: line.notes,
//   //         ),
//   //     ],

//   //     notes: _orderNotes.text.trim().isEmpty ? null : _orderNotes.text.trim(),

//   //     orderType: _orderType,

//   //     tableNumber:
//   //         _orderType == OrderType.dineIn ? _tableNumber.text.trim() : null,

//   //     // No payment method here.
//   //   );

//   //   try {
//   //     final newOrderId =
//   //         await ref.read(placeOrderControllerProvider.notifier).submit(order);

//   //     if (!mounted) return;

//   //     if (newOrderId == null || newOrderId.isEmpty) {
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         const SnackBar(
//   //           content: Text(
//   //             'Failed to place order. Please try again.',
//   //           ),
//   //         ),
//   //       );
//   //       return;
//   //     }

//   //     // The order has successfully been created in Firestore.
//   //     ref.read(cartProvider.notifier).clear();

//   //     Navigator.of(context).pushReplacement(
//   //       MaterialPageRoute(
//   //         builder: (_) => OrderDetailsScreen(
//   //           orderId: newOrderId,
//   //         ),
//   //       ),
//   //     );
//   //   } catch (e) {
//   //     if (!mounted) return;

//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(
//   //         content: Text(
//   //           'Failed to place order. Please try again.',
//   //         ),
//   //       ),
//   //     );
//   //   }
//   // }

//   Future<void> _placeOrder() async {
//     if (!_formKey.currentState!.validate()) return;

//     final cart = ref.read(cartProvider);

//     if (cart.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Your order is empty. Please add items first.',
//           ),
//         ),
//       );
//       return;
//     }

//     final total = ref.read(cartTotalProvider);

//     final order = OrderModel(
//       id: '',
//       customerName: _customerName.text.trim(),
//       customerPhone: _customerPhone.text.trim(),
//       deliveryAddress:
//           _orderType == OrderType.delivery ? _deliveryAddress.text.trim() : '',
//       status: OrderStatus.pending,
//       total: total,
//       createdAt: DateTime.now(),
//       items: [
//         for (final line in cart)
//           OrderItemModel(
//             name: line.menuItem.name,
//             quantity: line.quantity,
//             price: line.unitPrice,
//             spiceLevel: line.spiceLevel,
//             addOns: line.addOns.map((addOn) => addOn.displayLabel).toList(),
//             notes: line.notes,
//           ),
//       ],
//       notes: _orderNotes.text.trim().isEmpty ? null : _orderNotes.text.trim(),
//       orderType: _orderType,
//       tableNumber:
//           _orderType == OrderType.dineIn ? _tableNumber.text.trim() : null,

//       // Payment is intentionally not set here.
//       // paymentMethod remains null until settlement.
//     );

//     try {
//       final newOrderId =
//           await ref.read(placeOrderControllerProvider.notifier).submit(order);

//       if (!mounted) return;

//       if (newOrderId == null || newOrderId.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Failed to place order. Please try again.',
//             ),
//           ),
//         );
//         return;
//       }

//       ref.read(cartProvider.notifier).clear();

//       // Navigate to Bill & Receipt Settlement.
//       Navigator.of(context).pushReplacement(
//         MaterialPageRoute(
//           builder: (_) => BillSettlementScreen(
//             bill: BillSettlementData(
//               orderNumber: newOrderId,
//               restaurantName: 'RDX Restaurant',
//               orderType: _orderType.label,
//               tableNumber: _orderType == OrderType.dineIn
//                   ? _tableNumber.text.trim()
//                   : null,
//               billingMode: 'Dine-in',
//               cashier: 'Staff',
//               server: 'Staff',
//               kitchenName: 'Main Kitchen',
//               sequence: '',
//               covers: 1,
//               items: [
//                 for (final line in cart)
//                   BillItemData(
//                     name: line.menuItem.name,
//                     quantity: line.quantity,
//                     amount: line.subtotal,
//                     modifiers: [
//                       if (line.spiceLevel != null &&
//                           line.spiceLevel!.trim().isNotEmpty)
//                         'Spice: ${line.spiceLevel}',
//                       ...line.addOns.map(
//                         (addOn) => addOn.displayLabel,
//                       ),
//                       if (line.notes != null && line.notes!.trim().isNotEmpty)
//                         'Note: ${line.notes}',
//                     ],
//                   ),
//               ],
//               paymentMethod: null,
//               cardLastFour: null,
//               subtotal: total,
//               taxPercentage: 0,
//               guestName: _customerName.text.trim().isEmpty
//                   ? 'Walk-in Customer'
//                   : _customerName.text.trim(),
//               phoneNumber: _customerPhone.text.trim(),
//               sendDigitalReceipt: false,
//               invoiceReference: newOrderId,
//               receiptDateTime: DateTime.now(),
//             ),
//           ),
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Failed to place order. Please try again.',
//           ),
//         ),
//       );
//     }
//   }

//   void _editOrder() {
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(
//         builder: (_) => const PlaceOrderScreen(),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);
//     final cart = ref.watch(cartProvider);
//     final total = ref.watch(cartTotalProvider);
//     final placing = ref.watch(placeOrderControllerProvider).isLoading;

//     return Scaffold(
//       backgroundColor: colors.background,
//       body: Column(
//         children: [
//           const RdxHeader(
//             title: 'Checkout',
//             showBackButton: true,
//           ),
//           Expanded(
//             child: Form(
//               key: _formKey,
//               child: SingleChildScrollView(
//                 padding: EdgeInsets.fromLTRB(
//                   context.w(20),
//                   context.h(16),
//                   context.w(20),
//                   context.h(28),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildOrderSummary(
//                       context,
//                       colors,
//                       cart,
//                       total,
//                     ),
//                     SizedBox(height: context.h(16)),
//                     _panel(
//                       context,
//                       colors,
//                       'Customer Details',
//                       [
//                         RdxTextField(
//                           controller: _customerName,
//                           label: 'Customer Name(Optional)',
//                           hint: 'Enter customer name',
//                           // validator: (value) {
//                           //   if (value == null || value.trim().isEmpty) {
//                           //     return 'Required';
//                           //   }

//                           //   return null;
//                           // },
//                         ),
//                         SizedBox(height: context.h(14)),
//                         RdxTextField(
//                           controller: _customerPhone,
//                           label: 'Phone Number(Optional)',
//                           hint: 'Enter phone number',
//                           keyboardType: TextInputType.phone,
//                           // validator: (value) {
//                           //   if (value == null || value.trim().isEmpty) {
//                           //     return 'Required';
//                           //   }

//                           //   return null;
//                           // },
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: context.h(16)),
//                     _panel(
//                       context,
//                       colors,
//                       'Order Type',
//                       [
//                         RdxDropdown<OrderType>(
//                           label: 'Order Type',
//                           value: _orderType,
//                           items: OrderType.values,
//                           labelBuilder: (type) => type.label,
//                           hint: 'Select order type',
//                           onChanged: (value) {
//                             if (value == null) return;

//                             setState(() {
//                               _orderType = value;
//                             });
//                           },
//                         ),
//                         if (_orderType == OrderType.dineIn) ...[
//                           SizedBox(height: context.h(14)),
//                           RdxTextField(
//                             controller: _tableNumber,
//                             label: 'Table Number *',
//                             hint: 'e.g. T-04',
//                             validator: (value) {
//                               if (_orderType == OrderType.dineIn &&
//                                   (value == null || value.trim().isEmpty)) {
//                                 return 'Required';
//                               }

//                               return null;
//                             },
//                           ),
//                         ],
//                         if (_orderType == OrderType.delivery) ...[
//                           SizedBox(height: context.h(14)),
//                           RdxTextField(
//                             controller: _deliveryAddress,
//                             label: 'Delivery Address *',
//                             hint: 'Enter delivery address',
//                             maxLines: 3,
//                             validator: (value) {
//                               if (_orderType == OrderType.delivery &&
//                                   (value == null || value.trim().isEmpty)) {
//                                 return 'Required';
//                               }

//                               return null;
//                             },
//                           ),
//                         ],
//                       ],
//                     ),
//                     // SizedBox(height: context.h(16)),
//                     // _panel(
//                     //   context,
//                     //   colors,
//                     //   'Payment',
//                     //   [
//                     //     RdxDropdown<PaymentMethod>(
//                     //       label: 'Payment Method',
//                     //       value: _paymentMethod,
//                     //       items: PaymentMethod.values,
//                     //       labelBuilder: (method) => method.label,
//                     //       hint: 'Select payment method',
//                     //       onChanged: (value) {
//                     //         if (value == null) return;

//                     //         setState(() {
//                     //           _paymentMethod = value;
//                     //         });
//                     //       },
//                     //     ),
//                     //     SizedBox(height: context.h(14)),
//                     //     RdxTextField(
//                     //       controller: _orderNotes,
//                     //       label: 'Order Notes',
//                     //       hint: 'Any overall instructions for this order',
//                     //       maxLines: 3,
//                     //     ),
//                     //   ],
//                     // ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           SafeArea(
//             top: false,
//             child: Padding(
//               padding: EdgeInsets.fromLTRB(
//                 context.w(20),
//                 context.h(10),
//                 context.w(20),
//                 context.h(14),
//               ),
//               child: RdxActionButton.save(
//                 isLoading: placing,
//                 onPressed: cart.isEmpty ? null : _placeOrder,
//                 backgroundColor: Colors.red,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOrderSummary(
//     BuildContext context,
//     AppColorScheme colors,
//     List cart,
//     double total,
//   ) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(context.h(14)),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(context.h(8)),
//         border: Border.all(
//           color: colors.border,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   'Order Summary',
//                   style: AppTextStyles.section(context).copyWith(
//                     color: colors.textPrimary,
//                   ),
//                 ),
//               ),
//               TextButton.icon(
//                 onPressed: _editOrder,
//                 style: TextButton.styleFrom(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: context.w(8),
//                     vertical: context.h(6),
//                   ),
//                   minimumSize: Size.zero,
//                   tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                 ),
//                 icon: Icon(
//                   Icons.edit_outlined,
//                   size: context.h(16),
//                   color: AppColors.primary,
//                 ),
//                 label: Text(
//                   'Edit Order',
//                   style: AppTextStyles.label(context).copyWith(
//                     color: AppColors.primary,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: context.h(14)),
//           if (cart.isEmpty)
//             Text(
//               'No items in the order.',
//               style: AppTextStyles.body(context).copyWith(
//                 color: colors.textSecondary,
//               ),
//             )
//           else
//             for (final line in cart)
//               _buildSummaryItem(
//                 context,
//                 colors,
//                 line,
//               ),
//           Divider(
//             color: colors.divider,
//             height: context.h(20),
//           ),
//           Row(
//             children: [
//               Text(
//                 'Total',
//                 style: AppTextStyles.section(context).copyWith(
//                   color: colors.textPrimary,
//                 ),
//               ),
//               const Spacer(),
//               Text(
//                 '₹${total.toStringAsFixed(0)}',
//                 style: AppTextStyles.section(context).copyWith(
//                   color: AppColors.primary,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSummaryItem(
//     BuildContext context,
//     AppColorScheme colors,
//     dynamic line,
//   ) {
//     return Padding(
//       padding: EdgeInsets.only(
//         bottom: context.h(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: Text(
//                   '${line.quantity}x ${line.menuItem.name}',
//                   style: AppTextStyles.body(context).copyWith(
//                     color: colors.textPrimary,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//               SizedBox(width: context.w(12)),
//               Text(
//                 '₹${line.subtotal.toStringAsFixed(0)}',
//                 style: AppTextStyles.body(context).copyWith(
//                   color: colors.textPrimary,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: context.h(4)),
//           Text(
//             '₹${line.unitPrice.toStringAsFixed(0)} each',
//             style: AppTextStyles.caption(context).copyWith(
//               color: colors.textSecondary,
//             ),
//           ),
//           if (line.spiceLevel != null &&
//               line.spiceLevel.toString().trim().isNotEmpty) ...[
//             SizedBox(height: context.h(3)),
//             Text(
//               'Spice: ${line.spiceLevel}',
//               style: AppTextStyles.caption(context).copyWith(
//                 color: colors.textSecondary,
//               ),
//             ),
//           ],
//           if (line.addOns.isNotEmpty) ...[
//             SizedBox(height: context.h(3)),
//             Text(
//               'Add-ons: ${line.addOns.map((a) => a.displayLabel).join(', ')}',
//               style: AppTextStyles.caption(context).copyWith(
//                 color: colors.textSecondary,
//               ),
//             ),
//           ],
//           if (line.notes != null &&
//               line.notes.toString().trim().isNotEmpty) ...[
//             SizedBox(height: context.h(3)),
//             Text(
//               'Note: ${line.notes}',
//               style: AppTextStyles.caption(context).copyWith(
//                 color: colors.textSecondary,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _panel(
//     BuildContext context,
//     AppColorScheme colors,
//     String title,
//     List<Widget> children,
//   ) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(
//         context.h(14),
//       ),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(
//           context.h(8),
//         ),
//         border: Border.all(
//           color: colors.border,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: AppTextStyles.section(context).copyWith(
//               color: colors.textPrimary,
//             ),
//           ),
//           SizedBox(height: context.h(14)),
//           ...children,
//         ],
//       ),
//     );
//   }
// }

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cart = ref.read(cartProvider);

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your order is empty. Please add items first.',
          ),
        ),
      );
      return;
    }

    final total = ref.read(cartTotalProvider);

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
      tableNumber:
          _orderType == OrderType.dineIn ? _tableNumber.text.trim() : null,
    );

    final newOrderId =
        await ref.read(placeOrderControllerProvider.notifier).submit(order);

    if (!mounted) {
      return;
    }

    if (newOrderId == null || newOrderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to place order. Please try again.',
          ),
        ),
      );
      return;
    }

    /*
     * Copy everything required by settlement BEFORE clearing
     * the cart.
     */
    final billItems = [
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

    // Firestore order has been created successfully.
    ref.read(cartProvider.notifier).clear();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BillSettlementScreen(
          bill: BillSettlementData(
            orderNumber: newOrderId,
            restaurantName: 'RDX Restaurant',
            orderType: _orderType.label,
            tableNumber: _orderType == OrderType.dineIn
                ? _tableNumber.text.trim()
                : null,
            billingMode: _orderType.label,
            cashier: 'Staff',
            server: 'Staff',
            kitchenName: 'Main Kitchen',
            sequence: null,
            covers: 1,
            items: billItems,
            paymentMethod: null,
            cardLastFour: null,
            subtotal: total,
            taxPercentage: 0,
            guestName: guestName,
            phoneNumber: phoneNumber,
            sendDigitalReceipt: false,
            invoiceReference: newOrderId,
            receiptDateTime: DateTime.now(),
          ),
        ),
      ),
    );
  }

  void _editOrder() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const PlaceOrderScreen(),
      ),
    );
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
                    _buildOrderSummary(
                      context,
                      colors,
                      cart,
                      total,
                    ),
                    SizedBox(height: context.h(16)),
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
                        SizedBox(height: context.h(14)),
                        RdxTextField(
                          controller: _customerPhone,
                          label: 'Phone Number (Optional)',
                          hint: 'Enter phone number',
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                    SizedBox(height: context.h(16)),
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
                            });
                          },
                        ),
                        if (_orderType == OrderType.dineIn) ...[
                          SizedBox(height: context.h(14)),
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
                  ],
                ),
              ),
            ),
          ),
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
                backgroundColor: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(
    BuildContext context,
    AppColorScheme colors,
    List<CartLineItem> cart,
    double total,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.h(14)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  Icons.edit_outlined,
                  size: context.h(16),
                  color: AppColors.primary,
                ),
                label: Text(
                  'Edit Order',
                  style: AppTextStyles.label(context).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(14)),
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
          Divider(
            color: colors.divider,
            height: context.h(20),
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
            style: AppTextStyles.caption(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (line.spiceLevel != null &&
              line.spiceLevel!.trim().isNotEmpty) ...[
            SizedBox(height: context.h(3)),
            Text(
              'Spice: ${line.spiceLevel}',
              style: AppTextStyles.caption(context).copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          if (line.addOns.isNotEmpty) ...[
            SizedBox(height: context.h(3)),
            Text(
              'Add-ons: ${line.addOns.map((a) => a.displayLabel).join(', ')}',
              style: AppTextStyles.caption(context).copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          if (line.notes != null && line.notes!.trim().isNotEmpty) ...[
            SizedBox(height: context.h(3)),
            Text(
              'Note: ${line.notes}',
              style: AppTextStyles.caption(context).copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _panel(
    BuildContext context,
    AppColorScheme colors,
    String title,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.h(14)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(8)),
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
          SizedBox(height: context.h(14)),
          ...children,
        ],
      ),
    );
  }
}
