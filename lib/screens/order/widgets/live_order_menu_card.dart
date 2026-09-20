import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/responsive_size.dart';
import '../../../models/cart_item_model.dart';
import '../../../models/menu_item_model.dart';
import '../../../providers/cart_provider.dart';

// =============================================================================
// LIVE ORDER MENU CARD
// =============================================================================
//
// Menu item card used on the Create New Order screen. Shows an image area
// with a Featured badge and a Veg / Non-Veg indicator, then the category,
// price, name and description below.
//
// The bottom-right control starts as a "+ Add" pill. The moment the item is
// added, that pill turns into a quantity stepper (− / count / +) in the same
// spot, driven straight off the cart so it always reflects the live count.
// =============================================================================

class LiveOrderMenuCard extends ConsumerWidget {
  final MenuItemModel item;

  const LiveOrderMenuCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final isNarrow = context.isNarrow;
    final unavailable = !item.available;

    final cart = ref.watch(cartProvider);
    final line = _lineFor(cart);

    final outerRadius = context.h(isNarrow ? 12 : 10);
    final imagePadding = context.w(isNarrow ? 8 : 6);
    final imageRadius = context.h(isNarrow ? 10 : 8);
    final contentHPad = context.w(isNarrow ? 12 : 10);
    final contentTopPad = context.h(isNarrow ? 6 : 4);
    final bottomPad = EdgeInsets.fromLTRB(
      contentHPad,
      context.h(6),
      contentHPad,
      context.h(8),
    );

    return Opacity(
      opacity: unavailable ? 0.55 : 1,
      child: Container(
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
            Padding(
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.category,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyTertiary(context)
                              .copyWith(
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
                          color: colors.textPrimary,
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
                  if (item.ingredients.isNotEmpty ||
                      item.preparation.isNotEmpty) ...[
                    SizedBox(height: context.h(2)),
                    Text(
                      item.ingredients.isNotEmpty
                          ? item.ingredients.join(', ')
                          : item.preparation,
                      style: AppTextStyles.bodyTertiary(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // ── Fixed bottom — Add / stepper ─────────────────────────
            Padding(
              padding: bottomPad,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: context.h(6)),
                  // Fixed height so the Add-button and the stepper occupy
                  // exactly the same space — nothing below (the divider)
                  // shifts when the control swaps.
                  SizedBox(
                    height: context.h(30),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.94, end: 1)
                                .animate(animation),
                            alignment: Alignment.centerRight,
                            child: child,
                          ),
                        ),
                        // Default AnimatedSwitcher layout stacks the old
                        // and new child centered, which is what made the
                        // "+ Add" pill and the stepper appear to jump
                        // sideways (and dragged the divider with it)
                        // during the swap. Pin both to the right edge
                        // instead so the control swaps in place. The
                        // outer Align then keeps the whole switcher
                        // hugging the right edge without stretching the
                        // Add button to the full row width.
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        child: line == null
                            ? _addButton(
                                context,
                                key: const ValueKey('add'),
                                enabled: !unavailable,
                                onTap: () => ref
                                    .read(cartProvider.notifier)
                                    .addItem(
                                      menuItem: item,
                                      quantity: 1,
                                    ),
                              )
                            : _quantityStepper(
                                context,
                                key: const ValueKey('stepper'),
                                quantity: line.quantity,
                                onDecrement: () => ref
                                    .read(cartProvider.notifier)
                                    .updateQuantity(
                                        line.id, line.quantity - 1),
                                onIncrement: () => ref
                                    .read(cartProvider.notifier)
                                    .updateQuantity(
                                        line.id, line.quantity + 1),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: context.h(8)),
                  Divider(height: 1, color: colors.divider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cart lookup ────────────────────────────────────────────────

  CartLineItem? _lineFor(List<CartLineItem> cart) {
    for (final line in cart) {
      if (line.menuItem.id == item.id) {
        return line;
      }
    }
    return null;
  }

  // ── Add button ─────────────────────────────────────────────────

  Widget _addButton(
    BuildContext context, {
    Key? key,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(context.h(7)),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(12),
            vertical: context.h(7),
          ),
          decoration: BoxDecoration(
            color: enabled ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(context.h(7)),
          ),
          child: Text(
            '+ Add',
            style: AppTextStyles.caption(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ── Quantity stepper ──────────────────────────────────────────

  Widget _quantityStepper(
    BuildContext context, {
    Key? key,
    required int quantity,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return SizedBox(
      key: key,
      height: context.h(30),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _stepperButton(
            context,
            icon: Icons.remove,
            onTap: onDecrement,
          ),
          SizedBox(
            width: context.w(28),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.section(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _stepperButton(
            context,
            icon: Icons.add,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }

  Widget _stepperButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.h(6)),
        child: Container(
          width: context.h(24),
          height: context.h(24),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(context.h(6)),
          ),
          child: Icon(
            icon,
            size: context.h(14),
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── Badges ─────────────────────────────────────────────────────

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
}
