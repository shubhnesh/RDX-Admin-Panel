import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/responsive_size.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/buttons/rdx_action_button.dart';
import '../../../widgets/reusable_widgets/empty_state.dart';
import '../checkout_screen.dart';

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Selected items',
                style: AppTextStyles.section(context)
                    .copyWith(color: colors.textPrimary),
              ),
            ),
            Text(
              '${cart.length} ${cart.length == 1 ? 'item' : 'items'}',
              style: AppTextStyles.bodySecondary(context)
                  .copyWith(color: colors.textMuted),
            ),
          ],
        ),
        SizedBox(height: context.h(10)),
        Divider(height: 1, color: colors.divider),
        SizedBox(height: context.h(10)),
        Expanded(
          child: cart.isEmpty
              ? const EmptyState(
                  message: 'Cart is empty. Tap items to add them.')
              : ListView.separated(
                  padding: EdgeInsets.only(bottom: context.h(8)),
                  itemCount: cart.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: context.h(18), color: colors.divider),
                  itemBuilder: (context, index) {
                    final line = cart[index];
                    final customization = [
                      if (line.spiceLevel != null) line.spiceLevel!,
                      ...line.addOns.map((a) => a.name),
                    ].join(' · ');

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.menuItem.name,
                                style: AppTextStyles.body(context).copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600),
                              ),
                              if (customization.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: context.h(2)),
                                  child: Text(
                                    customization,
                                    style: AppTextStyles.caption(context)
                                        .copyWith(color: colors.textSecondary),
                                  ),
                                ),
                              if (line.notes != null && line.notes!.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: context.h(2)),
                                  child: Text(
                                    'Note: ${line.notes}',
                                    style: AppTextStyles.caption(context)
                                        .copyWith(
                                            color: colors.textMuted,
                                            fontStyle: FontStyle.italic),
                                  ),
                                ),
                              SizedBox(height: context.h(6)),
                              Row(
                                children: [
                                  _qtyButton(
                                      colors,
                                      Icons.remove,
                                      () => ref
                                          .read(cartProvider.notifier)
                                          .updateQuantity(
                                              line.id, line.quantity - 1)),
                                  SizedBox(width: context.w(10)),
                                  Text('${line.quantity}',
                                      style: AppTextStyles.body(context)
                                          .copyWith(color: colors.textPrimary)),
                                  SizedBox(width: context.w(10)),
                                  _qtyButton(
                                      colors,
                                      Icons.add,
                                      () => ref
                                          .read(cartProvider.notifier)
                                          .updateQuantity(
                                              line.id, line.quantity + 1)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹${line.subtotal.toStringAsFixed(0)}',
                                style: AppTextStyles.body(context)
                                    .copyWith(color: colors.textPrimary)),
                            IconButton(
                              onPressed: () => ref
                                  .read(cartProvider.notifier)
                                  .removeLine(line.id),
                              icon: Icon(Icons.delete_outline_rounded,
                                  size: context.h(18), color: AppColors.danger),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
        ),
        Divider(height: 1, color: colors.divider),
        SizedBox(height: context.h(12)),
        Row(
          children: [
            Text('Total',
                style: AppTextStyles.section(context)
                    .copyWith(color: colors.textPrimary)),
            const Spacer(),
            Text('₹${total.toStringAsFixed(0)}',
                style: AppTextStyles.section(context)
                    .copyWith(color: colors.textPrimary)),
          ],
        ),
        SizedBox(height: context.h(10)),
        SizedBox(
          width: double.infinity,
          child: RdxActionButton(
            label: 'Proceed to Checkout',
            isPrimary: true,
            onPressed: cart.isEmpty
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                    ),
          ),
        ),
        SizedBox(height: context.h(4)),
      ],
    );
  }

  Widget _qtyButton(AppColorScheme colors, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration:
            BoxDecoration(color: colors.surfaceVariant, shape: BoxShape.circle),
        child: Icon(icon, size: 14, color: colors.textPrimary),
      ),
    );
  }
}
