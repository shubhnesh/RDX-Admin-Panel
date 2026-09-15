import 'package:flutter/material.dart';
import 'package:rdx_admin/core/utils/formatters.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/widgets/reusable_widgets/stat_card.dart';
import '../../../core/theme/app_colors.dart';

class InventoryStatsRow extends StatelessWidget {
  final double overallCost;
  final int total;
  final int inStock;
  final int needsRestock;
  final int critical;
  final int lowStock;
  final VoidCallback? onNeedsRestockTap;

  const InventoryStatsRow({
    super.key,
    required this.overallCost,
    required this.total,
    required this.inStock,
    required this.needsRestock,
    required this.critical,
    required this.lowStock,
    this.onNeedsRestockTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 700;

    final cards = [
      StatCard(
        label: 'TOTAL EXPENDITURE',
        value: Formatters.currency(overallCost),
        subtitle: 'Cost of all materials',
        icon: Icons.payments_outlined,
        accentColor: AppColors.primary,
      ),
      StatCard(
        label: 'TOTAL ITEMS',
        value: '$total',
        subtitle: 'All recorded materials',
        icon: Icons.inventory_2_outlined,
        accentColor: AppColors.primary,
      ),
      StatCard(
        label: 'IN STOCK',
        value: '$inStock',
        subtitle: 'Normal supply',
        icon: Icons.check_circle_outline,
        accentColor: AppColors.success,
      ),
      InkWell(
        onTap: onNeedsRestockTap,
        borderRadius: BorderRadius.circular(context.h(12)),
        child: StatCard(
          label: 'NEEDS RESTOCK',
          value: '$needsRestock',
          subtitle: 'Items below minimum',
          icon: Icons.warning_amber_rounded,
          accentColor: AppColors.warning,
        ),
      ),
    ];

    if (isNarrow) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i != cards.length - 1) SizedBox(height: context.h(12)),
          ],
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i != cards.length - 1) SizedBox(width: context.w(12)),
          ],
        ],
      ),
    );
  }
}
