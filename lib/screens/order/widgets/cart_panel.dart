// // import 'package:flutter/material.dart';
// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'package:rdx_admin/screens/order/checkout_screen.dart';
// // import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
// // import '../../../core/theme/app_colors.dart';
// // import '../../../core/theme/text_styles.dart';
// // import '../../../core/utils/responsive_size.dart';
// // import '../../../providers/cart_provider.dart';
// // import '../../../models/cart_item_model.dart';

// // class CartPanel extends ConsumerWidget {
// //   final VoidCallback? onClose;
// //   final VoidCallback? onSendToKitchen;

// //   const CartPanel({
// //     super.key,
// //     this.onClose,
// //     this.onSendToKitchen,
// //   });

// //   @override
// //   Widget build(BuildContext context, WidgetRef ref) {
// //     final colors = AppColors.of(context);

// //     final cart = ref.watch(cartProvider);
// //     final subtotal = ref.watch(cartTotalProvider);

// //     // Kept separate so the calculation is easy to change later
// //     // when your actual restaurant tax configuration is connected.
// //     final tax = subtotal * 0.08;
// //     final total = subtotal + tax;

// //     return Container(
// //       decoration: BoxDecoration(
// //         color: colors.surface,
// //         borderRadius: BorderRadius.circular(
// //           context.h(10),
// //         ),
// //         border: Border.all(
// //           color: colors.border,
// //         ),
// //       ),
// //       child: Column(
// //         children: [
// //           // -----------------------------------------------------------------
// //           // HEADER
// //           // -----------------------------------------------------------------
// //           Padding(
// //             padding: EdgeInsets.fromLTRB(
// //               context.w(12),
// //               context.h(10),
// //               context.w(10),
// //               context.h(8),
// //             ),
// //             child: Row(
// //               children: [
// //                 Text(
// //                   'Active Order',
// //                   style: AppTextStyles.section(context).copyWith(
// //                     fontSize: context.h(14),
// //                     fontWeight: FontWeight.w600,
// //                   ),
// //                 ),
// //                 SizedBox(width: context.w(5)),
// //                 Text(
// //                   '#206',
// //                   style: AppTextStyles.caption(context).copyWith(
// //                     fontSize: context.h(9),
// //                     color: colors.textMuted,
// //                   ),
// //                 ),
// //                 const Spacer(),
// //                 Container(
// //                   padding: EdgeInsets.symmetric(
// //                     horizontal: context.w(7),
// //                     vertical: context.h(3),
// //                   ),
// //                   decoration: BoxDecoration(
// //                     color: AppColors.primary,
// //                     borderRadius: BorderRadius.circular(
// //                       context.h(7),
// //                     ),
// //                   ),
// //                   child: Text(
// //                     'NEW',
// //                     style: AppTextStyles.caption(context).copyWith(
// //                       fontSize: context.h(7),
// //                       color: Colors.white,
// //                       fontWeight: FontWeight.w700,
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),

// //           Divider(
// //             height: 1,
// //             color: colors.divider,
// //           ),

// //           // -----------------------------------------------------------------
// //           // ORDER TYPE / TABLE
// //           // -----------------------------------------------------------------
// //           Padding(
// //             padding: EdgeInsets.symmetric(
// //               horizontal: context.w(12),
// //               vertical: context.h(7),
// //             ),
// //             child: Row(
// //               children: [
// //                 Icon(
// //                   Icons.table_restaurant_outlined,
// //                   size: context.h(12),
// //                   color: colors.textMuted,
// //                 ),
// //                 SizedBox(width: context.w(4)),
// //                 Text(
// //                   'Eat In • Table 4',
// //                   style: AppTextStyles.caption(context).copyWith(
// //                     fontSize: context.h(9),
// //                     color: colors.textSecondary,
// //                   ),
// //                 ),
// //                 const Spacer(),
// //                 Text(
// //                   'CHANGE',
// //                   style: AppTextStyles.caption(context).copyWith(
// //                     fontSize: context.h(8),
// //                     color: AppColors.primary,
// //                     fontWeight: FontWeight.w600,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),

// //           Divider(
// //             height: 1,
// //             color: colors.divider,
// //           ),

// //           // -----------------------------------------------------------------
// //           // CART ITEMS
// //           // -----------------------------------------------------------------
// //           Expanded(
// //             child: cart.isEmpty
// //                 ? _emptyCart(
// //                     context,
// //                     colors,
// //                   )
// //                 : ListView.separated(
// //                     padding: EdgeInsets.symmetric(
// //                       horizontal: context.w(10),
// //                       vertical: context.h(7),
// //                     ),
// //                     itemCount: cart.length,
// //                     separatorBuilder: (_, __) => Divider(
// //                       height: context.h(12),
// //                       color: colors.divider,
// //                     ),
// //                     itemBuilder: (context, index) {
// //                       return _CartItem(
// //                         line: cart[index],
// //                       );
// //                     },
// //                   ),
// //           ),

// //           // -----------------------------------------------------------------
// //           // BOTTOM SUMMARY
// //           // -----------------------------------------------------------------
// //           Container(
// //               padding: EdgeInsets.fromLTRB(
// //                 context.w(12),
// //                 context.h(8),
// //                 context.w(12),
// //                 context.h(10),
// //               ),
// //               decoration: BoxDecoration(
// //                 border: Border(
// //                   top: BorderSide(
// //                     color: colors.border,
// //                   ),
// //                 ),
// //               ),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.stretch,
// //                 children: [
// //                   // subtotal
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                     children: [
// //                       Text(
// //                         'Subtotal',
// //                         style: AppTextStyles.caption(context),
// //                       ),
// //                       Text(
// //                         '₹${subtotal.toStringAsFixed(2)}',
// //                         style: AppTextStyles.caption(context),
// //                       ),
// //                     ],
// //                   ),

// //                   SizedBox(height: context.h(6)),

// //                   // tax
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                     children: [
// //                       Text(
// //                         'Tax (8%)',
// //                         style: AppTextStyles.caption(context),
// //                       ),
// //                       Text(
// //                         '₹${tax.toStringAsFixed(2)}',
// //                         style: AppTextStyles.caption(context),
// //                       ),
// //                     ],
// //                   ),

// //                   SizedBox(height: context.h(10)),

// //                   // total
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                     children: [
// //                       Text(
// //                         'Total Due',
// //                         style: AppTextStyles.section(context),
// //                       ),
// //                       Text(
// //                         '₹${total.toStringAsFixed(2)}',
// //                         style: AppTextStyles.heading(context).copyWith(
// //                           color: AppColors.primary,
// //                           fontWeight: FontWeight.w700,
// //                         ),
// //                       ),
// //                     ],
// //                   ),

// //                   SizedBox(height: context.h(14)),

// //                   // Proceed
// //                   SizedBox(
// //                     width: double.infinity,
// //                     child: RdxActionButton(
// //                       label: 'Proceed',
// //                       isPrimary: true,
// //                       onPressed: cart.isEmpty
// //                           ? null
// //                           : () => Navigator.of(context).push(
// //                                 MaterialPageRoute(
// //                                   builder: (_) => const CheckoutScreen(),
// //                                 ),
// //                               ),
// //                     ),
// //                   ),
// //                   SizedBox(
// //                     height: context.h(2),
// //                   ),
// //                   SizedBox(
// //                     width: double.infinity,
// //                     child: RdxActionButton(
// //                       label: 'Cancel',
// //                       isPrimary: true,
// //                       onPressed: cart.isEmpty
// //                           ? null
// //                           : () {
// //                               ref.read(cartProvider.notifier).clear();
// //                             },
// //                     ),
// //                   ),
// //                 ],
// //               )),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _emptyCart(
// //     BuildContext context,
// //     AppColorScheme colors,
// //   ) {
// //     return Center(
// //       child: Padding(
// //         padding: EdgeInsets.all(
// //           context.h(20),
// //         ),
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Icon(
// //               Icons.shopping_cart_outlined,
// //               size: context.h(30),
// //               color: colors.textMuted,
// //             ),
// //             SizedBox(height: context.h(8)),
// //             Text(
// //               'No items added',
// //               style: AppTextStyles.label(context).copyWith(
// //                 color: colors.textSecondary,
// //                 fontWeight: FontWeight.w600,
// //               ),
// //             ),
// //             SizedBox(height: context.h(3)),
// //             Text(
// //               'Select items from the menu',
// //               textAlign: TextAlign.center,
// //               style: AppTextStyles.caption(context).copyWith(
// //                 color: colors.textMuted,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _summaryRow(
// //     BuildContext context,
// //     String label,
// //     String value,
// //   ) {
// //     final colors = AppColors.of(context);

// //     return Row(
// //       children: [
// //         Text(
// //           label,
// //           style: AppTextStyles.caption(context).copyWith(
// //             fontSize: context.h(9),
// //             color: colors.textSecondary,
// //           ),
// //         ),
// //         const Spacer(),
// //         Text(
// //           value,
// //           style: AppTextStyles.caption(context).copyWith(
// //             fontSize: context.h(9),
// //             color: colors.textPrimary,
// //             fontWeight: FontWeight.w500,
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }

// // // =============================================================================
// // // CART ITEM
// // // =============================================================================

// // class _CartItem extends ConsumerWidget {
// //   final CartLineItem line;

// //   const _CartItem({
// //     required this.line,
// //   });

// //   @override
// //   Widget build(BuildContext context, WidgetRef ref) {
// //     final colors = AppColors.of(context);

// //     final cartNotifier = ref.read(cartProvider.notifier);

// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         // ---------------------------------------------------------------------
// //         // NAME + PRICE
// //         // ---------------------------------------------------------------------
// //         Row(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Expanded(
// //               child: Text(
// //                 line.menuItem.name,
// //                 maxLines: 1,
// //                 overflow: TextOverflow.ellipsis,
// //                 style: AppTextStyles.label(context).copyWith(
// //                   fontSize: context.h(10),
// //                   color: colors.textPrimary,
// //                   fontWeight: FontWeight.w600,
// //                 ),
// //               ),
// //             ),
// //             SizedBox(width: context.w(5)),
// //             Text(
// //               '₹${line.subtotal.toStringAsFixed(2)}',
// //               style: AppTextStyles.caption(context).copyWith(
// //                 fontSize: context.h(9),
// //                 color: colors.textPrimary,
// //                 fontWeight: FontWeight.w600,
// //               ),
// //             ),
// //           ],
// //         ),

// //         SizedBox(height: context.h(2)),

// //         // ---------------------------------------------------------------------
// //         // UNIT PRICE
// //         // ---------------------------------------------------------------------
// //         Text(
// //           '₹${line.menuItem.price.toStringAsFixed(2)} each',
// //           style: AppTextStyles.caption(context).copyWith(
// //             fontSize: context.h(8),
// //             color: colors.textMuted,
// //           ),
// //         ),

// //         SizedBox(height: context.h(5)),

// //         // ---------------------------------------------------------------------
// //         // QUANTITY CONTROL
// //         // ---------------------------------------------------------------------
// //         Row(
// //           children: [
// //             _quantityButton(
// //               context,
// //               icon: Icons.remove,
// //               onPressed: () {
// //                 cartNotifier.updateQuantity(
// //                   line.id,
// //                   line.quantity - 1,
// //                 );
// //               },
// //             ),
// //             Container(
// //               height: context.h(23),
// //               constraints: BoxConstraints(
// //                 minWidth: context.w(25),
// //               ),
// //               alignment: Alignment.center,
// //               child: Text(
// //                 '${line.quantity}',
// //                 style: AppTextStyles.caption(context).copyWith(
// //                   fontSize: context.h(9),
// //                   color: colors.textPrimary,
// //                   fontWeight: FontWeight.w600,
// //                 ),
// //               ),
// //             ),
// //             _quantityButton(
// //               context,
// //               icon: Icons.add,
// //               onPressed: () {
// //                 cartNotifier.updateQuantity(
// //                   line.id,
// //                   line.quantity + 1,
// //                 );
// //               },
// //             ),
// //             const Spacer(),
// //             if (line.spiceLevel != null && line.spiceLevel!.isNotEmpty)
// //               Text(
// //                 line.spiceLevel!,
// //                 style: AppTextStyles.caption(context).copyWith(
// //                   fontSize: context.h(8),
// //                   color: colors.textMuted,
// //                 ),
// //               ),
// //           ],
// //         ),

// //         // ---------------------------------------------------------------------
// //         // ADDONS
// //         // ---------------------------------------------------------------------
// //         if (line.addOns.isNotEmpty) ...[
// //           SizedBox(height: context.h(3)),
// //           Text(
// //             line.addOns.join(', '),
// //             maxLines: 1,
// //             overflow: TextOverflow.ellipsis,
// //             style: AppTextStyles.caption(context).copyWith(
// //               fontSize: context.h(8),
// //               color: colors.textSecondary,
// //             ),
// //           ),
// //         ],

// //         // ---------------------------------------------------------------------
// //         // NOTES
// //         // ---------------------------------------------------------------------
// //         if (line.notes != null && line.notes!.isNotEmpty) ...[
// //           SizedBox(height: context.h(2)),
// //           Text(
// //             line.notes!,
// //             maxLines: 1,
// //             overflow: TextOverflow.ellipsis,
// //             style: AppTextStyles.caption(context).copyWith(
// //               fontSize: context.h(8),
// //               color: colors.textMuted,
// //               fontStyle: FontStyle.italic,
// //             ),
// //           ),
// //         ],
// //       ],
// //     );
// //   }

// //   Widget _quantityButton(
// //     BuildContext context, {
// //     required IconData icon,
// //     required VoidCallback onPressed,
// //   }) {
// //     final colors = AppColors.of(context);

// //     return InkWell(
// //       onTap: onPressed,
// //       borderRadius: BorderRadius.circular(
// //         context.h(4),
// //       ),
// //       child: Container(
// //         width: context.w(23),
// //         height: context.h(23),
// //         alignment: Alignment.center,
// //         decoration: BoxDecoration(
// //           color: colors.surfaceVariant,
// //           border: Border.all(
// //             color: colors.border,
// //           ),
// //           borderRadius: BorderRadius.circular(
// //             context.h(4),
// //           ),
// //         ),
// //         child: Icon(
// //           icon,
// //           size: context.h(12),
// //           color: colors.textPrimary,
// //         ),
// //       ),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';

// import '../../../core/theme/app_colors.dart';
// import '../../../core/theme/text_styles.dart';
// import '../../../core/utils/responsive_size.dart';
// import '../../../providers/cart_provider.dart';
// import '../../../models/cart_item_model.dart';

// class CartPanel extends ConsumerWidget {
//   final VoidCallback? onProceed;

//   const CartPanel({
//     super.key,
//     this.onProceed,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final colors = AppColors.of(context);
//     final cart = ref.watch(cartProvider);
//     final subtotal = ref.watch(cartTotalProvider);

//     final tax = subtotal * 0.08;
//     final total = subtotal + tax;

//     return Container(
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(
//           context.h(10),
//         ),
//         border: Border.all(
//           color: colors.border,
//         ),
//       ),
//       child: Column(
//         children: [
//           // -------------------------------------------------------------------
//           // HEADER
//           // -------------------------------------------------------------------
//           Padding(
//             padding: EdgeInsets.fromLTRB(
//               context.w(12),
//               context.h(10),
//               context.w(10),
//               context.h(8),
//             ),
//             child: Row(
//               children: [
//                 Text(
//                   'Active Order',
//                   style: AppTextStyles.section(context).copyWith(
//                     fontSize: context.h(14),
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 SizedBox(width: context.w(5)),
//                 Text(
//                   '#206',
//                   style: AppTextStyles.caption(context).copyWith(
//                     fontSize: context.h(9),
//                     color: colors.textMuted,
//                   ),
//                 ),
//                 const Spacer(),
//                 Container(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: context.w(7),
//                     vertical: context.h(3),
//                   ),
//                   decoration: BoxDecoration(
//                     color: AppColors.primary,
//                     borderRadius: BorderRadius.circular(
//                       context.h(7),
//                     ),
//                   ),
//                   child: Text(
//                     'NEW',
//                     style: AppTextStyles.caption(context).copyWith(
//                       fontSize: context.h(7),
//                       color: Colors.white,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           Divider(
//             height: 1,
//             color: colors.divider,
//           ),

//           // -------------------------------------------------------------------
//           // ORDER TYPE / TABLE
//           // -------------------------------------------------------------------
//           Padding(
//             padding: EdgeInsets.symmetric(
//               horizontal: context.w(12),
//               vertical: context.h(7),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.table_restaurant_outlined,
//                   size: context.h(12),
//                   color: colors.textMuted,
//                 ),
//                 SizedBox(width: context.w(4)),
//                 Text(
//                   'Eat In • Table 4',
//                   style: AppTextStyles.caption(context).copyWith(
//                     fontSize: context.h(9),
//                     color: colors.textSecondary,
//                   ),
//                 ),
//                 const Spacer(),
//                 Text(
//                   'CHANGE',
//                   style: AppTextStyles.caption(context).copyWith(
//                     fontSize: context.h(8),
//                     color: AppColors.primary,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           Divider(
//             height: 1,
//             color: colors.divider,
//           ),

//           // -------------------------------------------------------------------
//           // CART ITEMS
//           // -------------------------------------------------------------------
//           Expanded(
//             child: cart.isEmpty
//                 ? _emptyCart(
//                     context,
//                     colors,
//                   )
//                 : ListView.separated(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: context.w(10),
//                       vertical: context.h(7),
//                     ),
//                     itemCount: cart.length,
//                     separatorBuilder: (_, __) => Divider(
//                       height: context.h(12),
//                       color: colors.divider,
//                     ),
//                     itemBuilder: (context, index) {
//                       return _CartItem(
//                         line: cart[index],
//                       );
//                     },
//                   ),
//           ),

//           // -------------------------------------------------------------------
//           // ORDER SUMMARY
//           // -------------------------------------------------------------------
//           Container(
//             padding: EdgeInsets.fromLTRB(
//               context.w(12),
//               context.h(8),
//               context.w(12),
//               context.h(10),
//             ),
//             decoration: BoxDecoration(
//               border: Border(
//                 top: BorderSide(
//                   color: colors.border,
//                 ),
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Subtotal
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Subtotal',
//                       style: AppTextStyles.caption(context).copyWith(
//                         fontSize: context.h(9),
//                         color: colors.textSecondary,
//                       ),
//                     ),
//                     Text(
//                       '₹${subtotal.toStringAsFixed(2)}',
//                       style: AppTextStyles.caption(context).copyWith(
//                         fontSize: context.h(9),
//                         color: colors.textPrimary,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),

//                 SizedBox(height: context.h(5)),

//                 // Tax
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Tax (8%)',
//                       style: AppTextStyles.caption(context).copyWith(
//                         fontSize: context.h(9),
//                         color: colors.textSecondary,
//                       ),
//                     ),
//                     Text(
//                       '₹${tax.toStringAsFixed(2)}',
//                       style: AppTextStyles.caption(context).copyWith(
//                         fontSize: context.h(9),
//                         color: colors.textPrimary,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),

//                 SizedBox(height: context.h(9)),

//                 // Total
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Text(
//                       'Total Due',
//                       style: AppTextStyles.section(context).copyWith(
//                         fontSize: context.h(13),
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     Text(
//                       '₹${total.toStringAsFixed(2)}',
//                       style: AppTextStyles.heading(context).copyWith(
//                         fontSize: context.h(20),
//                         color: AppColors.primary,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ],
//                 ),

//                 SizedBox(height: context.h(12)),

//                 // ----------------------------------------------------------------
//                 // PROCEED
//                 // ----------------------------------------------------------------
//                 SizedBox(
//                   width: double.infinity,
//                   child: RdxActionButton(
//                     label: 'Proceed',
//                     isPrimary: true,
//                     onPressed: cart.isEmpty ? null : onProceed,
//                   ),
//                 ),

//                 SizedBox(height: context.h(4)),

//                 // ----------------------------------------------------------------
//                 // CANCEL
//                 // ----------------------------------------------------------------
//                 SizedBox(
//                   width: double.infinity,
//                   child: RdxActionButton(
//                     label: 'Cancel',
//                     isPrimary: false,
//                     onPressed: cart.isEmpty
//                         ? null
//                         : () {
//                             ref.read(cartProvider.notifier).clear();
//                           },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _emptyCart(
//     BuildContext context,
//     AppColorScheme colors,
//   ) {
//     return Center(
//       child: Padding(
//         padding: EdgeInsets.all(
//           context.h(20),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               Icons.shopping_cart_outlined,
//               size: context.h(30),
//               color: colors.textMuted,
//             ),
//             SizedBox(height: context.h(8)),
//             Text(
//               'No items added',
//               style: AppTextStyles.label(context).copyWith(
//                 color: colors.textSecondary,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             SizedBox(height: context.h(3)),
//             Text(
//               'Select items from the menu',
//               textAlign: TextAlign.center,
//               style: AppTextStyles.caption(context).copyWith(
//                 color: colors.textMuted,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // =============================================================================
// // CART ITEM
// // =============================================================================

// class _CartItem extends ConsumerWidget {
//   final CartLineItem line;

//   const _CartItem({
//     required this.line,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final colors = AppColors.of(context);
//     final cartNotifier = ref.read(cartProvider.notifier);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // ---------------------------------------------------------------------
//         // NAME + PRICE
//         // ---------------------------------------------------------------------
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: Text(
//                 line.menuItem.name,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: AppTextStyles.label(context).copyWith(
//                   fontSize: context.h(10),
//                   color: colors.textPrimary,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//             SizedBox(width: context.w(5)),
//             Text(
//               '₹${line.subtotal.toStringAsFixed(2)}',
//               style: AppTextStyles.caption(context).copyWith(
//                 fontSize: context.h(9),
//                 color: colors.textPrimary,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),

//         SizedBox(height: context.h(2)),

//         // ---------------------------------------------------------------------
//         // UNIT PRICE
//         // ---------------------------------------------------------------------
//         Text(
//           '₹${line.menuItem.price.toStringAsFixed(2)} each',
//           style: AppTextStyles.caption(context).copyWith(
//             fontSize: context.h(8),
//             color: colors.textMuted,
//           ),
//         ),

//         SizedBox(height: context.h(5)),

//         // ---------------------------------------------------------------------
//         // QUANTITY
//         // ---------------------------------------------------------------------
//         Row(
//           children: [
//             _quantityButton(
//               context,
//               icon: Icons.remove,
//               onPressed: () {
//                 cartNotifier.updateQuantity(
//                   line.id,
//                   line.quantity - 1,
//                 );
//               },
//             ),
//             Container(
//               height: context.h(23),
//               constraints: BoxConstraints(
//                 minWidth: context.w(25),
//               ),
//               alignment: Alignment.center,
//               child: Text(
//                 '${line.quantity}',
//                 style: AppTextStyles.caption(context).copyWith(
//                   fontSize: context.h(9),
//                   color: colors.textPrimary,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//             _quantityButton(
//               context,
//               icon: Icons.add,
//               onPressed: () {
//                 cartNotifier.updateQuantity(
//                   line.id,
//                   line.quantity + 1,
//                 );
//               },
//             ),
//             const Spacer(),
//             if (line.spiceLevel != null && line.spiceLevel!.isNotEmpty)
//               Text(
//                 line.spiceLevel!,
//                 style: AppTextStyles.caption(context).copyWith(
//                   fontSize: context.h(8),
//                   color: colors.textMuted,
//                 ),
//               ),
//           ],
//         ),

//         // ---------------------------------------------------------------------
//         // ADD-ONS
//         // ---------------------------------------------------------------------
//         if (line.addOns.isNotEmpty) ...[
//           SizedBox(height: context.h(3)),
//           Text(
//             line.addOns.join(', '),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: AppTextStyles.caption(context).copyWith(
//               fontSize: context.h(8),
//               color: colors.textSecondary,
//             ),
//           ),
//         ],

//         // ---------------------------------------------------------------------
//         // NOTES
//         // ---------------------------------------------------------------------
//         if (line.notes != null && line.notes!.isNotEmpty) ...[
//           SizedBox(height: context.h(2)),
//           Text(
//             line.notes!,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: AppTextStyles.caption(context).copyWith(
//               fontSize: context.h(8),
//               color: colors.textMuted,
//               fontStyle: FontStyle.italic,
//             ),
//           ),
//         ],
//       ],
//     );
//   }

//   Widget _quantityButton(
//     BuildContext context, {
//     required IconData icon,
//     required VoidCallback onPressed,
//   }) {
//     final colors = AppColors.of(context);

//     return InkWell(
//       onTap: onPressed,
//       borderRadius: BorderRadius.circular(
//         context.h(4),
//       ),
//       child: Container(
//         width: context.w(23),
//         height: context.h(23),
//         alignment: Alignment.center,
//         decoration: BoxDecoration(
//           color: colors.surfaceVariant,
//           border: Border.all(
//             color: colors.border,
//           ),
//           borderRadius: BorderRadius.circular(
//             context.h(4),
//           ),
//         ),
//         child: Icon(
//           icon,
//           size: context.h(12),
//           color: colors.textPrimary,
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/screens/order/checkout_screen.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/responsive_size.dart';
import '../../../models/cart_item_model.dart';
import '../../../providers/cart_provider.dart';

class CartPanel extends ConsumerWidget {
  final VoidCallback? onClose;
  final VoidCallback? onProceed;

  const CartPanel({
    super.key,
    this.onClose,
    this.onProceed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final cart = ref.watch(cartProvider);
    final subtotal = ref.watch(cartTotalProvider);

    final tax = subtotal * 0.08;
    final total = subtotal + tax;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(
          context.h(10),
        ),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Column(
        children: [
          // -----------------------------------------------------------------
          // HEADER
          // -----------------------------------------------------------------
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(12),
              context.h(10),
              context.w(10),
              context.h(8),
            ),
            child: Row(
              children: [
                Text(
                  'Active Order',
                  // style: AppTextStyles.section(context).copyWith(
                  //   fontSize: context.h(14),
                  //   fontWeight: FontWeight.w600,
                  // ),
                  style: AppTextStyles.section(context)
                      .copyWith(color: colors.textPrimary),
                ),
                // SizedBox(width: context.w(5)),
                // Text(
                //   '#206',
                //   style: AppTextStyles.caption(context).copyWith(
                //     fontSize: context.h(9),
                //     color: colors.textMuted,
                //   ),
                // ),
                const Spacer(),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: colors.divider,
          ),

          // -----------------------------------------------------------------
          // ORDER TYPE / TABLE
          // -----------------------------------------------------------------
          // Padding(
          //   padding: EdgeInsets.symmetric(
          //     horizontal: context.w(12),
          //     vertical: context.h(7),
          //   ),
          //   child: Row(
          //     children: [
          //       Icon(
          //         Icons.table_restaurant_outlined,
          //         size: context.h(12),
          //         color: colors.textMuted,
          //       ),
          //       SizedBox(width: context.w(4)),
          //       Text(
          //         'Eat In • Table 4',
          //         style: AppTextStyles.caption(context).copyWith(
          //           fontSize: context.h(9),
          //           color: colors.textSecondary,
          //         ),
          //       ),
          //       const Spacer(),
          //       Text(
          //         'CHANGE',
          //         style: AppTextStyles.caption(context).copyWith(
          //           fontSize: context.h(8),
          //           color: AppColors.primary,
          //           fontWeight: FontWeight.w600,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          // Divider(
          //   height: 1,
          //   color: colors.divider,
          // ),

          // -----------------------------------------------------------------
          // CART ITEMS
          // -----------------------------------------------------------------
          Expanded(
            child: cart.isEmpty
                ? _emptyCart(
                    context,
                    colors,
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(10),
                      vertical: context.h(7),
                    ),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => Divider(
                      height: context.h(12),
                      color: colors.divider,
                    ),
                    itemBuilder: (context, index) {
                      return _CartItem(
                        line: cart[index],
                      );
                    },
                  ),
          ),

          // -----------------------------------------------------------------
          // BOTTOM SUMMARY
          // -----------------------------------------------------------------
          Container(
            padding: EdgeInsets.fromLTRB(
              context.w(12),
              context.h(8),
              context.w(12),
              context.h(10),
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colors.border,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SUBTOTAL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: AppTextStyles.bodySecondary(context),
                    ),
                    Text(
                      '₹${subtotal.toStringAsFixed(2)}',
                      style: AppTextStyles.bodySecondary(context),
                    ),
                  ],
                ),

                SizedBox(height: context.h(6)),

                // TAX
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tax (8%)',
                      style: AppTextStyles.bodySecondary(context),
                    ),
                    Text(
                      '₹${tax.toStringAsFixed(2)}',
                      style: AppTextStyles.bodySecondary(context),
                    ),
                  ],
                ),

                SizedBox(height: context.h(10)),

                // TOTAL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Due',
                      style: AppTextStyles.section(context),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: AppTextStyles.section(context).copyWith(
                        color: colors.primary,
                        // fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.h(14)),

                // PROCEED
                SizedBox(
                  width: double.infinity,
                  child: RdxActionButton(
                    label: 'Proceed',
                    isPrimary: true,
                    onPressed: cart.isEmpty
                        ? null
                        : onProceed ??
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CheckoutScreen(),
                                ),
                              );
                            },
                  ),
                ),

                SizedBox(
                  height: context.h(5),
                ),

                // CANCEL
                // SizedBox(
                //   width: double.infinity,
                //   child: RdxActionButton(
                //     label: 'Cancel',
                //     // isPrimary: true,
                // onPressed: cart.isEmpty
                //     ? null
                //     : () {
                //         ref.read(cartProvider.notifier).clear();
                //       },
                //   ),
                // ),
                RdxActionButton.discard(
                  onPressed: cart.isEmpty
                      ? null
                      : () {
                          ref.read(cartProvider.notifier).clear();
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCart(
    BuildContext context,
    AppColorScheme colors,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          context.h(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: context.h(30),
              color: colors.textMuted,
            ),
            SizedBox(height: context.h(8)),
            Text(
              'No items added',
              style: AppTextStyles.label(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: context.h(3)),
            Text(
              'Select items from the menu',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary(context).copyWith(
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// CART ITEM
// =============================================================================

class _CartItem extends ConsumerWidget {
  final CartLineItem line;

  const _CartItem({
    required this.line,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------------------------------------------------------------------
        // NAME + PRICE + DELETE
        // ---------------------------------------------------------------------
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                line.menuItem.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.section(context).copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),

            SizedBox(width: context.w(5)),

            Text(
              '₹${line.subtotal.toStringAsFixed(2)}',
              style: AppTextStyles.label(context).copyWith(
                // fontSize: context.h(9),
                color: colors.textPrimary,
                // fontWeight: FontWeight.w600,
              ),
            ),

            // -----------------------------------------------------------------
            // DELETE BUTTON
            // -----------------------------------------------------------------
            // SizedBox(
            //   width: context.w(24),
            //   height: context.h(20),
            //   child: IconButton(
            //     onPressed: () {
            //       cartNotifier.removeLine(line.id);
            //     },
            //     padding: EdgeInsets.zero,
            //     constraints: const BoxConstraints(),
            //     splashRadius: context.h(12),
            //     tooltip: 'Remove item',
            //     icon: Icon(
            //       Icons.delete_outline,
            //       size: context.h(13),
            //       color: colors.textSecondary,
            //     ),
            //   ),
            // ),
          ],
        ),

        SizedBox(height: context.h(2)),

        // ---------------------------------------------------------------------
        // UNIT PRICE
        // ---------------------------------------------------------------------
        Text(
          '₹${line.menuItem.price.toStringAsFixed(2)} each',
          style: AppTextStyles.body(context).copyWith(
            // fontSize: context.h(8),
            color: colors.textMuted,
          ),
        ),

        SizedBox(height: context.h(5)),

        // ---------------------------------------------------------------------
        // QUANTITY CONTROL
        // ---------------------------------------------------------------------
        Row(
          children: [
            _quantityButton(
              context,
              icon: Icons.remove,
              onPressed: () {
                cartNotifier.updateQuantity(
                  line.id,
                  line.quantity - 1,
                );
              },
            ),
            Container(
              height: context.h(23),
              constraints: BoxConstraints(
                minWidth: context.w(25),
              ),
              alignment: Alignment.center,
              child: Text(
                '${line.quantity}',
                style: AppTextStyles.bodySecondary(context).copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            _quantityButton(
              context,
              icon: Icons.add,
              onPressed: () {
                cartNotifier.updateQuantity(
                  line.id,
                  line.quantity + 1,
                );
              },
            ),
            const Spacer(),
            if (line.spiceLevel != null && line.spiceLevel!.isNotEmpty)
              Flexible(
                child: Text(
                  line.spiceLevel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySecondary(context).copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ),
            SizedBox(
              width: context.w(24),
              height: context.h(20),
              child: IconButton(
                onPressed: () {
                  cartNotifier.removeLine(line.id);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: context.h(12),
                tooltip: 'Remove item',
                icon: Icon(
                  Icons.delete,
                  size: context.h(22),
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        ),

        // ---------------------------------------------------------------------
        // ADDONS
        // ---------------------------------------------------------------------
        if (line.addOns.isNotEmpty) ...[
          SizedBox(height: context.h(3)),
          Text(
            line.addOns.join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySecondary(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],

        // ---------------------------------------------------------------------
        // NOTES
        // ---------------------------------------------------------------------
        if (line.notes != null && line.notes!.isNotEmpty) ...[
          SizedBox(height: context.h(2)),
          Text(
            line.notes!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySecondary(context).copyWith(
              color: colors.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _quantityButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final colors = AppColors.of(context);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(
        context.h(4),
      ),
      child: Container(
        width: context.w(28),
        height: context.h(28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          border: Border.all(
            color: colors.border,
          ),
          borderRadius: BorderRadius.circular(
            context.h(4),
          ),
        ),
        child: Icon(
          icon,
          size: context.h(14),
          color: colors.textPrimary,
        ),
      ),
    );
  }
}
