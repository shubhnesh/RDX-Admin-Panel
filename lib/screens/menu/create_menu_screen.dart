import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/screens/menu/widgets/menu_item_card.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/menu_item_model.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/resuable_options/rdx_dropdown.dart';
import '../../widgets/resuable_options/rdx_text_field.dart';
import '../../widgets/buttons/rdx_toggle_button.dart';

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

  String? _primaryCategory;
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

  List<MenuCategory> get _subcategories {
    if (_primaryCategory == null) return [];
    return MenuTaxonomy.categories
        .where((item) => item.parentId == _primaryCategory)
        .toList();
  }

  MenuItemModel get _previewItem {
    final price = double.tryParse(_price.text.trim()) ?? 0.0;

    return MenuItemModel(
      id: widget.itemId ?? 'preview',
      name: _name.text.trim().isEmpty ? 'Item Name' : _name.text.trim(),
      description: _description.text.trim(),
      imageUrl: _image.text.trim(),
      available: _available,
      featuredItem: _tags.contains('Featured'),
      sortOrder: int.tryParse(_sortOrder.text) ?? 0,
      dietaryType: _dietaryType ?? DietaryType.veg,
      preparationStyle: _preparationStyle ?? PreparationStyle.values.first,
      price: price,
      category: _primaryCategory == null
          ? 'Category'
          : _categoryLabel(_primaryCategory!),
      tags: _tags
          .where((tag) => tag != 'Featured')
          .map((tag) => tag.toLowerCase().replaceAll(' ', '_'))
          .toList(),
      ingredients: List<String>.from(_ingredients),
    );
  }

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
      _image.text = item.imageUrl;
      _price.text = item.price.toString();
      _sortOrder.text = item.sortOrder.toString();
      _primaryCategory = item.primaryCategoryId;
      _dietaryType = item.dietaryType;
      _preparationStyle = item.preparationStyle;
      final loadedTags = item.tags.map(_titleCase).toList();
      if (item.featuredItem) loadedTags.insert(0, 'Featured');
      _tags
        ..clear()
        ..addAll(loadedTags.take(4));
      _ingredients
        ..clear()
        ..addAll(item.ingredients);
      _available = item.available;
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

    if (_primaryCategory == null) {
      setState(() => _error = 'Please select a category.');
      return;
    }
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
      imageUrl: _image.text.trim(),
      available: _available,
      featuredItem: _tags.contains('Featured'),
      sortOrder: int.tryParse(_sortOrder.text) ?? 0,
      dietaryType: _dietaryType!,
      preparationStyle: _preparationStyle!,
      price: price,
      primaryCategoryId: _primaryCategory!,
      category: _categoryLabel(_primaryCategory!),
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
      body: Column(
        children: [
          RdxHeader(
            title: _editing ? 'Edit Menu Item' : 'Add Menu Item',
            showBackButton: true,
          ),
          Expanded(
            child: _loading && _editing
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
                                if (_error != null)
                                  _errorBanner(context, colors),
                                _mainColumn(context, colors),
                                SizedBox(height: context.h(16)),
                                _previewCard(context),
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
                                    padding:
                                        EdgeInsets.only(right: context.w(22)),
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
                                  width: context.w(320),
                                  child: Padding(
                                    padding:
                                        EdgeInsets.only(left: context.w(22)),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Preview',
                                          style: AppTextStyles.section(context)
                                              .copyWith(
                                                  color: colors.textPrimary),
                                        ),
                                        SizedBox(height: context.h(10)),
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.topCenter,
                                            child: SizedBox(
                                              width: context.w(225),
                                              height: context.h(410),
                                              child: MenuItemCard(
                                                item: _previewItem,
                                                categorySelected:
                                                    _primaryCategory != null,
                                                dietarySelected:
                                                    _dietaryType != null,
                                                hasTags: _tags.isNotEmpty ||
                                                    _preparationStyle != null,
                                                onToggleAvailability: () {
                                                  setState(() =>
                                                      _available = !_available);
                                                },
                                                onActions: (_) {},
                                              ),
                                            ),
                                          ),
                                        ),
                                        _actionButtons(context, colors),
                                      ],
                                    ),
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

  Widget _previewCard(BuildContext context) => Center(
        child: SizedBox(
          width: context.w(225),
          height: context.h(410),
          child: MenuItemCard(
            item: _previewItem,
            categorySelected: _primaryCategory != null,
            dietarySelected: _dietaryType != null,
            hasTags: _tags.isNotEmpty || _preparationStyle != null,
            onToggleAvailability: () {
              setState(() => _available = !_available);
            },
            onActions: (_) {},
          ),
        ),
      );

  Widget _actionButtons(BuildContext context, AppColorScheme colors) => Row(
        children: [
          Expanded(
            child: RdxActionButton.save(
              isLoading: _loading,
              onPressed: _save,
            ),
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: RdxActionButton.discard(
              onPressed: _loading ? null : () => Navigator.pop(context),
            ),
          ),
        ],
      );

  Widget _mainColumn(BuildContext context, AppColorScheme colors) => Column(
        children: [
          _panel(context, colors, 'Basic Information',
              Icons.description_outlined, [
            LayoutBuilder(builder: (context, c) {
              final stack = c.maxWidth < 400;
              final nameField = RdxTextField(
                controller: _name,
                label: 'Item Name *',
                hint: 'Enter item name',
                onChanged: (_) => setState(() {}),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              );
              final priceField = RdxTextField(
                controller: _price,
                label: 'Price *',
                hint: 'Enter price',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixText: '₹',
                onChanged: (_) => setState(() {}),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              );
              if (stack) {
                return Column(
                  children: [
                    nameField,
                    SizedBox(height: context.h(14)),
                    priceField,
                  ],
                );
              }
              return Row(children: [
                Expanded(child: nameField),
                SizedBox(width: context.w(14)),
                SizedBox(width: context.w(130), child: priceField),
              ]);
            }),
            SizedBox(height: context.h(15)),

            // ── Ingredients ────────────────────────────────────────
            Text(
              'Ingredients',
              style: AppTextStyles.bodySecondary(context).copyWith(
                color: colors.textMuted,
              ),
            ),
            SizedBox(height: context.h(4)),
            Text(
              '${_ingredients.length}/10 ingredients',
              style: AppTextStyles.bodyTertiary(context)
                  .copyWith(color: colors.textMuted),
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
                RdxActionButton(
                  label: 'Add',
                  onPressed: _ingredients.length >= 10 ? null : _addIngredient,
                  isPrimary: true,
                  height: context.h(35),
                  minWidth: context.w(60),
                ),
              ],
            ),
            if (_ingredients.isNotEmpty) ...[
              SizedBox(height: context.h(10)),
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
            LayoutBuilder(builder: (context, c) {
              final stack = c.maxWidth < 400;
              final cat = _dropdown(
                'Category',
                _primaryCategory,
                MenuTaxonomy.categories
                    .where((item) => item.parentId == null)
                    .map((item) => item.id)
                    .toList(),
                (value) => setState(() {
                  _primaryCategory = value;
                  _subcategory = null;
                }),
                _categoryLabel,
                required: true,
                hint: 'Select category',
              );
              final sub = _dropdown(
                'Subcategory',
                _subcategory,
                _subcategories.map((item) => item.id).toList(),
                (value) => setState(() => _subcategory = value),
                _categoryLabel,
                hint: 'Select subcategory',
              );
              if (stack) {
                return Column(children: [
                  cat,
                  SizedBox(height: context.h(14)),
                  sub,
                ]);
              }
              return Row(children: [
                Expanded(child: cat),
                SizedBox(width: context.w(14)),
                Expanded(child: sub),
              ]);
            }),
            SizedBox(height: context.h(15)),
            LayoutBuilder(builder: (context, c) {
              final stack = c.maxWidth < 400;
              final diet = _dropdown(
                'Dietary Type',
                _dietaryType,
                DietaryType.values,
                (value) => setState(() => _dietaryType = value),
                (value) => _titleCase(value.name),
              );
              final prep = _dropdown(
                'Preparation Style',
                _preparationStyle,
                PreparationStyle.values,
                (value) => setState(() => _preparationStyle = value),
                (value) => _titleCase(value.name),
              );
              if (stack) {
                return Column(children: [
                  diet,
                  SizedBox(height: context.h(14)),
                  prep,
                ]);
              }
              return Row(children: [
                Expanded(child: diet),
                SizedBox(width: context.w(14)),
                Expanded(child: prep),
              ]);
            }),
            SizedBox(height: context.h(15)),
            Text(
              'Tags',
              style: AppTextStyles.bodySecondary(context).copyWith(
                color: colors.textMuted,
              ),
            ),
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
                    size: context.h(18), color: AppColors.primary),
                SizedBox(width: context.w(8)),
                Expanded(
                  child: Text(
                    'Tip: Add high quality images and detailed descriptions to attract more customers.',
                    style: AppTextStyles.bodyTertiary(context)
                        .copyWith(color: colors.primary),
                  ),
                ),
              ],
            ),
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
                Icon(icon, size: context.h(18), color: AppColors.primary),
                SizedBox(width: context.w(8)),
                Text(
                  title,
                  style: AppTextStyles.section(context)
                      .copyWith(color: colors.textPrimary),
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
                  style: AppTextStyles.bodySecondary(context)
                      .copyWith(color: colors.textPrimary),
                ),
                SizedBox(height: context.h(3)),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySecondary(context)
                      .copyWith(color: colors.textSecondary),
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
          style: AppTextStyles.label(context).copyWith(
            color: _tags.contains(tag) ? AppColors.primary : colors.textPrimary,
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
