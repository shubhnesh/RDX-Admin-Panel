import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/responsive_size.dart';
import '../../../models/menu_item_model.dart';
import '../../../providers/cart_provider.dart';
import 'item_customize_sheet.dart';

class OrderMenuItemCard extends ConsumerWidget {
  final MenuItemModel item;

  const OrderMenuItemCard({super.key, required this.item});

  bool get _looksVeg {
    final name = item.dietaryType.name.toLowerCase();
    return name.contains('veg') && !name.contains('non');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final quantityInCart = ref.watch(
      cartProvider.select((_) => ref.read(cartProvider.notifier).quantityForMenuItem(item.id)),
    );
    final unavailable = !item.available;

    return Opacity(
      opacity: unavailable ? 0.55 : 1,
      child: InkWell(
        onTap: unavailable
            ? null
            : () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ItemCustomizeSheet(item: item),
                ),
        borderRadius: BorderRadius.circular(context.h(12)),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(context.h(12)),
            border: Border.all(color: colors.border),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(context.h(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(context.h(8)),
                      child: AspectRatio(
                        aspectRatio: 1.4,
                        child: item.imageUrl.isEmpty
                            ? Container(
                                color: colors.surfaceVariant,
                                child: Icon(Icons.restaurant_menu,
                                    color: colors.textMuted, size: context.h(30)),
                              )
                            : Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: colors.surfaceVariant,
                                  child: Icon(Icons.restaurant_menu,
                                      color: colors.textMuted, size: context.h(30)),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: context.h(8)),
                    Row(
                      children: [
                        Icon(
                          Icons.square,
                          size: context.h(9),
                          color: _looksVeg ? Colors.green : AppColors.danger,
                        ),
                        SizedBox(width: context.w(6)),
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body(context)
                                .copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (item.preparation.isNotEmpty) ...[
                      SizedBox(height: context.h(2)),
                      Text(
                        item.preparation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyTertiary(context)
                            .copyWith(color: colors.textSecondary),
                      ),
                    ],
                    SizedBox(height: context.h(6)),
                    Text(
                      '₹${item.price.toStringAsFixed(0)}',
                      style: AppTextStyles.section(context)
                          .copyWith(color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
              if (unavailable)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(10),
                        vertical: context.h(4),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(context.h(6)),
                      ),
                      child: Text(
                        'Unavailable',
                        style: AppTextStyles.label(context).copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              if (!unavailable)
                Positioned(
                  right: context.w(8),
                  top: context.h(8),
                  child: InkWell(
                    onTap: () => ref.read(cartProvider.notifier).addItem(
                          menuItem: item,
                          quantity: 1,
                        ),
                    borderRadius: BorderRadius.circular(context.h(16)),
                    child: Container(
                      padding: EdgeInsets.all(context.h(6)),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: context.h(4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.add, size: context.h(16), color: Colors.white),
                    ),
                  ),
                ),
              if (quantityInCart > 0)
                Positioned(
                  left: context.w(8),
                  top: context.h(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(8),
                      vertical: context.h(3),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(context.h(10)),
                    ),
                    child: Text(
                      '$quantityInCart in cart',
                      style: AppTextStyles.caption(context).copyWith(color: Colors.white),
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
