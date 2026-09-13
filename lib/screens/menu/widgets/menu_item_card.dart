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
    final preparation = item.preparation;
    final isNarrow = context.isNarrow;

    // Slightly tighter padding / type on narrow screens so the card
    // doesn't feel sparse when it's full-width.
    final outerRadius = context.h(isNarrow ? 12 : 10);
    final imagePadding = context.w(isNarrow ? 8 : 6);
    final imageRadius = context.h(isNarrow ? 10 : 8);
    final contentHPad = context.w(isNarrow ? 12 : 10);
    final contentTopPad = context.h(isNarrow ? 6 : 4);
    final bottomPad = EdgeInsets.fromLTRB(
      contentHPad,
      context.h(6),
      context.w(6),
      context.h(8),
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(outerRadius),
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
          // ── Image ───────────────────────────────────────────────
          AspectRatio(
            aspectRatio: isNarrow ? 1.7 : 1.55,
            child: Padding(
              padding: EdgeInsets.all(imagePadding),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(imageRadius),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: item.imageUrl.trim().isEmpty
                          ? Container(
                              color: colors.surfaceVariant,
                              child: Icon(
                                Icons.restaurant_outlined,
                                color: colors.textMuted,
                                size: context.h(isNarrow ? 36 : 32),
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
                                  size: context.h(isNarrow ? 36 : 32),
                                ),
                              ),
                            ),
                    ),
                    if (item.featuredItem)
                      Positioned(
                        left: context.w(8),
                        top: context.h(8),
                        child: _cardBadge(
                          context,
                          'Featured',
                          AppColors.primary,
                          Colors.white,
                        ),
                      ),
                    if (dietarySelected)
                      Positioned(
                        right: context.w(8),
                        bottom: context.h(8),
                        child: _dietaryBadge(context, item),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────
Expanded(
  child: Padding(
    padding: EdgeInsets.fromLTRB(
      contentHPad,
      contentTopPad,
      contentHPad,
      0,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Category (left) + Price (right) on one row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                categorySelected ? item.category : 'Category',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyTertiary(context).copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            SizedBox(width: context.w(8)),
            Text(
              '₹${item.price.toStringAsFixed(2)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.section(context).copyWith(
                color: colors.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(2)),
        Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.section(context).copyWith(
            color: colors.textPrimary,
          ),
        ),
        if (item.ingredients.isNotEmpty) ...[
          SizedBox(height: context.h(2)),
          Text(
            item.ingredients.join(', '),
            style: AppTextStyles.bodyTertiary(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        SizedBox(height: context.h(6)),
        ClipRect(
          child: Wrap(
            spacing: context.w(4),
            runSpacing: context.h(4),
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
                : [
                    _detailChip(
                      context,
                      'Tags',
                      colors.textSecondary,
                    ),
                  ],
          ),
        ),
        // Price moved up next to category — no second price here
      ],
    ),
  ),
),

          // ── Fixed bottom ────────────────────────────────────────
          Padding(
            padding: bottomPad,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(height: 1, color: colors.divider),
                SizedBox(height: context.h(6)),
                Row(
                  children: [
                    RdxToggleButton(
                      value: item.available,
                      activeColor: AppColors.primary,
                      onChanged: (_) => onToggleAvailability(),
                    ),
                    SizedBox(width: context.w(6)),
                    Expanded(
                      child: Text(
                        item.available ? 'Available' : 'Sold Out',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyTertiary(context).copyWith(
                          color: item.available
                              ? AppColors.success
                              : colors.textMuted,
                        ),
                      ),
                    ),
                    Builder(
                      builder: (buttonContext) {
                        return InkWell(
                          onTap: () => onActions(buttonContext),
                          borderRadius:
                              BorderRadius.circular(context.h(6)),
                          child: Padding(
                            padding: EdgeInsets.all(context.w(4)),
                            child: Icon(
                              Icons.more_vert_rounded,
                              size: context.h(18),
                              color: const Color(0xFF5D687A),
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
        style: AppTextStyles.caption(context).copyWith(
          color: foreground,
        ),
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
        style: AppTextStyles.caption(context).copyWith(
          color: color,
        ),
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
            style: AppTextStyles.caption(context).copyWith(
              color: color,
            ),
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