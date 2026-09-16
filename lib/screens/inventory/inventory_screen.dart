import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                    padding: context.defaultScreenPadding(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Header row: title/subtitle + Add Material ───
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
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
                            ),
                            SizedBox(width: context.w(12)),
                            RdxActionButton(
                              label: 'Add Material',
                              leadingIcon: Icons.add,
                              isPrimary: true,
                              onPressed: () => _openAddMaterial(context),
                            ),
                          ],
                        ),
                        SizedBox(height: context.h(20)),
                        // ── Stats ──────────────────────────────────────
                        InventoryStatsRow(
                          overallCost: provider.overallCost,
                          total: provider.totalItems,
                          inStock: provider.inStockCount,
                          needsRestock: provider.needsRestockCount,
                          critical: provider.criticalCount,
                          lowStock: provider.lowStockCount,
                          onNeedsRestockTap: () => _openLowStock(context),
                        ),
                        SizedBox(height: context.h(20)),
                        // ── Filters row: tabs (left) + search (right) ───
                        if (isNarrow)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              RdxCategoryTabs(
                                labels: const [
                                  'In Stock',
                                  'Low Stock',
                                  'Critical',
                                ],
                                selectedLabel: provider.stockLevelFilter,
                                allLabel: 'All',
                                onSelected: provider.setStockLevelFilter,
                                expand: false,
                              ),
                              SizedBox(height: context.h(12)),
                              RdxSearchBar(
                                controller: _searchController,
                                hintText: 'Search materials or categories',
                                onChanged: provider.setSearch,
                                height: context.h(40),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              RdxCategoryTabs(
                                labels: const [
                                  'In Stock',
                                  'Low Stock',
                                  'Critical',
                                ],
                                selectedLabel: provider.stockLevelFilter,
                                allLabel: 'All',
                                onSelected: provider.setStockLevelFilter,
                                expand: false,
                              ),
                              SizedBox(width: context.w(12)),
                              Expanded(
                                child: RdxSearchBar(
                                  controller: _searchController,
                                  hintText: 'Search materials or categories',
                                  onChanged: provider.setSearch,
                                  height: context.h(40),
                                ),
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
      columns: [
        // Trimmed CATEGORY and UNIT COST/TOTAL COST further so STOCK LEVEL
        // and ADDED/USED/UPDATED pull left too.
       RdxTableColumn(title: 'MATERIAL', minWidth: context.w(120), flex: 3),
RdxTableColumn(title: 'CATEGORY', minWidth: context.w(90), flex: 3),
RdxTableColumn(title: 'STOCK LEVEL', minWidth: context.w(170), flex: 2),
RdxTableColumn(title: 'UNIT COST', minWidth: context.w(80), flex: 2),   // back to 1 → sits closer to STOCK LEVEL
RdxTableColumn(title: 'TOTAL COST', minWidth: context.w(80), flex: 2),  // back to 1
RdxTableColumn(title: 'ADDED (+)', minWidth: context.w(90), flex: 2),   // bumped up to keep ADDED/USED/UPDATED pushed right
RdxTableColumn(title: 'USED (-)', minWidth: context.w(90), flex: 2),
RdxTableColumn(title: 'UPDATED', minWidth: context.w(110), flex: 1),
RdxTableColumn(title: 'ACTIONS', minWidth: context.w(70), flex: 1),
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
          _inventoryStockLevelCell(context, item),
          _inventoryUnitCostCell(context, item),
          _inventoryTotalCostCell(context, item),
          Align(
            alignment: Alignment.centerLeft,
            child: _StockAdjustField(
              key: ValueKey('${item.id}_added'),
              hint: '',
              maxValue: 5000,
              maxErrorText: 'Cannot add more than 5000 at once',
              onSubmit: (value) {
                context.read<InventoryProvider>().addStock(item.id, value);
              },
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _StockAdjustField(
              key: ValueKey('${item.id}_used'),
              hint: '',
              maxValue: item.quantity,
              maxErrorText: 'Cannot use more than current stock',
              onSubmit: (value) {
                context.read<InventoryProvider>().useStock(item.id, value);
              },
            ),
          ),
          _inventoryLastUpdatedCell(context, item),
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

  /// Unit cost, e.g. "₹100/g" — sits where STATUS used to be.
  Widget _inventoryUnitCostCell(
    BuildContext context,
    InventoryItemModel item,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '${Formatters.currency(item.unitCost)}/${item.unit}',
        style: AppTextStyles.bodySecondary(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Total cost (quantity × unit cost), read straight from the value
  /// persisted in Firestore rather than recomputed on the fly, so it
  /// stays consistent with whatever was last saved to the database.
  Widget _inventoryTotalCostCell(
    BuildContext context,
    InventoryItemModel item,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        Formatters.currency(item.totalCost),
        style: AppTextStyles.bodySecondary(context).copyWith(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Shows whichever of the last "added" or last "used" stock movement
  /// happened more recently:
  ///   • if the most recent movement was a restock  -> green "+" + qty
  ///   • if the most recent movement was a usage     -> red   "−" + qty
  /// followed by the timestamp as "DD MMM YY, HH:MM".
  /// Falls back to a dash if the item has never had a movement recorded.
  Widget _inventoryLastUpdatedCell(
    BuildContext context,
    InventoryItemModel item,
  ) {
    final colors = AppColors.of(context);
    final addedAt = item.lastAddedAt;
    final usedAt = item.lastUsedAt;

    if (addedAt == null && usedAt == null) {
      return Text(
        '—',
        style: AppTextStyles.bodySecondary(context)
            .copyWith(color: colors.textMuted),
      );
    }

    final bool showAdded;
    if (addedAt != null && usedAt != null) {
      showAdded = addedAt.isAfter(usedAt);
    } else {
      showAdded = addedAt != null;
    }

    final DateTime when = showAdded ? addedAt! : usedAt!;
    final double qty = showAdded ? (item.lastAddedQty ?? 0) : (item.lastUsedQty ?? 0);
    final Color color = showAdded ? AppColors.success : AppColors.danger;
    final IconData icon = showAdded ? Icons.add : Icons.remove;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon sits directly in front of the number, on the same line —
        // not centered against the two lines as a whole.
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: context.h(13), color: color),
            SizedBox(width: context.w(2)),
            Flexible(
              child: Text(
                '${_fmt(qty)} ${item.unit}',
                style: AppTextStyles.bodySecondary(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Text(
          _formatUpdatedAt(when),
          style: AppTextStyles.label(context)
              .copyWith(color: colors.textMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Formats as "DD MMM YY, HH:MM" (24-hour clock), e.g. "16 Sep 26,14:05".
  String _formatUpdatedAt(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = _months[local.month - 1];
    final year = (local.year % 100).toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
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
                  label: 'Total Cost',
                  value: Formatters.currency(item.totalCost),
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

/// Inline numeric entry used by the ADDED / USED table columns. Typing a
/// quantity and pressing enter/check calls [onSubmit] once, then clears
/// itself — it doesn't hold any running state of its own, the actual
/// stock/cost math happens server-side in InventoryService.addStock /
/// InventoryService.useStock.
class _StockAdjustField extends StatefulWidget {
  final String hint;
  final double maxValue;
  final String maxErrorText;
  final ValueChanged<double> onSubmit;

  const _StockAdjustField({
    super.key,
    required this.hint,
    required this.maxValue,
    required this.maxErrorText,
    required this.onSubmit,
  });

  @override
  State<_StockAdjustField> createState() => _StockAdjustFieldState();
}

class _StockAdjustFieldState extends State<_StockAdjustField> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_controller.text);
    if (value == null || value <= 0) {
      setState(() => _errorText = 'Enter a quantity greater than zero');
      return;
    }
    if (value > widget.maxValue) {
      setState(() => _errorText = widget.maxErrorText);
      return;
    }
    setState(() => _errorText = null);
    widget.onSubmit(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.w(84),
      height: context.h(36),
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          _MaxValueInputFormatter(widget.maxValue),
        ],
        style: AppTextStyles.bodySecondary(context),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hint,
          errorText: _errorText,
          errorMaxLines: 2,
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.w(8),
            vertical: context.h(6),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(context.h(6)),
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.check, size: context.h(16)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _submit,
          ),
        ),
        onChanged: (_) {
          if (_errorText != null) setState(() => _errorText = null);
        },
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}

class _MaxValueInputFormatter extends TextInputFormatter {
  final double maxValue;

  _MaxValueInputFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final value = double.tryParse(newValue.text);
    if (value == null || value > maxValue) return oldValue;
    return newValue;
  }
}
