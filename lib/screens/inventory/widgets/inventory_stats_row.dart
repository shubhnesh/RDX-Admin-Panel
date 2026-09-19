import 'package:flutter/material.dart';
import 'package:rdx_admin/core/utils/formatters.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/widgets/reusable_widgets/stat_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/inventory_provider.dart';

class InventoryStatsRow extends StatelessWidget {
  final double expenditure;
  final int total;

  /// Number of distinct materials that had at least one restock within
  /// the selected period (or ever, for "Overall") — a count of items,
  /// not a sum of quantities.
  final int addedItemCount;

  /// Number of distinct materials that had at least one consumption
  /// within the selected period (or ever, for "Overall") — a count of
  /// items, not a sum of quantities.
  final int usedItemCount;

  final int needsRestock;
  final StatsPeriod period;
  final VoidCallback? onNeedsRestockTap;

  const InventoryStatsRow({
    super.key,
    required this.expenditure,
    required this.total,
    required this.addedItemCount,
    required this.usedItemCount,
    required this.needsRestock,
    required this.period,
    this.onNeedsRestockTap,
  });

  bool get _isOverall => period == StatsPeriod.overall;

  String get _expenditureSubtitle =>
      _isOverall ? 'Overall' : 'Spent · ${period.label}';

  String get _addedSubtitle => _isOverall
      ? 'Items restocked (till now)'
      : 'Items restocked · ${period.label}';

  String get _usedSubtitle =>
      _isOverall ? 'Items used (till now)' : 'Items used · ${period.label}';

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 700;

    final cards = [
      StatCard(
        label: 'TOTAL EXPENDITURE',
        value: Formatters.currency(expenditure),
        subtitle: _expenditureSubtitle,
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
        label: 'USED',
        value: '$usedItemCount',
        subtitle: _usedSubtitle,
        icon: Icons.remove_circle_outline,
        accentColor: AppColors.danger,
      ),
      StatCard(
        label: 'ADDED',
        value: '$addedItemCount',
        subtitle: _addedSubtitle,
        icon: Icons.add_circle_outline,
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
