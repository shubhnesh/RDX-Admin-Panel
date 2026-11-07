import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/widgets/dialogs/category_dialog.dart';
import 'package:rdx_admin/widgets/dialogs/rdx_notice_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_header.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../models/inventory_category_model.dart';
import '../../models/inventory_item_model.dart';
import '../../models/unit_model.dart';
import '../../providers/inventory_provider.dart';
import '../../services/inventory_category_service.dart';
import '../../services/unit_service.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/rdx_text_field.dart';
import '../../widgets/reusable_widgets/rdx_dropdown.dart';
import 'inventory_manage_category_screen.dart';

/// Sentinel value placed as the first entry in the category dropdown.
/// Selecting it opens [CreateInventoryCategoryDialog] instead of setting a category.
const String _kCreateCategoryValue = '__create_category__';

/// Sentinel value placed as the first entry in the unit dropdown.
/// Selecting it opens [CreateUnitDialog].
const String _kCreateUnitValue = '__create_unit__';

class AddMaterialScreen extends ConsumerStatefulWidget {
  final InventoryItemModel? existing;

  const AddMaterialScreen({super.key, this.existing});

  @override
  ConsumerState<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends ConsumerState<AddMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _portionSizeCtrl;
  late final TextEditingController _costCtrl;

  /// Category and unit store **ids** (Firestore document ids).
  String? _category;
  String? _unit;
  String? _portionUnit;
  bool _saving = false;

  final _categoryService = InventoryCategoryService();
  final _unitService = UnitService();

  List<InventoryCategoryModel> _categories = [];
  List<UnitModel> _units = [];
  bool _categoriesLoading = true;
  bool _unitsLoading = true;

  bool get isEdit => widget.existing != null && widget.existing!.id.isNotEmpty;

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

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _qtyCtrl =
        TextEditingController(text: e != null ? e.quantity.toString() : '');
    _minCtrl =
        TextEditingController(text: e != null ? e.minRequired.toString() : '');
    _portionSizeCtrl =
        TextEditingController(text: e?.portionSize.toString() ?? '');
    _portionSizeCtrl.addListener(_onPortionSizeChanged);
    _costCtrl = TextEditingController(text: e?.unitCost.toString() ?? '');

    // existing.category / existing.unit may be stored as display names.
    // After lists load we map name → id if needed.
    if (e != null) {
      _category = e.category;
      _unit = e.unit;
      _portionUnit = e.portionUnit;
    }

    _loadCategories();
    _loadUnits();
  }

  Future<void> _loadCategories() async {
    setState(() => _categoriesLoading = true);
    try {
      final list = await _categoryService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = _sortedByName(list, (c) => c.name);
        _categoriesLoading = false;
        // If existing value is a name (not an id), resolve to id.
        if (_category != null && !_categories.any((c) => c.id == _category)) {
          final byName = _categories.where(
            (c) => c.name.toLowerCase() == _category!.toLowerCase(),
          );
          if (byName.isNotEmpty) {
            _category = byName.first.id;
          }
        }
        if (_portionUnit != null &&
            !_units.any((unit) => unit.id == _portionUnit)) {
          final byName = _units.where(
            (unit) => unit.name.toLowerCase() == _portionUnit!.toLowerCase(),
          );
          if (byName.isNotEmpty) {
            _portionUnit = byName.first.id;
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _categoriesLoading = false);
    }
  }

  Future<void> _loadUnits() async {
    setState(() => _unitsLoading = true);
    try {
      final list = await _unitService.fetchUnits();
      if (!mounted) return;
      setState(() {
        _units = _sortedByName(list, (u) => u.name);
        _unitsLoading = false;
        if (_unit != null && !_units.any((u) => u.id == _unit)) {
          final byName = _units.where(
            (u) => u.name.toLowerCase() == _unit!.toLowerCase(),
          );
          if (byName.isNotEmpty) {
            _unit = byName.first.id;
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _unitsLoading = false);
    }
  }

  Future<void> _openCreateCategoryDialog() async {
    final created = await CategoryEntryDialog.show<InventoryCategoryModel>(
      context,
      title: 'Create Category',
      editTitle: 'Edit Category',
      nameLabel: 'Category Name *',
      nameHint: 'e.g. Fresh Produce',
      onSave: (name, _) => _categoryService.createCategory(name: name),
    );
    if (created == null || !mounted) return;
    setState(() {
      _categories = _sortedByName([..._categories, created], (c) => c.name);
      _category = created.id;
    });
  }

  Future<void> _openCreateUnitDialog({bool forPortion = false}) async {
    final created = await CategoryEntryDialog.show<UnitModel>(
      context,
      title: 'Create Unit of Measurement',
      editTitle: 'Edit Unit',
      nameLabel: 'Unit Name *',
      nameHint: 'e.g. kg, L, box',
      onSave: (name, _) => _unitService.createUnit(name: name),
    );
    if (created == null || !mounted) return;
    setState(() {
      _units = _sortedByName([..._units, created], (u) => u.name);
      if (forPortion) {
        _portionUnit = created.id;
      } else {
        _unit = created.id;
      }
    });
  }

  Future<void> _openManageCategory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const InventoryManageCategoryScreen(),
      ),
    );
    if (!mounted) return;
    // Refresh lists in case user created/edited/deleted entries.
    await Future.wait([_loadCategories(), _loadUnits()]);
  }

  String _categoryLabel(String id) {
    if (id == _kCreateCategoryValue) return '+ Create category';
    final match = _categories.where((c) => c.id == id);
    return match.isEmpty ? id : match.first.name;
  }

  String _unitLabel(String id) {
    if (id == _kCreateUnitValue) return '+ Create unit';
    final match = _units.where((u) => u.id == id);
    return match.isEmpty ? id : match.first.name;
  }

  String get _categoryDisplayName {
    if (_category == null) return '';
    final match = _categories.where((c) => c.id == _category);
    return match.isEmpty ? _category! : match.first.name;
  }

  String get _unitDisplayName {
    if (_unit == null) return '';
    final match = _units.where((u) => u.id == _unit);
    return match.isEmpty ? _unit! : match.first.name;
  }

  String get _portionUnitDisplayName {
    if (_portionUnit == null) return '';
    final match = _units.where((u) => u.id == _portionUnit);
    return match.isEmpty ? _portionUnit! : match.first.name;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _minCtrl.dispose();
    _portionSizeCtrl.removeListener(_onPortionSizeChanged);
    _portionSizeCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  void _onPortionSizeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _showNotice(String message) async {
    if (!mounted) return;
    await RdxNoticeDialog.show(context, message: message);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final qtyText = _qtyCtrl.text.trim();
    final minText = _minCtrl.text.trim();
    final costText = _costCtrl.text.trim();

    if (!isEdit && name.isEmpty) {
      await _showNotice('Please enter a material name.');
      return;
    }
    if (!isEdit && _category == null) {
      await _showNotice('Please select a category.');
      return;
    }
    if (_unit == null) {
      await _showNotice('Please select a unit of measurement.');
      return;
    }
    final portionSizeText = _portionSizeCtrl.text.trim();
    final portionSize =
        portionSizeText.isEmpty ? 0.0 : double.tryParse(portionSizeText);
    if (portionSize == null || portionSize < 0) {
      await _showNotice('Please enter a valid portion size.');
      return;
    }
    if (portionSize > 0 && _portionUnit == null) {
      await _showNotice('Please select the portion unit of measurement.');
      return;
    }
    // Initial stock is required when creating; on edit quantity is locked.
    double quantity = widget.existing?.quantity ?? 0;
    if (!isEdit) {
      final initialQuantity = double.tryParse(qtyText);
      if (qtyText.isEmpty || initialQuantity == null) {
        await _showNotice('Please enter initial stock quantity.');
        return;
      }
      quantity = initialQuantity;
    }

    final enteredCost = double.tryParse(costText);
    if (costText.isEmpty || enteredCost == null || enteredCost < 0) {
      await _showNotice(
        isEdit
            ? 'Please enter a valid unit cost for future restocks.'
            : 'Please enter a valid total cost for the initial stock.',
      );
      return;
    }
    if (!isEdit && quantity == 0 && enteredCost > 0) {
      await _showNotice(
        'Initial stock cost must be zero when the initial quantity is zero.',
      );
      return;
    }
    final initialTotalCost = isEdit ? widget.existing!.totalCost : enteredCost;
    final unitCost = isEdit
        ? enteredCost
        : quantity > 0
            ? initialTotalCost / quantity
            : 0.0;

    final minimum = double.tryParse(minText);
    if (minText.isEmpty || minimum == null) {
      await _showNotice('Please enter minimum stock alert value.');
      return;
    }

    setState(() => _saving = true);
    final item = InventoryItemModel(
      id: widget.existing?.id ?? '',
      name: isEdit ? widget.existing!.name : _nameCtrl.text.trim(),
      category: isEdit ? widget.existing!.category : _categoryDisplayName,
      quantity: quantity,
      minRequired: minimum,
      maxCapacity: widget.existing?.maxCapacity ?? 0,
      unit: _unitDisplayName,
      portionSize: portionSize,
      portionUnit: portionSize > 0 ? _portionUnitDisplayName : null,
      unitCost: unitCost,
      totalCost: initialTotalCost,
    );

    try {
      await ref.read(inventoryProvider).saveItem(item);
      if (mounted) {
        Navigator.of(context).pop();
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text(isEdit ? 'Material updated' : 'Material added'),
        //   ),
        // );
      }
    } catch (error) {
      if (mounted) {
        await _showNotice('Failed to save material: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isNarrow = MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RdxHeader(
            title: isEdit ? 'Edit Material' : 'Add New Material',
            subtitle:
                'Create a new raw ingredient or packaging item in your inventory catalog.',
            showBackButton: true,
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: isNarrow
                  ? SingleChildScrollView(
                      padding: Responsive.pagePadding(
                        context,
                        top: context.h(16),
                        bottom: context.h(32),
                      ),
                      child: Column(
                        children: [
                          _basicInfoSection(context, colors),
                          SizedBox(height: context.h(16)),
                          _stockTrackingSection(context, colors),
                          SizedBox(height: context.h(16)),
                          _actionButtons(context),
                        ],
                      ),
                    )
                  : Padding(
                      padding: Responsive.pagePadding(
                        context,
                        top: context.h(16),
                        bottom: context.h(24),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.only(right: context.w(20)),
                              child: _basicInfoSection(context, colors),
                            ),
                          ),
                          VerticalDivider(
                            width: context.w(1),
                            thickness: context.h(1),
                            color: colors.border,
                          ),
                          SizedBox(width: context.w(20)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    child:
                                        _stockTrackingSection(context, colors),
                                  ),
                                ),
                                SizedBox(height: context.h(16)),
                                _actionButtons(context),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RdxActionButton.discard(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
          ),
        ),
        SizedBox(width: context.w(10)),
        Expanded(
          child: RdxActionButton.save(
            label: 'Done',
            onPressed: _save,
            isLoading: _saving,
          ),
        ),
      ],
    );
  }

  Widget _basicInfoSection(BuildContext context, AppColorScheme colors) {
    return _SectionCard(
      title: 'Basic Information & Category',
      icon: Icons.badge_outlined,
      headerTrailing: isEdit
          ? null
          : TextButton.icon(
              onPressed: _openManageCategory,
              icon: Icon(
                Icons.add_rounded,
                size: context.h(18),
                color: AppColors.primary,
              ),
              label: Text(
                'Create & Manage Category',
                style: AppTextStyles.label(context)
                    .copyWith(color: AppColors.primary),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RdxTextField(
            controller: _nameCtrl,
            maxLength: 10,
            label: 'Material Name *',
            hint: 'Enter material name',
            enabled: !isEdit,
          ),
          if (isEdit) ...[
            SizedBox(height: context.h(6)),
            Text(
              'Material name cannot be changed after creation.',
              style: AppTextStyles.bodyTertiary(context)
                  .copyWith(color: colors.textMuted),
            ),
          ],
          SizedBox(height: context.h(16)),
          RdxDropdown<String>(
            label: 'Category *',
            value: _category != null &&
                    (_categories.any((x) => x.id == _category) ||
                        _category == _kCreateCategoryValue)
                ? _category
                : null,
            items: [
              _kCreateCategoryValue,
              ..._categories.map((c) => c.id),
            ],
            labelBuilder: _categoryLabel,
            searchable: true,
            enabled: !isEdit,
            hint: _categoriesLoading
                ? 'Loading categories...'
                : 'Select category',
            onChanged: isEdit
                ? null
                : (v) {
                    if (v == _kCreateCategoryValue) {
                      _openCreateCategoryDialog();
                      return;
                    }
                    if (v != null) setState(() => _category = v);
                  },
          ),
          if (isEdit) ...[
            SizedBox(height: context.h(6)),
            Text(
              'Category cannot be changed after creation.',
              style: AppTextStyles.bodyTertiary(context)
                  .copyWith(color: colors.textMuted),
            ),
          ],
          SizedBox(height: context.h(16)),
          RdxTextField(
            controller: _costCtrl,
            maxLength: 10,
            label: isEdit
                ? 'Unit Cost for Future Restocks (₹) *'
                : 'Total Cost (₹) *',
            hint: isEdit
                ? 'Enter cost per unit'
                : 'Enter total amount paid for initial stock',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
          ),
          if (isEdit) ...[
            SizedBox(height: context.h(6)),
            Text(
              'This sets the per-unit cost for future restocks and does not '
              'change the cost already recorded for stock on hand.',
              style: AppTextStyles.bodyTertiary(context)
                  .copyWith(color: colors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stockTrackingSection(BuildContext context, AppColorScheme colors) {
    return _SectionCard(
      title: 'Stock Tracking & Thresholds',
      icon: Icons.bar_chart_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final quantity = RdxTextField(
                controller: _qtyCtrl,
                maxLength: 5,
                label: isEdit ? 'Current Stock Quantity' : 'Initial Stock *',
                hint: 'Enter quantity',
                enabled: !isEdit,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
              );
              final portionSize = RdxTextField(
                controller: _portionSizeCtrl,
                maxLength: 6,
                label:
                    'Portions per ${_unitDisplayName.isEmpty ? 'unit' : _unitDisplayName}',
                hint: 'Optional',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
              );
              final portionUnit = _portionUnitDropdown();

              if (constraints.maxWidth < 620) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: quantity),
                        SizedBox(width: context.w(12)),
                        Expanded(child: _unitDropdown()),
                      ],
                    ),
                    SizedBox(height: context.h(12)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: portionSize),
                        SizedBox(width: context.w(12)),
                        Expanded(child: portionUnit),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: quantity),
                  SizedBox(width: context.w(10)),
                  Expanded(child: _unitDropdown()),
                  SizedBox(width: context.w(10)),
                  Expanded(child: portionSize),
                  SizedBox(width: context.w(10)),
                  Expanded(child: portionUnit),
                ],
              );
            },
          ),
          if (isEdit) ...[
            SizedBox(height: context.h(6)),
            Text(
              'Stock quantity is locked here. Update stock from the inventory '
              'table to keep stock records accurate.',
              style: AppTextStyles.bodyTertiary(context)
                  .copyWith(color: colors.textMuted),
            ),
          ],
          SizedBox(height: context.h(16)),

          // Minimum Required
          RdxTextField(
            controller: _minCtrl,
            maxLength: 3,
            label: 'Minimum Stock Alert Value *',
            hint: 'Enter minimum stock value',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
          ),
          SizedBox(height: context.h(6)),
          Text(
            'Restock alert triggers when stock falls below this amount — no confusing PAR terminology',
            style: AppTextStyles.bodyTertiary(context)
                .copyWith(color: colors.textMuted),
          ),
          SizedBox(height: context.h(20)),

          Container(
            padding: EdgeInsets.all(context.h(14)),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(context.h(10)),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Stock status preview',
                        style: AppTextStyles.bodySecondary(context).copyWith(
                          color: colors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(8)),
                Text(
                  'Stock percentage and status update after saving.',
                  style: AppTextStyles.bodyTertiary(context)
                      .copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(12)),

          // Tip
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: context.w(14),
              vertical: context.h(11),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1EA),
              borderRadius: BorderRadius.circular(context.h(7)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: context.h(20), color: colors.primary),
                SizedBox(width: context.w(8)),
                Expanded(
                  child: Text(
                    'Stock status is based on the current quantity and minimum stock level.',
                    style: AppTextStyles.bodyTertiary(context)
                        .copyWith(color: colors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitDropdown() {
    return RdxDropdown<String>(
      label: 'Unit of Measurement *',
      value: _unit != null &&
              (_units.any((x) => x.id == _unit) || _unit == _kCreateUnitValue)
          ? _unit
          : null,
      items: [
        _kCreateUnitValue,
        ..._units.map((unit) => unit.id),
      ],
      labelBuilder: _unitLabel,
      searchable: true,
      hint: _unitsLoading ? 'Loading units...' : 'Select unit',
      onChanged: (value) {
        if (value == _kCreateUnitValue) {
          _openCreateUnitDialog();
          return;
        }
        if (value != null) setState(() => _unit = value);
      },
    );
  }

  Widget _portionUnitDropdown() {
    final enabled = (double.tryParse(_portionSizeCtrl.text.trim()) ?? 0) > 0;
    return RdxDropdown<String>(
      label: 'Portion Unit${enabled ? ' *' : ''}',
      value: _portionUnit != null &&
              (_units.any((unit) => unit.id == _portionUnit) ||
                  _portionUnit == _kCreateUnitValue)
          ? _portionUnit
          : null,
      items: [
        _kCreateUnitValue,
        ..._units.map((unit) => unit.id),
      ],
      labelBuilder: _unitLabel,
      searchable: true,
      enabled: enabled,
      hint: enabled
          ? (_unitsLoading ? 'Loading units...' : 'Select unit')
          : 'Enter a portion size',
      onChanged: !enabled
          ? null
          : (value) {
              if (value == _kCreateUnitValue) {
                _openCreateUnitDialog(forPortion: true);
                return;
              }
              if (value != null) setState(() => _portionUnit = value);
            },
    );
  }
}

class _SectionCard extends ConsumerWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? headerTrailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.headerTrailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    return Container(
      padding: EdgeInsets.all(context.h(20)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(12)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: context.h(18), color: AppColors.primary),
              SizedBox(width: context.w(8)),
              Expanded(
                child: Text(title, style: AppTextStyles.section(context)),
              ),
              if (headerTrailing != null) ...[
                headerTrailing!,
                SizedBox(width: context.w(8)),
              ],
            ],
          ),
          SizedBox(height: context.h(16)),
          child,
        ],
      ),
    );
  }
}
