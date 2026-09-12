import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/menu_item_model.dart';
import 'package:rdx_admin/widgets/buttons/rdx_toggle_button.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItemModel item;
  final VoidCallback onToggleAvailability;
  final void Function(BuildContext buttonContext) onActions;
  final bool categorySelected;
  final bool dietarySelected;
  final bool hasTags;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.onToggleAvailability,
    required this.onActions,
    this.categorySelected = true,
    this.dietarySelected = true,
    this.hasTags = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final preparation = item.preparationStyle.name.replaceAll('_', ' ');

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image (flexible but capped via aspect ratio) ───────
          AspectRatio(
            aspectRatio: 1.55,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: item.imageUrl.trim().isEmpty
                          ? Container(
                              color: colors.surfaceVariant,
                              child: Icon(
                                Icons.restaurant_outlined,
                                color: colors.textMuted,
                                size: 32,
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
                                  size: 32,
                                ),
                              ),
                            ),
                    ),
                    if (item.featuredItem)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: _cardBadge(
                          context,
                          'Featured',
                          AppColors.primary,
                          Colors.white,
                        ),
                      ),
                    if (dietarySelected)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: _dietaryBadge(context, item),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    categorySelected ? item.category : 'Category',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyTertiary(context)
                        .copyWith(color: AppColors.primary, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.section(context)
                        .copyWith(color: colors.textPrimary, fontSize: 14),
                  ),
                  if (item.ingredients.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.ingredients.join(', '),
                      style: AppTextStyles.bodyTertiary(context)
                          .copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  ClipRect(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: hasTags
                          ? [
                              _detailChip(
                                context,
                                _titleCase(preparation),
                                colors.textSecondary,
                              ),
                              for (final tag in item.tags
                                  .where((tag) => tag.toLowerCase() != 'featured')
                                  .take(item.featuredItem ? 2 : 3))
                                _detailChip(
                                  context,
                                  _titleCase(tag),
                                  colors.textSecondary,
                                ),
                            ]
                          : [_detailChip(context, 'Tags', colors.textSecondary)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${item.price.toStringAsFixed(2)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.section(context)
                        .copyWith(color: colors.primary, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // ── Fixed bottom (compact) ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 6, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(height: 1, color: colors.divider),
                const SizedBox(height: 6),
                Row(
                  children: [
                    RdxToggleButton(
                      value: item.available,
                      activeColor: AppColors.primary,
                      onChanged: (_) => onToggleAvailability(),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.available ? 'Available' : 'Sold Out',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyTertiary(context).copyWith(
                          color: item.available
                              ? AppColors.success
                              : colors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Builder(
                      builder: (buttonContext) {
                        return InkWell(
                          onTap: () => onActions(buttonContext),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.more_vert_rounded,
                              size: 18,
                              color: Color(0xFF5D687A),
                            ),
                          ),
                        );
                      },
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
        color: background,
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
