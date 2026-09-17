// // import 'package:flutter/material.dart';
// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';

// // import '../../../core/theme/app_colors.dart';
// // import '../../../core/theme/text_styles.dart';
// // import '../../../core/utils/responsive_size.dart';
// // import '../../../models/menu_item_model.dart';
// // import '../../../providers/cart_provider.dart';
// // import 'item_customize_sheet.dart';

// // class OrderMenuItemCard extends ConsumerWidget {
// //   final MenuItemModel item;

// //   const OrderMenuItemCard({super.key, required this.item});

// //   bool get _looksVeg {
// //     final name = item.dietaryType.name.toLowerCase();
// //     return name.contains('veg') && !name.contains('non');
// //   }

// //   // @override
// //   // Widget build(BuildContext context, WidgetRef ref) {
// //   //   final colors = AppColors.of(context);
// //   //   final quantityInCart = ref.watch(
// //   //     cartProvider.select((_) => ref.read(cartProvider.notifier).quantityForMenuItem(item.id)),
// //   //   );
// //   //   final unavailable = !item.available;

// //   //   return Opacity(
// //   //     opacity: unavailable ? 0.55 : 1,
// //   //     child: InkWell(
// //   //       onTap: unavailable
// //   //           ? null
// //   //           : () => showModalBottomSheet(
// //   //                 context: context,
// //   //                 isScrollControlled: true,
// //   //                 backgroundColor: Colors.transparent,
// //   //                 builder: (_) => ItemCustomizeSheet(item: item),
// //   //               ),
// //   //       borderRadius: BorderRadius.circular(context.h(12)),
// //   //       child: Container(
// //   //         decoration: BoxDecoration(
// //   //           color: colors.surface,
// //   //           borderRadius: BorderRadius.circular(context.h(12)),
// //   //           border: Border.all(color: colors.border),
// //   //         ),
// //   //         child: Stack(
// //   //           children: [
// //   //             Padding(
// //   //               padding: EdgeInsets.all(context.h(12)),
// //   //               child: Column(
// //   //                 crossAxisAlignment: CrossAxisAlignment.start,
// //   //                 children: [
// //   //                   ClipRRect(
// //   //                     borderRadius: BorderRadius.circular(context.h(8)),
// //   //                     child: AspectRatio(
// //   //                       aspectRatio: 1.4,
// //   //                       child: item.imageUrl.isEmpty
// //   //                           ? Container(
// //   //                               color: colors.surfaceVariant,
// //   //                               child: Icon(Icons.restaurant_menu,
// //   //                                   color: colors.textMuted, size: context.h(30)),
// //   //                             )
// //   //                           : Image.network(
// //   //                               item.imageUrl,
// //   //                               fit: BoxFit.cover,
// //   //                               errorBuilder: (_, __, ___) => Container(
// //   //                                 color: colors.surfaceVariant,
// //   //                                 child: Icon(Icons.restaurant_menu,
// //   //                                     color: colors.textMuted, size: context.h(30)),
// //   //                               ),
// //   //                             ),
// //   //                     ),
// //   //                   ),
// //   //                   SizedBox(height: context.h(8)),
// //   //                   Row(
// //   //                     children: [
// //   //                       Icon(
// //   //                         Icons.square,
// //   //                         size: context.h(9),
// //   //                         color: _looksVeg ? Colors.green : AppColors.danger,
// //   //                       ),
// //   //                       SizedBox(width: context.w(6)),
// //   //                       Expanded(
// //   //                         child: Text(
// //   //                           item.name,
// //   //                           maxLines: 1,
// //   //                           overflow: TextOverflow.ellipsis,
// //   //                           style: AppTextStyles.body(context)
// //   //                               .copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600),
// //   //                         ),
// //   //                       ),
// //   //                     ],
// //   //                   ),
// //   //                   if (item.preparation.isNotEmpty) ...[
// //   //                     SizedBox(height: context.h(2)),
// //   //                     Text(
// //   //                       item.preparation,
// //   //                       maxLines: 1,
// //   //                       overflow: TextOverflow.ellipsis,
// //   //                       style: AppTextStyles.bodyTertiary(context)
// //   //                           .copyWith(color: colors.textSecondary),
// //   //                     ),
// //   //                   ],
// //   //                   SizedBox(height: context.h(6)),
// //   //                   Text(
// //   //                     '₹${item.price.toStringAsFixed(0)}',
// //   //                     style: AppTextStyles.section(context)
// //   //                         .copyWith(color: colors.textPrimary),
// //   //                   ),
// //   //                 ],
// //   //               ),
// //   //             ),
// //   //             if (unavailable)
// //   //               Positioned.fill(
// //   //                 child: Center(
// //   //                   child: Container(
// //   //                     padding: EdgeInsets.symmetric(
// //   //                       horizontal: context.w(10),
// //   //                       vertical: context.h(4),
// //   //                     ),
// //   //                     decoration: BoxDecoration(
// //   //                       color: Colors.black.withValues(alpha: 0.65),
// //   //                       borderRadius: BorderRadius.circular(context.h(6)),
// //   //                     ),
// //   //                     child: Text(
// //   //                       'Unavailable',
// //   //                       style: AppTextStyles.label(context).copyWith(color: Colors.white),
// //   //                     ),
// //   //                   ),
// //   //                 ),
// //   //               ),
// //   //             if (!unavailable)
// //   //               Positioned(
// //   //                 right: context.w(8),
// //   //                 top: context.h(8),
// //   //                 child: InkWell(
// //   //                   onTap: () => ref.read(cartProvider.notifier).addItem(
// //   //                         menuItem: item,
// //   //                         quantity: 1,
// //   //                       ),
// //   //                   borderRadius: BorderRadius.circular(context.h(16)),
// //   //                   child: Container(
// //   //                     padding: EdgeInsets.all(context.h(6)),
// //   //                     decoration: BoxDecoration(
// //   //                       color: AppColors.primary,
// //   //                       shape: BoxShape.circle,
// //   //                       boxShadow: [
// //   //                         BoxShadow(
// //   //                           color: Colors.black.withValues(alpha: 0.15),
// //   //                           blurRadius: context.h(4),
// //   //                         ),
// //   //                       ],
// //   //                     ),
// //   //                     child: Icon(Icons.add, size: context.h(16), color: Colors.white),
// //   //                   ),
// //   //                 ),
// //   //               ),
// //   //             if (quantityInCart > 0)
// //   //               Positioned(
// //   //                 left: context.w(8),
// //   //                 top: context.h(8),
// //   //                 child: Container(
// //   //                   padding: EdgeInsets.symmetric(
// //   //                     horizontal: context.w(8),
// //   //                     vertical: context.h(3),
// //   //                   ),
// //   //                   decoration: BoxDecoration(
// //   //                     color: AppColors.primary,
// //   //                     borderRadius: BorderRadius.circular(context.h(10)),
// //   //                   ),
// //   //                   child: Text(
// //   //                     '$quantityInCart in cart',
// //   //                     style: AppTextStyles.caption(context).copyWith(color: Colors.white),
// //   //                   ),
// //   //                 ),
// //   //               ),
// //   //           ],
// //   //         ),
// //   //       ),
// //   //     ),
// //   //   );
// //   // }
// //   // widgets/order_menu_item_card.dart – key visual updates

// // // Keep the existing logic; only adjust the visual layout of the card body:

// //   @override
// //   Widget build(BuildContext context, WidgetRef ref) {
// //     final colors = AppColors.of(context);
// //     final quantityInCart = ref.watch(
// //       cartProvider.select(
// //           (_) => ref.read(cartProvider.notifier).quantityForMenuItem(item.id)),
// //     );
// //     final unavailable = !item.available;

// //     return Opacity(
// //       opacity: unavailable ? 0.55 : 1,
// //       child: InkWell(
// //         onTap: unavailable
// //             ? null
// //             : () {
// //                 ref.read(cartProvider.notifier).addItem(item);
// //               },
// //         //   onTap: unavailable
// //         //       ? null
// //         //       : () => showModalBottomSheet(
// //         //             context: context,
// //         //             isScrollControlled: true,
// //         //             backgroundColor: Colors.transparent,
// //         //             builder: (_) => ItemCustomizeSheet(item: item),
// //         //           ),
// //         //   borderRadius: BorderRadius.circular(context.h(12)),
// //         //   child: Container(
// //         //     decoration: BoxDecoration(
// //         //       color: colors.surface,
// //         //       borderRadius: BorderRadius.circular(context.h(12)),
// //         //       border: Border.all(color: colors.border),
// //         //     ),
// //         //     child: Stack(
// //         //       children: [
// //         //         Padding(
// //         //           padding: EdgeInsets.all(context.h(12)),
// //         //           child: Column(
// //         //             crossAxisAlignment: CrossAxisAlignment.start,
// //         //             children: [
// //         //               // name + veg indicator
// //         //               Row(
// //         //                 children: [
// //         //                   Icon(
// //         //                     Icons.square,
// //         //                     size: context.h(9),
// //         //                     color: _looksVeg ? Colors.green : AppColors.danger,
// //         //                   ),
// //         //                   SizedBox(width: context.w(6)),
// //         //                   Expanded(
// //         //                     child: Text(
// //         //                       item.name,
// //         //                       maxLines: 1,
// //         //                       overflow: TextOverflow.ellipsis,
// //         //                       style: AppTextStyles.body(context).copyWith(
// //         //                         color: colors.textPrimary,
// //         //                         fontWeight: FontWeight.w600,
// //         //                       ),
// //         //                     ),
// //         //                   ),
// //         //                 ],
// //         //               ),
// //         //               if (item.preparation.isNotEmpty) ...[
// //         //                 SizedBox(height: context.h(4)),
// //         //                 Text(
// //         //                   item.preparation,
// //         //                   maxLines: 2,
// //         //                   overflow: TextOverflow.ellipsis,
// //         //                   style: AppTextStyles.bodyTertiary(context)
// //         //                       .copyWith(color: colors.textSecondary),
// //         //                 ),
// //         //               ],
// //         //               const Spacer(),
// //         //               // price + Add button row
// //         //               Row(
// //         //                 children: [
// //         //                   Text(
// //         //                     '₹${item.price.toStringAsFixed(0)}',
// //         //                     style: AppTextStyles.section(context)
// //         //                         .copyWith(color: colors.textPrimary),
// //         //                   ),
// //         //                   const Spacer(),
// //         //                   if (!unavailable)
// //         //                     SizedBox(
// //         //                       height: context.h(32),
// //         //                       child: RdxActionButton(
// //         //                         label: 'Add',
// //         //                         isPrimary: true,
// //         //                         // onPressed: () => showModalBottomSheet(
// //         //                         //   context: context,
// //         //                         //   isScrollControlled: true,
// //         //                         //   backgroundColor: Colors.transparent,
// //         //                         //   builder: (_) => ItemCustomizeSheet(item: item),
// //         //                         // ),
// //         //                         onPressed: () {
// //         //                           ref.read(cartProvider.notifier).addItem(item);
// //         //                         },
// //         //                       ),
// //         //                     ),
// //         //                 ],
// //         //               ),
// //         //             ],
// //         //           ),
// //         //         ),
// //         //         if (unavailable)
// //         //           Positioned.fill(
// //         //             child: Center(
// //         //               child: Container(
// //         //                 padding: EdgeInsets.symmetric(
// //         //                   horizontal: context.w(10),
// //         //                   vertical: context.h(4),
// //         //                 ),
// //         //                 decoration: BoxDecoration(
// //         //                   color: Colors.black.withValues(alpha: 0.65),
// //         //                   borderRadius: BorderRadius.circular(context.h(6)),
// //         //                 ),
// //         //                 child: Text(
// //         //                   'Unavailable',
// //         //                   style: AppTextStyles.label(context)
// //         //                       .copyWith(color: Colors.white),
// //         //                 ),
// //         //               ),
// //         //             ),
// //         //           ),
// //         //         if (quantityInCart > 0)
// //         //           Positioned(
// //         //             left: context.w(8),
// //         //             top: context.h(8),
// //         //             child: Container(
// //         //               padding: EdgeInsets.symmetric(
// //         //                 horizontal: context.w(8),
// //         //                 vertical: context.h(3),
// //         //               ),
// //         //               decoration: BoxDecoration(
// //         //                 color: AppColors.primary,
// //         //                 borderRadius: BorderRadius.circular(context.h(10)),
// //         //               ),
// //         //               child: Text(
// //         //                 '$quantityInCart',
// //         //                 style: AppTextStyles.caption(context)
// //         //                     .copyWith(color: Colors.white),
// //         //               ),
// //         //             ),
// //         //           ),
// //         //       ],
// //         //     ),
// //         //   ),
// //       ),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../../core/theme/app_colors.dart';
// import '../../../core/theme/text_styles.dart';
// import '../../../core/utils/responsive_size.dart';
// import '../../../models/menu_item_model.dart';
// import '../../../providers/cart_provider.dart';
// import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';

// class OrderMenuItemCard extends ConsumerWidget {
//   final MenuItemModel item;

//   const OrderMenuItemCard({
//     super.key,
//     required this.item,
//   });

//   bool get _looksVeg {
//     switch (item.dietaryType) {
//       case DietaryType.veg:
//         return true;
//       case DietaryType.nonVeg:
//       case DietaryType.egg:
//         return false;
//     }
//   }

//   void _addToCart(WidgetRef ref) {
//     ref.read(cartProvider.notifier).addItem(
//           menuItem: item,
//           quantity: 1,
//         );
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final colors = AppColors.of(context);

//     final quantityInCart = ref.watch(
//       cartProvider.select(
//         (cart) => ref.read(cartProvider.notifier).quantityForMenuItem(item.id),
//       ),
//     );

//     final unavailable = !item.available;

//     return Opacity(
//       opacity: unavailable ? 0.55 : 1.0,
//       child: Container(
//         decoration: BoxDecoration(
//           color: colors.surface,
//           borderRadius: BorderRadius.circular(
//             context.h(12),
//           ),
//           border: Border.all(
//             color: colors.border,
//           ),
//         ),
//         child: Stack(
//           children: [
//             Padding(
//               padding: EdgeInsets.all(
//                 context.h(12),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // -------------------------------------------------------
//                   // ITEM NAME + DIETARY INDICATOR
//                   // -------------------------------------------------------
//                   Row(
//                     children: [
//                       Container(
//                         width: context.h(9),
//                         height: context.h(9),
//                         decoration: BoxDecoration(
//                           color: _looksVeg ? Colors.green : AppColors.danger,
//                           borderRadius: BorderRadius.circular(
//                             context.h(2),
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: context.w(6)),
//                       Expanded(
//                         child: Text(
//                           item.name,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: AppTextStyles.body(context).copyWith(
//                             color: colors.textPrimary,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),

//                   // -------------------------------------------------------
//                   // PREPARATION
//                   // -------------------------------------------------------
//                   if (item.preparation.isNotEmpty) ...[
//                     SizedBox(height: context.h(4)),
//                     Text(
//                       item.preparation,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: AppTextStyles.bodyTertiary(context).copyWith(
//                         color: colors.textSecondary,
//                       ),
//                     ),
//                   ],

//                   const Spacer(),

//                   // -------------------------------------------------------
//                   // PRICE + ADD BUTTON
//                   // -------------------------------------------------------
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Text(
//                         '₹${item.price.toStringAsFixed(0)}',
//                         style: AppTextStyles.section(context).copyWith(
//                           color: colors.textPrimary,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       const Spacer(),
//                       if (!unavailable)
//                         SizedBox(
//                           height: context.h(32),
//                           child: RdxActionButton(
//                             label: 'Add',
//                             isPrimary: true,
//                             onPressed: () => _addToCart(ref),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             // -------------------------------------------------------------
//             // QUANTITY BADGE
//             // -------------------------------------------------------------
//             if (quantityInCart > 0)
//               Positioned(
//                 top: context.h(8),
//                 right: context.w(8),
//                 child: Container(
//                   constraints: BoxConstraints(
//                     minWidth: context.h(22),
//                   ),
//                   padding: EdgeInsets.symmetric(
//                     horizontal: context.w(6),
//                     vertical: context.h(3),
//                   ),
//                   decoration: BoxDecoration(
//                     color: AppColors.primary,
//                     borderRadius: BorderRadius.circular(
//                       context.h(10),
//                     ),
//                   ),
//                   child: Text(
//                     '$quantityInCart',
//                     textAlign: TextAlign.center,
//                     style: AppTextStyles.caption(context).copyWith(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),

//             // -------------------------------------------------------------
//             // UNAVAILABLE OVERLAY
//             // -------------------------------------------------------------
//             if (unavailable)
//               Positioned.fill(
//                 child: Center(
//                   child: Container(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: context.w(10),
//                       vertical: context.h(4),
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withValues(
//                         alpha: 0.65,
//                       ),
//                       borderRadius: BorderRadius.circular(
//                         context.h(6),
//                       ),
//                     ),
//                     child: Text(
//                       'Unavailable',
//                       style: AppTextStyles.label(context).copyWith(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/responsive_size.dart';
import '../../../models/menu_item_model.dart';
import '../../../providers/cart_provider.dart';

class OrderMenuItemCard extends ConsumerWidget {
  final MenuItemModel item;

  const OrderMenuItemCard({
    super.key,
    required this.item,
  });

  bool get _looksVeg {
    switch (item.dietaryType) {
      case DietaryType.veg:
        return true;
      case DietaryType.nonVeg:
      case DietaryType.egg:
        return false;
    }
  }

  void _addItem(WidgetRef ref) {
    ref.read(cartProvider.notifier).addItem(
          menuItem: item,
          quantity: 1,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    final quantityInCart = ref.watch(
      cartProvider.select(
        (cart) => ref.read(cartProvider.notifier).quantityForMenuItem(item.id),
      ),
    );

    final unavailable = !item.available;

    return Opacity(
      opacity: unavailable ? 0.55 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(
            context.h(8),
          ),
          border: Border.all(
            color: colors.border,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.w(10),
            context.h(8),
            context.w(8),
            context.h(7),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------------------------------------------------
                  // NAME + PRICE
                  // ---------------------------------------------------------
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: context.h(7),
                        height: context.h(7),
                        margin: EdgeInsets.only(
                          top: context.h(3),
                        ),
                        decoration: BoxDecoration(
                          color: _looksVeg ? Colors.green : AppColors.danger,
                          borderRadius: BorderRadius.circular(
                            context.h(1.5),
                          ),
                        ),
                      ),
                      SizedBox(width: context.w(5)),
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label(context).copyWith(
                            fontSize: context.h(11),
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: context.w(4)),
                      Text(
                        '₹${item.price.toStringAsFixed(0)}',
                        style: AppTextStyles.caption(context).copyWith(
                          fontSize: context.h(9),
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // ---------------------------------------------------------
                  // DESCRIPTION / PREPARATION
                  // ---------------------------------------------------------
                  if (item.description.isNotEmpty ||
                      item.preparation.isNotEmpty) ...[
                    SizedBox(height: context.h(3)),
                    Text(
                      item.description.isNotEmpty
                          ? item.description
                          : item.preparation,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        fontSize: context.h(8.5),
                        height: 1.15,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // ---------------------------------------------------------
                  // ADD BUTTON
                  // ---------------------------------------------------------
                  if (!unavailable)
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: SizedBox(
                        height: context.h(25),
                        child: RdxActionButton(
                          label: '+ Add',
                          isPrimary: true,
                          onPressed: () => _addItem(ref),
                        ),
                      ),
                    ),
                ],
              ),

              // -------------------------------------------------------------
              // CART QUANTITY
              // -------------------------------------------------------------
              if (quantityInCart > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: context.h(18),
                      minHeight: context.h(18),
                    ),
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(4),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(
                        context.h(9),
                      ),
                    ),
                    child: Text(
                      '$quantityInCart',
                      style: AppTextStyles.caption(context).copyWith(
                        fontSize: context.h(8),
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

              // -------------------------------------------------------------
              // UNAVAILABLE
              // -------------------------------------------------------------
              if (unavailable)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(8),
                        vertical: context.h(3),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: 0.65,
                        ),
                        borderRadius: BorderRadius.circular(
                          context.h(5),
                        ),
                      ),
                      child: Text(
                        'Unavailable',
                        style: AppTextStyles.caption(context).copyWith(
                          fontSize: context.h(9),
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
