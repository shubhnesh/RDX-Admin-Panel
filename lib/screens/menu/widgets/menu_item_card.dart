import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/menu_item_model.dart';
import 'package:rdx_admin/widgets/rdx_toggle_button.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItemModel item;
  final VoidCallback onToggleAvailability;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.onToggleAvailability,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final preparation = item.preparationStyle.name.replaceAll('_', ' ');

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: context.h(10),
            offset: Offset(0, context.h(3)),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ──────────────────────────────────────────────
          AspectRatio(
            aspectRatio: 1.45,
            child: Padding(
              padding: EdgeInsets.all(context.h(6)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(context.h(8)),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: item.imageUrl.trim().isEmpty
                          ? Container(
                              color: colors.surfaceVariant,
                              child: Icon(
                                Icons.restaurant_outlined,
                                color: colors.textMuted,
                                size: context.h(34),
                              ),
                            )
                          : Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: colors.surfaceVariant,
                                child: Icon(
                                  Icons.restaurant_outlined,
                                  color: colors.textMuted,
                                  size: context.h(34),
                                ),
                              ),
                            ),
                    ),
                    if (item.featuredItem)
                      Positioned(
                        left: context.w(10),
                        top: context.h(10),
                        child: _cardBadge(
                          context,
                          'Featured',
                          AppColors.primary,
                          Colors.white,
                        ),
                      ),
                    Positioned(
                      right: context.w(10),
                      bottom: context.h(10),
                      child: _dietaryBadge(context, item),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Flexible content ───────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(12),
                context.h(6),
                context.w(12),
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyTertiary(context)
                        .copyWith(color: AppColors.primary),
                  ),
                  SizedBox(height: context.h(3)),
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.section(context)
                        .copyWith(color: colors.textPrimary),
                  ),
                  SizedBox(height: context.h(3)),
                  if (item.ingredients.isNotEmpty) ...[
                    Text(
                      item.ingredients.join(', '),
                      style: AppTextStyles.bodyTertiary(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.h(3)),
                  ],
                  SizedBox(height: context.h(8)),
                  SizedBox(
                    height: context.h(28),
                    child: ClipRect(
                      child: Wrap(
                        spacing: context.w(5),
                        runSpacing: context.h(5),
                        children: [
                          _detailChip(
                            context,
                            _titleCase(preparation),
                            colors.textSecondary,
                          ),
                          for (final tag in item.tags
                              .where((tag) => tag.toLowerCase() != 'featured')
                              .take(item.featuredItem ? 3 : 4))
                            _detailChip(
                              context,
                              _titleCase(tag),
                              colors.textSecondary,
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: context.h(10)),
                  Text(
                    '₹${item.price.toStringAsFixed(2)}',
                    style: AppTextStyles.section(context)
                        .copyWith(color: colors.primary),
                  ),
                  const Spacer(), // pushes bottom section down
                ],
              ),
            ),
          ),

          // ── Fixed bottom section ───────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(12),
              0,
              context.w(12),
              context.h(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(height: context.h(1), color: colors.divider),
                SizedBox(height: context.h(6)),
                Row(
                  children: [
                    RdxToggleButton(
                      value: item.available,
                      activeColor: AppColors.primary,
                      onChanged: (_) => onToggleAvailability(),
                    ),
                    SizedBox(width: context.w(5)),
                    Text(
                      item.available ? 'Available' : 'Sold Out',
                      style: AppTextStyles.bodyTertiary(context).copyWith(
                        color: item.available
                            ? AppColors.success
                            : colors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(context.h(6)),
                      child: Padding(
                        padding: EdgeInsets.all(context.h(5)),
                        child: Icon(
                          Icons.edit_outlined,
                          size: context.h(20),
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    // Optional: uncomment if you want delete button visible
                    // SizedBox(width: context.w(4)),
                    // InkWell(
                    //   onTap: onDelete,
                    //   borderRadius: BorderRadius.circular(context.h(6)),
                    //   child: Padding(
                    //     padding: EdgeInsets.all(context.h(5)),
                    //     child: Icon(
                    //       Icons.delete_outline,
                    //       size: context.h(20),
                    //       color: colors.textSecondary,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  Widget _cardBadge(
    BuildContext context,
    String label,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(5),
        vertical: context.h(2),
      ),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(context.h(5)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(context).copyWith(color: foreground),
      ),
    );
  }

  Widget _detailChip(BuildContext context, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(6),
        vertical: context.h(3),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(context.h(4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(context).copyWith(color: color),
      ),
    );
  }

  Widget _dietaryBadge(BuildContext context, MenuItemModel item) {
    final color = item.isVeg ? AppColors.success : AppColors.danger;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(5),
        vertical: context.h(2),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(context.h(5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: context.h(8), color: color),
          SizedBox(width: context.w(5)),
          Text(
            _dietaryLabel(item.dietaryType),
            style: AppTextStyles.caption(context).copyWith(color: color),
          ),
        ],
      ),
    );
  }

  String _dietaryLabel(DietaryType type) {
    return type == DietaryType.veg
        ? 'Veg'
        : type == DietaryType.egg
            ? 'Contains Egg'
            : 'Non-Veg';
  }

  String _titleCase(String value) {
    return value
        .split(' ')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}