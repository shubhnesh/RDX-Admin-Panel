import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category_model.dart';
import '../models/menu_item_model.dart';
import '../services/category_service.dart';
import '../services/menu_service.dart';

class MenuProvider extends ChangeNotifier {
  MenuProvider(this._service, {CategoryService? categoryService})
      : _categoryService = categoryService ?? CategoryService();

  final MenuService _service;
  final CategoryService _categoryService;

  List<MenuItemModel> _items = [];
  List<CategoryModel> _categoryList = [];
  StreamSubscription<List<MenuItemModel>>? _itemsSubscription;
  StreamSubscription<List<CategoryModel>>? _categoriesSubscription;
  bool _hasItemsSnapshot = false;
  bool _hasCategoriesSnapshot = false;
  String? _itemsError;
  String? _categoriesError;

  bool isLoading = false;
  String? errorMessage;

  String selectedCategory = 'All';
  String searchQuery = '';

  List<MenuItemModel> get items => List.unmodifiable(_items);

  /// Categories as fetched from the `menu_categories` collection, each
  /// carrying its own (optional) subcategories. No hardcoded category.
  List<CategoryModel> get categoryList => List.unmodifiable(_categoryList);

  List<String> get categories =>
      ['All', ..._categoryList.map((category) => category.name)];

  List<MenuItemModel> get filteredItems {
    final query = searchQuery.trim().toLowerCase();

    return _items.where((item) {
      final matchesCategory = selectedCategory == 'All' ||
          item.primaryCategoryId == _categoryId(selectedCategory);

      final matchesSearch = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  /// Starts the menu and category listeners once. Calling this again after
  /// navigation is harmless; a failed listener is restarted on retry.
  Future<void> load() {
    if (_itemsSubscription != null && _categoriesSubscription != null) {
      return Future<void>.value();
    }

    if (_itemsSubscription == null) _itemsError = null;
    if (_categoriesSubscription == null) _categoriesError = null;
    errorMessage = _itemsError ?? _categoriesError;
    isLoading =
        errorMessage == null && (!_hasItemsSnapshot || !_hasCategoriesSnapshot);
    notifyListeners();

    if (_itemsSubscription == null) {
      late final StreamSubscription<List<MenuItemModel>> subscription;
      subscription = _service.streamMenuItems().listen(
        _applyItemsSnapshot,
        onError: (Object error, StackTrace stackTrace) {
          _log('Menu item stream failed', error, stackTrace);
          if (identical(_itemsSubscription, subscription)) {
            _itemsSubscription = null;
          }
          unawaited(subscription.cancel());
          _setStreamError(
            'Unable to receive live menu item updates.',
            isItems: true,
          );
        },
        onDone: () {
          if (identical(_itemsSubscription, subscription)) {
            _itemsSubscription = null;
            _setStreamError(
              'Live menu item updates have stopped.',
              isItems: true,
            );
          }
        },
      );
      _itemsSubscription = subscription;
    }

    if (_categoriesSubscription == null) {
      late final StreamSubscription<List<CategoryModel>> subscription;
      subscription = _categoryService.streamCategories().listen(
        _applyCategoriesSnapshot,
        onError: (Object error, StackTrace stackTrace) {
          _log('Menu category stream failed', error, stackTrace);
          if (identical(_categoriesSubscription, subscription)) {
            _categoriesSubscription = null;
          }
          unawaited(subscription.cancel());
          _setStreamError(
            'Unable to receive live menu category updates.',
            isItems: false,
          );
        },
        onDone: () {
          if (identical(_categoriesSubscription, subscription)) {
            _categoriesSubscription = null;
            _setStreamError(
              'Live menu category updates have stopped.',
              isItems: false,
            );
          }
        },
      );
      _categoriesSubscription = subscription;
    }

    return Future<void>.value();
  }

  void _applyItemsSnapshot(List<MenuItemModel> snapshot) {
    final previousError = _itemsError;
    final previousById = {for (final item in _items) item.id: item};
    final updatedItems = snapshot.map((item) {
      final previous = previousById[item.id];
      return previous != null && _sameMenuItem(previous, item)
          ? previous
          : item;
    }).toList(growable: false);

    final unchanged = _hasItemsSnapshot &&
        updatedItems.length == _items.length &&
        List.generate(
          updatedItems.length,
          (index) => identical(updatedItems[index], _items[index]),
        ).every((same) => same);
    _hasItemsSnapshot = true;
    _itemsError = null;
    if (unchanged) {
      if (previousError != null) _refreshLoadingState();
      return;
    }

    _items = updatedItems;
    _refreshLoadingState();
  }

  void _applyCategoriesSnapshot(List<CategoryModel> snapshot) {
    final previousError = _categoriesError;
    final previousById = {for (final item in _categoryList) item.id: item};
    final updatedCategories = snapshot.map((category) {
      final previous = previousById[category.id];
      return previous != null && _sameCategory(previous, category)
          ? previous
          : category;
    }).toList(growable: false);
    final unchanged = _hasCategoriesSnapshot &&
        updatedCategories.length == _categoryList.length &&
        List.generate(
          updatedCategories.length,
          (index) => identical(updatedCategories[index], _categoryList[index]),
        ).every((same) => same);

    _hasCategoriesSnapshot = true;
    _categoriesError = null;
    if (unchanged) {
      if (previousError != null) _refreshLoadingState();
      return;
    }

    _categoryList = updatedCategories;
    if (selectedCategory != 'All' &&
        !_categoryList.any((category) => category.name == selectedCategory)) {
      selectedCategory = 'All';
    }
    _refreshLoadingState();
  }

  void _refreshLoadingState() {
    errorMessage = _itemsError ?? _categoriesError;
    isLoading =
        errorMessage == null && (!_hasItemsSnapshot || !_hasCategoriesSnapshot);
    notifyListeners();
  }

  void _setStreamError(String message, {required bool isItems}) {
    if (isItems) {
      _itemsError = message;
    } else {
      _categoriesError = message;
    }
    isLoading = false;
    errorMessage = _itemsError ?? _categoriesError;
    notifyListeners();
  }

  void _log(String message, Object error, StackTrace stackTrace) {
    if (kDebugMode) debugPrint('[MenuProvider] $message: $error\n$stackTrace');
  }

  bool _sameMenuItem(MenuItemModel first, MenuItemModel second) {
    if (first.id != second.id ||
        first.name != second.name ||
        first.description != second.description ||
        first.image != second.image ||
        first.isAvailable != second.isAvailable ||
        first.showOnMobileApp != second.showOnMobileApp ||
        first.isFeatured != second.isFeatured ||
        first.sortOrder != second.sortOrder ||
        first.dietaryType != second.dietaryType ||
        first.preparationId != second.preparationId ||
        first.preparation != second.preparation ||
        first.primaryCategoryId != second.primaryCategoryId ||
        first.category != second.category ||
        first.subCategoryId != second.subCategoryId ||
        first.subCategory != second.subCategory ||
        first.regionalityId != second.regionalityId ||
        first.regionality != second.regionality ||
        first.price != second.price ||
        first.createdAt != second.createdAt ||
        first.updatedAt != second.updatedAt ||
        !listEquals(first.tags, second.tags) ||
        !listEquals(first.ingredients, second.ingredients) ||
        first.sizes.length != second.sizes.length) {
      return false;
    }

    for (var index = 0; index < first.sizes.length; index++) {
      if (first.sizes[index].name != second.sizes[index].name ||
          first.sizes[index].price != second.sizes[index].price) {
        return false;
      }
    }
    return true;
  }

  bool _sameCategory(CategoryModel first, CategoryModel second) {
    if (first.id != second.id ||
        first.name != second.name ||
        first.subcategories.length != second.subcategories.length) {
      return false;
    }

    for (var index = 0; index < first.subcategories.length; index++) {
      final firstSubcategory = first.subcategories[index];
      final secondSubcategory = second.subcategories[index];
      if (firstSubcategory.id != secondSubcategory.id ||
          firstSubcategory.name != secondSubcategory.name) {
        return false;
      }
    }
    return true;
  }

  /// Refreshes just the category list (e.g. after creating one elsewhere)
  /// without re-fetching every menu item.
  Future<void> loadCategories() => load();

  Future<MenuItemModel> getItemById(String id) {
    return _service.fetchItemById(id);
  }

  List<String> subCategoriesFor(String category) {
    final match = _categoryList.where((item) => item.name == category);
    if (match.isEmpty) return [];
    return match.first.subcategories.map((sub) => sub.name).toList();
  }

  String _categoryId(String category) {
    final match = _categoryList.where((item) => item.name == category);
    return match.isEmpty ? category : match.first.id;
  }

  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  Future<bool> saveItem(MenuItemModel item) async {
    errorMessage = null;
    notifyListeners();

    try {
      await _service.saveItem(item);
      return true;
    } catch (error, stackTrace) {
      _log('Saving menu item failed', error, stackTrace);
      errorMessage = 'Failed to save menu item.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleAvailability(MenuItemModel item) async {
    errorMessage = null;
    try {
      await _service.toggleAvailability(item.id, !item.available);
      return true;
    } catch (error, stackTrace) {
      _log('Updating menu item availability failed', error, stackTrace);
      errorMessage = 'Failed to update availability.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    errorMessage = null;
    try {
      await _service.deleteItem(id);
      return true;
    } catch (error, stackTrace) {
      _log('Deleting menu item failed', error, stackTrace);
      errorMessage = 'Failed to delete menu item.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDisplaySettings({
    required MenuItemModel item,
    required bool showOnMobileApp,
    required bool featuredItem,
  }) async {
    errorMessage = null;
    try {
      await _service.updateDisplaySettings(
        id: item.id,
        showOnMobileApp: showOnMobileApp,
        featuredItem: featuredItem,
      );
      return true;
    } catch (error, stackTrace) {
      _log('Updating menu item display settings failed', error, stackTrace);
      errorMessage = 'Failed to update display settings.';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    final itemsSubscription = _itemsSubscription;
    final categoriesSubscription = _categoriesSubscription;
    _itemsSubscription = null;
    _categoriesSubscription = null;
    if (itemsSubscription != null) unawaited(itemsSubscription.cancel());
    if (categoriesSubscription != null) {
      unawaited(categoriesSubscription.cancel());
    }
    super.dispose();
  }
}

/// Riverpod provider wrapping [MenuProvider].
final menuProvider = ChangeNotifierProvider<MenuProvider>(
  (ref) => MenuProvider(MenuService()),
);
