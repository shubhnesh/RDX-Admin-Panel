import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/menu_item_model.dart';
import '../../providers/menu_provider.dart';

/// Add or edit a menu item.
///
/// Every interactive control on this screen (toggle switch, dropdown,
/// checkbox, segmented pill) is hand-built rather than the stock Flutter
/// widget, so the visuals can match the reference design exactly instead
/// of inheriting Material's default shapes/animations.
class EditMenuItemScreen extends StatefulWidget {
  final String? itemId;
  const EditMenuItemScreen({super.key, this.itemId});

  @override
  State<EditMenuItemScreen> createState() => _EditMenuItemScreenState();
}

class _EditMenuItemScreenState extends State<EditMenuItemScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final _ingredientController = TextEditingController();
  final Map<ItemSize, TextEditingController> _portionControllers = {
    ItemSize.small: TextEditingController(),
    ItemSize.medium: TextEditingController(),
    ItemSize.large: TextEditingController(),
  };

  String category = 'Uncategorized';
  String? subCategory;
  bool _addingCustomSubCategory = false;

  bool available = true;
  bool showOnMobileApp = true;
  bool featuredItem = false;
  bool isVeg = false;
  ItemSize selectedSize = ItemSize.medium;

  bool isLoading = false;
  String? errorMessage;
  List<MenuItemCustomizationGroup> customizations = [];
  List<String> majorIngredients = [];

  bool get isEditing => widget.itemId != null;

  static const List<String> _defaultCategories = [
    'Uncategorized',
    'Starters',
    'Mains',
    'Rolls',
    'Breads',
    'Beverages',
    'Desserts',
  ];

  @override
  void initState() {
    super.initState();
    if (isEditing) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => isLoading = true);
    final item = await context.read<MenuProvider>().getItemById(widget.itemId!);
    nameController.text = item.name;
    descriptionController.text = item.description;
    priceController.text = item.price.toString();
    category = item.category.isEmpty ? 'Uncategorized' : item.category;
    subCategory = item.subCategory.isEmpty ? null : item.subCategory;
    available = item.available;
    isVeg = item.isVeg;
    customizations = item.customizations;
    majorIngredients = List.from(item.majorIngredients);
    selectedSize = item.selectedSize;
    for (final size in ItemSize.values) {
      _portionControllers[size]!.text = item.portionQuantities[size] ?? '';
    }
    setState(() => isLoading = false);
  }

  void _addIngredient() {
    final value = _ingredientController.text.trim();
    if (value.isEmpty) return;
    if (majorIngredients.length >= MenuItemModel.maxMajorIngredients) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You can add up to ${MenuItemModel.maxMajorIngredients} major ingredients.')),
      );
      return;
    }
    if (majorIngredients.any((e) => e.toLowerCase() == value.toLowerCase())) {
      _ingredientController.clear();
      return;
    }
    setState(() {
      majorIngredients.add(value);
      _ingredientController.clear();
    });
  }

  void _removeIngredient(String ingredient) {
    setState(() => majorIngredients.remove(ingredient));
  }

  Future<void> _save() async {
    if (nameController.text.trim().isEmpty || double.tryParse(priceController.text.trim()) == null) {
      setState(() => errorMessage = 'Please fill in item name and a valid price.');
      return;
    }

    final item = MenuItemModel(
      id: widget.itemId ?? 'm${DateTime.now().millisecondsSinceEpoch}',
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      price: double.parse(priceController.text.trim()),
      category: category,
      subCategory: subCategory ?? '',
      imageUrl: '',
      available: available,
      isVeg: isVeg,
      customizations: customizations,
      majorIngredients: majorIngredients,
      selectedSize: selectedSize,
      portionQuantities: {
        for (final size in ItemSize.values) size: _portionControllers[size]!.text.trim(),
      },
    );

    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    final success = await context.read<MenuProvider>().saveItem(item);
    if (!mounted) return;
    setState(() => isLoading = false);
    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() => errorMessage = 'Failed to save item.');
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    _ingredientController.dispose();
    for (final c in _portionControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: isLoading && isEditing
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(colors),
                  const SizedBox(height: 20),
                  if (errorMessage != null) ...[
                    Text(errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                    const SizedBox(height: 12),
                  ],
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 900;
                      final left = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildImageUpload(colors),
                          const SizedBox(height: 16),
                          _buildDisplaySettings(colors),
                        ],
                      );
                      final right = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildItemDetailsCard(colors),
                          const SizedBox(height: 16),
                          _buildCategoryCard(colors),
                          const SizedBox(height: 16),
                          _buildPriceDietaryCard(colors),
                          const SizedBox(height: 16),
                          _buildSizeCard(colors),
                          const SizedBox(height: 16),
                          _buildIngredientsCard(colors),
                          const SizedBox(height: 16),
                          _buildCustomizationsCard(colors),
                        ],
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [left, const SizedBox(height: 16), right],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 1, child: left),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: right),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TOP BAR — breadcrumb + title + Cancel/Save
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTopBar(AppColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'MENU MANAGEMENT',
                    style: TextStyle(color: colors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.chevron_right, size: 14, color: colors.textMuted),
                  ),
                  const Text(
                    'EDIT ITEM',
                    style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isEditing ? 'Edit Menu Item' : 'Add Menu Item',
                style: TextStyle(color: colors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        _PillButton(
          label: 'Cancel',
          outlined: true,
          colors: colors,
          onTap: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 10),
        _PillButton(
          label: 'Save Item',
          outlined: false,
          colors: colors,
          isLoading: isLoading,
          onTap: _save,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // IMAGE UPLOAD
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildImageUpload(AppColorScheme colors) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Container(
            height: 220,
            width: double.infinity,
            color: colors.surfaceVariant,
            child: Icon(Icons.image_outlined, size: 40, color: colors.textMuted),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.05), Colors.black.withOpacity(0.6)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 10),
                  const Text('Update Item Image',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Drag and drop or click to replace the current photo',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: Row(
              children: [
                _CircleIconButton(icon: Icons.zoom_in, onTap: () {}),
                const SizedBox(width: 8),
                _CircleIconButton(icon: Icons.delete_outline, onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // DISPLAY SETTINGS
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildDisplaySettings(AppColorScheme colors) {
    return _Card(
      colors: colors,
      title: 'Display Settings',
      child: Column(
        children: [
          _switchRow(colors, 'Show on Mobile App', showOnMobileApp, (v) => setState(() => showOnMobileApp = v)),
          const SizedBox(height: 14),
          _switchRow(colors, 'Featured Item', featuredItem, (v) => setState(() => featuredItem = v)),
          const SizedBox(height: 14),
          _switchRow(colors, 'Available on Menu', available, (v) => setState(() => available = v)),
        ],
      ),
    );
  }

  Widget _switchRow(AppColorScheme colors, String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w500)),
        ),
        _CustomToggle(value: value, onChanged: onChanged),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ITEM NAME / DESCRIPTION
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildItemDetailsCard(AppColorScheme colors) {
    return _Card(
      colors: colors,
      child: Column(
        children: [
          _LabeledField(colors: colors, label: 'Item Name', controller: nameController),
          const SizedBox(height: 16),
          _LabeledField(colors: colors, label: 'Description', controller: descriptionController, maxLines: 3),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CATEGORY / SUBCATEGORY (fully custom dropdown, no DropdownButton)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildCategoryCard(AppColorScheme colors) {
    final provider = context.watch<MenuProvider>();
    final subOptions = provider.subCategoriesFor(category);

    return _Card(
      colors: colors,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _CustomDropdown(
              colors: colors,
              label: 'Category',
              value: category,
              options: {
                ..._defaultCategories,
                ...provider.categories.where((c) => c != 'All'),
              }.toList(),
              onSelected: (v) => setState(() {
                category = v;
                subCategory = null;
              }),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _addingCustomSubCategory
                ? _subCategoryTextInput(colors)
                : _CustomDropdown(
                    colors: colors,
                    label: 'Subcategory',
                    value: subOptions.contains(subCategory) ? subCategory : null,
                    placeholder: 'Select subcategory',
                    options: subOptions,
                    trailingAddNew: true,
                    onSelected: (v) => setState(() => subCategory = v),
                    onAddNew: () => setState(() => _addingCustomSubCategory = true),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _subCategoryTextInput(AppColorScheme colors) {
    final controller = TextEditingController(text: subCategory ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(colors, 'Subcategory'),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: _InputBox(
                colors: colors,
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'New subcategory name',
                  ),
                  onSubmitted: (v) => setState(() {
                    subCategory = v.trim().isEmpty ? null : v.trim();
                    _addingCustomSubCategory = false;
                  }),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _CircleIconButton(
              icon: Icons.check,
              size: 36,
              bg: AppColors.success.withOpacity(0.15),
              iconColor: AppColors.success,
              onTap: () => setState(() {
                subCategory = controller.text.trim().isEmpty ? null : controller.text.trim();
                _addingCustomSubCategory = false;
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fieldLabel(AppColorScheme colors, String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(color: colors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.7),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRICE + DIETARY PREFERENCE
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildPriceDietaryCard(AppColorScheme colors) {
    return _Card(
      colors: colors,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _LabeledField(
              colors: colors,
              label: 'Price (\$)',
              controller: priceController,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel(colors, 'Dietary Preference'),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: _SolidPill(
                        label: 'VEG',
                        selected: isVeg,
                        activeColor: AppColors.success,
                        colors: colors,
                        onTap: () => setState(() => isVeg = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SolidPill(
                        label: 'NON-VEG',
                        selected: !isVeg,
                        activeColor: AppColors.primary,
                        colors: colors,
                        onTap: () => setState(() => isVeg = false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SIZE + editable portion quantities (segmented, subtle-fill style)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSizeCard(AppColorScheme colors) {
    return _Card(
      colors: colors,
      title: 'Size',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose the default size and set the portion quantity served for each.',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: ItemSize.values.map((size) {
              final selected = selectedSize == size;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: size != ItemSize.large ? 8 : 0),
                  child: _OutlinePill(
                    label: size.label.toUpperCase(),
                    selected: selected,
                    colors: colors,
                    onTap: () => setState(() => selectedSize = size),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          _fieldLabel(colors, 'Portion Quantities'),
          const SizedBox(height: 4),
          Text(
            'e.g. 250 g, 2 pcs, Serves 1',
            style: TextStyle(color: colors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Row(
            children: ItemSize.values.map((size) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: size != ItemSize.large ? 12 : 0),
                  child: _LabeledField(
                    colors: colors,
                    label: size.label,
                    controller: _portionControllers[size]!,
                    hint: 'Quantity',
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MAJOR INGREDIENTS (up to 5)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildIngredientsCard(AppColorScheme colors) {
    final atLimit = majorIngredients.length >= MenuItemModel.maxMajorIngredients;
    return _Card(
      colors: colors,
      title: 'Major Ingredients',
      trailing: Text(
        '${majorIngredients.length}/${MenuItemModel.maxMajorIngredients}',
        style: TextStyle(color: colors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final ingredient in majorIngredients) _IngredientChip(label: ingredient, colors: colors, onRemove: () => _removeIngredient(ingredient)),
              if (majorIngredients.isEmpty)
                Text('No major ingredients added yet', style: TextStyle(color: colors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InputBox(
                  colors: colors,
                  child: TextField(
                    controller: _ingredientController,
                    enabled: !atLimit,
                    style: TextStyle(color: colors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: atLimit ? 'Maximum of 5 ingredients reached' : 'e.g. Basmati Rice',
                    ),
                    onSubmitted: (_) => _addIngredient(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _PillButton(
                label: 'Add',
                icon: Icons.add,
                outlined: true,
                colors: colors,
                enabled: !atLimit,
                onTap: _addIngredient,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CUSTOMIZATIONS
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildCustomizationsCard(AppColorScheme colors) {
    return _Card(
      colors: colors,
      title: 'Customizations',
      trailing: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.add, size: 15, color: AppColors.primary),
              SizedBox(width: 4),
              Text(
                'ADD NEW GROUP',
                style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4),
              ),
            ],
          ),
        ),
      ),
      child: customizations.isEmpty
          ? Text('No customization groups yet.', style: TextStyle(color: colors.textMuted, fontSize: 12))
          : Column(
              children: customizations.map((group) => _CustomizationGroupCard(group: group, colors: colors)).toList(),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SHARED CARD SHELL
// ═══════════════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final AppColorScheme colors;
  final String? title;
  final Widget? trailing;
  final Widget child;

  const _Card({required this.colors, this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(title!, style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// LABELED TEXT FIELD — custom uppercase letter-spaced label + boxed input
// ═══════════════════════════════════════════════════════════════════════

class _LabeledField extends StatelessWidget {
  final AppColorScheme colors;
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? hint;

  const _LabeledField({
    required this.colors,
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(color: colors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.7),
        ),
        const SizedBox(height: 7),
        _InputBox(
          colors: colors,
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared boxed container used underneath every text input / custom
/// dropdown trigger / inline-add field, so borders and radii stay identical.
class _InputBox extends StatelessWidget {
  final AppColorScheme colors;
  final Widget child;
  const _InputBox({required this.colors, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CUSTOM TOGGLE SWITCH (replaces Material Switch)
// ═══════════════════════════════════════════════════════════════════════

class _CustomToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _CustomToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 44,
        height: 25,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? AppColors.primary : const Color(0xFF3A2226),
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 19,
            height: 19,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 3, offset: const Offset(0, 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CUSTOM DROPDOWN (replaces DropdownButtonFormField)
// ═══════════════════════════════════════════════════════════════════════

class _CustomDropdown extends StatefulWidget {
  final AppColorScheme colors;
  final String label;
  final String? value;
  final String? placeholder;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final bool trailingAddNew;
  final VoidCallback? onAddNew;

  const _CustomDropdown({
    required this.colors,
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    this.placeholder,
    this.trailingAddNew = false,
    this.onAddNew,
  });

  @override
  State<_CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<_CustomDropdown> {
  final GlobalKey _triggerKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _open = false;

  void _toggleMenu() {
    if (_open) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final renderBox = _triggerKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final colors = widget.colors;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeMenu,
            ),
          ),
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height + 6,
            width: size.width,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 260),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 8)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shrinkWrap: true,
                  children: [
                    for (final option in widget.options)
                      _menuItem(colors, label: option, selected: option == widget.value, onTap: () {
                        widget.onSelected(option);
                        _closeMenu();
                      }),
                    if (widget.trailingAddNew) ...[
                      if (widget.options.isNotEmpty) Divider(height: 1, color: colors.divider),
                      _menuItem(
                        colors,
                        label: 'Add new',
                        icon: Icons.add,
                        iconColor: AppColors.primary,
                        textColor: AppColors.primary,
                        selected: false,
                        onTap: () {
                          _closeMenu();
                          widget.onAddNew?.call();
                        },
                      ),
                    ],
                    if (widget.options.isEmpty && !widget.trailingAddNew)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Text('No options yet', style: TextStyle(color: colors.textMuted, fontSize: 12.5)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _open = true);
  }

  Widget _menuItem(
    AppColorScheme colors, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    Color? iconColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        color: selected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: iconColor ?? colors.textSecondary),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor ?? (selected ? AppColors.primary : colors.textPrimary),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected) const Icon(Icons.check, size: 15, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _open = false);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final displayText = widget.value ?? widget.placeholder ?? 'Select';
    final isPlaceholder = widget.value == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: TextStyle(color: colors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.7),
        ),
        const SizedBox(height: 7),
        InkWell(
          key: _triggerKey,
          onTap: _toggleMenu,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _open ? AppColors.primary : colors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isPlaceholder ? colors.textMuted : colors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 150),
                  turns: _open ? 0.5 : 0,
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 19, color: colors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SEGMENTED PILLS — solid-fill (dietary) and subtle-fill (size) variants
// ═══════════════════════════════════════════════════════════════════════

/// Bold, fully solid pill — used for VEG / NON-VEG where the reference
/// design shows a strong filled state.
class _SolidPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final AppColorScheme colors;
  final VoidCallback onTap;

  const _SolidPill({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? activeColor : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: selected ? activeColor : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

/// Subtle translucent-fill pill — used for the Size segmented row where the
/// reference design shows a soft tinted selected state, not a hard fill.
class _OutlinePill extends StatelessWidget {
  final String label;
  final bool selected;
  final AppColorScheme colors;
  final VoidCallback onTap;

  const _OutlinePill({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: selected ? AppColors.primary.withOpacity(0.7) : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colors.textPrimary : colors.textMuted,
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// BUTTONS — Cancel / Save / Add (replaces ElevatedButton/OutlinedButton)
// ═══════════════════════════════════════════════════════════════════════

class _PillButton extends StatelessWidget {
  final String label;
  final bool outlined;
  final bool isLoading;
  final bool enabled;
  final IconData? icon;
  final AppColorScheme colors;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.outlined,
    required this.colors,
    required this.onTap,
    this.isLoading = false,
    this.enabled = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = !enabled || isLoading;
    return Opacity(
      opacity: isDisabled ? 0.55 : 1,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : AppColors.primary,
            borderRadius: BorderRadius.circular(9),
            border: outlined ? Border.all(color: colors.border) : null,
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: outlined ? colors.textPrimary : Colors.white),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: outlined ? colors.textPrimary : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? bg;
  final Color? iconColor;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.size = 30,
    this.bg,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg ?? Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
          border: bg == null ? Border.all(color: Colors.white.withOpacity(0.12)) : null,
        ),
        child: Icon(icon, size: size * 0.5, color: iconColor ?? Colors.white),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// INGREDIENT CHIP (replaces Chip)
// ═══════════════════════════════════════════════════════════════════════

class _IngredientChip extends StatelessWidget {
  final String label;
  final AppColorScheme colors;
  final VoidCallback onRemove;

  const _IngredientChip({required this.label, required this.colors, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(3),
              child: Icon(Icons.close, size: 13, color: colors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CUSTOMIZATION GROUP CARD (drag handle, badge tag, gear, custom checkbox)
// ═══════════════════════════════════════════════════════════════════════

class _CustomizationGroupCard extends StatelessWidget {
  final MenuItemCustomizationGroup group;
  final AppColorScheme colors;

  const _CustomizationGroupCard({required this.group, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
            child: Row(
              children: [
                Icon(Icons.drag_indicator, size: 16, color: colors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    group.title,
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                _tag(group.required ? 'REQUIRED' : 'OPTIONAL', group.required),
                const SizedBox(width: 8),
                Icon(Icons.settings_outlined, size: 16, color: colors.textMuted),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: group.options
                  .map((opt) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            _CustomCheckbox(checked: opt.included),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(opt.name, style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
                            ),
                            Text(
                              opt.included ? 'Included' : '+\$${opt.extraPrice.toStringAsFixed(2)}',
                              style: TextStyle(color: colors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, bool required) {
    final color = required ? AppColors.primary : colors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.3),
      ),
    );
  }
}

/// Fully custom checkbox (replaces Material Checkbox) — square, thin
/// border, filled with a check glyph when selected.
class _CustomCheckbox extends StatelessWidget {
  final bool checked;
  const _CustomCheckbox({required this.checked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: checked ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: checked ? AppColors.primary : const Color(0xFF5A4245), width: 1.4),
      ),
      child: checked ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
    );
  }
}
