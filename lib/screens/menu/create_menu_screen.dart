import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/menu_item_model.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/rdx_header.dart';
import '../../widgets/form_action_button.dart';
import '../../widgets/rdx_dropdown.dart';
import '../../widgets/rdx_text_field.dart';
import '../../widgets/rdx_toggle_button.dart';

class CreateMenuScreen extends StatefulWidget {
  final String? itemId;
  const CreateMenuScreen({super.key, this.itemId});

  @override
  State<CreateMenuScreen> createState() => _CreateMenuScreenState();
}

class _CreateMenuScreenState extends State<CreateMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _image = TextEditingController();
  final _price = TextEditingController();
  final _sortOrder = TextEditingController(text: '0');
  final _ingredientInput = TextEditingController();

  String _primaryCategory = MenuTaxonomy.categories.first.id;
  String? _subcategory;
  DietaryType? _dietaryType;
  PreparationStyle? _preparationStyle;
  final Set<String> _tags = {};
  final List<String> _ingredients = [];
  bool _available = true;
  bool _loading = false;
  String? _error;

  static const _tagOptions = [
    'Featured',
    'Bestseller',
    'New',
    'Popular',
  ];
  bool get _editing => widget.itemId != null;

  List<MenuCategory> get _subcategories => MenuTaxonomy.categories
      .where((item) => item.parentId == _primaryCategory)
      .toList();

  @override
  void initState() {
    super.initState();
    if (_editing) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final item =
          await context.read<MenuProvider>().getItemById(widget.itemId!);
      _name.text = item.name;
      _description.text = item.description;
      _image.text = item.image;
      _price.text = item.price.toString();
      _sortOrder.text = item.sortOrder.toString();
      _primaryCategory = item.primaryCategoryId;
      _dietaryType = item.dietaryType;
      _preparationStyle = item.preparationStyle;
      final loadedTags = item.tags.map(_titleCase).toList();
      if (item.isFeatured) loadedTags.insert(0, 'Featured');
      _tags
        ..clear()
        ..addAll(loadedTags.take(4));
      _ingredients
        ..clear()
        ..addAll(item.ingredients);
      _available = item.isAvailable;
    } catch (_) {
      _error = 'Failed to load menu item.';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _addIngredient() {
    final value = _ingredientInput.text.trim();
    if (value.isEmpty) return;
    if (_ingredients.length >= 10) return;
    if (_ingredients.any((e) => e.toLowerCase() == value.toLowerCase())) {
      _ingredientInput.clear();
      return;
    }
    setState(() {
      _ingredients.add(value);
      _ingredientInput.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dietaryType == null || _preparationStyle == null) {
      setState(
          () => _error = 'Please select a dietary type and preparation style.');
      return;
    }
    final price = double.tryParse(_price.text.trim());
    if (price == null || price < 0) {
      setState(() => _error = 'Please enter a valid price.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final item = MenuItemModel(
      id: widget.itemId ?? '',
      name: _name.text.trim(),
      description: _description.text.trim(),
      image: _image.text.trim(),
      isAvailable: _available,
      isFeatured: _tags.contains('Featured'),
      sortOrder: int.tryParse(_sortOrder.text) ?? 0,
      dietaryType: _dietaryType,
      preparationStyle: _preparationStyle!,
      price: price,
      primaryCategoryId: _primaryCategory,
      tags: _tags
          .where((tag) => tag != 'Featured')
          .map((tag) => tag.toLowerCase().replaceAll(' ', '_'))
          .toList(),
      ingredients: List<String>.from(_ingredients),
    );
    final success = await context.read<MenuProvider>().saveItem(item);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _loading = false;
        _error = context.read<MenuProvider>().errorMessage ??
            'Failed to save menu item.';
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _image.dispose();
    _price.dispose();
    _sortOrder.dispose();
    _ingredientInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: RdxHeader(
        title: _editing ? 'Edit Menu Item' : 'Add Menu Item',
      ),
      body: _loading && _editing
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: narrow
                  ? SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        context.w(20),
                        context.h(16),
                        context.w(20),
                        context.h(28),
                      ),
                      child: Column(
                        children: [
                          if (_error != null) _errorBanner(context, colors),
                          _mainColumn(context, colors),
                          SizedBox(height: context.h(16)),
                          _preview(context, colors),
                          SizedBox(height: context.h(14)),
                          _actionButtons(context, colors),
                        ],
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.w(20),
                        context.h(16),
                        context.w(20),
                        context.h(24),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.only(right: context.w(22)),
                              child: Column(
                                children: [
                                  if (_error != null)
                                    _errorBanner(context, colors),
                                  _mainColumn(context, colors),
                                ],
                              ),
                            ),
                          ),
                          VerticalDivider(
                            width: context.w(1),
                            thickness: context.h(1),
                            color: colors.border,
                          ),
                          SizedBox(
                            width: context.w(300),
                            child: Padding(
                              padding: EdgeInsets.only(left: context.w(22)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _preview(context, colors),
                                  const Spacer(),
                                  _actionButtons(context, colors),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _actionButtons(BuildContext context, AppColorScheme colors) => Row(
        children: [
          Expanded(
            child: FormActionButton.save(
              isLoading: _loading,
              onPressed: _save,
            ),
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: FormActionButton.discard(
              onPressed: _loading ? null : () => Navigator.pop(context),
            ),
          ),
        ],
      );

  Widget _mainColumn(BuildContext context, AppColorScheme colors) => Column(
        children: [
          _panel(context, colors, 'Basic Information',
              Icons.description_outlined, [
            Row(children: [
              Expanded(
                child: RdxTextField(
                  controller: _name,
                  label: 'Item Name *',
                  hint: 'Enter item name',
                  onChanged: (_) => setState(() {}),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
              ),
              SizedBox(width: context.w(14)),
              SizedBox(
                width: context.w(130),
                child: RdxTextField(
                  controller: _price,
                  label: 'Price *',
                  hint: 'Enter price',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixText: '₹',
                  onChanged: (_) => setState(() {}),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
              ),
            ]),
            SizedBox(height: context.h(15)),

            // ── Ingredients (max 10) ────────────────────────────────
            Text('Ingredients', style: _labelStyle(context, colors)),
            SizedBox(height: context.h(4)),
            // Text(
            //   'Add up to 10 major ingredients. These appear on the menu card.',
            //   style: TextStyle(
            //     color: colors.textSecondary,
            //     fontSize: context.h(10),
            //   ),
            // ),
            SizedBox(height: context.h(4)),
            Text(
              '${_ingredients.length}/10 ingredients',
              style:
                  TextStyle(color: colors.textMuted, fontSize: context.h(10)),
            ),
            SizedBox(height: context.h(8)),
            Row(
              children: [
                Expanded(
                  child: RdxTextField(
                    controller: _ingredientInput,
                    hint: 'Add an ingredient and press add',
                    onSubmitted: (_) => _addIngredient(),
                  ),
                ),
                SizedBox(width: context.w(8)),
                FormActionButton(
                  label: 'Add',
                  onPressed: _ingredients.length >= 10 ? null : _addIngredient,
                  isPrimary: true,
                  // Optional: make it more compact to match the image
                  height: context
                      .h(35), // or whatever height matches your text field
                  minWidth: context.w(60), // adjust as needed
                ),
              ],
            ),
            if (_ingredients.isNotEmpty) ...[
              Wrap(
                spacing: context.w(8),
                runSpacing: context.h(8),
                children: [
                  for (final ing in _ingredients)
                    _IngredientChip(
                      label: ing,
                      colors: colors,
                      onDeleted: () => setState(() => _ingredients.remove(ing)),
                    ),
                ],
              ),
            ],

            SizedBox(height: context.h(15)),
            RdxTextField(
              controller: _description,
              label: 'Description',
              maxLines: 5,
              hint: 'Add item description',
              counterText: '${_description.text.length}/250',
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: context.h(15)),
            RdxTextField(
              controller: _image,
              label: 'Item Image',
              hint: 'Enter image URL',
              onChanged: (_) => setState(() {}),
            ),
          ]),
          SizedBox(height: context.h(16)),
          _panel(context, colors, 'Item Details', Icons.assignment_outlined, [
            Row(children: [
              Expanded(
                child: _dropdown(
                  'Category',
                  _primaryCategory,
                  MenuTaxonomy.categories
                      .where((item) => item.parentId == null)
                      .map((item) => item.id)
                      .toList(),
                  (value) => setState(() {
                    _primaryCategory = value!;
                    _subcategory = null;
                  }),
                  _categoryLabel,
                  required: true,
                ),
              ),
              SizedBox(width: context.w(14)),
              Expanded(
                child: _dropdown(
                  'Subcategory',
                  _subcategory,
                  _subcategories.map((item) => item.id).toList(),
                  (value) => setState(() => _subcategory = value),
                  _categoryLabel,
                  hint: 'Select subcategory',
                ),
              ),
            ]),
            SizedBox(height: context.h(15)),
            Row(children: [
              Expanded(
                child: _dropdown(
                  'Dietary Type',
                  _dietaryType,
                  DietaryType.values,
                  (value) => setState(() => _dietaryType = value),
                  (value) => _titleCase(value.name),
                ),
              ),
              SizedBox(width: context.w(14)),
              Expanded(
                child: _dropdown(
                  'Preparation Style',
                  _preparationStyle,
                  PreparationStyle.values,
                  (value) => setState(() => _preparationStyle = value),
                  (value) => _titleCase(value.name),
                ),
              ),
            ]),
            SizedBox(height: context.h(15)),
            Text('Tags', style: _labelStyle(context, colors)),
            SizedBox(height: context.h(7)),
            Wrap(
              spacing: context.w(8),
              runSpacing: context.h(8),
              children: [
                for (final tag in _tagOptions) _tagChip(context, colors, tag),
              ],
            ),
          ]),
          SizedBox(height: context.h(16)),
          _panel(context, colors, 'Display Settings',
              Icons.desktop_windows_outlined, [
            Row(children: [
              Expanded(
                child: _switch(
                  context,
                  colors,
                  'Available on Menu',
                  'Make this item available for ordering',
                  _available,
                  (value) => setState(() => _available = value),
                ),
              ),
            ]),
          ]),
          SizedBox(height: context.h(12)),
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
                Icon(Icons.lightbulb_outline,
                    size: context.h(16), color: AppColors.primary),
                SizedBox(width: context.w(8)),
                Expanded(
                  child: Text(
                    'Tip: Add high quality images and detailed descriptions to attract more customers.',
                    style: TextStyle(
                      color: Color(0xFF9B5B3A),
                      fontSize: context.h(11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _preview(BuildContext context, AppColorScheme colors) => _panel(
        context,
        colors,
        'Preview',
        Icons.visibility_outlined,
        [
          Padding(
            padding: EdgeInsets.all(context.h(6)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.h(8)),
              child: SizedBox(
                height: context.h(170),
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFFFFF1EA),
                        child: _image.text.trim().isEmpty
                            ? Icon(Icons.restaurant,
                                size: context.h(48), color: Color(0xFFFFD4BF))
                            : Image.network(
                                _image.text.trim(),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.restaurant,
                                  size: context.h(48),
                                  color: Color(0xFFFFD4BF),
                                ),
                              ),
                      ),
                    ),
                    if (_tags.contains('Featured'))
                      Positioned(
                        left: context.w(10),
                        top: context.h(10),
                        child: _previewCardBadge(
                          context,
                          'Featured',
                          AppColors.primary,
                          Colors.white,
                        ),
                      ),
                    if (_dietaryType != null)
                      Positioned(
                        right: context.w(10),
                        bottom: context.h(10),
                        child: _dietaryBadge(context, colors),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: context.h(5)),
          Text(
            _categoryLabel(_primaryCategory),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: context.h(9),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: context.h(3)),
          Text(
            _name.text.trim().isEmpty ? 'Item Name' : _name.text.trim(),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: context.h(14),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: context.h(4)),
          SizedBox(
            height: context.h(16),
            child: _ingredients.isEmpty
                ? null
                : Text(
                    _ingredients.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: context.h(11),
                      height: context.h(1.4),
                    ),
                  ),
          ),
          SizedBox(height: context.h(8)),
          Wrap(
            spacing: context.w(5),
            runSpacing: context.h(5),
            children: [
              for (final tag in _tags.where((tag) => tag != 'Featured'))
                _previewDetailChip(context, tag, colors.textSecondary),
            ],
          ),
          SizedBox(height: context.h(10)),
          Text(
            '₹${_price.text.trim().isEmpty ? '0.00' : _price.text.trim()}',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: context.h(15),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: context.h(8)),
          Divider(height: context.h(1), color: colors.divider),
          SizedBox(height: context.h(6)),
          Row(
            children: [
              RdxToggleButton(
                value: _available,
                activeColor: AppColors.primary,
                onChanged: (value) => setState(() => _available = value),
              ),
              SizedBox(width: context.w(5)),
              Text(
                _available ? 'Available' : 'Sold Out',
                style: AppTextStyles.label(context).copyWith(
                  color: _available ? AppColors.primary : colors.textMuted,
                ),
              ),
            ],
          ),
        ],
      );

  Widget _panel(
    BuildContext context,
    AppColorScheme colors,
    String title,
    IconData icon,
    List<Widget> children,
  ) =>
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.h(14)),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(context.h(8)),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: context.h(15), color: colors.textSecondary),
                SizedBox(width: context.w(8)),
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: context.h(12),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(16)),
            ...children,
          ],
        ),
      );

  Widget _dropdown<T>(
    String label,
    T? value,
    List<T> values,
    ValueChanged<T?> onChanged,
    String Function(T) labelFor, {
    String? hint,
    bool required = false,
  }) =>
      RdxDropdown<T>(
        label: required ? '$label *' : label,
        value: values.contains(value) ? value : null,
        items: values,
        labelBuilder: labelFor,
        hint: hint ?? 'Select $label',
        onChanged: onChanged,
      );

  Widget _switch(
    BuildContext context,
    AppColorScheme colors,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) =>
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: context.h(11),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: context.h(3)),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: context.h(10),
                  ),
                ),
              ],
            ),
          ),
          RdxToggleButton(
            value: value,
            onChanged: onChanged,
          ),
        ],
      );

  Widget _tagChip(BuildContext context, AppColorScheme colors, String tag) =>
      FilterChip(
        label: Text(
          tag,
          style: TextStyle(
            color: _tags.contains(tag) ? AppColors.primary : colors.textPrimary,
            fontSize: context.h(10),
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: _tags.contains(tag),
        showCheckmark: true,
        checkmarkColor: AppColors.primary,
        backgroundColor: colors.surfaceVariant,
        selectedColor: Colors.white,
        side: BorderSide(
          color: _tags.contains(tag) ? AppColors.primary : colors.border,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.h(8)),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(9),
          vertical: context.h(5),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onSelected: _tags.length >= 4 && !_tags.contains(tag)
            ? null
            : (selected) => setState(() {
                  if (selected) {
                    _tags.add(tag);
                  } else {
                    _tags.remove(tag);
                  }
                }),
      );

  Widget _previewCardBadge(
    BuildContext context,
    String label,
    Color background,
    Color foreground,
  ) =>
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(7),
          vertical: context.h(4),
        ),
        decoration: BoxDecoration(
          color: background.withValues(
              alpha: background == AppColors.primary ? 1 : 0.92),
          borderRadius: BorderRadius.circular(context.h(5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: context.h(9),
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _previewDetailChip(
    BuildContext context,
    String label,
    Color color,
  ) =>
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(6),
          vertical: context.h(3),
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(context.h(4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: context.h(9),
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _dietaryBadge(BuildContext context, AppColorScheme colors) =>
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(9),
          vertical: context.h(5),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(context.h(6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: context.h(8), color: _dietaryColor),
            SizedBox(width: context.w(5)),
            Text(
              _dietaryLabel,
              style: TextStyle(
                color: _dietaryColor,
                fontSize: context.h(10),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Color get _dietaryColor =>
      _dietaryType == DietaryType.veg ? AppColors.success : AppColors.danger;

  String get _dietaryLabel => _dietaryType == null
      ? 'Dietary type not selected'
      : _dietaryType == DietaryType.veg
          ? 'Veg'
          : _dietaryType == DietaryType.egg
              ? 'Contains Egg'
              : 'Non-Veg';

  Widget _errorBanner(BuildContext context, AppColorScheme colors) => Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: context.h(12)),
        padding: EdgeInsets.all(context.h(12)),
        color: const Color(0xFFFFEDEA),
        child: Text(
          _error!,
          style: TextStyle(color: AppColors.danger, fontSize: context.h(12)),
        ),
      );

  TextStyle _labelStyle(BuildContext context, AppColorScheme colors) =>
      TextStyle(
        color: colors.textPrimary,
        fontSize: context.h(11),
        fontWeight: FontWeight.w600,
      );

  String _categoryLabel(String id) => MenuTaxonomy.nameFor(id);

  String _titleCase(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .map((part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class _IngredientChip extends StatelessWidget {
  final String label;
  final AppColorScheme colors;
  final VoidCallback onDeleted;

  const _IngredientChip({
    required this.label,
    required this.colors,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: context.w(9),
        right: context.w(4),
        top: context.h(5),
        bottom: context.h(5),
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: context.h(10),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: context.w(4)),
          InkWell(
            onTap: onDeleted,
            borderRadius: BorderRadius.circular(context.h(10)),
            child: Padding(
              padding: EdgeInsets.all(context.h(2)),
              child: Icon(
                Icons.close_rounded,
                size: context.h(14),
                color: colors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
