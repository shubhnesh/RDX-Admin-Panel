import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rdx_search_bar.dart';

class LowStockScreen extends StatefulWidget {
  const LowStockScreen({super.key});

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  String _filter = 'ALL'; // ALL | CRITICAL | LOW STOCK
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final colors = AppColors.of(context);

    final items = provider.lowStockItems.where((item) {
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        if (!item.name.toLowerCase().contains(q) &&
            !item.category.toLowerCase().contains(q)) return false;
      }
      if (_filter == 'CRITICAL' && item.status != StockStatus.critical) return false;
      if (_filter == 'LOW STOCK' && item.status != StockStatus.lowStock) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: colors.background,
      body: provider.isLoading
          ? const LoadingIndicator()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Breadcrumb + badge ──────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    Responsive.pageHorizontal(context),
                    context.h(16),
                    Responsive.pageHorizontal(context),
                    0,
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: Row(
                          children: [
                            Icon(Icons.arrow_back_ios_new,
                                size: 12, color: colors.textMuted),
                            SizedBox(width: context.w(6)),
                            Text('Back to Inventory',
                                style: AppTextStyles.caption(context)
                                    .copyWith(color: colors.textMuted)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.w(10), vertical: context.h(5)),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle),
                            ),
                            SizedBox(width: context.w(6)),
                            Text(
                              '${provider.needsRestockCount} ITEMS BELOW THRESHOLD',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontSize: context.h(11),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    Responsive.pageHorizontal(context),
                    context.h(10),
                    Responsive.pageHorizontal(context),
                    context.h(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Low Stock & Restock',
                                style: AppTextStyles.heading(context)),
                            SizedBox(height: context.h(4)),
                            Text(
                              '${provider.needsRestockCount} items below minimum threshold replenishment level',
                              style: AppTextStyles.caption(context)
                                  .copyWith(color: colors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: items.isEmpty
                            ? null
                            : () {
                                // Placeholder for bulk reorder action
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Reorder all queued (demo)')),
                                );
                              },
                        icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                        label: Text('+ REORDER ALL (${provider.needsRestockCount})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: context.w(16),
                            vertical: context.h(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Summary cards
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.pageHorizontal(context),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'CRITICAL',
                          value: '${provider.criticalCount} Item${provider.criticalCount == 1 ? '' : 's'}',
                          subtitle: provider.criticalCount > 0
                              ? provider.lowStockItems
                                  .where((e) => e.status == StockStatus.critical)
                                  .map((e) => e.name)
                                  .join(', ')
                              : '—',
                          accent: AppColors.danger,
                          icon: Icons.warning_amber_rounded,
                        ),
                      ),
                      SizedBox(width: context.w(12)),
                      Expanded(
                        child: _SummaryCard(
                          label: 'LOW STOCK',
                          value: '${provider.lowStockCount} Items',
                          subtitle: provider.lowStockCount > 0
                              ? provider.lowStockItems
                                  .where((e) => e.status == StockStatus.lowStock)
                                  .map((e) => e.name)
                                  .join(', ')
                              : '—',
                          accent: AppColors.warning,
                          icon: Icons.hourglass_bottom_rounded,
                        ),
                      ),
                      SizedBox(width: context.w(12)),
                      Expanded(
                        child: _SummaryCard(
                          label: 'RESTOCK COST',
                          value: '${Formatters.currency(provider.restockCostEstimate)} est.',
                          subtitle: 'Covers deficit for all flagged items',
                          accent: AppColors.info,
                          icon: Icons.credit_card_outlined,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: context.h(16)),

                // Tabs + search
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.pageHorizontal(context),
                  ),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'ALL (${provider.needsRestockCount})',
                        selected: _filter == 'ALL',
                        onTap: () => setState(() => _filter = 'ALL'),
                      ),
                      SizedBox(width: context.w(8)),
                      _FilterChip(
                        label: 'CRITICAL (${provider.criticalCount})',
                        selected: _filter == 'CRITICAL',
                        onTap: () => setState(() => _filter = 'CRITICAL'),
                      ),
                      SizedBox(width: context.w(8)),
                      _FilterChip(
                        label: 'LOW STOCK (${provider.lowStockCount})',
                        selected: _filter == 'LOW STOCK',
                        onTap: () => setState(() => _filter = 'LOW STOCK'),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: context.w(220),
                        child: RdxSearchBar(
                          controller: _searchController,
                          hintText: 'Search items...',
                          onChanged: (v) => setState(() => _search = v),
                          height: context.h(38),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: context.h(12)),

                // Table
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.pageHorizontal(context),
                    ),
                    child: items.isEmpty
                        ? Center(
                            child: Text('No items need restocking.',
                                style: AppTextStyles.bodySecondary(context)))
                        : _LowStockTable(items: items),
                  ),
                ),
                SizedBox(height: context.h(16)),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: EdgeInsets.all(context.h(14)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(12)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: AppTextStyles.caption(context)
                      .copyWith(color: colors.textMuted, letterSpacing: 0.5)),
              const Spacer(),
              Icon(icon, size: 18, color: accent),
            ],
          ),
          SizedBox(height: context.h(6)),
          Text(value, style: AppTextStyles.section(context)),
          SizedBox(height: context.h(4)),
          Text(subtitle,
              style: AppTextStyles.caption(context)
                  .copyWith(color: colors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: context.w(14), vertical: context.h(8)),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : colors.textSecondary,
            fontSize: context.h(12),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _LowStockTable extends StatelessWidget {
  final List<InventoryItemModel> items;
  const _LowStockTable({required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(12)),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: colors.surfaceVariant,
            padding: EdgeInsets.symmetric(
                horizontal: context.w(16), vertical: context.h(12)),
            child: Row(
              children: [
                _H('ITEM', 3),
                _H('IN STOCK', 2),
                _H('STATUS', 2),
                _H('SHORTAGE', 2),
                _H('EST. COST', 2),
                _H('ACTION', 1, align: TextAlign.center),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: colors.divider),
              itemBuilder: (context, i) {
                final item = items[i];
                final isCritical = item.status == StockStatus.critical;
                final color = isCritical ? AppColors.danger : AppColors.warning;
                final short = item.shortage;
                final cost = short > 0 ? short * item.unitCost : 0.0;
                final pct = item.stockPercent.clamp(0, 100);

                return Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: context.w(16), vertical: context.h(12)),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name,
                                style: AppTextStyles.body(context)
                                    .copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            SizedBox(height: context.h(4)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: context.w(6), vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.surfaceVariant,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: colors.border),
                              ),
                              child: Text(item.category,
                                  style: AppTextStyles.caption(context)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${_fmt(item.quantity)} ${item.unit} / ${_fmt(item.maxCapacity)} ${item.unit}',
                                  style: AppTextStyles.caption(context),
                                ),
                                SizedBox(width: context.w(6)),
                                Text(
                                  '${pct.toStringAsFixed(0)}%',
                                  style: AppTextStyles.caption(context)
                                      .copyWith(
                                          color: color,
                                          fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: (item.stockPercent / 100).clamp(0, 1),
                                minHeight: 5,
                                backgroundColor: colors.border,
                                valueColor: AlwaysStoppedAnimation(color),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: context.w(10), vertical: context.h(4)),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                      color: color, shape: BoxShape.circle),
                                ),
                                SizedBox(width: context.w(6)),
                                Text(
                                  isCritical ? 'CRITICAL' : 'LOW STOCK',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: context.h(11),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          short > 0
                              ? '-${_fmt(short)} ${item.unit} short'
                              : '—',
                          style: AppTextStyles.body(context)
                              .copyWith(color: AppColors.danger),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(Formatters.currency(cost),
                            style: AppTextStyles.body(context)),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Reorder ${item.name} (demo)')),
                              );
                            },
                            icon: const Icon(Icons.add_shopping_cart, size: 14),
                            label: const Text('REORDER'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCritical
                                  ? AppColors.danger
                                  : colors.surfaceVariant,
                              foregroundColor: isCritical
                                  ? Colors.white
                                  : colors.textPrimary,
                              padding: EdgeInsets.symmetric(
                                  horizontal: context.w(10),
                                  vertical: context.h(8)),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

class _H extends StatelessWidget {
  final String label;
  final int flex;
  final TextAlign align;
  const _H(this.label, this.flex, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: AppTextStyles.caption(context).copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.of(context).textMuted,
        ),
      ),
    );
  }
}
