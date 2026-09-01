import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../models/menu_item_model.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_indicator.dart';

/// Add or edit a menu item. Uses local TextEditingControllers for form
/// state (simple + standard Flutter pattern), and calls MenuProvider.saveItem
/// when the admin taps Save — no dedicated form provider needed.
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
          ? const LoadingIndicator()
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
                  Text(
                    'EDIT ITEM',
                    style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
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
        OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        const SizedBox(width: 10),
        CustomButton(label: 'Save Item', isLoading: isLoading, onPressed: _save),
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
                  colors: [Colors.black.withOpacity(0.05), Colors.black.withOpacity(0.55)],
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
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
                _imageIconBtn(Icons.zoom_in, () {}),
                const SizedBox(width: 8),
                _imageIconBtn(Icons.delete_outline, () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageIconBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // DISPLAY SETTINGS
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildDisplaySettings(AppColorScheme colors) {
    return _card(
      colors,
      title: 'Display Settings',
      child: Column(
        children: [
          _switchRow(colors, 'Show on Mobile App', showOnMobileApp, (v) => setState(() => showOnMobileApp = v)),
          const SizedBox(height: 4),
          _switchRow(colors, 'Featured Item', featuredItem, (v) => setState(() => featuredItem = v)),
          const SizedBox(height: 4),
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
        Switch(value: value, activeColor: AppColors.primary, onChanged: onChanged),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ITEM NAME / DESCRIPTION
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildItemDetailsCard(AppColorScheme colors) {
    return _card(
      colors,
      title: null,
      child: Column(
        children: [
          CustomTextField(controller: nameController, label: 'Item Name'),
          const SizedBox(height: 16),
          CustomTextField(controller: descriptionController, label: 'Description', maxLines: 3),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CATEGORY / SUBCATEGORY (dropdowns, using core utils via provider)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildCategoryCard(AppColorScheme colors) {
    final provider = context.watch<MenuProvider>();
    final subOptions = provider.subCategoriesFor(category);

    return _card(
      colors,
      title: null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _dropdownField(
              colors,
              label: 'Category',
              value: category,
              items: {
                ..._defaultCategories,
                ...provider.categories.where((c) => c != 'All'),
              }.toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  category = v;
                  subCategory = null;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _addingCustomSubCategory
                ? _subCategoryTextInput(colors)
                : _dropdownField(
                    colors,
                    label: 'Subcategory',
                    value: subOptions.contains(subCategory) ? subCategory : null,
                    hint: 'Select subcategory',
                    items: subOptions,
                    onChanged: (v) {
                      if (v == '__add_new__') {
                        setState(() => _addingCustomSubCategory = true);
                        return;
                      }
                      setState(() => subCategory = v);
                    },
                    trailingAddNew: true,
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
        Text('Subcategory', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(hintText: 'New subcategory name'),
                onSubmitted: (v) => setState(() {
                  subCategory = v.trim().isEmpty ? null : v.trim();
                  _addingCustomSubCategory = false;
                }),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check, color: AppColors.success),
              onPressed: () => setState(() {
                subCategory = controller.text.trim().isEmpty ? null : controller.text.trim();
                _addingCustomSubCategory = false;
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dropdownField(
    AppColorScheme colors, {
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? hint,
    bool trailingAddNew = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          dropdownColor: colors.surface,
          hint: hint != null ? Text(hint, style: TextStyle(color: colors.textMuted, fontSize: 13)) : null,
          items: [
            ...items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))),
            if (trailingAddNew)
              const DropdownMenuItem(
                value: '__add_new__',
                child: Row(
                  children: [
                    Icon(Icons.add, size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text('Add new', style: TextStyle(color: AppColors.primary)),
                  ],
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRICE + DIETARY PREFERENCE
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildPriceDietaryCard(AppColorScheme colors) {
    return _card(
      colors,
      title: null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CustomTextField(
              controller: priceController,
              label: 'Price (₹)',
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dietary Preference', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _toggleChip(
                        colors,
                        label: 'VEG',
                        selected: isVeg,
                        color: AppColors.success,
                        onTap: () => setState(() => isVeg = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _toggleChip(
                        colors,
                        label: 'NON-VEG',
                        selected: !isVeg,
                        color: AppColors.primary,
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
  // SIZE (renamed from Spice Level) + editable portion quantities
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSizeCard(AppColorScheme colors) {
    return _card(
      colors,
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
                  child: _toggleChip(
                    colors,
                    label: size.label.toUpperCase(),
                    selected: selected,
                    color: AppColors.primary,
                    onTap: () => setState(() => selectedSize = size),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Portion Quantities', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
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
                  child: CustomTextField(
                    controller: _portionControllers[size]!,
                    label: size.label,
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

  Widget _toggleChip(
    AppColorScheme colors, {
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : colors.textSecondary,
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MAJOR INGREDIENTS (up to 5)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildIngredientsCard(AppColorScheme colors) {
    final atLimit = majorIngredients.length >= MenuItemModel.maxMajorIngredients;
    return _card(
      colors,
      title: 'Major Ingredients',
      trailing: Text(
        '${majorIngredients.length}/${MenuItemModel.maxMajorIngredients}',
        style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final ingredient in majorIngredients)
                Chip(
                  label: Text(ingredient, style: const TextStyle(fontSize: 12.5)),
                  backgroundColor: colors.surfaceVariant,
                  side: BorderSide(color: colors.border),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => _removeIngredient(ingredient),
                ),
              if (majorIngredients.isEmpty)
                Text('No major ingredients added yet', style: TextStyle(color: colors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ingredientController,
                  enabled: !atLimit,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: atLimit ? 'Maximum of 5 ingredients reached' : 'e.g. Basmati Rice',
                  ),
                  onSubmitted: (_) => _addIngredient(),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: atLimit ? null : _addIngredient,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CUSTOMIZATIONS (existing groups, read-only preview)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildCustomizationsCard(AppColorScheme colors) {
    return _card(
      colors,
      title: 'Customizations',
      trailing: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add New Group'),
      ),
      child: customizations.isEmpty
          ? Text('No customization groups yet.', style: TextStyle(color: colors.textMuted, fontSize: 12))
          : Column(
              children: customizations
                  .map((group) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${group.title}${group.required ? " (Required)" : " (Optional)"}',
                              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            ...group.options.map((opt) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(opt.name, style: AppTextStyles.bodyMuted),
                                      Text(
                                        opt.included ? 'Included' : '+₹${opt.extraPrice.toStringAsFixed(0)}',
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ))
                  .toList(),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Shared card shell
  // ═══════════════════════════════════════════════════════════════════

  Widget _card(AppColorScheme colors, {String? title, Widget? trailing, required Widget child}) {
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
                  child: Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                if (trailing != null) trailing,
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
