import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdx_admin/core/utils/formatters.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_action_menu_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_delete_dialog.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_table.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/resuable_options/rdx_search_bar.dart';
import '../../widgets/resuable_options/rdx_category_tabs.dart';
import '../../widgets/resuable_options/rdx_dropdown.dart';
import 'add_material_screen.dart';
import 'low_stock_screen.dart';
import 'widgets/inventory_stats_row.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<InventoryProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showInventoryActions(
    BuildContext buttonContext,
    InventoryItemModel item,
  ) {
    final renderBox = buttonContext.findRenderObject() as RenderBox;
    final buttonPosition = renderBox.localToGlobal(Offset.zero);

    showGeneralDialog<void>(
      context: buttonContext,
      barrierDismissible: true,
      barrierLabel: 'Inventory actions',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return RdxActionMenuDialog(
          position: buttonPosition,
          gap: 6,
          items: [
            RdxActionMenuItem(
              title: 'Edit',
              onTap: () {
                _openAddMaterial(context, item: item);
              },
            ),
            RdxActionMenuItem(
              title: 'Delete',
              textColor: AppColors.danger,
              onTap: () {
                _confirmDelete(context, item);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final colors = AppColors.of(context);
    final isNarrow = MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: provider.isLoading
            ? const LoadingIndicator()
            : provider.errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          provider.errorMessage!,
                          style: AppTextStyles.body(context),
                        ),
                        SizedBox(height: context.h(12)),
                        RdxActionButton(
                          label: 'Retry',
                          onPressed: () => provider.load(),
                          isPrimary: true,
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: Responsive.pagePadding(
                      context,
                      top: context.h(14),
                      bottom: context.h(0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RdxSearchToolbar(
                          controller: _searchController,
                          hintText: 'Search materials or categories',
                          onChanged: provider.setSearch,
                          actions: [
                            RdxActionButton(
                              label: 'Add Material',
                              leadingIcon: Icons.add,
                              onPressed: () => _openAddMaterial(context),
                            ),
                          ],
                        ),
                        // ── Header ─────────────────────────────────────
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inventory',
                              style: AppTextStyles.heading(context),
                            ),
                            SizedBox(height: context.h(4)),
                            Text(
                              'Track raw materials, stock levels, and replenishment alerts',
                              style: AppTextStyles.bodySecondary(context)
                                  .copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),

                        SizedBox(height: context.h(20)),

                        // ── Stats ──────────────────────────────────────
                        InventoryStatsRow(
                          total: provider.totalItems,
                          inStock: provider.inStockCount,
                          needsRestock: provider.needsRestockCount,
                          critical: provider.criticalCount,
                          lowStock: provider.lowStockCount,
                          onNeedsRestockTap: () => _openLowStock(context),
                        ),

                        SizedBox(height: context.h(20)),

                        // ── Filters row ────────────────────────────────
                        if (isNarrow)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              RdxCategoryTabs(
                                labels: provider.categories,
                                selectedLabel: provider.selectedCategory,
                                allLabel: 'All',
                                onSelected: provider.setCategory,
                                expand: false,
                              ),
                              SizedBox(height: context.h(12)),
                              Row(
                                children: [
                                  Expanded(
                                    child: RdxSearchBar(
                                      controller: _searchController,
                                      hintText: 'Search materials',
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
                            ],
                          )
                        else
                          Row(
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
                              SizedBox(width: context.w(10)),
                              _StockLevelDropdown(
                                value: provider.stockLevelFilter,
                                onChanged: provider.setStockLevelFilter,
                              ),
                            ],
                          ),

                        SizedBox(height: context.h(16)),

                        // ── Table ──────────────────────────────────────
                        Expanded(
                          child: _buildInventoryTable(
                            context,
                            provider.filteredItems,
                          ),
                        ),

                        // ── Footer ─────────────────────────────────────
                        Padding(
                          padding: EdgeInsets.only(
                            top: context.h(8),
                            bottom: context.h(16),
                          ),
                          child: Text(
                            'Showing ${provider.filteredItems.length} of ${provider.totalItems} raw materials',
                            style: AppTextStyles.label(context)
                                .copyWith(color: colors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

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
      showFooter: false,
      columns: const [
        RdxTableColumn(title: 'MATERIAL', minWidth: 180, flex: 3),
        RdxTableColumn(title: 'CATEGORY', minWidth: 130, flex: 2),
        RdxTableColumn(title: 'MIN. REQUIRED', minWidth: 130, flex: 2),
        RdxTableColumn(title: 'STOCK LEVEL', minWidth: 220, flex: 3),
        RdxTableColumn(title: 'STATUS', minWidth: 140, flex: 2),
        RdxTableColumn(title: 'UNIT COST', minWidth: 120, flex: 2),
        RdxTableColumn(title: 'ACTIONS', minWidth: 72, flex: 0),
      ],
      rows: items.map((item) {
        return [
          Text(
            item.name,
            style: AppTextStyles.bodySecondary(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
                border: Border.all(color: AppColors.of(context).border),
              ),
              child: Text(
                item.category,
                style: AppTextStyles.label(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Text(
            '${_fmt(item.minRequired)} ${item.unit} min',
            style: AppTextStyles.bodySecondary(context),
          ),
          _inventoryStockLevelCell(context, item),
          _inventoryStatusCell(context, item),
          Text(
            '${Formatters.currency(item.unitCost)}/${item.unit}',
            style: AppTextStyles.bodySecondary(context),
          ),
          Builder(
            builder: (buttonContext) {
              return RdxTableMoreButton(
                tooltip: 'More actions',
                onPressed: () {
                  _showInventoryActions(buttonContext, item);
                },
              );
            },
          ),
        ];
      }).toList(),
    );
  }

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
          style: AppTextStyles.bodySecondary(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: context.h(5)),
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
              width: context.w(6),
              height: context.h(6),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: context.w(6)),
            Text(
              label,
              style: AppTextStyles.label(context).copyWith(color: color),
            ),
          ],
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
    BuildContext context,
    InventoryItemModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Material',
        itemName: item.name,
        itemDetails: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.w(8),
              vertical: context.h(3),
            ),
            decoration: BoxDecoration(
              color: AppColors.of(context).surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.of(context).border),
            ),
            child: Text(
              item.category,
              style: AppTextStyles.body(context),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RdxDeleteMetric(
                  label: 'Current Stock',
                  value: '${_formatQuantity(item.quantity)} ${item.unit} / '
                      '${_formatQuantity(item.maxCapacity)} ${item.unit} max',
                ),
              ),
              SizedBox(width: context.w(16)),
              Expanded(
                child: RdxDeleteMetric(
                  label: 'Unit Cost',
                  value: '${Formatters.currency(item.unitCost)} / ${item.unit}',
                ),
              ),
            ],
          ),
        ],
        deleteButtonLabel: 'Delete Material',
        warningMessage:
            'Removing this raw material will delete its inventory stock '
            'history, supplier linkage, and usage logs from recipes and '
            'kitchen queue orders. This cannot be undone.',
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<InventoryProvider>().deleteItem(item.id);
    }
  }

  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

class _StockLevelDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StockLevelDropdown({
    required this.value,
    required this.onChanged,
  });

  static const _options = ['All', 'In Stock', 'Low Stock', 'Critical'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.w(140),
      child: RdxDropdown<String>(
        value: value,
        items: _options,
        labelBuilder: (option) => option,
        hint: 'Stock level',
        isDense: true,
        onChanged: (selected) {
          if (selected != null) onChanged(selected);
        },
      ),
    );
  }
}
