import 'package:flutter/material.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/widgets/stat_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';

class InventoryStatsRow extends StatelessWidget {
  final int total;
  final int inStock;
  final int needsRestock;
  final int critical;
  final int lowStock;
  final VoidCallback? onNeedsRestockTap;

  const InventoryStatsRow({
    super.key,
    required this.total,
    required this.inStock,
    required this.needsRestock,
    required this.critical,
    required this.lowStock,
    this.onNeedsRestockTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'TOTAL ITEMS',
            value: '$total',
            subtitle: 'All recorded materials',
            icon: Icons.inventory_2_outlined,
            accentColor: AppColors.primary,
          ),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: StatCard(
            label: 'IN STOCK',
            value: '$inStock',
            subtitle: 'Normal supply',
            // trailing: Text(
            //   '${((inStock / (total == 0 ? 1 : total)) * 100).toStringAsFixed(1)}% of total inventory',
            //   style: AppTextStyles.caption(context)
            //       .copyWith(color: AppColors.success),
            // ),
            icon: Icons.check_circle_outline,
            accentColor: AppColors.success,
          ),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: InkWell(
            onTap: onNeedsRestockTap,
            borderRadius: BorderRadius.circular(context.h(12)),
            child: StatCard(
              label: 'NEEDS RESTOCK',
              value: '$needsRestock',
              subtitle: 'Items below minimum',
              // trailing: Row(
              //   children: [
              //     if (critical > 0)
              //       _Badge(text: '$critical CRITICAL', color: AppColors.danger),
              //     if (critical > 0 && lowStock > 0)
              //       SizedBox(width: context.w(6)),
              //     if (lowStock > 0)
              //       _Badge(
              //           text: '$lowStock LOW STOCK', color: AppColors.warning),
              //   ],
              // ),
              icon: Icons.warning_amber_rounded,
              accentColor: AppColors.warning,
              // highlight: true,
            ),
          ),
        ),
      ],
    );
  }
}

// class _StatCard extends StatelessWidget {
//   final String label;
//   final String value;
//   final String subtitle;
//   final Widget? trailing;
//   final IconData icon;
//   final Color accent;
//   final bool highlight;

//   const _StatCard({
//     required this.label,
//     required this.value,
//     required this.subtitle,
//     this.trailing,
//     required this.icon,
//     required this.accent,
//     this.highlight = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);
//     return Container(
//       padding: EdgeInsets.all(context.h(16)),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(context.h(12)),
//         border: Border.all(
//           color: highlight ? accent.withValues(alpha: 0.45) : colors.border,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Text(
//                 label,
//                 // style: AppTextStyles.caption(context)
//                 //     .copyWith(color: colors.textMuted, letterSpacing: 0.6),
//                 style: AppTextStyles.section(context)
//                     .copyWith(color: colors.textMuted),
//               ),
//               const Spacer(),
//               Icon(icon, size: 20, color: accent),
//             ],
//           ),
//           SizedBox(height: context.h(8)),
//           Text(
//             value,
//             // style: AppTextStyles.heading(context).copyWith(
//             //   fontSize: context.h(28),
//             // ),
//             style: AppTextStyles.heading(context),
//           ),
//           SizedBox(height: context.h(4)),
//           Text(subtitle,
//               // style: AppTextStyles.caption(context),
//               style: AppTextStyles.bodySecondary(context)),
//           if (trailing != null) ...[
//             SizedBox(height: context.h(8)),
//             trailing!,
//           ],
//         ],
//       ),
//     );
//   }
// }

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.w(8), vertical: context.h(3)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(context.h(6)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: context.h(10),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
