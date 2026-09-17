import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/resuable_options/rdx_search_bar.dart';
import '../../widgets/reusable_widgets/rdx_table.dart';

class LowStockScreen extends ConsumerStatefulWidget {
  const LowStockScreen({super.key});

  @override
  ConsumerState<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends ConsumerState<LowStockScreen> {
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
    final provider = ref.watch(inventoryProvider);
    final colors = AppColors.of(context);
    final isNarrow = MediaQuery.sizeOf(context).width < 900;

    final items = provider.lowStockItems.where((item) {
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        if (!item.name.toLowerCase().contains(q) &&
            !item.category.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_filter == 'CRITICAL' && item.status != StockStatus.critical) {
        return false;
      }
      if (_filter == 'LOW STOCK' && item.status != StockStatus.lowStock) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: provider.isLoading
            ? const LoadingIndicator()
            : Padding(
                padding: Responsive.pagePadding(
                  context,
                  top: context.h(14),
                  bottom: context.h(0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Breadcrumb + badge ──────────────────────────
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(context.h(6)),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: context.h(4),
                              horizontal: context.w(2),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_back_ios_new,
                                  size: context.h(12),
                                  color: colors.textMuted,
                                ),
                                SizedBox(width: context.w(6)),
                                Text(
                                  'Back to Inventory',
                                  style: AppTextStyles.caption(context)
                                      .copyWith(color: colors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.w(10),
                            vertical: context.h(5),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: context.w(6),
                                height: context.h(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: context.w(6)),
                              Text(
                                '${provider.needsRestockCount} ITEMS BELOW THRESHOLD',
                                style: AppTextStyles.label(context).copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: context.h(12)),

                    // ── Header ─────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Low Stock & Restock',
                                style: AppTextStyles.heading(context),
                              ),
                              SizedBox(height: context.h(4)),
                              Text(
                                '${provider.needsRestockCount} items below minimum threshold replenishment level',
                                style: AppTextStyles.bodySecondary(context)
                                    .copyWith(color: colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (!isNarrow)
                          RdxActionButton(
                            label:
                                'Reorder All (${provider.needsRestockCount})',
                            onPressed: items.isEmpty
                                ? null
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Reorder all queued (demo)',
                                        ),
                                      ),
                                    );
                                  },
                            isPrimary: true,
                            leadingIcon: Icons.add_shopping_cart_outlined,
                            iconSize: context.h(18),
                          ),
                      ],
                    ),

                    if (isNarrow) ...[
                      SizedBox(height: context.h(12)),
                      SizedBox(
                        width: double.infinity,
                        child: RdxActionButton(
                          label: 'Reorder All (${provider.needsRestockCount})',
                          onPressed: items.isEmpty
                              ? null
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Reorder all queued (demo)',
                                      ),
                                    ),
                                  );
                                },
                          isPrimary: true,
                          leadingIcon: Icons.add_shopping_cart_outlined,
                          iconSize: context.h(18),
                        ),
                      ),
                    ],

                    SizedBox(height: context.h(20)),

                    // ── Summary cards ──────────────────────────────
                    if (isNarrow)
                      Column(
                        children: [
                          _SummaryCard(
                            label: 'CRITICAL',
                            value:
                                '${provider.criticalCount} Item${provider.criticalCount == 1 ? '' : 's'}',
                            subtitle: provider.criticalCount > 0
                                ? provider.lowStockItems
                                    .where(
                                      (e) => e.status == StockStatus.critical,
                                    )
                                    .map((e) => e.name)
                                    .join(', ')
                                : '—',
                            accent: AppColors.danger,
                            icon: Icons.warning_amber_rounded,
                          ),
                          SizedBox(height: context.h(12)),
                          _SummaryCard(
                            label: 'LOW STOCK',
                            value: '${provider.lowStockCount} Items',
                            subtitle: provider.lowStockCount > 0
                                ? provider.lowStockItems
                                    .where(
                                      (e) => e.status == StockStatus.lowStock,
                                    )
                                    .map((e) => e.name)
                                    .join(', ')
                                : '—',
                            accent: AppColors.warning,
                            icon: Icons.hourglass_bottom_rounded,
                          ),
                          SizedBox(height: context.h(12)),
                          _SummaryCard(
                            label: 'RESTOCK COST',
                            value:
                                '${Formatters.currency(provider.restockCostEstimate)} est.',
                            subtitle: 'Covers deficit for all flagged items',
                            accent: AppColors.info,
                            icon: Icons.credit_card_outlined,
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              label: 'CRITICAL',
                              value:
                                  '${provider.criticalCount} Item${provider.criticalCount == 1 ? '' : 's'}',
                              subtitle: provider.criticalCount > 0
                                  ? provider.lowStockItems
                                      .where(
                                        (e) => e.status == StockStatus.critical,
                                      )
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
                                      .where(
                                        (e) => e.status == StockStatus.lowStock,
                                      )
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
                              value:
                                  '${Formatters.currency(provider.restockCostEstimate)} est.',
                              subtitle: 'Covers deficit for all flagged items',
                              accent: AppColors.info,
                              icon: Icons.credit_card_outlined,
                            ),
                          ),
                        ],
                      ),

                    SizedBox(height: context.h(20)),

                    // ── Tabs + search ──────────────────────────────
                    if (isNarrow)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
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
                                  onTap: () =>
                                      setState(() => _filter = 'CRITICAL'),
                                ),
                                SizedBox(width: context.w(8)),
                                _FilterChip(
                                  label:
                                      'LOW STOCK (${provider.lowStockCount})',
                                  selected: _filter == 'LOW STOCK',
                                  onTap: () =>
                                      setState(() => _filter = 'LOW STOCK'),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: context.h(12)),
                          RdxSearchBar(
                            controller: _searchController,
                            hintText: 'Search items...',
                            onChanged: (v) => setState(() => _search = v),
                            height: context.h(38),
                          ),
                        ],
                      )
                    else
                      Row(
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

                    SizedBox(height: context.h(16)),

                    // ── Table ──────────────────────────────────────
                    Expanded(
                      child: items.isEmpty
                          ? Center(
                              child: Text(
                                'No items need restocking.',
                                style: AppTextStyles.bodySecondary(context),
                              ),
                            )
                          : _LowStockTable(items: items),
                    ),

                    SizedBox(height: context.h(16)),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SummaryCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
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
              Text(
                label,
                style: AppTextStyles.caption(context).copyWith(
                  color: colors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Icon(icon, size: context.h(18), color: accent),
            ],
          ),
          SizedBox(height: context.h(6)),
          Text(value, style: AppTextStyles.section(context)),
          SizedBox(height: context.h(4)),
          Text(
            subtitle,
            style: AppTextStyles.caption(context)
                .copyWith(color: colors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends ConsumerWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(8),
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label(context).copyWith(
            color: selected ? Colors.white : colors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _LowStockTable extends ConsumerWidget {
  final List<InventoryItemModel> items;
  const _LowStockTable({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RdxTable(
      showFooter: false,
      columns: [
        RdxTableColumn(title: 'ITEM', minWidth: context.w(180), flex: 3),
        RdxTableColumn(title: 'IN STOCK', minWidth: context.w(160), flex: 2),
        RdxTableColumn(title: 'STATUS', minWidth: context.w(130), flex: 2),
        RdxTableColumn(title: 'SHORTAGE', minWidth: context.w(120), flex: 2),
        RdxTableColumn(title: 'EST. COST', minWidth: context.w(110), flex: 2),
        RdxTableColumn(
          title: 'ACTION',
          minWidth: context.w(120),
          flex: 1,
          alignment: Alignment.center,
        ),
      ],
      rows: items.map((item) {
        final isCritical = item.status == StockStatus.critical;
        final color = isCritical ? AppColors.danger : AppColors.warning;
        final short = item.shortage;
        final cost = short > 0 ? short * item.unitCost : 0.0;
        final pct = item.stockPercent.clamp(0, 100);
        final colors = AppColors.of(context);

        return [
          // ITEM
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style: AppTextStyles.body(context)
                    .copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: context.h(4)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(6),
                  vertical: context.h(2),
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  item.category,
                  style: AppTextStyles.caption(context),
                ),
              ),
            ],
          ),

          // IN STOCK
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '${_fmt(item.quantity)} ${item.unit} / ${_fmt(item.maxCapacity)} ${item.unit}',
                      style: AppTextStyles.caption(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: context.w(6)),
                  Text(
                    '${pct.toStringAsFixed(0)}%',
                    style: AppTextStyles.caption(context).copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.h(4)),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (item.stockPercent / 100).clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: colors.border,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),

          // STATUS
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(10),
                vertical: context.h(4),
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: context.w(6),
                    height: context.h(6),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: context.w(6)),
                  Text(
                    isCritical ? 'CRITICAL' : 'LOW STOCK',
                    style: AppTextStyles.label(context).copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // SHORTAGE
          Text(
            short > 0 ? '-${_fmt(short)} ${item.unit} short' : '—',
            style:
                AppTextStyles.body(context).copyWith(color: AppColors.danger),
          ),

          // EST. COST
          Text(
            Formatters.currency(cost),
            style: AppTextStyles.body(context),
          ),

          // ACTION
          Center(
            child: RdxActionButton(
              label: 'Reorder',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reorder ${item.name} (demo)')),
                );
              },
              isPrimary: true,
              leadingIcon: Icons.add_shopping_cart,
              iconSize: context.h(14),
              backgroundColor:
                  isCritical ? AppColors.danger : colors.surfaceVariant,
              textColor: isCritical ? Colors.white : colors.textPrimary,
              height: context.h(32),
            ),
          ),
        ];
      }).toList(),
    );
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}
