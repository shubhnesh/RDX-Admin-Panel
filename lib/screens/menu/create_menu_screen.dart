import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/menu_item_model.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/rdx_header.dart';

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
  DietaryType _dietaryType = DietaryType.veg;
  PreparationStyle _preparationStyle = PreparationStyle.other;
  String? _spiceLevel;
  String? _servingSize;
  final Set<String> _tags = {};
  final List<String> _ingredients = [];
  bool _available = true;
  bool _featured = false;
  bool _loading = false;
  String? _error;

  static const _tagOptions = [
    'Bestseller',
    'Spicy',
    'Crispy',
    'New',
    'Popular',
    'Chef Special'
  ];
  static const _spiceOptions = ['Mild', 'Medium', 'Hot', 'Extra Hot'];
  static const _servingOptions = [
    'Single serving',
    'Regular',
    'Large',
    'Family size'
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
      _tags
        ..clear()
        ..addAll(item.tags.map(_titleCase));
      _ingredients
        ..clear()
        ..addAll(item.ingredients);
      _available = item.isAvailable;
      _featured = item.isFeatured;
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
      isFeatured: _featured,
      sortOrder: int.tryParse(_sortOrder.text) ?? 0,
      dietaryType: _dietaryType,
      preparationStyle: _preparationStyle,
      price: price,
      primaryCategoryId: _primaryCategory,
      tags: _tags
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
                        Responsive.pageHorizontal(context),
                        16,
                        Responsive.pageHorizontal(context),
                        28,
                      ),
                      child: Column(
                        children: [
                          if (_error != null) _errorBanner(colors),
                          _mainColumn(colors),
                          const SizedBox(height: 16),
                          _preview(colors),
                          const SizedBox(height: 14),
                          _actionButtons(colors),
                        ],
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.fromLTRB(
                        Responsive.pageHorizontal(context),
                        16,
                        Responsive.pageHorizontal(context),
                        24,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(right: 22),
                              child: Column(
                                children: [
                                  if (_error != null) _errorBanner(colors),
                                  _mainColumn(colors),
                                ],
                              ),
                            ),
                          ),
                          VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: colors.border,
                          ),
                          SizedBox(
                            width: 300,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _preview(colors),
                                  const Spacer(),
                                  _actionButtons(colors),
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

  Widget _actionButtons(AppColorScheme colors) => Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _loading ? null : () => Navigator.pop(context),
              child: const Text('Discard'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              child: Text(_editing ? 'Save Changes' : 'Save Item'),
            ),
          ),
        ],
      );

  Widget _mainColumn(AppColorScheme colors) => Column(
        children: [
          _panel(colors, 'Basic Information', Icons.description_outlined, [
            Row(children: [
              Expanded(
                child: _field(
                  'Item Name',
                  _name,
                  required: true,
                  hint: 'e.g. Paneer Tikka Masala',
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 130,
                child: _field(
                  'Price',
                  _price,
                  required: true,
                  hint: '0.00',
                  keyboard:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefix: '₹',
                ),
              ),
            ]),
            const SizedBox(height: 15),

            // ── Ingredients (max 10) ────────────────────────────────
            Text('Ingredients', style: _labelStyle(colors)),
            const SizedBox(height: 4),
            Text(
              'Add up to 10 major ingredients. These appear on the menu card.',
              style: TextStyle(color: colors.textSecondary, fontSize: 10),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ingredientInput,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Paneer, Onion, Capsicum',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addIngredient(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed:
                      _ingredients.length >= 10 ? null : _addIngredient,
                  child: const Text('Add'),
                ),
              ],
            ),
            if (_ingredients.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final ing in _ingredients)
                    Chip(
                      label: Text(ing, style: const TextStyle(fontSize: 11)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () =>
                          setState(() => _ingredients.remove(ing)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${_ingredients.length}/10 ingredients',
              style: TextStyle(color: colors.textMuted, fontSize: 10),
            ),

            const SizedBox(height: 15),
            _field(
              'Description',
              _description,
              maxLines: 3,
              hint: 'Optional longer description...',
            ),
            const SizedBox(height: 15),
            _field('Image URL', _image, hint: 'Paste an image URL'),
          ]),
          const SizedBox(height: 16),
          _panel(colors, 'Item Details', Icons.assignment_outlined, [
            Row(children: [
              Expanded(
                child: _dropdown(
                  'Dietary Type',
                  _dietaryType,
                  DietaryType.values,
                  (value) => setState(() => _dietaryType = value!),
                  (value) => _titleCase(value.name),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _dropdown(
                  'Preparation Style',
                  _preparationStyle,
                  PreparationStyle.values,
                  (value) => setState(() => _preparationStyle = value!),
                  (value) => _titleCase(value.name),
                ),
              ),
            ]),
            const SizedBox(height: 15),
            Row(children: [
              Expanded(
                child: _dropdown(
                  'Spice Level',
                  _spiceLevel,
                  _spiceOptions,
                  (value) => setState(() => _spiceLevel = value),
                  (value) => value,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _dropdown(
                  'Serving Size',
                  _servingSize,
                  _servingOptions,
                  (value) => setState(() => _servingSize = value),
                  (value) => value,
                ),
              ),
            ]),
          ]),
          const SizedBox(height: 16),
          _panel(colors, 'Organization', Icons.account_tree_outlined, [
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
              const SizedBox(width: 14),
              Expanded(
                child: _dropdown(
                  'Subcategory',
                  _subcategory,
                  _subcategories.map((item) => item.id).toList(),
                  (value) => setState(() => _subcategory = value),
                  _categoryLabel,
                  hint: 'Select subcategory (optional)',
                ),
              ),
            ]),
            const SizedBox(height: 15),
            Text('Tags', style: _labelStyle(colors)),
            const SizedBox(height: 7),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in _tagOptions) _tagChip(colors, tag),
              ],
            ),
          ]),
          const SizedBox(height: 16),
          _panel(colors, 'Display Settings', Icons.desktop_windows_outlined, [
            Row(children: [
              Expanded(
                child: _switch(
                  colors,
                  'Available on Menu',
                  'Make this item available for ordering',
                  _available,
                  (value) => setState(() => _available = value),
                ),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: _switch(
                  colors,
                  'Featured Item',
                  'Highlight this item in the menu',
                  _featured,
                  (value) => setState(() => _featured = value),
                ),
              ),
            ]),
          ]),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1EA),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: Add high quality images and detailed descriptions to attract more customers.',
                    style: TextStyle(color: Color(0xFF9B5B3A), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _preview(AppColorScheme colors) => _panel(
        colors,
        'Preview',
        Icons.visibility_outlined,
        [
          Container(
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _image.text.trim().isEmpty
                ? const Icon(Icons.restaurant,
                    size: 48, color: Color(0xFFFFD4BF))
                : Image.network(
                    _image.text.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.restaurant,
                      size: 48,
                      color: Color(0xFFFFD4BF),
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            _name.text.trim().isEmpty ? 'Item Name' : _name.text.trim(),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _ingredients.isEmpty
                ? 'Ingredients will appear here as comma separated.'
                : _ingredients.join(', '),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '₹${_price.text.trim().isEmpty ? '0.00' : _price.text.trim()}',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _dietaryBadge(colors),
        ],
      );

  Widget _panel(
    AppColorScheme colors,
    String title,
    IconData icon,
    List<Widget> children,
  ) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: colors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      );

  Widget _field(
    String label,
    TextEditingController controller, {
    bool required = false,
    int maxLines = 1,
    String? hint,
    TextInputType? keyboard,
    String? prefix,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          prefixText: prefix,
          counterText:
              maxLines > 1 ? '${controller.text.length}/250' : null,
        ),
        validator: required
            ? (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null
            : null,
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
      DropdownButtonFormField<T>(
        value: values.contains(value) ? value : null,
        decoration:
            InputDecoration(labelText: required ? '$label *' : label),
        hint: Text(hint ?? 'Select $label'.toLowerCase()),
        items: values
            .map((v) =>
                DropdownMenuItem(value: v, child: Text(labelFor(v))))
            .toList(),
        onChanged: onChanged,
      );

  Widget _switch(
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
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style:
                      TextStyle(color: colors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      );

  Widget _tagChip(AppColorScheme colors, String tag) => FilterChip(
        label: Text(tag, style: const TextStyle(fontSize: 10)),
        selected: _tags.contains(tag),
        onSelected: (selected) => setState(() {
          if (selected) {
            _tags.add(tag);
          } else {
            _tags.remove(tag);
          }
        }),
      );

  Widget _dietaryBadge(AppColorScheme colors) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEFFAF2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.circle, size: 8, color: Colors.green),
            const SizedBox(width: 5),
            Text(
              _titleCase(_dietaryType.name),
              style: const TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  Widget _errorBanner(AppColorScheme colors) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        color: const Color(0xFFFFEDEA),
        child: Text(
          _error!,
          style: const TextStyle(color: AppColors.danger, fontSize: 12),
        ),
      );

  TextStyle _labelStyle(AppColorScheme colors) => TextStyle(
        color: colors.textPrimary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      );

  String _categoryLabel(String id) => MenuTaxonomy.nameFor(id);

  String _titleCase(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .map((part) => part.isEmpty
          ? part
          : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}