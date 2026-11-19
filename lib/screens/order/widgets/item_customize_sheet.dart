import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/responsive_size.dart';
import '../../../models/menu_item_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/buttons/rdx_action_button.dart';

/// Bottom sheet shown when "+ Add" is tapped on an item that has sizes.
/// Lists only that item's sizes with their prices.
class ItemCustomizeSheet extends ConsumerStatefulWidget {
  final MenuItemModel item;

  /// true on wide screens: rendered inside a centered dialog instead of a
  /// bottom sheet (rounded on all corners, no drag handle).
  final bool asDialog;

  const ItemCustomizeSheet({
    super.key,
    required this.item,
    this.asDialog = false,
  });

  @override
  ConsumerState<ItemCustomizeSheet> createState() => _ItemCustomizeSheetState();
}

class _ItemCustomizeSheetState extends ConsumerState<ItemCustomizeSheet> {
  MenuItemSize? _selected;

  @override
  void initState() {
    super.initState();
    final sizes = widget.item.sizes;
    _selected = sizes.isNotEmpty ? sizes.first : null;
  }

  void _submit() {
    final size = _selected;
    if (size == null) return;
    ref.read(cartProvider.notifier).addItem(
          menuItem: widget.item,
          size: size.name,
          sizePrice: size.price,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final selected = _selected;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: widget.asDialog
            ? BorderRadius.circular(context.h(14))
            : BorderRadius.vertical(top: Radius.circular(context.h(18))),
        border: widget.asDialog ? Border.all(color: colors.border) : null,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: context.h(10)),
            if (!widget.asDialog)
              Container(
                width: context.w(40),
                height: context.h(4),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(context.h(2)),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(18),
                context.h(14),
                context.w(8),
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLargeSemi(context)
                          .copyWith(color: colors.textPrimary),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: colors.textMuted),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(
                  context.w(18),
                  context.h(6),
                  context.w(18),
                  context.h(14),
                ),
                children: [
                  Text(
                    'Select size',
                    style: AppTextStyles.body(context)
                        .copyWith(color: colors.textMuted),
                  ),
                  SizedBox(height: context.h(10)),
                  for (final size in widget.item.sizes)
                    _sizeTile(colors, size, size == selected),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                context.w(18),
                context.h(12),
                context.w(18),
                context.h(16),
              ),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selected == null
                          ? ''
                          : '₹${selected.price.toStringAsFixed(0)}',
                      style: AppTextStyles.bodyLargeSemi(context)
                          .copyWith(color: colors.textPrimary),
                    ),
                  ),
                  SizedBox(
                    width: context.w(180),
                    child: RdxActionButton(
                      label: 'Add to Cart',
                      isPrimary: true,
                      onPressed: selected == null ? null : _submit,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sizeTile(AppColorScheme colors, MenuItemSize size, bool isSelected) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(8)),
      child: Material(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.08)
            : colors.surface,
        borderRadius: BorderRadius.circular(context.h(10)),
        child: InkWell(
          onTap: () => setState(() => _selected = size),
          borderRadius: BorderRadius.circular(context.h(10)),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(14),
              vertical: context.h(12),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.h(10)),
              border: Border.all(
                color: isSelected ? AppColors.primary : colors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: context.h(20),
                  color: isSelected ? AppColors.primary : colors.textMuted,
                ),
                SizedBox(width: context.w(10)),
                Expanded(
                  child: Text(
                    size.name,
                    style: AppTextStyles.bodySemi(context)
                        .copyWith(color: colors.textPrimary),
                  ),
                ),
                Text(
                  '₹${size.price.toStringAsFixed(0)}',
                  style: AppTextStyles.bodySemi(context).copyWith(
                    color: isSelected ? AppColors.primary : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens [ItemCustomizeSheet] for sized items. Items without sizes have
/// nothing to choose, so they are added to the cart directly.
Future<void> showItemCustomizeSheet(BuildContext context, MenuItemModel item) {
  if (!item.hasSizes) {
    ProviderScope.containerOf(context, listen: false)
        .read(cartProvider.notifier)
        .addItem(menuItem: item);
    return Future<void>.value();
  }
  // Wide screens: a centered dialog looks better than a full-width sheet.
  if (MediaQuery.sizeOf(context).width >= 900) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ItemCustomizeSheet(item: item, asDialog: true),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ItemCustomizeSheet(item: item),
  );
}
