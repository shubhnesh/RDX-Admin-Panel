import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/providers/cart_provider.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/responsive_size.dart';
import '../../../models/menu_item_model.dart';


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
