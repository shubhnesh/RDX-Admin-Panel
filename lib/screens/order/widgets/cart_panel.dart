// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../core/theme/app_colors.dart';
// import '../../../core/theme/text_styles.dart';
// import '../../../core/utils/responsive_size.dart';
// import '../../../providers/cart_provider.dart';
// import '../../../widgets/buttons/rdx_action_button.dart';
// import '../../../widgets/reusable_widgets/empty_state.dart';
// import '../checkout_screen.dart';

// class CartPanel extends ConsumerWidget {
//   const CartPanel({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final colors = AppColors.of(context);
//     final cart = ref.watch(cartProvider);
//     final total = ref.watch(cartTotalProvider);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         // Row(
//         //   children: [
//         //     Expanded(
//         //       child: Text(
//         //         'Selected items',
//         //         style: AppTextStyles.section(context)
//         //             .copyWith(color: colors.textPrimary),
//         //       ),
//         //     ),
//         //     Text(
//         //       '${cart.length} ${cart.length == 1 ? 'item' : 'items'}',
//         //       style: AppTextStyles.bodySecondary(context)
//         //           .copyWith(color: colors.textMuted),
//         //     ),
//         //   ],
//         // ),

//         Row(
//           children: [
//             Expanded(
//               child: Text(
//                 'Active Order',
//                 style: AppTextStyles.section(context)
//                     .copyWith(color: colors.textPrimary),
//               ),
//             ),
//             Text(
//               '${cart.length} ${cart.length == 1 ? 'item' : 'items'}',
//               style: AppTextStyles.bodySecondary(context)
//                   .copyWith(color: colors.textMuted),
//             ),
//           ],
//         ),
//         SizedBox(height: context.h(10)),
//         Divider(height: 1, color: colors.divider),
//         SizedBox(height: context.h(10)),
//         Expanded(
//           child: cart.isEmpty
//               ? const EmptyState(
//                   message: 'Cart is empty. Tap items to add them.')
//               : ListView.separated(
//                   padding: EdgeInsets.only(bottom: context.h(8)),
//                   itemCount: cart.length,
//                   separatorBuilder: (_, __) =>
//                       Divider(height: context.h(18), color: colors.divider),
//                   itemBuilder: (context, index) {
//                     final line = cart[index];
//                     final customization = [
//                       if (line.spiceLevel != null) line.spiceLevel!,
//                       ...line.addOns.map((a) => a.name),
//                     ].join(' · ');

//                     return Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 line.menuItem.name,
//                                 style: AppTextStyles.body(context).copyWith(
//                                     color: colors.textPrimary,
//                                     fontWeight: FontWeight.w600),
//                               ),
//                               if (customization.isNotEmpty)
//                                 Padding(
//                                   padding: EdgeInsets.only(top: context.h(2)),
//                                   child: Text(
//                                     customization,
//                                     style: AppTextStyles.caption(context)
//                                         .copyWith(color: colors.textSecondary),
//                                   ),
//                                 ),
//                               if (line.notes != null && line.notes!.isNotEmpty)
//                                 Padding(
//                                   padding: EdgeInsets.only(top: context.h(2)),
//                                   child: Text(
//                                     'Note: ${line.notes}',
//                                     style: AppTextStyles.caption(context)
//                                         .copyWith(
//                                             color: colors.textMuted,
//                                             fontStyle: FontStyle.italic),
//                                   ),
//                                 ),
//                               SizedBox(height: context.h(6)),
//                               Row(
//                                 children: [
//                                   _qtyButton(
//                                       colors,
//                                       Icons.remove,
//                                       () => ref
//                                           .read(cartProvider.notifier)
//                                           .updateQuantity(
//                                               line.id, line.quantity - 1)),
//                                   SizedBox(width: context.w(10)),
//                                   Text('${line.quantity}',
//                                       style: AppTextStyles.body(context)
//                                           .copyWith(color: colors.textPrimary)),
//                                   SizedBox(width: context.w(10)),
//                                   _qtyButton(
//                                       colors,
//                                       Icons.add,
//                                       () => ref
//                                           .read(cartProvider.notifier)
//                                           .updateQuantity(
//                                               line.id, line.quantity + 1)),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: [
//                             Text('₹${line.subtotal.toStringAsFixed(0)}',
//                                 style: AppTextStyles.body(context)
//                                     .copyWith(color: colors.textPrimary)),
//                             IconButton(
//                               onPressed: () => ref
//                                   .read(cartProvider.notifier)
//                                   .removeLine(line.id),
//                               icon: Icon(Icons.delete_outline_rounded,
//                                   size: context.h(18), color: AppColors.danger),
//                               padding: EdgeInsets.zero,
//                               constraints: const BoxConstraints(),
//                             ),
//                           ],
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//         ),
//         Divider(height: 1, color: colors.divider),
//         SizedBox(height: context.h(12)),
//         Row(
//           children: [
//             Text('Total',
//                 style: AppTextStyles.section(context)
//                     .copyWith(color: colors.textPrimary)),
//             const Spacer(),
//             Text('₹${total.toStringAsFixed(0)}',
//                 style: AppTextStyles.section(context)
//                     .copyWith(color: colors.textPrimary)),
//           ],
//         ),
//         SizedBox(height: context.h(10)),
//         SizedBox(
//           width: double.infinity,
//           child: RdxActionButton(
//             label: 'Proceed to Checkout',
//             isPrimary: true,
//             onPressed: cart.isEmpty
//                 ? null
//                 : () => Navigator.of(context).push(
//                       MaterialPageRoute(builder: (_) => const CheckoutScreen()),
//                     ),
//           ),
//         ),
//         SizedBox(height: context.h(4)),
//       ],
//     );
//   }

//   Widget _qtyButton(AppColorScheme colors, IconData icon, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(999),
//       child: Container(
//         padding: const EdgeInsets.all(4),
//         decoration:
//             BoxDecoration(color: colors.surfaceVariant, shape: BoxShape.circle),
//         child: Icon(icon, size: 14, color: colors.textPrimary),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/responsive_size.dart';
import '../../../providers/cart_provider.dart';
import '../../../models/cart_item_model.dart';

class CartPanel extends ConsumerWidget {
  final VoidCallback? onClose;

  const CartPanel({
    super.key,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    final cart = ref.watch(cartProvider);
    final subtotal = ref.watch(cartTotalProvider);

    // Kept separate so the calculation is easy to change later
    // when your actual restaurant tax configuration is connected.
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
                  style: AppTextStyles.section(context).copyWith(
                    fontSize: context.h(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: context.w(5)),
                Text(
                  '#206',
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: context.h(9),
                    color: colors.textMuted,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(7),
                    vertical: context.h(3),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(
                      context.h(7),
                    ),
                  ),
                  child: Text(
                    'NEW',
                    style: AppTextStyles.caption(context).copyWith(
                      fontSize: context.h(7),
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(12),
              vertical: context.h(7),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.table_restaurant_outlined,
                  size: context.h(12),
                  color: colors.textMuted,
                ),
                SizedBox(width: context.w(4)),
                Text(
                  'Eat In • Table 4',
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: context.h(9),
                    color: colors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  'CHANGE',
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: context.h(8),
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: colors.divider,
          ),

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
              children: [
                _summaryRow(
                  context,
                  'Subtotal',
                  '₹${subtotal.toStringAsFixed(2)}',
                ),

                SizedBox(height: context.h(3)),

                _summaryRow(
                  context,
                  'Tax (8%)',
                  '₹${tax.toStringAsFixed(2)}',
                ),

                SizedBox(height: context.h(7)),

                Row(
                  children: [
                    Text(
                      'Total Due',
                      style: AppTextStyles.section(context).copyWith(
                        fontSize: context.h(12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: AppTextStyles.heading(context).copyWith(
                        fontSize: context.h(19),
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.h(8)),

                // -----------------------------------------------------------
                // SEND TO KITCHEN
                // -----------------------------------------------------------
                SizedBox(
                  width: double.infinity,
                  height: context.h(36),
                  child: ElevatedButton.icon(
                    onPressed: cart.isEmpty ? null : () {},
                    icon: Icon(
                      Icons.send_outlined,
                      size: context.h(13),
                    ),
                    label: Text(
                      'Send to Kitchen',
                      style: AppTextStyles.label(context).copyWith(
                        fontSize: context.h(10),
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: colors.surfaceVariant,
                      disabledForegroundColor: colors.textMuted,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.h(6),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: context.h(5)),

                // -----------------------------------------------------------
                // PAY / CANCEL
                // -----------------------------------------------------------
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: context.h(28),
                        child: OutlinedButton(
                          onPressed: cart.isEmpty ? null : () {},
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side: BorderSide(
                              color: colors.border,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                context.h(5),
                              ),
                            ),
                          ),
                          child: Text(
                            'Pay Now',
                            style: AppTextStyles.caption(context).copyWith(
                              fontSize: context.h(9),
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: context.w(6)),
                    Expanded(
                      child: SizedBox(
                        height: context.h(28),
                        child: TextButton(
                          onPressed: cart.isEmpty
                              ? null
                              : () {
                                  ref.read(cartProvider.notifier).clear();
                                },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                context.h(5),
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.caption(context).copyWith(
                              fontSize: context.h(9),
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
              style: AppTextStyles.caption(context).copyWith(
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value,
  ) {
    final colors = AppColors.of(context);

    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.caption(context).copyWith(
            fontSize: context.h(9),
            color: colors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.caption(context).copyWith(
            fontSize: context.h(9),
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
        // NAME + PRICE
        // ---------------------------------------------------------------------
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                line.menuItem.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label(context).copyWith(
                  fontSize: context.h(10),
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: context.w(5)),
            Text(
              '₹${line.subtotal.toStringAsFixed(2)}',
              style: AppTextStyles.caption(context).copyWith(
                fontSize: context.h(9),
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        SizedBox(height: context.h(2)),

        // ---------------------------------------------------------------------
        // UNIT PRICE
        // ---------------------------------------------------------------------
        Text(
          '₹${line.menuItem.price.toStringAsFixed(2)} each',
          style: AppTextStyles.caption(context).copyWith(
            fontSize: context.h(8),
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
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: context.h(9),
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
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
              Text(
                line.spiceLevel!,
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: context.h(8),
                  color: colors.textMuted,
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
            style: AppTextStyles.caption(context).copyWith(
              fontSize: context.h(8),
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
            style: AppTextStyles.caption(context).copyWith(
              fontSize: context.h(8),
              color: colors.textMuted,
              fontStyle: FontStyle.italic,
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
        width: context.w(23),
        height: context.h(23),
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
          size: context.h(12),
          color: colors.textPrimary,
        ),
      ),
    );
  }
}
