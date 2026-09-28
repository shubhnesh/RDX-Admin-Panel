import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/screens/order/checkout_screen.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/responsive_size.dart';
import '../../../core/utils/tax.dart';
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

    final tax = subtotal * (AppTax.gstPercentage / 100);
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
                  'Added Items',
                  style: AppTextStyles.section(context)
                      .copyWith(color: colors.textPrimary),
                ),
                if (cart.isNotEmpty) ...[
                  SizedBox(width: context.w(6)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(7),
                      vertical: context.h(2),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(context.h(20)),
                    ),
                    child: Text(
                      '${cart.length}',
                      style: AppTextStyles.caption(context).copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
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
                      vertical: context.h(10),
                    ),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => SizedBox(
                      height: context.h(10),
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

                // GST
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GST (${AppTax.gstPercentage.toStringAsFixed(0)}%)',
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
                    isPrimary: cart.isNotEmpty,
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
                  height: context.h(10),
                ),

                // CANCEL
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
    final imageUrl = line.menuItem.imageUrl.trim();

    return Container(
      padding: EdgeInsets.all(context.w(10)),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -----------------------------------------------------------------
          // THUMBNAIL
          // -----------------------------------------------------------------
          _itemThumbnail(context, colors, imageUrl),
          SizedBox(width: context.w(10)),

          // -----------------------------------------------------------------
          // DETAILS
          // -----------------------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + line total
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
                    SizedBox(width: context.w(8)),
                    Text(
                      '₹${line.subtotal.toStringAsFixed(2)}',
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
                  '₹${line.menuItem.price.toStringAsFixed(2)} each',
                  style: AppTextStyles.bodyTertiary(context).copyWith(
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: context.h(8)),

                // Quantity + spice + delete
                Row(
                  children: [
                    _stepperPill(
                      context,
                      colors: colors,
                      quantity: line.quantity,
                      onDecrement: () => cartNotifier.updateQuantity(
                        line.id,
                        line.quantity - 1,
                      ),
                      onIncrement: () => cartNotifier.updateQuantity(
                        line.id,
                        line.quantity + 1,
                      ),
                    ),
                    const Spacer(),
                    if (line.spiceLevel != null &&
                        line.spiceLevel!.isNotEmpty) ...[
                      Flexible(
                        child: Padding(
                          padding: EdgeInsets.only(right: context.w(6)),
                          child: Text(
                            line.spiceLevel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                AppTextStyles.bodySecondary(context).copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                    _deleteButton(
                      context,
                      colors: colors,
                      onPressed: () => cartNotifier.removeLine(line.id),
                    ),
                  ],
                ),

                if (line.addOns.isNotEmpty) ...[
                  SizedBox(height: context.h(6)),
                  Text(
                    line.addOns.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySecondary(context).copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],

                if (line.notes != null && line.notes!.isNotEmpty) ...[
                  SizedBox(height: context.h(2)),
                  Text(
                    line.notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySecondary(context).copyWith(
                      color: colors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemThumbnail(
    BuildContext context,
    AppColorScheme colors,
    String imageUrl,
  ) {
    final size = context.w(64);

    return ClipRRect(
      borderRadius: BorderRadius.circular(context.h(8)),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl.isEmpty
            ? Container(
                color: colors.surfaceVariant,
                child: Icon(
                  Icons.restaurant_outlined,
                  color: colors.textMuted,
                  size: context.h(22),
                ),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: colors.surfaceVariant,
                  child: Icon(
                    Icons.restaurant_outlined,
                    color: colors.textMuted,
                    size: context.h(22),
                  ),
                ),
              ),
      ),
    );
  }

  /// − / count / + control using the same square, filled-primary buttons
  /// as LiveOrderMenuCard's stepper, so the two look like one family.
  Widget _stepperPill(
    BuildContext context, {
    required AppColorScheme colors,
    required int quantity,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return SizedBox(
      height: context.h(28),
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

  /// Quiet outlined icon button — sits inline with the stepper instead
  /// of floating disconnected, and stays understated (like the card's
  /// dietary badge) rather than a loud red block.
  Widget _deleteButton(
    BuildContext context, {
    required AppColorScheme colors,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(context.h(6)),
        child: Container(
          width: context.h(35),
          height: context.h(35),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(context.h(6)),
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            size: context.h(20),
            color: AppColors.danger,
          ),
        ),
      ),
    );
  }
}
