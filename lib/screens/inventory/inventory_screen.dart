import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/utils/formatters.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_action_menu_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_delete_dialog.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/buttons/stats_collapse_button.dart';
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
import 'widgets/inventory_stats_row.dart';

/// Which action (add/use) most recently happened for an item — used to
/// star the more recent one in the ADDED / USED table columns.
enum _RecentAction { added, used, none }

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();

  /// Whether the stat card row is hidden, giving the table below more
  /// vertical room. Toggled by [StatsCollapseButton].
  bool _statsCollapsed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(inventoryProvider).load();
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
    final provider = ref.watch(inventoryProvider);
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
                        // ── Stats collapse toggle ───────────────────────
                        // Sits above the stat row's left edge; collapsing
                        // hides the row entirely so the table below gets
                        // more vertical space.
                        Align(
                          alignment: Alignment.centerLeft,
                          child: StatsCollapseButton(
                            collapsed: _statsCollapsed,
                            onPressed: () => setState(
                              () => _statsCollapsed = !_statsCollapsed,
                            ),
                          ),
                        ),
                        SizedBox(height: context.h(8)),
                        // ── Stats ──────────────────────────────────────
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          alignment: Alignment.topCenter,
                          child: _statsCollapsed
                              ? const SizedBox(width: double.infinity)
                              : InventoryStatsRow(
                                  expenditure: provider.periodExpenditure,
                                  total: provider.totalItems,
                                  addedItemCount:
                                      provider.periodAddedItemCount,
                                  usedItemCount: provider.periodUsedItemCount,
                                  needsRestock: provider.needsRestockCount,
                                  period: provider.periodFilter,
                                  // onNeedsRestockTap: () =>
                                  //     _openLowStock(context),
                                ),
                        ),
                        SizedBox(height: context.h(20)),
                        // ── Filters row: stock tabs, search, activity chips, period dropdown ───
                        if (isNarrow)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              RdxCategoryTabs(
                                labels: const ['Low Stock', 'Critical'],
                                selectedLabel: provider.stockLevelFilter,
                                allLabel: 'All',
                                onSelected: (label) =>
                                    _onStockLevelSelected(provider, label),
                                expand: false,
                              ),
                              SizedBox(height: context.h(12)),
                              RdxSearchBar(
                                controller: _searchController,
                                hintText: 'Search materials or categories',
                                onChanged: provider.setSearch,
                                height: context.h(40),
                              ),
                              SizedBox(height: context.h(12)),
                              Row(
                                children: [
                                  _activityFilterChip(
                                    context,
                                    provider,
                                    'Used',
                                  ),
                                  SizedBox(width: context.w(8)),
                                  _activityFilterChip(
                                    context,
                                    provider,
                                    'Added',
                                  ),
                                  SizedBox(width: context.w(8)),
                                  Expanded(
                                    child: _periodDropdown(context, provider),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              RdxCategoryTabs(
                                labels: const ['Low Stock', 'Critical'],
                                selectedLabel: provider.stockLevelFilter,
                                allLabel: 'All',
                                onSelected: (label) =>
                                    _onStockLevelSelected(provider, label),
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
                              SizedBox(width: context.w(12)),
                              _activityFilterChip(context, provider, 'Used'),
                              SizedBox(width: context.w(8)),
                              _activityFilterChip(context, provider, 'Added'),
                              SizedBox(width: context.w(12)),
                              SizedBox(
                                width: context.w(150),
                                child: _periodDropdown(context, provider),
                              ),
                            ],
                          ),
                        SizedBox(height: context.h(16)),
                        // ── Table ──────────────────────────────────────
                        Expanded(
                          child: _buildInventoryTable(
                            context,
                            provider,
                            provider.filteredItems,
                          ),
                        ),
                        // ── Footer ─────────────────────────────────────
                        Padding(
                          padding: EdgeInsets.only(
                            top: context.h(8),
                            bottom: context.h(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: context.h(14),
                                color: AppColors.warning,
                              ),
                              SizedBox(width: context.w(4)),
                              Text(
                                'indicates whichever action happened most recently for that material.',
                                style: AppTextStyles.label(context)
                                    .copyWith(color: colors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  /// Custom "Used"/"Added" pill — separate from the RdxCategoryTabs group so
  /// it can sit on the right of the search bar, and disabled until a period
  /// is picked in the dropdown (Used/Added only make sense once "Overall"
  /// has been narrowed down to a specific window).
  Widget _activityFilterChip(
    BuildContext context,
    InventoryProvider provider,
    String label,
  ) {
    final colors = AppColors.of(context);
    final enabled = provider.periodFilter != StatsPeriod.overall;
    final selected = enabled && provider.stockLevelFilter == label;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: !enabled
            ? null
            : () => _onStockLevelSelected(
                  provider,
                  selected ? 'All' : label,
                ),
        borderRadius: BorderRadius.circular(context.h(20)),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(14),
            vertical: context.h(9),
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : colors.surface,
            borderRadius: BorderRadius.circular(context.h(20)),
            border: Border.all(
              color: selected ? AppColors.primary : colors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.label(context).copyWith(
              color: selected ? Colors.white : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _periodDropdown(BuildContext context, InventoryProvider provider) {
    final isOverall = provider.periodFilter == StatsPeriod.overall;
    return RdxDropdown<StatsPeriod>(
      items: StatsPeriod.values
          .where((p) => p != StatsPeriod.overall)
          .toList(),
      value: isOverall ? null : provider.periodFilter,
      labelBuilder: (p) => p.label,
      hint: 'Select',
      onChanged: (p) {
        if (p != null) provider.setPeriodFilter(p);
      },
      isDense: true,
    );
  }

  /// Selecting a stock-level tag ("All", "Low Stock", "Critical") resets
  /// the period dropdown back to "Select" (StatsPeriod.overall). Only the
  /// activity chips ("Used"/"Added") are period-scoped, so any stock-level
  /// tag clears the period the same way "All" does.
  void _onStockLevelSelected(InventoryProvider provider, String label) {
    provider.setStockLevelFilter(label);
    if (label != 'Used' && label != 'Added') {
      provider.setPeriodFilter(StatsPeriod.overall);
    }
  }

  Widget _buildInventoryTable(
    BuildContext context,
    InventoryProvider provider,
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
        // Equal flex so leftover width is shared across every column
        // instead of dumping into MATERIAL alone.
        RdxTableColumn(title: 'MATERIAL', minWidth: context.w(100), flex: 1),
        RdxTableColumn(title: 'CATEGORY', minWidth: context.w(85), flex: 1),
        RdxTableColumn(title: 'STOCKS', minWidth: context.w(170), flex: 1.3),
        RdxTableColumn(title: '₹ / UNIT', minWidth: context.w(75), flex: 1),
        RdxTableColumn(title: 'TOTAL (₹)', minWidth: context.w(75), flex: 1),
        RdxTableColumn(title: 'ADDED (+)', minWidth: context.w(78), flex: 0.6),
        RdxTableColumn(title: 'USED (-)', minWidth: context.w(78), flex: 0.6),
        RdxTableColumn(title: 'TOTAL ADDED', minWidth: context.w(100), flex: 1),
        RdxTableColumn(title: 'TOTAL USED', minWidth: context.w(100), flex: 1),
        RdxTableColumn(title: 'ACTIONS', minWidth: context.w(56), flex: 1),
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
              maxValue: 999,
              maxErrorText: 'Max 3 digits (999)',
              onSubmit: (value) {
                ref.read(inventoryProvider).addStock(item.id, value);
              },
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _StockAdjustField(
              key: ValueKey('${item.id}_used'),
              hint: '',
              maxValue: item.quantity > 999 ? 999 : item.quantity,
              maxErrorText: item.quantity > 999
                  ? 'Max 3 digits (999)'
                  : 'Cannot use more than current stock',
              onSubmit: (value) {
                ref.read(inventoryProvider).useStock(item.id, value);
              },
            ),
          ),
          _inventoryTotalAddedCell(context, provider, item),
          _inventoryTotalUsedCell(context, provider, item),
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
    final baseStyle = AppTextStyles.bodySecondary(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: baseStyle,
            children: [
              TextSpan(
                text: _fmt(item.quantity),
                style: baseStyle.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: ' / ${_fmt(item.maxCapacity)} '
                    '${item.unit} (${pct.toStringAsFixed(0)}%)',
              ),
            ],
          ),
        ),
        SizedBox(height: context.h(5)),
        FractionallySizedBox(
          widthFactor: 0.82,
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

  /// Which of the two actions (add/use) most recently happened for an
  /// item, so the Overall view can star whichever one is more recent.
  /// Only meaningful when the item has *both* an add and a use event —
  /// with just one kind of event there's nothing to compare, so no star.
  _RecentAction _mostRecentAction(InventoryItemModel item) {
    final added = item.lastAddedAt;
    final used = item.lastUsedAt;
    if (added == null || used == null) return _RecentAction.none;
    return added.isAfter(used) ? _RecentAction.added : _RecentAction.used;
  }

  /// Lifetime cumulative quantity added (initial stock + every restock),
  /// shown when the period dropdown is "Overall" — green "+" amount with
  /// the most recent add timestamp underneath. For a specific window
  /// (Today / Yesterday / This Week / This Month) this instead shows the
  /// most recent add *if it happened inside that window*, with the
  /// window's name ("Today", etc.) instead of the date — the model only
  /// keeps the latest add event, not a full history, so a window that
  /// doesn't contain it shows "—".
  Widget _inventoryTotalAddedCell(
    BuildContext context,
    InventoryProvider provider,
    InventoryItemModel item,
  ) {
    final colors = AppColors.of(context);
    final overall = provider.periodFilter == StatsPeriod.overall;
    final inPeriod = provider.isInCurrentPeriod(item.lastAddedAt);

    if (overall) {
      if (item.totalAdded <= 0 && item.lastAddedAt == null) {
        return Text(
          '—',
          style: AppTextStyles.bodySecondary(context)
              .copyWith(color: colors.textMuted),
        );
      }
      return _addedUsedCellContent(
        context,
        icon: Icons.add,
        color: AppColors.success,
        amountLabel: '${_fmt(item.totalAdded)} ${item.unit}',
        footer: item.lastAddedAt != null
            ? _formatUpdatedAt(item.lastAddedAt!)
            : null,
        showStar: _mostRecentAction(item) == _RecentAction.added,
      );
    }

    if (!inPeriod) {
      return Text(
        '—',
        style: AppTextStyles.bodySecondary(context)
            .copyWith(color: colors.textMuted),
      );
    }
    return _addedUsedCellContent(
      context,
      icon: Icons.add,
      color: AppColors.success,
      amountLabel: '${_fmt(item.lastAddedQty ?? 0)} ${item.unit}',
      footer: provider.periodFilter.label,
    );
  }

  /// Lifetime cumulative quantity used, shown when the period dropdown is
  /// "Overall" — red "−" amount with the most recent use timestamp
  /// underneath. For a specific window this shows the most recent use
  /// *if it happened inside that window*, with the window's name instead
  /// of the date.
  Widget _inventoryTotalUsedCell(
    BuildContext context,
    InventoryProvider provider,
    InventoryItemModel item,
  ) {
    final colors = AppColors.of(context);
    final overall = provider.periodFilter == StatsPeriod.overall;
    final inPeriod = provider.isInCurrentPeriod(item.lastUsedAt);

    if (overall) {
      if (item.totalUsed <= 0 && item.lastUsedAt == null) {
        return Text(
          '—',
          style: AppTextStyles.bodySecondary(context)
              .copyWith(color: colors.textMuted),
        );
      }
      return _addedUsedCellContent(
        context,
        icon: Icons.remove,
        color: AppColors.danger,
        amountLabel: '${_fmt(item.totalUsed)} ${item.unit}',
        footer:
            item.lastUsedAt != null ? _formatUpdatedAt(item.lastUsedAt!) : null,
        showStar: _mostRecentAction(item) == _RecentAction.used,
      );
    }

    if (!inPeriod) {
      return Text(
        '—',
        style: AppTextStyles.bodySecondary(context)
            .copyWith(color: colors.textMuted),
      );
    }
    return _addedUsedCellContent(
      context,
      icon: Icons.remove,
      color: AppColors.danger,
      amountLabel: '${_fmt(item.lastUsedQty ?? 0)} ${item.unit}',
      footer: provider.periodFilter.label,
    );
  }

  /// Shared layout for the ADDED / USED total cells: an icon + amount row,
  /// with an optional muted footer line underneath (either a formatted
  /// date/time or a period label like "Today"). [showStar] marks whichever
  /// of the two actions (add/use) happened most recently for this item.
  Widget _addedUsedCellContent(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String amountLabel,
    String? footer,
    bool showStar = false,
  }) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: context.h(13), color: color),
            SizedBox(width: context.w(2)),
            Flexible(
              child: Text(
                amountLabel,
                style: AppTextStyles.bodySecondary(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showStar) ...[
              SizedBox(width: context.w(2)),
              Icon(
                Icons.star_rounded,
                size: context.h(13),
                color: AppColors.warning,
              ),
            ],
          ],
        ),
        if (footer != null)
          Text(
            footer,
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

  // void _openLowStock(BuildContext context) {
  //   Navigator.of(context).push(
  //     MaterialPageRoute(builder: (_) => const LowStockScreen()),
  //   );
  // }

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
      await ref.read(inventoryProvider).deleteItem(item.id);
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
class _StockAdjustField extends ConsumerStatefulWidget {
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
  ConsumerState<_StockAdjustField> createState() => _StockAdjustFieldState();
}

class _StockAdjustFieldState extends ConsumerState<_StockAdjustField> {
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
      width: context.w(74),
      height: context.h(36),
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          _MaxThreeDigitsFormatter(),
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
            horizontal: context.w(6),
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

/// Blocks any input that would contain more than 3 digit characters
/// (e.g. "1000" or "99.99" → rejected; "999" / "99.9" → allowed).
class _MaxThreeDigitsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final digitCount = newValue.text.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (digitCount > 3) return oldValue;
    return newValue;
  }
}
