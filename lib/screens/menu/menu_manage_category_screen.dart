import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rdx_admin/widgets/dialogs/category_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_table.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/category_model.dart';
import '../../models/preparation_model.dart';
import '../../models/regionality_model.dart';
import '../../models/tag_model.dart';
import '../../services/category_service.dart';
import '../../services/preparation_service.dart';
import '../../services/regionality_service.dart';
import '../../services/tag_service.dart';
import '../../widgets/dialogs/rdx_delete_dialog.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';
import '../../widgets/buttons/rdx_header_action_button.dart';
import '../../widgets/reusable_widgets/empty_state.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';

enum _CategorySection { category, preparation, regionality, tag }

/// "View all" screen for managing Category, Preparation Style,
/// Regionality, and Tag entries in one place. Editing reuses the same
/// dialog used to create each entry; deleting shows [RdxDeleteDialog].
///
/// Every create/edit/delete on THIS screen is immediate — unlike the
/// dropdown "+" on [CreateMenuScreen], where Regionality and Preparation
/// are deferred until the menu item form itself is saved. Here, all four
/// category types are standalone entities managed independently of any
/// menu item, so they persist to Firestore right away.
///
/// Tables keep the same layout at every screen size and scroll horizontally
/// when their minimum column widths exceed the available space.
class MenuManageCategoryScreen extends StatefulWidget {
  const MenuManageCategoryScreen({super.key});

  @override
  State<MenuManageCategoryScreen> createState() =>
      _MenuManageCategoryScreenState();
}

class _MenuManageCategoryScreenState extends State<MenuManageCategoryScreen> {
  final _categoryService = CategoryService();
  final _preparationService = PreparationService();
  final _regionalityService = RegionalityService();
  final _tagService = TagService();

  _CategorySection _section = _CategorySection.category;
  bool _loading = true;
  String? _error;
  final Map<String, String> _streamErrors = {};

  List<CategoryModel> _categories = [];
  List<PreparationModel> _preparations = [];
  List<RegionalityModel> _regionalities = [];
  List<TagModel> _tags = [];
  int _loadGeneration = 0;
  StreamSubscription<List<CategoryModel>>? _categoriesSubscription;
  StreamSubscription<List<PreparationModel>>? _preparationsSubscription;
  StreamSubscription<List<RegionalityModel>>? _regionalitiesSubscription;
  StreamSubscription<List<TagModel>>? _tagsSubscription;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final generation = ++_loadGeneration;
    final subscriptions = [
      _categoriesSubscription,
      _preparationsSubscription,
      _regionalitiesSubscription,
      _tagsSubscription,
    ];
    _categoriesSubscription = null;
    _preparationsSubscription = null;
    _regionalitiesSubscription = null;
    _tagsSubscription = null;

    setState(() {
      _loading = true;
      _error = null;
      _streamErrors.clear();
    });
    for (final subscription in subscriptions) {
      if (subscription != null) await subscription.cancel();
    }
    if (!mounted || generation != _loadGeneration) return;

    late final StreamSubscription<List<CategoryModel>> categoriesSubscription;
    categoriesSubscription = _categoryService.streamCategories().listen(
      (categories) {
        if (!mounted ||
            !identical(_categoriesSubscription, categoriesSubscription)) {
          return;
        }
        setState(() {
          _categories = _sortedByName(categories, (category) => category.name);
          _streamErrors.remove('categories');
          _refreshStreamError();
          _loading = false;
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        _handleStreamError(
          categoriesSubscription,
          _categoriesSubscription,
          'categories',
          error,
          stackTrace,
        );
      },
    );
    _categoriesSubscription = categoriesSubscription;

    late final StreamSubscription<List<PreparationModel>>
        preparationsSubscription;
    preparationsSubscription = _preparationService.streamPreparations().listen(
      (preparations) {
        if (!mounted ||
            !identical(_preparationsSubscription, preparationsSubscription)) {
          return;
        }
        setState(() {
          _preparations =
              _sortedByName(preparations, (preparation) => preparation.name);
          _streamErrors.remove('preparation styles');
          _refreshStreamError();
          _loading = false;
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        _handleStreamError(
          preparationsSubscription,
          _preparationsSubscription,
          'preparation styles',
          error,
          stackTrace,
        );
      },
    );
    _preparationsSubscription = preparationsSubscription;

    late final StreamSubscription<List<RegionalityModel>>
        regionalitiesSubscription;
    regionalitiesSubscription =
        _regionalityService.streamRegionalities().listen(
      (regionalities) {
        if (!mounted ||
            !identical(_regionalitiesSubscription, regionalitiesSubscription)) {
          return;
        }
        setState(() {
          _regionalities =
              _sortedByName(regionalities, (regionality) => regionality.name);
          _streamErrors.remove('regionalities');
          _refreshStreamError();
          _loading = false;
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        _handleStreamError(
          regionalitiesSubscription,
          _regionalitiesSubscription,
          'regionalities',
          error,
          stackTrace,
        );
      },
    );
    _regionalitiesSubscription = regionalitiesSubscription;

    late final StreamSubscription<List<TagModel>> tagsSubscription;
    tagsSubscription = _tagService.streamTags().listen(
      (tags) {
        if (!mounted || !identical(_tagsSubscription, tagsSubscription)) {
          return;
        }
        setState(() {
          _tags = _sortedByName(tags, (tag) => tag.name);
          _streamErrors.remove('tags');
          _refreshStreamError();
          _loading = false;
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        _handleStreamError(
          tagsSubscription,
          _tagsSubscription,
          'tags',
          error,
          stackTrace,
        );
      },
    );
    _tagsSubscription = tagsSubscription;
  }

  void _handleStreamError(
    StreamSubscription<dynamic> subscription,
    StreamSubscription<dynamic>? activeSubscription,
    String collectionName,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint(
      'MenuManageCategoryScreen $collectionName stream failed: '
      '$error\n$stackTrace',
    );
    if (!mounted || !identical(activeSubscription, subscription)) return;
    setState(() {
      _loading = false;
      _streamErrors[collectionName] =
          'Failed to receive live $collectionName updates.';
      _refreshStreamError();
    });
  }

  void _refreshStreamError() {
    _error = _streamErrors.values.isEmpty ? null : _streamErrors.values.first;
  }

  @override
  void dispose() {
    final subscriptions = [
      _categoriesSubscription,
      _preparationsSubscription,
      _regionalitiesSubscription,
      _tagsSubscription,
    ];
    for (final subscription in subscriptions) {
      if (subscription != null) unawaited(subscription.cancel());
    }
    super.dispose();
  }

  // ─── Category actions ─────────────────────────────────────────────

  // ─── Category actions ─────────────────────────────────────────────

  Future<void> _createCategory() async {
    final created = await CategoryEntryDialog.show<CategoryModel>(
      context,
      title: 'Create Category',
      editTitle: 'Edit Category',
      nameLabel: 'Category Name *',
      nameHint: 'e.g. Beverages',
      initialSubItems: const [],
      // One text field at a time — user can add as many subcategories as needed.
      subItemsLabel: 'Subcategories (optional)',
      subItemHintBuilder: (_) => 'Add a subcategory and press Add',
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
    setState(
      () =>
          _categories = _sortedByName([..._categories, created], (c) => c.name),
    );
  }

  Future<void> _editCategory(CategoryModel category) async {
    final updated = await CategoryEntryDialog.show<CategoryModel>(
      context,
      title: 'Create Category',
      editTitle: 'Edit Category',
      nameLabel: 'Category Name *',
      nameHint: 'e.g. Beverages',
      initialName: category.name,
      initialSubItems: category.subcategories.map((s) => s.name).toList(),
      // One text field at a time — user can add as many subcategories as needed.
      subItemsLabel: 'Subcategories (optional)',
      subItemHintBuilder: (_) => 'Add a subcategory and press Add',
      onSave: (name, subNames) async {
        final updated = CategoryModel(
          id: category.id,
          name: name,
          subcategories: [
            for (final subName in subNames)
              SubcategoryModel(
                id: '${category.id}-${subName.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}',
                name: subName,
              ),
          ],
        );
        await _categoryService.updateCategory(updated);
        return updated;
      },
    );
    if (updated == null || !mounted) return;
    setState(() {
      _categories = _sortedByName(
        [
          for (final item in _categories)
            if (item.id == updated.id) updated else item,
        ],
        (c) => c.name,
      );
    });
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Category',
        itemName: category.name,
        itemDetails: category.subcategories.isEmpty
            ? const []
            : [
                Text(
                  '${category.subcategories.length} subcategor${category.subcategories.length == 1 ? 'y' : 'ies'}',
                  style: AppTextStyles.body(context).copyWith(color: AppColors.of(context).textSecondary,
                  ),
                ),
              ],
        deleteButtonLabel: 'Delete Category',
        warningMessage:
            'Deleting this category also removes all of its subcategories. '
            'Menu items using it will keep the old category name until '
            're-saved.',
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

  // ─── Preparation actions ──────────────────────────────────────────

  // ─── Preparation actions ──────────────────────────────────────────

  Future<void> _createPreparation() async {
    final created = await CategoryEntryDialog.show<PreparationModel>(
      context,
      title: 'Add Preparation Style',
      nameLabel: 'Preparation Style',
      nameHint: 'e.g. Tandoori',
      description:
          'e.g. Tandoori, Gravy, Steam. Saved right away for use across items.',
      onSave: (name, _) => _preparationService.createPreparation(name: name),
    );
    if (created == null || !mounted) return;
    setState(
      () => _preparations =
          _sortedByName([..._preparations, created], (p) => p.name),
    );
  }

  Future<void> _editPreparation(PreparationModel preparation) async {
    final updated = await CategoryEntryDialog.show<PreparationModel>(
      context,
      title: 'Add Preparation Style',
      editTitle: 'Edit Preparation Style',
      nameLabel: 'Preparation Style',
      nameHint: 'e.g. Tandoori',
      initialName: preparation.name,
      onSave: (name, _) async {
        final updated = PreparationModel(id: preparation.id, name: name);
        await _preparationService.updatePreparation(updated);
        return updated;
      },
    );
    if (updated == null || !mounted) return;
    setState(() {
      _preparations = _sortedByName(
        [
          for (final item in _preparations)
            if (item.id == updated.id) updated else item,
        ],
        (p) => p.name,
      );
    });
  }

  Future<void> _deletePreparation(PreparationModel preparation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Preparation Style',
        itemName: preparation.name,
        deleteButtonLabel: 'Delete',
        warningMessage:
            'Deleting this preparation style will permanently remove it. '
            'Menu items using it will keep the old name until re-saved.',
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _preparationService.deletePreparation(preparation.id);
      if (!mounted) return;
      setState(() {
        _preparations =
            _preparations.where((p) => p.id != preparation.id).toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete preparation style.')),
      );
    }
  }

  // ─── Regionality actions ────────────────────────────────────────────
  //
  // Same immediate create/edit/delete contract as Preparation above.
  // This is the only place a regionality can be edited or deleted; the
  // "+ Add regionality" flow on CreateMenuScreen only ever *creates* one,
  // and only persists it once the menu item form is saved.

  // ─── Regionality actions ────────────────────────────────────────────

  Future<void> _createRegionality() async {
    final created = await CategoryEntryDialog.show<RegionalityModel>(
      context,
      title: 'Add Regionality',
      nameLabel: 'Regionality',
      nameHint: 'e.g. Punjabi',
      description:
          'e.g. Punjabi, Indo-Chinese, South Indian. Saved right away for use across items.',
      onSave: (name, _) => _regionalityService.createRegionality(name: name),
    );
    if (created == null || !mounted) return;
    setState(
      () => _regionalities =
          _sortedByName([..._regionalities, created], (r) => r.name),
    );
  }

  Future<void> _editRegionality(RegionalityModel regionality) async {
    final updated = await CategoryEntryDialog.show<RegionalityModel>(
      context,
      title: 'Add Regionality',
      editTitle: 'Edit Regionality',
      nameLabel: 'Regionality',
      nameHint: 'e.g. Punjabi',
      initialName: regionality.name,
      onSave: (name, _) async {
        final updated = RegionalityModel(id: regionality.id, name: name);
        await _regionalityService.updateRegionality(updated);
        return updated;
      },
    );
    if (updated == null || !mounted) return;
    setState(() {
      _regionalities = _sortedByName(
        [
          for (final item in _regionalities)
            if (item.id == updated.id) updated else item,
        ],
        (r) => r.name,
      );
    });
  }

  Future<void> _deleteRegionality(RegionalityModel regionality) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Regionality',
        itemName: regionality.name,
        deleteButtonLabel: 'Delete',
        warningMessage:
            'Deleting this regionality will permanently remove it. Menu '
            'items using it will keep the old name until re-saved.',
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _regionalityService.deleteRegionality(regionality.id);
      if (!mounted) return;
      setState(() {
        _regionalities =
            _regionalities.where((r) => r.id != regionality.id).toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete regionality.')),
      );
    }
  }

  // ─── Tag actions ───────────────────────────────────────────────────

  // ─── Tag actions ───────────────────────────────────────────────────

  Future<void> _createTag() async {
    if (_tags.length >= TagService.maxCustomTags) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(
      //       'You can only create up to ${TagService.maxCustomTags} custom tags.',
      //     ),
      //   ),
      // );
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
    setState(() => _tags = _sortedByName([..._tags, created], (t) => t.name));
  }

  Future<void> _editTag(TagModel tag) async {
    final updated = await CategoryEntryDialog.show<TagModel>(
      context,
      title: 'Create Tag',
      editTitle: 'Edit Tag',
      nameLabel: 'Tag Name',
      nameHint: "e.g. Chef's Special",
      initialName: tag.name,
      onSave: (name, _) async {
        final updated = TagModel(id: tag.id, name: name);
        await _tagService.updateTag(updated);
        return updated;
      },
    );
    if (updated == null || !mounted) return;
    setState(() {
      _tags = _sortedByName(
        [
          for (final item in _tags)
            if (item.id == updated.id) updated else item,
        ],
        (t) => t.name,
      );
    });
  }

  Future<void> _deleteTag(TagModel tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Tag',
        itemName: tag.name,
        deleteButtonLabel: 'Delete',
        warningMessage:
            'Deleting this tag will permanently remove it. Menu items '
            'using it will keep showing it until re-saved.',
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _tagService.deleteTag(tag.id);
      if (!mounted) return;
      setState(() => _tags = _tags.where((t) => t.id != tag.id).toList());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete tag.')),
      );
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────

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
            title: 'Manage Category',
            showBackButton: true,
          ),
          SizedBox(height: context.h(isNarrow ? 10 : 14)),
          // Tabs + Add button on the same row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: _tabsAndAddRow(context, colors),
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
                          context.h(0),
                          horizontal,
                          context.h(20),
                        ),
                        child: _sectionContent(context, colors),
                      ),
          ),
        ],
      ),
    );
  }

  /// Tabs on the left (scrollable) + the current section’s “+ Add” button on the right.
  Widget _tabsAndAddRow(BuildContext context, AppColorScheme colors) {
    return Row(
      children: [
        Expanded(child: _sectionTabs(context, colors)),
        SizedBox(width: context.w(8)),
        _currentAddButton(context),
      ],
    );
  }

  Widget _sectionTabs(BuildContext context, AppColorScheme colors) {
    final entries = <_CategorySection, String>{
      _CategorySection.category: 'Categories',
      _CategorySection.preparation: 'Preparation Styles',
      _CategorySection.regionality: 'Regionalities',
      _CategorySection.tag: 'Tags',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in entries.entries) ...[
            _sectionTab(context, colors, entry.key, entry.value),
            SizedBox(width: context.w(8)),
          ],
        ],
      ),
    );
  }

  Widget _sectionTab(
    BuildContext context,
    AppColorScheme colors,
    _CategorySection section,
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
          style: AppTextStyles.bodySemi(context).copyWith(color: selected ? AppColors.white : colors.textPrimary),
        ),
      ),
    );
  }

  Widget _currentAddButton(BuildContext context) {
    final (String label, VoidCallback onTap) = switch (_section) {
      _CategorySection.category => ('Add category', _createCategory),
      _CategorySection.preparation => (
          'Add preparation style',
          _createPreparation
        ),
      _CategorySection.regionality => ('Add regionality', _createRegionality),
      _CategorySection.tag => ('Add tag', _createTag),
    };

    return RdxHeaderActionButton(
      label: label,
      onPressed: onTap,
    );
  }

  Widget _sectionContent(
    BuildContext context,
    AppColorScheme colors,
  ) {
    switch (_section) {
      case _CategorySection.category:
        return _categorySection(context, colors);
      case _CategorySection.preparation:
        return _preparationSection(context);
      case _CategorySection.regionality:
        return _regionalitySection(context);
      case _CategorySection.tag:
        return _tagSection(context);
    }
  }

  // ─── Categories ─────────────────────────────────────────────────────

  Widget _categorySection(
    BuildContext context,
    AppColorScheme colors,
  ) {
    return _categories.isEmpty
        ? const EmptyState(message: 'No categories yet.')
        : _categoryTable(context, colors);
  }

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

  /// Formats subcategory names for the table in alphabetical order, up to 8
  /// per line.
  String _formatSubcategories(List<SubcategoryModel> subs) {
    if (subs.isEmpty) return '—';
    final names =
        _sortedByName(subs, (s) => s.name).map((s) => s.name).toList();
    final lines = <String>[];
    for (var i = 0; i < names.length; i += 8) {
      final end = i + 8 > names.length ? names.length : i + 8;
      lines.add(names.sublist(i, end).join(', '));
    }
    return lines.join('\n');
  }

  Widget _categoryTable(BuildContext context, AppColorScheme colors) {
    return RdxTable(
      columns: [
        RdxTableColumn(title: 'Category', minWidth: context.w(180), flex: 2),
        RdxTableColumn(title: 'Subcategories', minWidth: context.w(200), flex: 3),
        RdxTableColumn(
          title: 'Actions',
          minWidth: context.w(90),
          alignment: Alignment.centerRight,
        ),
      ],
      rows: [
        for (final category in _categories)
          [
            Text(category.name, style: AppTextStyles.body(context)),
            Text(
              category.subcategories.isEmpty
                  ? '—'
                  : _formatSubcategories(category.subcategories),
              style: AppTextStyles.body(context)
                  .copyWith(color: colors.textSecondary),
            ),
            _actionsCell(
              onEdit: () => _editCategory(category),
              onDelete: () => _deleteCategory(category),
            ),
          ],
      ],
    );
  }

  // ─── Preparation ────────────────────────────────────────────────────

  Widget _preparationSection(BuildContext context) {
    return _preparations.isEmpty
        ? const EmptyState(message: 'No preparation styles yet.')
        : _preparationTable(context);
  }

  Widget _preparationTable(BuildContext context) {
    return RdxTable(
      columns: [
        RdxTableColumn(title: 'Preparation Style', minWidth: context.w(220), flex: 3),
        RdxTableColumn(
          title: 'Actions',
          minWidth: context.w(90),
          alignment: Alignment.centerRight,
        ),
      ],
      rows: [
        for (final preparation in _preparations)
          [
            Text(preparation.name, style: AppTextStyles.body(context)),
            _actionsCell(
              onEdit: () => _editPreparation(preparation),
              onDelete: () => _deletePreparation(preparation),
            ),
          ],
      ],
    );
  }

  // ─── Regionality ────────────────────────────────────────────────────

  Widget _regionalitySection(BuildContext context) {
    return _regionalities.isEmpty
        ? const EmptyState(message: 'No regionalities yet.')
        : _regionalityTable(context);
  }

  Widget _regionalityTable(BuildContext context) {
    return RdxTable(
      columns: [
        RdxTableColumn(title: 'Regionality', minWidth: context.w(220), flex: 3),
        RdxTableColumn(
          title: 'Actions',
          minWidth: context.w(90),
          alignment: Alignment.centerRight,
        ),
      ],
      rows: [
        for (final regionality in _regionalities)
          [
            Text(regionality.name, style: AppTextStyles.body(context)),
            _actionsCell(
              onEdit: () => _editRegionality(regionality),
              onDelete: () => _deleteRegionality(regionality),
            ),
          ],
      ],
    );
  }

  // ─── Tags ───────────────────────────────────────────────────────────

  Widget _tagSection(
    BuildContext context,
  ) {
    if (_tags.isEmpty) {
      return const EmptyState(message: 'No custom tags yet.');
    }
    return _tagTable(context);
  }

  Widget _tagTable(BuildContext context) {
    return RdxTable(
      columns: [
        RdxTableColumn(title: 'Tag', minWidth: context.w(200), flex: 3),
        RdxTableColumn(
          title: 'Actions',
          minWidth: context.w(90),
          alignment: Alignment.centerRight,
        ),
      ],
      rows: [
        for (final tag in _tags)
          [
            Text(tag.name, style: AppTextStyles.body(context)),
            _actionsCell(
              onEdit: () => _editTag(tag),
              onDelete: () => _deleteTag(tag),
            ),
          ],
      ],
    );
  }

  Widget _actionsCell({
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
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
