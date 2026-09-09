import 'package:flutter/material.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../models/inventory_item_model.dart';
import '../../../core/utils/formatters.dart';

class DeleteMaterialDialog extends StatelessWidget {
  final InventoryItemModel item;

  const DeleteMaterialDialog({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.h(14)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.w(420)),
        child: Padding(
          padding: EdgeInsets.all(context.h(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.h(8)),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_forever_rounded,
                        color: AppColors.danger, size: 20),
                  ),
                  SizedBox(width: context.w(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delete Material',
                            style: AppTextStyles.section(context)),
                        Text('PERMANENT REMOVAL',
                            style: AppTextStyles.caption(context)
                                .copyWith(color: AppColors.danger, letterSpacing: 0.8)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: colors.textMuted),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              SizedBox(height: context.h(16)),

              // Item summary
              Container(
                padding: EdgeInsets.all(context.h(14)),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(context.h(10)),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: AppTextStyles.body(context)
                                  .copyWith(fontWeight: FontWeight.w600)),
                          SizedBox(height: context.h(4)),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: context.w(8), vertical: context.h(2)),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: colors.border),
                            ),
                            child: Text(item.category,
                                style: AppTextStyles.caption(context)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('CURRENT STOCK',
                            style: AppTextStyles.caption(context)
                                .copyWith(color: colors.textMuted)),
                        Text(
                          '${_fmt(item.quantity)} / ${_fmt(item.maxCapacity)} ${item.unit}',
                          style: AppTextStyles.body(context),
                        ),
                        SizedBox(height: context.h(6)),
                        Text('UNIT COST',
                            style: AppTextStyles.caption(context)
                                .copyWith(color: colors.textMuted)),
                        Text(
                          '${Formatters.currency(item.unitCost)} / ${item.unit}',
                          style: AppTextStyles.body(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(14)),

              // Warning
              Container(
                padding: EdgeInsets.all(context.h(12)),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(context.h(8)),
                  border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.danger, size: 18),
                    SizedBox(width: context.w(10)),
                    Expanded(
                      child: Text(
                        'IRREVERSIBLE ACTION\nRemoving this raw material will delete its inventory stock history, supplier linkage, and usage logs from recipes and kitchen queue orders. This cannot be undone.',
                        style: AppTextStyles.caption(context)
                            .copyWith(color: AppColors.danger, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(20)),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('CANCEL'),
                  ),
                  SizedBox(width: context.w(10)),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('DELETE MATERIAL'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}
