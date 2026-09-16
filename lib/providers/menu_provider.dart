import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../models/menu_item_model.dart';
import '../services/category_service.dart';
import '../services/menu_service.dart';

/// Riverpod replacement for the old `provider`-package `MenuProvider`.
/// Exposes the same shape (isLoading, categories, selectedCategory,
/// filteredItems, setSearchQuery, setCategory, load) so screens only
/// need to swap `context.watch<MenuProvider>()` for
/// `ref.watch(menuNotifierProvider)` / `ref.read(menuNotifierProvider.notifier)`.
class MenuState {
  final bool isLoading;
  final String? errorMessage;
  final List<MenuItemModel> items;
  final String selectedCategory;
  final String searchQuery;

  const MenuState({
    this.isLoading = false,
    this.errorMessage,
    this.items = const [],
    this.selectedCategory = 'All',
    this.searchQuery = '',
  });

  List<String> get categories {
    final set = <String>{'All', ...items.map((i) => i.category)};
    return set.toList();
  }

  List<MenuItemModel> get filteredItems {
    return items.where((item) {
      final matchesCategory =
          selectedCategory == 'All' || item.category == selectedCategory;
      final matchesSearch = searchQuery.isEmpty ||
          item.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  MenuState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<MenuItemModel>? items,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return MenuState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      items: items ?? this.items,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class MenuNotifier extends StateNotifier<MenuState> {
  MenuNotifier(this._service) : super(const MenuState());
  final MenuService _service;
  final CategoryService _categoryService;

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _service.fetchMenuItems();
      state = state.copyWith(isLoading: false, items: items);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load menu.',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }
}

final menuServiceProvider = Provider<MenuService>((ref) => MenuService());

final menuNotifierProvider = StateNotifierProvider<MenuNotifier, MenuState>(
  (ref) => MenuNotifier(ref.watch(menuServiceProvider)),
);

/// Compatibility provider for the existing menu management screens.
/// New order screens can use [menuNotifierProvider] directly.
class MenuProvider extends ChangeNotifier {
  MenuProvider(this._service);

  final MenuService _service;
  final CategoryService _categoryService = CategoryService();
  List<MenuItemModel> items = [];
  List<CategoryModel> categoryList = [];
  String selectedCategory = 'All';
  String searchQuery = '';
  bool isLoading = false;
  String? errorMessage;

  List<String> get categories {
    final set = <String>{'All', ...items.map((item) => item.category)};
    return set.toList();
  }

  List<MenuItemModel> get filteredItems {
    return items.where((item) {
      final matchesCategory =
          selectedCategory == 'All' || item.category == selectedCategory;
      final matchesSearch = searchQuery.isEmpty ||
          item.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      items = await _service.fetchMenuItems();
      try {
        categoryList = await _categoryService.fetchCategories();
      } catch (_) {
        // Menu items can still be displayed when taxonomy data is unavailable.
        categoryList = [];
      }
    } catch (_) {
      errorMessage = 'Failed to load menu.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes just the category list (e.g. after creating one elsewhere)
  /// without re-fetching every menu item.
  Future<void> loadCategories() async {
    try {
      _categoryList = await _categoryService.fetchCategories();
      notifyListeners();
    } catch (_) {
      // Category refresh is non-critical — keep whatever was loaded before.
    }
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  Future<MenuItemModel> getItemById(String id) => _service.fetchItemById(id);

  Future<bool> saveItem(MenuItemModel item) async {
    try {
      await _service.saveItem(item);
      await load();
      return true;
    } catch (_) {
      errorMessage = 'Failed to save menu item.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    try {
      await _service.deleteItem(id);
      items = items.where((item) => item.id != id).toList();
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = 'Failed to delete menu item.';
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleAvailability(MenuItemModel item) async {
    await _service.toggleAvailability(item.id, !item.available);
    final index = items.indexWhere((current) => current.id == item.id);
    if (index != -1) {
      items[index] = item.copyWith(available: !item.available);
      notifyListeners();
    }
  }
}
