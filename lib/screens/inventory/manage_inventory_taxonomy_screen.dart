import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/inventory_category_model.dart';
import 'package:rdx_admin/models/unit_model.dart';
import 'package:rdx_admin/services/inventory_category_service.dart';
import 'package:rdx_admin/services/unit_service.dart';
import 'package:rdx_admin/widgets/dialogs/taxonomy_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/empty_state.dart';
import 'package:rdx_admin/widgets/reusable_widgets/loading_indicator.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_delete_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_header.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_table.dart';

enum _Section { category, unit }

class ManageInventoryTaxonomyScreen extends StatefulWidget {
  const ManageInventoryTaxonomyScreen({super.key});

  @override
  State<ManageInventoryTaxonomyScreen> createState() =>
      _ManageInventoryTaxonomyScreenState();
}

class _ManageInventoryTaxonomyScreenState
    extends State<ManageInventoryTaxonomyScreen> {
  final _categoryService = InventoryCategoryService();
  final _unitService = UnitService();

  _Section _section = _Section.category;
  bool _loading = true;
  String? _error;

  List<InventoryCategoryModel> _categories = [];
  List<UnitModel> _units = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
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
        _categories = results[0] as List<InventoryCategoryModel>;
        _units = results[1] as List<UnitModel>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load. Try again.';
      });
    }
  }

  // ── Category actions ──────────────────────────────────────────────

  Future<void> _createCategory() async {
    final created = await TaxonomyEntryDialog.show<InventoryCategoryModel>(
      context,
      title: 'Create Category',
      editTitle: 'Edit Category',
      nameLabel: 'Category Name *',
      nameHint: 'e.g. Fresh Produce',
      onSave: (name, _) => _categoryService.createCategory(name: name),
    );
    if (created == null || !mounted) return;
    setState(() => _categories = [..._categories, created]);
  }

  Future<void> _editCategory(InventoryCategoryModel category) async {
    final updated = await TaxonomyEntryDialog.show<InventoryCategoryModel>(
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
      _categories = [
        for (final c in _categories)
          if (c.id == updated.id) updated else c,
      ];
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
    final created = await TaxonomyEntryDialog.show<UnitModel>(
      context,
      title: 'Create Unit of Measurement',
      editTitle: 'Edit Unit',
      nameLabel: 'Unit Name *',
      nameHint: 'e.g. kg, L, box',
      onSave: (name, _) => _unitService.createUnit(name: name),
    );
    if (created == null || !mounted) return;
    setState(() => _units = [..._units, created]);
  }

  Future<void> _editUnit(UnitModel unit) async {
    final updated = await TaxonomyEntryDialog.show<UnitModel>(
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
      _units = [
        for (final u in _units)
          if (u.id == updated.id) updated else u,
      ];
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
            title: 'Manage Inventory Taxonomy',
            showBackButton: true,
          ),
          SizedBox(height: context.h(isNarrow ? 10 : 14)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: Row(
              children: [
                Expanded(child: _tabs(context, colors)),
                SizedBox(width: context.w(8)),
                _addButton(context),
              ],
            ),
          ),
          SizedBox(height: context.h(isNarrow ? 10 : 14)),
          Expanded(
            child: _loading
                ? const LoadingIndicator()
                : _error != null
                    ? EmptyState(message: _error!)
                    : Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          0,
                          horizontal,
                          context.h(20),
                        ),
                        child: _section == _Section.category
                            ? _categoryContent(context, colors, isNarrow)
                            : _unitContent(context, colors, isNarrow),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _tabs(BuildContext context, AppColorScheme colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tab(context, colors, _Section.category, 'Categories'),
          SizedBox(width: context.w(8)),
          _tab(context, colors, _Section.unit, 'Units of Measurement'),
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

    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(Icons.add_rounded, size: context.h(18), color: AppColors.primary),
      label: Text(
        label,
        style: AppTextStyles.label(context).copyWith(color: AppColors.primary),
      ),
    );
  }

  Widget _categoryContent(
    BuildContext context,
    AppColorScheme colors,
    bool isNarrow,
  ) {
    if (_categories.isEmpty) {
      return const EmptyState(message: 'No categories yet.');
    }
    return isNarrow
        ? _simpleCards(
            context,
            colors,
            items: _categories.map((c) => (c.name, c as Object)).toList(),
            onEdit: (c) => _editCategory(c as InventoryCategoryModel),
            onDelete: (c) => _deleteCategory(c as InventoryCategoryModel),
          )
        : RdxTable(
            columns: [
              RdxTableColumn(title: 'Category', minWidth: context.w(180), flex: 3),
              RdxTableColumn(
                title: 'Actions',
                minWidth: context.w(90),
                alignment: Alignment.centerRight,
              ),
            ],
            rows: [
              for (final c in _categories)
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

  Widget _unitContent(
    BuildContext context,
    AppColorScheme colors,
    bool isNarrow,
  ) {
    if (_units.isEmpty) {
      return const EmptyState(message: 'No units yet.');
    }
    return isNarrow
        ? _simpleCards(
            context,
            colors,
            items: _units.map((u) => (u.name, u as Object)).toList(),
            onEdit: (u) => _editUnit(u as UnitModel),
            onDelete: (u) => _deleteUnit(u as UnitModel),
          )
        : RdxTable(
            columns: [
              RdxTableColumn(
                  title: 'Unit of Measurement', minWidth: context.w(180), flex: 3),
              RdxTableColumn(
                title: 'Actions',
                minWidth: context.w(90),
                alignment: Alignment.centerRight,
              ),
            ],
            rows: [
              for (final u in _units)
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

  Widget _simpleCards(
    BuildContext context,
    AppColorScheme colors, {
    required List<(String, Object)> items,
    required void Function(Object) onEdit,
    required void Function(Object) onDelete,
  }) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: context.h(10)),
      itemBuilder: (context, index) {
        final (title, item) = items[index];
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: context.w(14),
            vertical: context.h(12),
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(context.h(12)),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _actions(
                onEdit: () => onEdit(item),
                onDelete: () => onDelete(item),
              ),
            ],
          ),
        );
      },
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
