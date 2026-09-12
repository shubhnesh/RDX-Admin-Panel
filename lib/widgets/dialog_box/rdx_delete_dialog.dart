// import 'package:flutter/material.dart';

// import '../../../core/theme/app_colors.dart';
// import '../../../core/theme/text_styles.dart';
// import '../../../core/utils/formatters.dart';
// import '../../../models/inventory_item_model.dart';

// class DeleteMaterialDialog extends StatelessWidget {
//   final InventoryItemModel item;

//   const DeleteMaterialDialog({
//     super.key,
//     required this.item,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);

//     return Dialog(
//       backgroundColor: Colors.transparent,
//       insetPadding: const EdgeInsets.symmetric(
//         horizontal: 24,
//         vertical: 24,
//       ),
//       child: ConstrainedBox(
//         constraints: BoxConstraints(
//           maxWidth: 520,
//           maxHeight: MediaQuery.sizeOf(context).height - 48,
//         ),
//         child: IntrinsicHeight(
//           child: Material(
//             color: colors.surface,
//             borderRadius: BorderRadius.circular(12),
//             clipBehavior: Clip.antiAlias,
//             child: SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(14),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     _buildHeader(context),
//                     const SizedBox(height: 12),
//                     _buildMaterialInformation(context),
//                     const SizedBox(height: 10),
//                     _buildWarningSection(context),
//                     const SizedBox(height: 14),
//                     _buildActions(context),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader(BuildContext context) {
//     final colors = AppColors.of(context);

//     return Row(
//       children: [
//         Container(
//           width: 34,
//           height: 34,
//           decoration: BoxDecoration(
//             color: AppColors.danger.withValues(
//               alpha: 0.10,
//             ),
//             borderRadius: BorderRadius.circular(7),
//           ),
//           child: Icon(
//             Icons.delete_outline_rounded,
//             size: 20,
//             color: AppColors.danger,
//           ),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 'Delete Material',
//                 style: AppTextStyles.section(context).copyWith(
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(height: 1),
//               Text(
//                 'PERMANENT REMOVAL',
//                 style: AppTextStyles.label(context).copyWith(
//                   color: colors.textMuted,
//                   letterSpacing: 0.7,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         InkWell(
//           onTap: () => Navigator.of(context).pop(false),
//           borderRadius: BorderRadius.circular(6),
//           child: SizedBox(
//             width: 30,
//             height: 30,
//             child: Icon(
//               Icons.close,
//               size: 20,
//               color: colors.textMuted,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildMaterialInformation(
//     BuildContext context,
//   ) {
//     final colors = AppColors.of(context);

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: colors.surfaceVariant.withValues(
//           alpha: 0.45,
//         ),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: colors.border,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             item.name,
//             style: AppTextStyles.bodySecondary(
//               context,
//             ).copyWith(
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 5),
//           Container(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 7,
//               vertical: 3,
//             ),
//             decoration: BoxDecoration(
//               color: colors.surface,
//               borderRadius: BorderRadius.circular(5),
//               border: Border.all(
//                 color: colors.border,
//               ),
//             ),
//             child: Text(
//               item.category,
//               style: AppTextStyles.label(context),
//             ),
//           ),
//           const SizedBox(height: 10),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: _InfoColumn(
//                   label: 'CURRENT STOCK',
//                   value: '${_fmt(item.quantity)} ${item.unit} / '
//                       '${_fmt(item.maxCapacity)} max',
//                 ),
//               ),
//               const SizedBox(width: 20),
//               Expanded(
//                 child: _InfoColumn(
//                   label: 'UNIT COST',
//                   value: '${Formatters.currency(item.unitCost)} / ${item.unit}',
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildWarningSection(
//     BuildContext context,
//   ) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: AppColors.danger.withValues(
//           alpha: 0.06,
//         ),
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(
//           color: AppColors.danger.withValues(
//             alpha: 0.35,
//           ),
//         ),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(top: 1),
//             child: Icon(
//               Icons.warning_amber_rounded,
//               size: 18,
//               color: AppColors.danger,
//             ),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   'IRREVERSIBLE ACTION',
//                   style: AppTextStyles.label(context).copyWith(
//                     color: AppColors.danger,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   'Removing this raw material will delete its inventory '
//                   'stock history, supplier linkage, and usage logs from '
//                   'recipes and kitchen queue orders. This cannot be undone.',
//                   style: AppTextStyles.bodySecondary(
//                     context,
//                   ).copyWith(
//                     color: AppColors.danger,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActions(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         TextButton(
//           onPressed: () {
//             Navigator.of(context).pop(false);
//           },
//           style: TextButton.styleFrom(
//             foregroundColor: AppColors.of(context).textSecondary,
//             padding: const EdgeInsets.symmetric(
//               horizontal: 14,
//               vertical: 10,
//             ),
//           ),
//           child: Text(
//             'CANCEL',
//             style: AppTextStyles.section(context).copyWith(
//               color: AppColors.of(context).textSecondary,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//         const SizedBox(width: 8),
//         ElevatedButton.icon(
//           onPressed: () {
//             Navigator.of(context).pop(true);
//           },
//           icon: const Icon(
//             Icons.delete_outline_rounded,
//             size: 17,
//           ),
//           label: Text(
//             'DELETE MATERIAL',
//             style: AppTextStyles.section(context).copyWith(
//               color: Colors.white,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppColors.danger,
//             foregroundColor: Colors.white,
//             elevation: 0,
//             padding: const EdgeInsets.symmetric(
//               horizontal: 14,
//               vertical: 10,
//             ),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(6),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   String _fmt(double value) {
//     if (value == value.roundToDouble()) {
//       return value.toInt().toString();
//     }

//     return value.toStringAsFixed(1);
//   }
// }

// class _InfoColumn extends StatelessWidget {
//   final String label;
//   final String value;

//   const _InfoColumn({
//     required this.label,
//     required this.value,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text(
//           label,
//           style: AppTextStyles.label(context).copyWith(
//             color: colors.textMuted,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 2),
//         Text(
//           value,
//           maxLines: 2,
//           overflow: TextOverflow.ellipsis,
//           style: AppTextStyles.bodySecondary(context),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
import '../form_action_button.dart';

class RdxDeleteDialog extends StatelessWidget {
  /// Main dialog title.
  final String title;

  /// Small text displayed below the title.
  final String? subtitle;

  /// Name/title of the item being deleted.
  final String itemName;

  /// Optional custom content displayed inside the item summary section.
  ///
  /// The caller decides what to show here:
  /// category, metrics, description, dates, etc.
  final List<Widget> itemDetails;

  /// Warning heading.
  final String? warningTitle;

  /// Warning message.
  final String warningMessage;

  /// Text displayed on the delete button.
  final String deleteButtonLabel;

  /// Icon displayed beside the title.
  final IconData titleIcon;

  /// Icon displayed inside the delete button.
  final IconData deleteIcon;

  /// Text displayed on the cancel button.
  final String cancelButtonLabel;

  /// Dialog maximum width.
  final double? maxWidth;

  /// Dialog padding.
  final EdgeInsetsGeometry? padding;

  /// Whether the close button should be shown.
  final bool showCloseButton;

  /// Whether the item summary container should be shown.
  final bool showItemSummary;

  /// Whether the warning section should be shown.
  final bool showWarning;

  /// Optional custom warning icon.
  final IconData warningIcon;

  const RdxDeleteDialog({
    super.key,
    required this.title,
    required this.itemName,
    required this.warningMessage,
    this.subtitle = 'PERMANENT REMOVAL',
    this.itemDetails = const [],
    this.warningTitle = 'IRREVERSIBLE ACTION',
    this.deleteButtonLabel = 'DELETE',
    this.titleIcon = Icons.delete,
    this.deleteIcon = Icons.delete,
    this.cancelButtonLabel = 'CANCEL',
    this.maxWidth,
    this.padding,
    this.showCloseButton = true,
    this.showItemSummary = true,
    this.showWarning = true,
    this.warningIcon = Icons.warning_amber_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.h(14)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? context.w(420),
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.all(context.h(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              if (showItemSummary) ...[
                SizedBox(height: context.h(16)),
                _buildItemSummary(context),
              ],
              if (showWarning) ...[
                SizedBox(height: context.h(14)),
                _buildWarning(context),
              ],
              SizedBox(height: context.h(20)),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(context.h(8)),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            titleIcon,
            color: AppColors.danger,
            size: 22,
          ),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.section(context),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTextStyles.bodySecondary(context).copyWith(
                    color: colors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
            ],
          ),
        ),
        if (showCloseButton)
          IconButton(
            icon: Icon(
              Icons.close,
              size: 20,
              color: colors.textMuted,
            ),
            onPressed: () => Navigator.of(context).pop(false),
          ),
      ],
    );
  }

  Widget _buildItemSummary(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: EdgeInsets.all(context.h(14)),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            itemName,
            style: AppTextStyles.bodySecondary(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (itemDetails.isNotEmpty) ...[
            SizedBox(height: context.h(12)),
            ..._buildDetails(context),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDetails(BuildContext context) {
    final widgets = <Widget>[];

    for (int i = 0; i < itemDetails.length; i++) {
      widgets.add(itemDetails[i]);

      if (i < itemDetails.length - 1) {
        widgets.add(
          SizedBox(height: context.h(10)),
        );
      }
    }

    return widgets;
  }

  Widget _buildWarning(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: EdgeInsets.all(context.h(12)),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warningIcon,
            color: AppColors.danger,
            size: 20,
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (warningTitle != null)
                  Text(
                    warningTitle!,
                    style: AppTextStyles.label(context).copyWith(
                      color: AppColors.danger,
                      letterSpacing: 0.5,
                    ),
                  ),
                if (warningTitle != null) SizedBox(height: context.h(4)),
                Text(
                  warningMessage,
                  style: AppTextStyles.body(context).copyWith(
                    color: AppColors.danger,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FormActionButton(
          label: cancelButtonLabel,
          onPressed: () => Navigator.of(context).pop(false),
          backgroundColor: Colors.transparent,
          textColor: AppColors.lightTextSecondary,
          borderColor: AppColors.border,
        ),
        SizedBox(width: context.w(10)),
        FormActionButton(
          label: deleteButtonLabel,
          onPressed: () => Navigator.of(context).pop(true),
          leadingIcon: deleteIcon,
          iconSize: 18,
          backgroundColor: AppColors.danger,
          textColor: Colors.white,
          iconColor: Colors.white,
        ),
      ],
    );
  }
}

/// Generic metric/detail widget used inside reusable dialogs.
class RdxDeleteMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? labelColor;
  final TextStyle? valueStyle;

  const RdxDeleteMetric({
    super.key,
    required this.label,
    required this.value,
    this.labelColor,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label(context).copyWith(
            color: labelColor ?? colors.textMuted,
          ),
        ),
        SizedBox(height: context.h(2)),
        Text(
          value,
          style: valueStyle ?? AppTextStyles.body(context),
        ),
      ],
    );
  }
}
