import 'package:flutter/material.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/widgets/form_action_button.dart';
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
                    child: const Icon(Icons.delete,
                        color: AppColors.danger, size: 22),
                  ),
                  SizedBox(width: context.w(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delete Material',
                            style: AppTextStyles.section(context)),
                        Text('PERMANENT REMOVAL',
                            style: AppTextStyles.bodySecondary(context)
                                .copyWith(
                                    color: colors.textMuted,
                                    letterSpacing: 0.8)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: colors.textMuted),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: AppTextStyles.bodySecondary(context)
                                  .copyWith(fontWeight: FontWeight.w600)),
                          SizedBox(height: context.h(8)),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: context.w(8),
                                vertical: context.h(3)),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: colors.border),
                            ),
                            child: Text(item.category,
                                style: AppTextStyles.body(context)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CURRENT STOCK',
                            style: AppTextStyles.label(context)
                                .copyWith(color: colors.textMuted)),
                        SizedBox(height: context.h(2)),
                        Text(
                          '${_fmt(item.quantity)} ${item.unit} / ${_fmt(item.maxCapacity)} ${item.unit} max',
                          style: AppTextStyles.body(context),
                        ),
                      ],
                    ),
                    SizedBox(width: context.w(24)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('UNIT COST',
                            style: AppTextStyles.label(context)
                                .copyWith(color: colors.textMuted)),
                        SizedBox(height: context.h(2)),
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
                        color: AppColors.danger, size: 20),
                    SizedBox(width: context.w(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'IRREVERSIBLE ACTION',
                            style: AppTextStyles.label(context).copyWith(
                                color: AppColors.danger, letterSpacing: 0.5),
                          ),
                          SizedBox(height: context.h(4)),
                          Text(
                            'Removing this raw material will delete its inventory stock history, supplier linkage, and usage logs from recipes and kitchen queue orders. This cannot be undone.',
                            style: AppTextStyles.body(context)
                                .copyWith(color: AppColors.danger, height: 1.4),
                          ),
                        ],
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
                  FormActionButton(
                    label: 'CANCEL',
                    onPressed: () => Navigator.of(context).pop(true),
                    // isPrimary: false,
                    // leadingIcon: Icons.delete_outline,
                    // iconSize: 18,
                    backgroundColor: Colors.transparent,
                    textColor: AppColors.lightTextSecondary,
                    // iconColor: AppColors.danger,
                    borderColor: AppColors.border,
                  ),

                  // OutlinedButton(
                  //   onPressed: () => Navigator.of(context).pop(false),
                  //   style: OutlinedButton.styleFrom(
                  //     side: BorderSide(color: colors.border),
                  //     foregroundColor: colors.textSecondary,
                  //   ),
                  //   child: const Text('CANCEL'),
                  // ),
                  SizedBox(width: context.w(10)),
                  FormActionButton(
                    label: 'DELETE MATERIAL',
                    onPressed: () => Navigator.of(context).pop(true),
                    leadingIcon: Icons.delete,
                    iconSize: 18,
                    backgroundColor: AppColors.danger,
                    textColor: Colors.white,
                    iconColor: Colors.white,
                  ),
                  // ElevatedButton.icon(
                  //   onPressed: () => Navigator.of(context).pop(true),
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: AppColors.danger,
                  //     foregroundColor: Colors.white,
                  //   ),
                  //   icon: const Icon(Icons.delete_outline, size: 18),
                  //   label: const Text('DELETE MATERIAL'),
                  // ),
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
