import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/utils/formatters.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/widgets/reusable_widgets/stat_card.dart';

class InventoryStatsRow extends StatelessWidget {
  final double expenditure;
  final int total;
  final int addedItemCount;
  final int usedItemCount;
  final int needsRestock;

  const InventoryStatsRow({
    super.key,
    required this.expenditure,
    required this.total,
    required this.addedItemCount,
    required this.usedItemCount,
    required this.needsRestock,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          final spacing = isNarrow ? context.w(6) : context.w(16);
          final minH = isNarrow ? context.h(62) : context.h(72);

          final cards = <Widget>[
            StatCard(
              label: 'Expenditure',
              value: Formatters.currency(expenditure),
              icon: Icons.payments_outlined,
              accentColor: AppColors.warning,
              minHeight: minH,
            ),
            StatCard(
              label: 'Total Items',
              value: '$total',
              icon: Icons.inventory_2_outlined,
              minHeight: minH,
            ),
            StatCard(
              label: 'Added',
              value: '$addedItemCount',
              icon: Icons.add_circle_outline,
              accentColor: AppColors.success,
              minHeight: minH,
            ),
            StatCard(
              label: 'Used',
              value: '$usedItemCount',
              icon: Icons.remove_circle_outline,
              accentColor: AppColors.danger,
              minHeight: minH,
            ),
            StatCard(
              label: 'Needs Restock',
              value: '$needsRestock',
              icon: Icons.warning_amber_rounded,
              accentColor: AppColors.danger,
              minHeight: minH,
            ),
          ];

          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i != cards.length - 1) SizedBox(width: spacing),
              ],
            ],
          );
        },
      ),
    );
  }
}
