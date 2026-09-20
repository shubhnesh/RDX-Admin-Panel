import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/screens/menu/menu_manage_category_screen.dart';
import 'package:rdx_admin/screens/menu/widgets/menu_item_card.dart';
import 'package:rdx_admin/widgets/dialogs/category_dialog.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/category_model.dart';
import '../../models/menu_item_model.dart';
import '../../models/preparation_model.dart';
import '../../models/regionality_model.dart';
import '../../models/tag_model.dart';
import '../../providers/menu_provider.dart';
import '../../services/category_service.dart';
import '../../services/preparation_service.dart';
import '../../services/regionality_service.dart';
import '../../services/tag_service.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/resuable_options/rdx_dropdown.dart';
import '../../widgets/resuable_options/rdx_text_field.dart';
import '../../widgets/buttons/rdx_toggle_button.dart';

/// Sentinel value placed as the first entry in the category dropdown.
/// Selecting it opens [CreateCategoryDialog] instead of setting a category.
const String _kCreateCategoryValue = '__create_category__';

/// Sentinel value placed as the first entry in the regionality dropdown.
/// Selecting it opens [CreateRegionalityDialog].
const String _kCreateRegionalityValue = '__create_regionality__';

/// Local-only ID used to represent a regionality the user just typed but
/// that hasn't been written to Firestore yet. It's swapped for a real
/// slug ID (via [RegionalityService.createRegionality]) at save time.
const String _kPendingRegionalityId = '__pending_regionality__';

/// Sentinel value placed as the first entry in the preparation dropdown.
/// Selecting it opens [CreatePreparationDialog].
const String _kCreatePreparationValue = '__create_preparation__';

/// Local-only ID for a preparation style typed but not yet persisted —
/// same deferred-creation contract as [_kPendingRegionalityId].
const String _kPendingPreparationId = '__pending_preparation__';

class CreateMenuScreen extends ConsumerStatefulWidget {
  final String? itemId;
  const CreateMenuScreen({super.key, this.itemId});

  @override
  ConsumerState<CreateMenuScreen> createState() => _CreateMenuScreenState();
}

class _CreateMenuScreenState extends ConsumerState<CreateMenuScreen> {
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
  String? _preparation;
  final Set<String> _tags = {};
  final List<String> _ingredients = [];
  bool _available = true;
  bool _loading = false;
  String? _error;

  final _categoryService = CategoryService();
  List<CategoryModel> _categories = [];
  bool _categoriesLoading = true;

  final _regionalityService = RegionalityService();
  List<RegionalityModel> _regionalities = [];
  bool _regionalitiesLoading = true;
  String? _regionality;

  /// Name typed into the regionality dialog, held locally and only
  /// written to Firestore (via [RegionalityService.createRegionality])
  /// when the menu item itself is saved.
  String? _pendingRegionalityName;

  final _preparationService = PreparationService();
  List<PreparationModel> _preparations = [];
  bool _preparationsLoading = true;

  /// Name typed into the preparation dialog, held locally and only
  /// written to Firestore (via [PreparationService.createPreparation])
  /// when the menu item itself is saved. Same contract as
  /// [_pendingRegionalityName].
  String? _pendingPreparationName;

  final _tagService = TagService();
  List<TagModel> _customTags = [];
  bool _customTagsLoading = true;

  static const _tagOptions = [
    'Featured',
    'Bestseller',
    'New',
    'Popular',
  ];

  bool get _editing => widget.itemId != null;

  List<SubcategoryModel> get _subcategories {
    if (_primaryCategory == null) return [];
    final category =
        _categories.where((item) => item.id == _primaryCategory).toList();
    return category.isEmpty ? [] : category.first.subcategories;
  }

  Future<void> _loadCategories() async {
    setState(() => _categoriesLoading = true);
    try {
      final categories = await _categoryService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _categoriesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _categoriesLoading = false);
    }
  }

  Future<void> _loadRegionalities() async {
    setState(() => _regionalitiesLoading = true);
    try {
      final regionalities = await _regionalityService.fetchRegionalities();
      if (!mounted) return;
      setState(() {
        _regionalities = regionalities;
        _regionalitiesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _regionalitiesLoading = false);
    }
  }

  Future<void> _openCreateCategoryDialog() async {
    final created = await CategoryEntryDialog.show<CategoryModel>(
      context,
      title: 'Create Category',
      editTitle: 'Edit Category',
      nameLabel: 'Category Name *',
      nameHint: 'e.g. Beverages',
      initialSubItems: const [],
      maxSubItems: CategoryService.maxSubcategories,
      subItemsLabel:
          'Subcategories (optional, up to ${CategoryService.maxSubcategories})',
      subItemHintBuilder: (i) => 'Subcategory ${i + 1}',
      onSave: (name, subNames) async {
        final id = await _categoryService.createCategory(
          name: name,
          subcategoryNames: subNames,
        );
        return CategoryModel(
          id: id,
          name: name,
          subcategories: [
            for (final subName in subNames)
              SubcategoryModel(id: subName, name: subName),
          ],
        );
      },
    );
    if (created == null || !mounted) return;
    setState(() {
      _categories = [..._categories, created];
      _primaryCategory = created.id;
      _subcategory = null;
    });
  }

  Future<void> _openCreateRegionalityDialog() async {
    final enteredName = await CategoryEntryDialog.show<String>(
      context,
      title: 'Add Regionality',
      nameLabel: 'Regionality',
      nameHint: 'e.g. Punjabi',
      description: 'e.g. Punjabi, Indo-Chinese, South Indian. Saved along '
          'with this item once you submit the form.',
      initialName: _pendingRegionalityName,
      // Local-only: no service call here, the menu item form persists it
      // once the item itself is saved.
      onSave: (name, _) async => name,
    );
    if (enteredName == null || enteredName.trim().isEmpty || !mounted) return;

    setState(() {
      _pendingRegionalityName = enteredName.trim();
      _regionality = _kPendingRegionalityId;
    });
  }

  Future<void> _openCreatePreparationDialog() async {
    final enteredName = await CategoryEntryDialog.show<String>(
      context,
      title: 'Add Preparation Style',
      editTitle: 'Edit Preparation Style',
      nameLabel: 'Preparation Style',
      nameHint: 'e.g. Tandoori',
      description: 'e.g. Tandoori, Gravy, Steam. Saved along with this '
          'item once you submit the form.',
      initialName: _pendingPreparationName,
      onSave: (name, _) async => name,
    );
    if (enteredName == null || enteredName.trim().isEmpty || !mounted) return;

    setState(() {
      _pendingPreparationName = enteredName.trim();
      _preparation = _kPendingPreparationId;
    });
  }

  Future<void> _openCreateTagDialog() async {
    if (_customTags.length >= TagService.maxCustomTags) {
      setState(
        () => _error =
            'You can only create up to ${TagService.maxCustomTags} custom tags.',
      );
      return;
    }

    final created = await CategoryEntryDialog.show<TagModel>(
      context,
      title: 'Create Tag',
      nameLabel: 'Tag Name',
      nameHint: "e.g. Chef's Special",
      description:
          'Custom tags are saved right away so they can be reused on other items.',
      onSave: (name, _) => _tagService.createTag(name: name),
    );
    if (created == null || !mounted) return;

    setState(() {
      _customTags = [..._customTags, created];
      _tags.add(created.name);
    });
  }

//Fetching options is done in parallel, so they can fail independently.

  Future<void> _loadPreparations() async {
    setState(() => _preparationsLoading = true);
    try {
      final preparations = await _preparationService.fetchPreparations();
      if (!mounted) return;
      setState(() {
        _preparations = preparations;
        _preparationsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _preparationsLoading = false);
    }
  }

  Future<void> _loadCustomTags() async {
    setState(() => _customTagsLoading = true);
    try {
      final tags = await _tagService.fetchTags();
      if (!mounted) return;
      setState(() {
        _customTags = tags;
        _customTagsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _customTagsLoading = false);
    }
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
      preparationId: _preparation ?? '',
      preparation: _preparationLabel(_preparation),
      price: price,
      category: _primaryCategory == null
          ? 'Category'
          : _categoryLabel(_primaryCategory!),
      subCategoryId: _subcategory ?? '',
      subCategory: _subcategory == null ? '' : _categoryLabel(_subcategory!),
      regionalityId: _regionality ?? '',
      regionality: _regionalityLabel(_regionality),
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
    _loadCategories();
    _loadRegionalities();
    _loadPreparations();
    _loadCustomTags();
    if (_editing) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final item = await ref.read(menuProvider).getItemById(widget.itemId!);
      _name.text = item.name;
      _description.text = item.description;
      _image.text = item.imageUrl;
      _price.text = item.price.toString();
      _sortOrder.text = item.sortOrder.toString();
      _primaryCategory = item.primaryCategoryId;
      _subcategory = item.subCategoryId.isEmpty ? null : item.subCategoryId;
      _regionality = item.regionalityId.isEmpty ? null : item.regionalityId;
      _pendingRegionalityName = null;
      _dietaryType = item.dietaryType;
      _preparation = item.preparationId.isEmpty ? null : item.preparationId;
      _pendingPreparationName = null;
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
    if (_dietaryType == null || _preparation == null) {
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

    // A regionality typed via the dialog is only held locally until now —
    // persist it (and swap the pending marker for the real ID) right
    // before the menu item itself is written.
    var regionalityId = _regionality ?? '';
    var regionalityName = _regionalityLabel(_regionality);

    if (_regionality == _kPendingRegionalityId &&
        _pendingRegionalityName != null &&
        _pendingRegionalityName!.trim().isNotEmpty) {
      try {
        final created = await _regionalityService.createRegionality(
          name: _pendingRegionalityName!,
        );
        regionalityId = created.id;
        regionalityName = created.name;
        if (mounted) {
          setState(() {
            _regionalities = [..._regionalities, created];
            _regionality = created.id;
            _pendingRegionalityName = null;
          });
        }
      } catch (_) {
        setState(() {
          _loading = false;
          _error = 'Failed to save regionality. Please try again.';
        });
        return;
      }
    }

    // Same deferred-creation handling for a preparation typed via its
    // dialog.
    var preparationId = _preparation ?? '';
    var preparationName = _preparationLabel(_preparation);

    if (_preparation == _kPendingPreparationId &&
        _pendingPreparationName != null &&
        _pendingPreparationName!.trim().isNotEmpty) {
      try {
        final created = await _preparationService.createPreparation(
          name: _pendingPreparationName!,
        );
        preparationId = created.id;
        preparationName = created.name;
        if (mounted) {
          setState(() {
            _preparations = [..._preparations, created];
            _preparation = created.id;
            _pendingPreparationName = null;
          });
        }
      } catch (_) {
        setState(() {
          _loading = false;
          _error = 'Failed to save preparation style. Please try again.';
        });
        return;
      }
    }

    final item = MenuItemModel(
      id: widget.itemId ?? '',
      name: _name.text.trim(),
      description: _description.text.trim(),
      imageUrl: _image.text.trim(),
      available: _available,
      featuredItem: _tags.contains('Featured'),
      sortOrder: int.tryParse(_sortOrder.text) ?? 0,
      dietaryType: _dietaryType!,
      preparationId: preparationId,
      preparation: preparationName,
      price: price,
      primaryCategoryId: _primaryCategory!,
      category: _categoryLabel(_primaryCategory!),
      subCategoryId: _subcategory ?? '',
      subCategory: _subcategory == null ? '' : _categoryLabel(_subcategory!),
      regionalityId: regionalityId,
      regionality: regionalityName,
      tags: _tags
          .where((tag) => tag != 'Featured')
          .map((tag) => tag.toLowerCase().replaceAll(' ', '_'))
          .toList(),
      ingredients: List<String>.from(_ingredients),
    );

    final success = await ref.read(menuProvider).saveItem(item);
    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _loading = false;
        _error =
            ref.read(menuProvider).errorMessage ?? 'Failed to save menu item.';
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
                                                    _preparation != null,
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
            hasTags: _tags.isNotEmpty || _preparation != null,
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
          _panel(
            context,
            colors,
            'Item Details',
            Icons.assignment_outlined,
            [
              LayoutBuilder(builder: (context, c) {
                final stack = c.maxWidth < 400;
                final cat = _dropdown(
                  'Category',
                  _primaryCategory,
                  [
                    _kCreateCategoryValue,
                    ..._categories.map((item) => item.id),
                  ],
                  (value) {
                    if (value == _kCreateCategoryValue) {
                      _openCreateCategoryDialog();
                      return;
                    }
                    setState(() {
                      _primaryCategory = value;
                      _subcategory = null;
                    });
                  },
                  _categoryLabel,
                  required: true,
                  searchable: true,
                  hint: _categoriesLoading
                      ? 'Loading categories...'
                      : 'Select category',
                );
                final sub = _dropdown(
                  'Subcategory',
                  _subcategory,
                  _subcategories.map((item) => item.id).toList(),
                  (value) => setState(() => _subcategory = value),
                  _categoryLabel,
                  searchable: true,
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
                final regionality = _dropdown(
                  'Regionality',
                  _regionality,
                  [
                    _kCreateRegionalityValue,
                    ..._regionalities.map((item) => item.id),
                    if (_pendingRegionalityName != null) _kPendingRegionalityId,
                  ],
                  (value) {
                    if (value == _kCreateRegionalityValue) {
                      _openCreateRegionalityDialog();
                      return;
                    }
                    setState(() {
                      _regionality = value;
                      if (value != _kPendingRegionalityId) {
                        _pendingRegionalityName = null;
                      }
                    });
                  },
                  _regionalityLabel,
                  searchable: true,
                  hint: _regionalitiesLoading
                      ? 'Loading regionalities...'
                      : 'Select regionality',
                );
                return regionality;
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
                  _preparation,
                  [
                    _kCreatePreparationValue,
                    ..._preparations.map((item) => item.id),
                    if (_pendingPreparationName != null) _kPendingPreparationId,
                  ],
                  (value) {
                    if (value == _kCreatePreparationValue) {
                      _openCreatePreparationDialog();
                      return;
                    }
                    setState(() {
                      _preparation = value;
                      if (value != _kPendingPreparationId) {
                        _pendingPreparationName = null;
                      }
                    });
                  },
                  _preparationLabel,
                  required: true,
                  searchable: true,
                  hint: _preparationsLoading
                      ? 'Loading preparation styles...'
                      : 'Select preparation style',
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tags',
                      style: AppTextStyles.bodySecondary(context).copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _customTagsLoading ? null : _openCreateTagDialog,
                    borderRadius: BorderRadius.circular(context.h(6)),
                    child: Padding(
                      padding: EdgeInsets.all(context.w(2)),
                      child: Icon(
                        Icons.add_circle_outline_rounded,
                        size: context.h(18),
                        color: _customTagsLoading
                            ? colors.textMuted
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.h(7)),
              Wrap(
                spacing: context.w(8),
                runSpacing: context.h(8),
                children: [
                  for (final tag in _tagOptions) _tagChip(context, colors, tag),
                  for (final tag in _customTags)
                    _tagChip(context, colors, tag.name),
                ],
              ),
            ],
            headerTrailing: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MenuManageCategoryScreen(),
                  ),
                );
              },
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
          ),
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
    List<Widget> children, {
    Widget? headerTrailing,
  }) =>
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
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.section(context)
                        .copyWith(color: colors.textPrimary),
                  ),
                ),
                if (headerTrailing != null) headerTrailing,
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
    bool searchable = false,
  }) =>
      RdxDropdown<T>(
        label: required ? '$label *' : label,
        value: values.contains(value) ? value : null,
        items: values,
        labelBuilder: labelFor,
        hint: hint ?? 'Select $label',
        onChanged: onChanged,
        searchable: searchable,
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
          style: TextStyle(color: AppColors.danger),
        ),
      );

  String _categoryLabel(String id) {
    if (id == _kCreateCategoryValue) return '+ Create your category';

    final match = _categories.where((item) => item.id == id).toList();
    if (match.isNotEmpty) return match.first.name;

    final subMatch = _subcategories.where((item) => item.id == id).toList();
    if (subMatch.isNotEmpty) return subMatch.first.name;

    return id;
  }

  /// Label for the regionality dropdown. Handles the "create" sentinel,
  /// the not-yet-persisted pending entry, and normal saved regionalities.
  String _regionalityLabel(String? id) {
    if (id == null) return '';
    if (id == _kCreateRegionalityValue) return '+ Add regionality';
    if (id == _kPendingRegionalityId) {
      return _pendingRegionalityName ?? '';
    }

    final match = _regionalities.where((item) => item.id == id).toList();
    return match.isEmpty ? id : match.first.name;
  }

  /// Label for the preparation dropdown — same shape as
  /// [_regionalityLabel] (sentinel, pending entry, saved value).
  String _preparationLabel(String? id) {
    if (id == null) return '';
    if (id == _kCreatePreparationValue) return '+ Add preparation style';
    if (id == _kPendingPreparationId) {
      return _pendingPreparationName ?? '';
    }

    final match = _preparations.where((item) => item.id == id).toList();
    return match.isEmpty ? id : match.first.name;
  }

  String _titleCase(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .map((part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class _IngredientChip extends ConsumerWidget {
  final String label;
  final AppColorScheme colors;
  final VoidCallback onDeleted;

  const _IngredientChip({
    required this.label,
    required this.colors,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            style: AppTextStyles.bodyTertiary(context),
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
