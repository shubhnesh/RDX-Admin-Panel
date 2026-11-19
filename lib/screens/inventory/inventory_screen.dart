import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/buttons/rdx_header_action_button.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_table.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/reusable_widgets/rdx_search_bar.dart';
import '../../widgets/reusable_widgets/rdx_category_tabs.dart';
import 'add_material_screen.dart';
import 'inventory_item_detail_screen.dart';
import 'inventory_manage_category_screen.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  final Map<String, TextEditingController> _stockControllers = {};
  final Map<String, TextEditingController> _portionControllers = {};
  final Map<String, TextEditingController> _purchaseCostControllers = {};
  InventoryStockMode _stockMode = InventoryStockMode.add;
  bool _savingStock = false;

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
    for (final controller in _stockControllers.values) {
      controller.dispose();
    }
    for (final controller in _portionControllers.values) {
      controller.dispose();
    }
    for (final controller in _purchaseCostControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(inventoryProvider);
    final canEditInventory =
        ref.watch(authProvider).permissions.canEditInventory;
    final colors = AppColors.of(context);
    final isNarrow = MediaQuery.sizeOf(context).width < 900;
    final isMobile = Responsive.isMobile(context);
    final showCategorySidebar = MediaQuery.sizeOf(context).width >= 1000;
    final pagePad = context.defaultScreenPadding();
    if (provider.isLoading && !provider.hasLoadedOnce) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const SafeArea(child: LoadingIndicator()),
      );
    }

    if (provider.errorMessage != null && provider.items.isEmpty) {
      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Center(
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
                  onPressed: () => provider.refresh(),
                  isPrimary: true,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                pagePad.left,
                pagePad.top,
                pagePad.right,
                context.h(0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inventory',
                              style: AppTextStyles.h2(context),
                            ),
                            SizedBox(height: context.h(isMobile ? 2 : 4)),
                            Text(
                              'Track raw materials, stock levels, and replenishment alerts',
                              style: AppTextStyles.body(context)
                                  .copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: context.w(isMobile ? 6 : 12)),
                      if (canEditInventory)
                        RdxHeaderActionButton(
                          label: 'Add Item',
                          onPressed: () => _openAddMaterial(context),
                        ),
                    ],
                  ),
                  SizedBox(height: context.h(isMobile ? 12 : 20)),
                ],
              ),
            ),
            if (provider.refreshError != null ||
                (provider.errorMessage != null && provider.items.isNotEmpty))
              Padding(
                padding: EdgeInsets.fromLTRB(
                  pagePad.left,
                  context.h(8),
                  pagePad.right,
                  context.h(0),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: context.h(18),
                    ),
                    SizedBox(width: context.w(8)),
                    Expanded(
                      child: Text(
                        provider.refreshError ?? provider.errorMessage!,
                        style: AppTextStyles.body(context)
                            .copyWith(color: colors.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: provider.refreshError != null
                          ? provider.retryAutoRefresh
                          : provider.refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: context.h(52),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: pagePad.left),
                child: _buildFiltersRow(context, provider, isNarrow),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  pagePad.left,
                  context.h(12),
                  pagePad.right,
                  pagePad.bottom,
                ),
                child: Column(
                  children: [
                    if (!showCategorySidebar) ...[
                      _buildCompactCategoryFilter(context, provider),
                      SizedBox(height: context.h(10)),
                    ],
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showCategorySidebar) ...[
                            SizedBox(
                              width: context.w(220),
                              child: _buildCategoryPanel(context, provider),
                            ),
                            SizedBox(width: context.w(10)),
                          ],
                          Expanded(
                            child: _buildInventoryTable(
                              context,
                              provider,
                              provider.filteredItems,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStockActions(
                      context,
                      provider,
                      showCategorySidebar: showCategorySidebar,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Stock tabs and search.
  Widget _buildFiltersRow(
    BuildContext context,
    InventoryProvider provider,
    bool isNarrow,
  ) {
    if (isNarrow) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: context.w(700).clamp(700.0, 900.0),
          child: _buildFiltersRow(context, provider, false),
        ),
      );
    }

    return Row(
      children: [
        RdxCategoryTabs(
          labels: const ['Low Stock', 'Critical'],
          selectedLabel: provider.stockLevelFilter,
          allLabel: 'All',
          onSelected: (label) => _onStockLevelSelected(provider, label),
          expand: false,
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: RdxSearchBar(
            controller: _searchController,
            hintText: 'Search materials or categories',
            onChanged: provider.setSearch,
            height: RdxSearchBar.standardHeight(context),
          ),
        ),
      ],
    );
  }

  /// Selecting a stock-level tag clears any activity-only stock filter.
  void _onStockLevelSelected(InventoryProvider provider, String label) {
    provider.setStockLevelFilter(label);
  }

  Widget _buildInventoryTable(
    BuildContext context,
    InventoryProvider provider,
    List<InventoryItemModel> items,
  ) {
    if (items.isEmpty && provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No materials match the current filters.',
          style: AppTextStyles.body(context),
        ),
      );
    }
    final canEdit = ref.watch(authProvider).permissions.canEditInventory;
    return RdxTable(
      showFooter: false,
      columns: [
        RdxTableColumn(title: 'RAW MATERIAL', minWidth: context.w(200), flex: 1.5),
        RdxTableColumn(title: 'CURRENT STOCK', minWidth: context.w(130), flex: 1),
        RdxTableColumn(
          title: 'ADD / USE STOCK',
          minWidth: context.w(250),
          flex: 1.5,
          header: canEdit
              ? Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: context.w(106),
                        child: _stockModeSelector(context),
                      ),
                      SizedBox(width: context.w(4)),
                      IconButton(
                        tooltip: 'Apply all stock changes',
                        visualDensity: VisualDensity.compact,
                        constraints: BoxConstraints(
                          minWidth: context.w(34),
                          minHeight: context.h(34),
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: _savingStock
                            ? null
                            : () => _saveStockChanges(provider),
                        icon: Icon(
                          Icons.check_circle_outline,
                          size: context.h(22),
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
        RdxTableColumn(title: 'PURCHASE COST (₹)', minWidth: context.w(160), flex: 1),
        RdxTableColumn(title: 'VARIANCE', minWidth: context.w(170), flex: 1),
      ],
      rows: items.map((item) {
        final controller = _stockControllers.putIfAbsent(
          item.id,
          TextEditingController.new,
        );
        final portionController = _portionControllers.putIfAbsent(
          item.id,
          TextEditingController.new,
        );
        final purchaseCostController = _purchaseCostControllers.putIfAbsent(
          item.id,
          TextEditingController.new,
        );
        return [
          Text(
            item.name,
            style: AppTextStyles.body(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _stockQuantityLabel(item, item.quantity),
            style: AppTextStyles.body(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          canEdit
              ? _newStockField(
                  context,
                  item,
                  controller,
                  portionController,
                  onProcess: () => _saveStockChanges(
                    provider,
                    onlyItemId: item.id,
                  ),
                )
              : Text('—', style: AppTextStyles.body(context)),
          canEdit && _stockMode == InventoryStockMode.add
              ? _purchaseCostField(
                  context,
                  purchaseCostController,
                  onSubmitted: (_) => _saveStockChanges(
                    provider,
                    onlyItemId: item.id,
                  ),
                )
              : Text('—', style: AppTextStyles.body(context)),
          _stockVariance(
            context,
            item,
            controller,
            portionController,
            _stockMode,
          ),
        ];
      }).toList(),
      onRowTap: (index) => _openItemDetails(context, items[index]),
    );
  }

  Widget _buildCategoryPanel(
    BuildContext context,
    InventoryProvider provider,
  ) {
    final colors = AppColors.of(context);
    final canEdit = ref.watch(authProvider).permissions.canEditInventory;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: context.h(48),
            padding: EdgeInsets.symmetric(horizontal: context.w(14)),
            color: colors.surfaceVariant.withValues(alpha: 0.35),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'CATEGORIES',
                    style: AppTextStyles.caption(context).copyWith(
                      color: colors.textMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (canEdit)
                  TextButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const InventoryManageCategoryScreen(),
                        ),
                      );
                      if (context.mounted) await provider.refresh();
                    },
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(4),
                        vertical: context.h(4),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Edit',
                      style: AppTextStyles.bodySemi(context).copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: context.h(1), color: colors.divider),
          Expanded(
            child: Scrollbar(
              child: ListView(
                primary: false,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: EdgeInsets.zero,
                children: [
                  for (final category in _categoryNames(provider))
                    _categoryTile(context, provider, category),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCategoryFilter(
    BuildContext context,
    InventoryProvider provider,
  ) {
    return SizedBox(
      width: double.infinity,
      height: context.h(42),
      child: Align(
        alignment: Alignment.centerLeft,
        child: RdxCategoryTabs(
          labels: provider.categories
              .where((category) => category != 'All')
              .toList(),
          selectedLabel: provider.selectedCategory,
          allLabel: 'All',
          onSelected: provider.setCategory,
          expand: false,
        ),
      ),
    );
  }

  List<String> _categoryNames(InventoryProvider provider) => [
        'All',
        ...provider.categories.where((category) => category != 'All'),
      ];

  Widget _categoryTile(
    BuildContext context,
    InventoryProvider provider,
    String category,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: provider.selectedCategory == category
              ? null
              : () => provider.setCategory(category),
          child: Container(
            constraints: BoxConstraints(
              minHeight: context.h(46),
            ),
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: context.w(12),
              vertical: context.h(10),
            ),
            decoration: BoxDecoration(
              color: provider.selectedCategory == category
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: provider.selectedCategory == category
                      ? AppColors.primary
                      : Colors.transparent,
                  width: 3,
                ),
                bottom: BorderSide(color: AppColors.of(context).divider),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    category == 'All' ? 'All categories' : category,
                    style: provider.selectedCategory == category
                        ? AppTextStyles.bodySemi(context).copyWith(
                            color: AppColors.primary,
                          )
                        : AppTextStyles.body(context).copyWith(
                            color: AppColors.of(context).textPrimary,
                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (provider.selectedCategory == category) ...[
                  SizedBox(width: context.w(6)),
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.primary,
                    size: context.h(17),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _newStockField(BuildContext context, InventoryItemModel item,
      TextEditingController controller, TextEditingController portionController,
      {required VoidCallback onProcess}) {
    final hasPortions =
        item.portionSize > 0 && item.portionUnit?.isNotEmpty == true;
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: context.w(204),
        child: Row(
          children: [
            Expanded(
              child: _stockQuantityField(
                context,
                controller,
                suffix: item.unit,
                onSubmitted: (_) => onProcess(),
              ),
            ),
            if (hasPortions) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.w(4)),
                child: Text(
                  '+',
                  style: AppTextStyles.body(context),
                ),
              ),
              Expanded(
                child: _stockQuantityField(
                  context,
                  portionController,
                  suffix: item.portionUnit!,
                  onSubmitted: (_) => onProcess(),
                ),
              ),
            ],
            IconButton(
              tooltip: 'Apply stock change',
              visualDensity: VisualDensity.compact,
              constraints: BoxConstraints(
                minWidth: context.w(34),
                minHeight: context.h(34),
              ),
              padding: EdgeInsets.zero,
              onPressed: _savingStock ? null : onProcess,
              icon: Icon(
                Icons.check_circle_outline,
                size: context.h(22),
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stockModeSelector(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      height: context.h(30),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(context.h(7)),
      ),
      child: Row(
        children: [
          for (final option in InventoryStockMode.values) ...[
            if (option == InventoryStockMode.use) SizedBox(width: context.w(4)),
            Expanded(
              child: InkWell(
                onTap: _savingStock
                    ? null
                    : () => setState(() => _stockMode = option),
                borderRadius: BorderRadius.circular(context.h(6)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _stockMode == option
                        ? (option == InventoryStockMode.add
                            ? AppColors.success
                            : AppColors.danger)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(context.h(6)),
                  ),
                  child: Text(
                    option == InventoryStockMode.add ? 'Add' : 'Use',
                    style: AppTextStyles.bodySemi(context).copyWith(
                      color: _stockMode == option
                          ? AppColors.white
                          : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stockQuantityField(
    BuildContext context,
    TextEditingController controller, {
    required String suffix,
    ValueChanged<String>? onSubmitted,
  }) {
    final colors = AppColors.of(context);
    return TextField(
      controller: controller,
      enabled: !_savingStock,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      style: AppTextStyles.body(context),
      decoration: InputDecoration(
        suffixText: suffix,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.w(6),
          vertical: context.h(10),
        ),
        suffixStyle: AppTextStyles.bodySemi(context),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.h(8)),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.h(8)),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.h(8)),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _purchaseCostField(
      BuildContext context, TextEditingController controller,
      {ValueChanged<String>? onSubmitted}) {
    final colors = AppColors.of(context);
    return TextField(
      controller: controller,
      enabled: !_savingStock,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      style: AppTextStyles.body(context),
      decoration: InputDecoration(
        prefixText: '₹ ',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.w(10),
          vertical: context.h(10),
        ),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.h(8)),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.h(8)),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.h(8)),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _stockVariance(
    BuildContext context,
    InventoryItemModel item,
    TextEditingController controller,
    TextEditingController portionController,
    InventoryStockMode mode,
  ) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, portionController]),
      builder: (context, _) {
        if (controller.text.trim().isEmpty &&
            portionController.text.trim().isEmpty) {
          return Text('—', style: AppTextStyles.body(context));
        }
        final amount = _enteredStockAmount(item, controller, portionController);
        final color = mode == InventoryStockMode.add
            ? AppColors.success
            : AppColors.danger;
        return Text(
          '${mode == InventoryStockMode.add ? '+' : '−'}'
          '${_stockQuantityLabel(item, amount)}',
          style: AppTextStyles.body(context).copyWith(color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  (double, double) _stockParts(InventoryItemModel item, double quantity) {
    if (item.portionSize <= 0 || item.portionUnit == null) {
      return (quantity, 0);
    }
    var whole = quantity.floorToDouble();
    var portions = ((quantity - whole) * item.portionSize);
    final roundedPortions = double.parse(portions.toStringAsFixed(4));
    if (roundedPortions >= item.portionSize) {
      whole += 1;
      portions = 0;
    } else {
      portions = roundedPortions;
    }
    return (whole, portions);
  }

  String _stockQuantityLabel(InventoryItemModel item, double quantity) {
    if (item.portionSize <= 0 ||
        item.portionUnit == null ||
        item.portionUnit!.isEmpty) {
      return '${_fmt(quantity)} ${item.unit}';
    }
    final (whole, portions) = _stockParts(item, quantity);
    return '${_fmt(whole)} ${item.unit} + '
        '${_fmt(portions)} ${item.portionUnit}';
  }

  double _enteredStockAmount(
    InventoryItemModel item,
    TextEditingController stockController,
    TextEditingController portionController,
  ) {
    final whole = double.tryParse(stockController.text.trim()) ?? 0;
    final portions = item.portionSize > 0
        ? double.tryParse(portionController.text.trim()) ?? 0
        : 0;
    return whole + (item.portionSize > 0 ? portions / item.portionSize : 0);
  }

  Widget _buildStockActions(BuildContext context, InventoryProvider provider,
      {required bool showCategorySidebar}) {
    final canEdit = ref.watch(authProvider).permissions.canEditInventory;
    return Padding(
      padding: EdgeInsets.only(top: context.h(10)),
      child: Row(
        children: [
          if (showCategorySidebar) SizedBox(width: context.w(220) + context.w(10)),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'Showing ${provider.items.length} of '
                    '${provider.totalMatching} '
                    '${provider.totalMatching == 1 ? 'item' : 'items'}'
                    '${provider.isOffline ? ' • offline' : ''}',
                    style: AppTextStyles.body(context).copyWith(
                      color: AppColors.of(context).textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (provider.hasMore) ...[
                  SizedBox(width: context.w(8)),
                  provider.isLoadingMore
                      ? SizedBox(
                          width: context.h(18),
                          height: context.h(18),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : TextButton(
                          onPressed: provider.loadMore,
                          child: const Text('Load more'),
                        ),
                ],
              ],
            ),
          ),
          if (canEdit)
            SizedBox(
              width: context.w(150),
              child: RdxActionButton(
                label: _savingStock ? 'Saving...' : 'Save',
                isPrimary: true,
                isLoading: _savingStock,
                onPressed:
                    _savingStock ? null : () => _saveStockChanges(provider),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _saveStockChanges(
    InventoryProvider provider, {
    String? onlyItemId,
  }) async {
    final itemsById = {for (final item in provider.items) item.id: item};
    final changes = <String, InventoryStockChange>{};
    for (final item in provider.items) {
      if (onlyItemId != null && item.id != onlyItemId) continue;
      final stockController = _stockControllers[item.id];
      final portionController = _portionControllers[item.id];
      final stockText = stockController?.text.trim() ?? '';
      final portionText = portionController?.text.trim() ?? '';
      if (stockText.isEmpty && portionText.isEmpty) continue;

      final whole = stockText.isEmpty ? 0.0 : double.tryParse(stockText);
      final portions = item.portionSize <= 0
          ? 0.0
          : portionText.isEmpty
              ? 0.0
              : double.tryParse(portionText);
      if (whole == null ||
          portions == null ||
          whole < 0 ||
          portions < 0 ||
          (item.portionSize > 0 &&
              (item.portionUnit == null || item.portionUnit!.isEmpty))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              item.portionSize > 0 &&
                      (item.portionUnit == null || item.portionUnit!.isEmpty)
                  ? 'Set the portion unit for ${item.name} before editing stock.'
                  : 'Enter a valid stock quantity for ${item.name}.',
            ),
          ),
        );
        return;
      }
      final quantity =
          item.portionSize > 0 ? whole + portions / item.portionSize : whole;
      if (quantity <= 0) continue;

      final mode = _stockMode;
      double? purchaseCost;
      if (mode == InventoryStockMode.add) {
        final costText = _purchaseCostControllers[item.id]?.text.trim() ?? '';
        purchaseCost = double.tryParse(costText);
        if (costText.isEmpty || purchaseCost == null || purchaseCost < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Enter a valid purchase cost for ${item.name}.',
              ),
            ),
          );
          return;
        }
      }
      changes[item.id] = InventoryStockChange(
        mode: mode,
        quantity: quantity,
        purchaseCost: purchaseCost,
      );
    }

    if (changes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter stock to add or use before saving.')),
      );
      return;
    }

    setState(() => _savingStock = true);
    try {
      final failures = await provider.applyStockChanges(changes);
      if (!mounted) return;
      for (final id in changes.keys) {
        if (!failures.containsKey(id)) {
          _stockControllers[id]?.clear();
          _portionControllers[id]?.clear();
          _purchaseCostControllers[id]?.clear();
        }
      }
      if (failures.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock updated successfully.')),
        );
      } else {
        final details = failures.entries.map((entry) {
          final itemName = itemsById[entry.key]?.name ?? entry.key;
          return '$itemName: ${entry.value}';
        }).join('\n');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Some stock changes failed:\n$details')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingStock = false);
    }
  }

  String _fmt(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  void _openAddMaterial(BuildContext context, {InventoryItemModel? item}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddMaterialScreen(existing: item),
      ),
    );
  }

  void _openItemDetails(
    BuildContext context,
    InventoryItemModel item,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InventoryItemDetailScreen(item: item),
      ),
    );
  }

  // void _openLowStock(BuildContext context) {
  //   Navigator.of(context).push(
  //     MaterialPageRoute(builder: (_) => const LowStockScreen()),
  //   );
  // }
}
