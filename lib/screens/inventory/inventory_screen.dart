import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdx_admin/core/utils/formatters.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/widgets/rdx_table.dart';
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
// import 'widgets/inventory_table.dart';
import 'package:rdx_admin/widgets/rdx_table.dart';
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
                                  // style: AppTextStyles.caption(context)
                                  //     .copyWith(color: colors.textMuted),
                                  style: AppTextStyles.bodySecondary(context),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _openAddMaterial(context),
                            icon: const Icon(Icons.add, size: 20),
                            label: Text(
                              'ADD MATERIAL',
                              style: AppTextStyles.section(context)
                                  .copyWith(color: Colors.white),
                            ),
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
                        child: _buildInventoryTable(
                          context,
                          provider.filteredItems,
                        ),
                        // InventoryTable(
                        //   items: provider.filteredItems,
                        //   onEdit: (item) =>
                        //       _openAddMaterial(context, item: item),
                        //   onDelete: (item) => _confirmDelete(context, item),
                        // ),
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
                        // style: AppTextStyles.caption(context),
                        style: AppTextStyles.label(context)
                            .copyWith(color: colors.textMuted),
                      ),
                    ),
                  ],
                ),
    );
  }

  // Widget _buildInventoryTable(
  //   BuildContext context,
  //   List<InventoryItemModel> items,
  // ) {
  //   if (items.isEmpty) {
  //     return _buildEmptyInventoryState(context);
  //   }

  //   return RdxTable(
  //     mobileMinTableWidth: 900,
  //     tabletMinTableWidth: 950,
  //     showFooter: false,
  //     columns: const [
  //       RdxTableColumn(
  //         title: 'MATERIAL',
  //         minWidth: 220,
  //         flex: 0.30,
  //       ),
  //       RdxTableColumn(
  //         title: 'CATEGORY',
  //         minWidth: 150,
  //         flex: 0.20,
  //       ),
  //       RdxTableColumn(
  //         title: 'STOCK',
  //         minWidth: 120,
  //         flex: 0.15,
  //       ),
  //       RdxTableColumn(
  //         title: 'UNIT',
  //         minWidth: 100,
  //         flex: 0.10,
  //       ),
  //       RdxTableColumn(
  //         title: 'STATUS',
  //         minWidth: 130,
  //         flex: 0.15,
  //       ),
  //       RdxTableColumn(
  //         title: 'ACTIONS',
  //         minWidth: 110,
  //         flex: 0.10,
  //       ),
  //     ],
  //     rows: items.map((item) {
  //       return [
  //         _inventoryTextCell(
  //           context,
  //           item.name,
  //         ),
  //         _inventoryTextCell(
  //           context,
  //           item.category,
  //         ),
  //         _inventoryTextCell(
  //           context,
  //           item.quantity.toString(),
  //         ),
  //         _inventoryTextCell(
  //           context,
  //           item.unit,
  //         ),
  //         _inventoryStatusCell(
  //           context,
  //           item,
  //         ),
  //         Row(
  //           children: [
  //             RdxTableActionButton(
  //               icon: Icons.edit_outlined,
  //               tooltip: 'Edit material',
  //               onPressed: () => _openAddMaterial(
  //                 context,
  //                 item: item,
  //               ),
  //             ),
  //             const SizedBox(width: 4),
  //             RdxTableActionButton(
  //               icon: Icons.delete_outline,
  //               tooltip: 'Delete material',
  //               onPressed: () => _confirmDelete(
  //                 context,
  //                 item,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ];
  //     }).toList(),
  //   );
  // }
  Widget _buildInventoryTable(
    BuildContext context,
    List<InventoryItemModel> items,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No materials match the current filters.',
          style: AppTextStyles.bodySecondary(context),
        ),
      );
    }

    return RdxTable(
      // mobileMinTableWidth: 1080,
      // tabletMinTableWidth: 1080,
      showFooter: false,
      columns: const [
        RdxTableColumn(
          title: 'MATERIAL',
          minWidth: 180,
          flex: 3,
        ),
        RdxTableColumn(
          title: 'CATEGORY',
          minWidth: 130,
          flex: 2,
        ),
        RdxTableColumn(
          title: 'MIN. REQUIRED',
          minWidth: 130,
          flex: 2,
        ),
        RdxTableColumn(
          title: 'STOCK LEVEL',
          minWidth: 220,
          flex: 3,
        ),
        RdxTableColumn(
          title: 'STATUS',
          minWidth: 140,
          flex: 2,
        ),
        RdxTableColumn(
          title: 'UNIT COST',
          minWidth: 120,
          flex: 2,
        ),
        RdxTableColumn(
          title: 'ACTIONS',
          minWidth: 110,
          flex: 1,
        ),
      ],
      rows: items.map((item) {
        return [
          // MATERIAL
          Text(
            item.name,
            style: AppTextStyles.body(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // CATEGORY
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(8),
                vertical: context.h(3),
              ),
              decoration: BoxDecoration(
                color: AppColors.of(context).surfaceVariant,
                borderRadius: BorderRadius.circular(context.h(6)),
                border: Border.all(
                  color: AppColors.of(context).border,
                ),
              ),
              child: Text(
                item.category,
                style: AppTextStyles.caption(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // MIN. REQUIRED
          Text(
            '${_fmt(item.minRequired)} ${item.unit} min',
            style: AppTextStyles.body(context),
          ),

          // STOCK LEVEL
          _inventoryStockLevelCell(
            context,
            item,
          ),

          // STATUS
          _inventoryStatusCell(
            context,
            item,
          ),

          // UNIT COST
          Text(
            '${Formatters.currency(item.unitCost)}/${item.unit}',
            style: AppTextStyles.body(context),
          ),

          // ACTIONS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              RdxTableActionButton(
                icon: Icons.edit_outlined,
                tooltip: 'Edit',
                onPressed: () => _openAddMaterial(
                  context,
                  item: item,
                ),
              ),
              RdxTableActionButton(
                icon: Icons.delete_outline,
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(
                  context,
                  item,
                ),
              ),
            ],
          ),
        ];
      }).toList(),
    );
  }

  // Widget _inventoryStockLevelCell(
  //   BuildContext context,
  //   InventoryItemModel item,
  // ) {
  //   final colors = AppColors.of(context);
  //   final status = item.status;

  //   final Color color;

  //   switch (status) {
  //     case StockStatus.inStock:
  //       color = AppColors.success;
  //       break;
  //     case StockStatus.lowStock:
  //       color = AppColors.warning;
  //       break;
  //     case StockStatus.critical:
  //       color = AppColors.danger;
  //       break;
  //     case StockStatus.outOfStock:
  //       color = AppColors.danger;
  //       break;
  //   }

  //   final pct = item.stockPercent.clamp(0, 100);

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       Text(
  //         '${_fmt(item.quantity)} / ${_fmt(item.maxCapacity)} '
  //         '${item.unit} (${pct.toStringAsFixed(0)}%)',
  //         style: AppTextStyles.caption(context),
  //         maxLines: 1,
  //         overflow: TextOverflow.ellipsis,
  //       ),
  //       SizedBox(height: context.h(4)),
  //       ClipRRect(
  //         borderRadius: BorderRadius.circular(4),
  //         child: LinearProgressIndicator(
  //           value: pct / 100,
  //           minHeight: 6,
  //           backgroundColor: colors.border,
  //           valueColor: AlwaysStoppedAnimation(color),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _inventoryStockLevelCell(
    BuildContext context,
    InventoryItemModel item,
  ) {
    final colors = AppColors.of(context);
    final status = item.status;

    final Color color;

    switch (status) {
      case StockStatus.inStock:
        color = AppColors.success;
        break;
      case StockStatus.lowStock:
        color = AppColors.warning;
        break;
      case StockStatus.critical:
        color = AppColors.danger;
        break;
      case StockStatus.outOfStock:
        color = AppColors.danger;
        break;
    }

    final pct = item.stockPercent.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_fmt(item.quantity)} / ${_fmt(item.maxCapacity)} '
          '${item.unit} (${pct.toStringAsFixed(0)}%)',
          style: AppTextStyles.caption(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: context.h(5)),

        // Progress bar intentionally uses a percentage of the
        // available cell width instead of the complete column width.
        FractionallySizedBox(
          widthFactor: 0.72,
          alignment: Alignment.centerLeft,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _inventoryTextCell(
    BuildContext context,
    String value,
  ) {
    return Text(
      value,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodySecondary(context),
    );
  }

  // Widget _inventoryStatusCell(
  //   BuildContext context,
  //   InventoryItemModel item,
  // ) {
  //   final colors = AppColors.of(context);

  //   final String status;
  //   final Color statusColor;

  //   switch (item.status) {
  //     case StockStatus.critical:
  //       status = 'Critical';
  //       statusColor = AppColors.danger;
  //       break;

  //     case StockStatus.lowStock:
  //       status = 'Low Stock';
  //       statusColor = AppColors.warning;
  //       break;

  //     case StockStatus.outOfStock:
  //       status = 'Out of Stock';
  //       statusColor = AppColors.danger;
  //       break;

  //     case StockStatus.inStock:
  //       status = 'In Stock';
  //       statusColor = AppColors.success;
  //       break;
  //   }

  //   return Row(
  //     children: [
  //       Container(
  //         width: 7,
  //         height: 7,
  //         decoration: BoxDecoration(
  //           color: statusColor,
  //           shape: BoxShape.circle,
  //         ),
  //       ),
  //       const SizedBox(width: 8),
  //       Flexible(
  //         child: Text(
  //           status,
  //           maxLines: 1,
  //           overflow: TextOverflow.ellipsis,
  //           style: AppTextStyles.bodySecondary(context).copyWith(
  //             color: colors.textPrimary,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
  Widget _inventoryStatusCell(
    BuildContext context,
    InventoryItemModel item,
  ) {
    final status = item.status;
    final Color color;
    final String label;

    switch (status) {
      case StockStatus.inStock:
        color = AppColors.success;
        label = 'In Stock';
        break;

      case StockStatus.lowStock:
        color = AppColors.warning;
        label = 'Low Stock';
        break;

      case StockStatus.critical:
        color = AppColors.danger;
        label = 'Critical';
        break;

      case StockStatus.outOfStock:
        color = AppColors.danger;
        label = 'Out of Stock';
        break;
    }

    return Align(
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
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: context.w(6)),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: context.h(11),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInventoryState(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: Text(
        'No inventory items found',
        style: AppTextStyles.bodySecondary(context).copyWith(
          color: colors.textMuted,
        ),
      ),
    );
  }

  String _fmt(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
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
          style: AppTextStyles.section(context).copyWith(
            color: colors.textSecondary,
          ),
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
