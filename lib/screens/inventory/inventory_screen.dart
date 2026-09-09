import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rdx_search_bar.dart';
import '../../widgets/rdx_category_tabs.dart';
import 'add_material_screen.dart';
import 'low_stock_screen.dart';
import 'widgets/inventory_stats_row.dart';
import 'widgets/inventory_table.dart';
import 'widgets/delete_material_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<InventoryProvider>().load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: provider.isLoading
          ? const LoadingIndicator()
          : provider.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(provider.errorMessage!,
                          style: AppTextStyles.body(context)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => provider.load(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Page header ─────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        Responsive.pageHorizontal(context),
                        context.h(20),
                        Responsive.pageHorizontal(context),
                        context.h(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Inventory',
                                    style: AppTextStyles.heading(context)),
                                const SizedBox(height: 4),
                                Text(
                                  'Track raw materials, stock levels, and replenishment alerts',
                                  style: AppTextStyles.caption(context)
                                      .copyWith(color: colors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _openAddMaterial(context),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('ADD MATERIAL'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: context.w(18),
                                vertical: context.h(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Stats cards ─────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.pageHorizontal(context),
                      ),
                      child: InventoryStatsRow(
                        total: provider.totalItems,
                        inStock: provider.inStockCount,
                        needsRestock: provider.needsRestockCount,
                        critical: provider.criticalCount,
                        lowStock: provider.lowStockCount,
                        onNeedsRestockTap: () => _openLowStock(context),
                      ),
                    ),

                    SizedBox(height: context.h(16)),

                    // ── Category tabs + search + stock filter ───────────
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.pageHorizontal(context),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: RdxCategoryTabs(
                              labels: provider.categories,
                              selectedLabel: provider.selectedCategory,
                              allLabel: 'All',
                              onSelected: provider.setCategory,
                              expand: false,
                            ),
                          ),
                          SizedBox(width: context.w(12)),
                          SizedBox(
                            width: context.w(220),
                            child: RdxSearchBar(
                              controller: _searchController,
                              hintText: 'Search materials or categories',
                              onChanged: provider.setSearch,
                              height: context.h(40),
                            ),
                          ),
                          SizedBox(width: context.w(10)),
                          _StockLevelDropdown(
                            value: provider.stockLevelFilter,
                            onChanged: provider.setStockLevelFilter,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: context.h(12)),

                    // ── Table ───────────────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.pageHorizontal(context),
                        ),
                        child: InventoryTable(
                          items: provider.filteredItems,
                          onEdit: (item) => _openAddMaterial(context, item: item),
                          onDelete: (item) => _confirmDelete(context, item),
                        ),
                      ),
                    ),

                    // ── Pagination footer (simple) ──────────────────────
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        Responsive.pageHorizontal(context),
                        context.h(8),
                        Responsive.pageHorizontal(context),
                        context.h(16),
                      ),
                      child: Text(
                        'Showing ${provider.filteredItems.length} of ${provider.totalItems} raw materials',
                        style: AppTextStyles.caption(context),
                      ),
                    ),
                  ],
                ),
    );
  }

  void _openAddMaterial(BuildContext context, {InventoryItemModel? item}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddMaterialScreen(existing: item),
      ),
    );
  }

  void _openLowStock(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LowStockScreen()),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, InventoryItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteMaterialDialog(item: item),
    );
    if (confirmed == true && context.mounted) {
      await context.read<InventoryProvider>().deleteItem(item.id);
    }
  }
}

class _StockLevelDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StockLevelDropdown({required this.value, required this.onChanged});

  static const _options = ['All', 'In Stock', 'Low Stock', 'Critical'];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      height: context.h(40),
      padding: EdgeInsets.symmetric(horizontal: context.w(12)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: colors.textSecondary),
          style: AppTextStyles.body(context),
          items: _options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
