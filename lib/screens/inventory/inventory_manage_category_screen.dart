import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/inventory_category_model.dart';
import 'package:rdx_admin/models/unit_model.dart';
import 'package:rdx_admin/services/inventory_category_service.dart';
import 'package:rdx_admin/services/unit_service.dart';
import 'package:rdx_admin/widgets/dialogs/category_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/empty_state.dart';
import 'package:rdx_admin/widgets/reusable_widgets/loading_indicator.dart';
import 'package:rdx_admin/widgets/dialogs/rdx_delete_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_header.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_table.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_search_bar.dart';
import 'package:rdx_admin/widgets/buttons/rdx_header_action_button.dart';

enum _Section { category, unit }

class InventoryManageCategoryScreen extends StatefulWidget {
  const InventoryManageCategoryScreen({super.key});

  @override
  State<InventoryManageCategoryScreen> createState() =>
      _InventoryManageCategoryScreenState();
}

class _InventoryManageCategoryScreenState
    extends State<InventoryManageCategoryScreen> {
  final _categoryService = InventoryCategoryService();
  final _unitService = UnitService();

  final _itemSearchController = TextEditingController();

  _Section _section = _Section.category;
  bool _loading = true;
  String? _error;

  /// Filters the rows shown inside the active table (category or unit names).
  String _itemQuery = '';

  List<InventoryCategoryModel> _categories = [];
  List<UnitModel> _units = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _itemSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _categoryService.fetchCategories(),
        _unitService.fetchUnits(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = _sortedByName(
          results[0] as List<InventoryCategoryModel>,
          (c) => c.name,
        );
        _units = _sortedByName(results[1] as List<UnitModel>, (u) => u.name);
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('InventoryManageCategoryScreen._loadAll failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load. ${e.toString()}';
      });
    }
  }

  // ── Category actions ──────────────────────────────────────────────

  Future<void> _createCategory() async {
    final created = await CategoryEntryDialog.show<InventoryCategoryModel>(
      context,
      title: 'Create Category',
      editTitle: 'Edit Category',
      nameLabel: 'Category Name *',
      nameHint: 'e.g. Fresh Produce',
      onSave: (name, _) => _categoryService.createCategory(name: name),
    );
    if (created == null || !mounted) return;
    setState(
      () =>
          _categories = _sortedByName([..._categories, created], (c) => c.name),
    );
  }

  Future<void> _editCategory(InventoryCategoryModel category) async {
    final updated = await CategoryEntryDialog.show<InventoryCategoryModel>(
      context,
      title: 'Create Category',
      editTitle: 'Edit Category',
      nameLabel: 'Category Name *',
      nameHint: 'e.g. Fresh Produce',
      initialName: category.name,
      onSave: (name, _) async {
        final updated = InventoryCategoryModel(id: category.id, name: name);
        await _categoryService.updateCategory(updated);
        return updated;
      },
    );
    if (updated == null || !mounted) return;
    setState(() {
      _categories = _sortedByName(
        [
          for (final c in _categories)
            if (c.id == updated.id) updated else c,
        ],
        (c) => c.name,
      );
    });
  }

  Future<void> _deleteCategory(InventoryCategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Category',
        itemName: category.name,
        deleteButtonLabel: 'Delete Category',
        warningMessage:
            'Materials using this category will keep the old name until re-saved.',
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _categoryService.deleteCategory(category.id);
      if (!mounted) return;
      setState(() {
        _categories = _categories.where((c) => c.id != category.id).toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete category.')),
      );
    }
  }

  // ── Unit actions ──────────────────────────────────────────────────

  Future<void> _createUnit() async {
    final created = await CategoryEntryDialog.show<UnitModel>(
      context,
      title: 'Create Unit of Measurement',
      editTitle: 'Edit Unit',
      nameLabel: 'Unit Name *',
      nameHint: 'e.g. kg, L, box',
      onSave: (name, _) => _unitService.createUnit(name: name),
    );
    if (created == null || !mounted) return;
    setState(() => _units = _sortedByName([..._units, created], (u) => u.name));
  }

  Future<void> _editUnit(UnitModel unit) async {
    final updated = await CategoryEntryDialog.show<UnitModel>(
      context,
      title: 'Create Unit of Measurement',
      editTitle: 'Edit Unit',
      nameLabel: 'Unit Name *',
      nameHint: 'e.g. kg, L, box',
      initialName: unit.name,
      onSave: (name, _) async {
        final updated = UnitModel(id: unit.id, name: name);
        await _unitService.updateUnit(updated);
        return updated;
      },
    );
    if (updated == null || !mounted) return;
    setState(() {
      _units = _sortedByName(
        [
          for (final u in _units)
            if (u.id == updated.id) updated else u,
        ],
        (u) => u.name,
      );
    });
  }

  Future<void> _deleteUnit(UnitModel unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Unit',
        itemName: unit.name,
        deleteButtonLabel: 'Delete',
        warningMessage:
            'Materials using this unit will keep the old name until re-saved.',
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _unitService.deleteUnit(unit.id);
      if (!mounted) return;
      setState(() {
        _units = _units.where((u) => u.id != unit.id).toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete unit.')),
      );
    }
  }

  // ── Filtering helpers ───────────────────────────────────────────────

  /// Case-insensitive alphabetical sort for named entities.
  List<T> _sortedByName<T>(
    Iterable<T> items,
    String Function(T) nameOf,
  ) {
    final list = List<T>.from(items);
    list.sort(
      (a, b) => nameOf(a).toLowerCase().compareTo(nameOf(b).toLowerCase()),
    );
    return list;
  }

  List<InventoryCategoryModel> get _filteredCategories {
    final source = _itemQuery.trim().isEmpty
        ? _categories
        : _categories
            .where((c) =>
                c.name.toLowerCase().contains(_itemQuery.trim().toLowerCase()))
            .toList();
    return _sortedByName(source, (c) => c.name);
  }

  List<UnitModel> get _filteredUnits {
    final source = _itemQuery.trim().isEmpty
        ? _units
        : _units
            .where((u) =>
                u.name.toLowerCase().contains(_itemQuery.trim().toLowerCase()))
            .toList();
    return _sortedByName(source, (u) => u.name);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isNarrow = Responsive.isNarrow(context);
    final horizontal = Responsive.pageHorizontal(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const RdxHeader(
            title: 'Manage Inventory Category',
            showBackButton: true,
          ),
          SizedBox(height: context.h(isNarrow ? 10 : 14)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: Row(
              children: [
                Expanded(child: _itemSearchBar(context)),
                SizedBox(width: context.w(8)),
                _addButton(context),
              ],
            ),
          ),
          SizedBox(height: context.h(10)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _tabs(context, colors),
            ),
          ),
          SizedBox(height: context.h(isNarrow ? 10 : 14)),
          Expanded(
            child: _loading
                ? const LoadingIndicator()
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(context.w(24)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body(context),
                              ),
                              SizedBox(height: context.h(12)),
                              TextButton(
                                onPressed: _loadAll,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          0,
                          horizontal,
                          context.h(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _section == _Section.category
                                  ? _categoryContent(context)
                                  : _unitContent(context),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// Search bar that filters the rows inside the active table.
  Widget _itemSearchBar(BuildContext context) {
    return RdxSearchBar(
      controller: _itemSearchController,
      hintText:
          _section == _Section.category ? 'Search categories' : 'Search units',
      height: RdxSearchBar.standardHeight(context),
      onChanged: (value) => setState(() => _itemQuery = value),
    );
  }

  /// Scrollable row of sections.
  Widget _tabs(BuildContext context, AppColorScheme colors) {
    const tags = <(_Section, String)>[
      (_Section.category, 'Categories'),
      (_Section.unit, 'Units of Measurement'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < tags.length; i++) ...[
            _tab(context, colors, tags[i].$1, tags[i].$2),
            if (i != tags.length - 1) SizedBox(width: context.w(8)),
          ],
        ],
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    AppColorScheme colors,
    _Section section,
    String label,
  ) {
    final selected = _section == section;
    return InkWell(
      onTap: () => setState(() => _section = section),
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
    );
  }

  Widget _addButton(BuildContext context) {
    final (label, onTap) = switch (_section) {
      _Section.category => ('Add category', _createCategory),
      _Section.unit => ('Add unit', _createUnit),
    };

    return RdxHeaderActionButton(
      label: label,
      onPressed: onTap,
    );
  }

  Widget _categoryContent(BuildContext context) {
    final categories = _filteredCategories;
    if (categories.isEmpty) {
      return EmptyState(
        message: _categories.isEmpty
            ? 'No categories yet.'
            : 'No categories match your search.',
      );
    }
    return RdxTable(
      columns: [
        RdxTableColumn(title: 'Category', minWidth: 180, flex: 3),
        RdxTableColumn(
          title: 'Actions',
          minWidth: 90,
          alignment: Alignment.centerRight,
        ),
      ],
      rows: [
        for (final c in categories)
          [
            Text(c.name, style: AppTextStyles.body(context)),
            _actions(
              onEdit: () => _editCategory(c),
              onDelete: () => _deleteCategory(c),
            ),
          ],
      ],
    );
  }

  Widget _unitContent(BuildContext context) {
    final units = _filteredUnits;
    if (units.isEmpty) {
      return EmptyState(
        message:
            _units.isEmpty ? 'No units yet.' : 'No units match your search.',
      );
    }
    return RdxTable(
      columns: [
        RdxTableColumn(title: 'Unit of Measurement', minWidth: 180, flex: 3),
        RdxTableColumn(
          title: 'Actions',
          minWidth: 90,
          alignment: Alignment.centerRight,
        ),
      ],
      rows: [
        for (final u in units)
          [
            Text(u.name, style: AppTextStyles.body(context)),
            _actions(
              onEdit: () => _editUnit(u),
              onDelete: () => _deleteUnit(u),
            ),
          ],
      ],
    );
  }

  Widget _actions({
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RdxTableActionButton(
          icon: Icons.edit_outlined,
          tooltip: 'Edit',
          onPressed: onEdit,
        ),
        RdxTableActionButton(
          icon: Icons.delete_outline_rounded,
          tooltip: 'Delete',
          onPressed: onDelete,
        ),
      ],
    );
  }
}
