import 'package:flutter/foundation.dart';
import '../models/menu_item_model.dart';
import '../services/menu_service.dart';

class MenuProvider extends ChangeNotifier {
  final MenuService _service;

  MenuProvider(this._service);

  List<MenuItemModel> _items = [];

  bool isLoading = false;
  String? errorMessage;

  String selectedCategory = 'All';
  String searchQuery = '';

  List<MenuItemModel> get items => List.unmodifiable(_items);

  List<String> get categories {
    return ['All', ...MenuTaxonomy.categories.map((category) => category.name)];
  }

  List<MenuItemModel> get filteredItems {
    final query = searchQuery.trim().toLowerCase();

    return _items.where((item) {
      final selectedId = _categoryId(selectedCategory);
      final matchesCategory = selectedCategory == 'All' ||
          MenuTaxonomy.descendantsOf(selectedId)
              .contains(item.primaryCategoryId);

      final matchesSearch = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _items = await _service.fetchMenuItems();
    } catch (e) {
      errorMessage = 'Failed to load menu.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<MenuItemModel> getItemById(String id) {
    return _service.fetchItemById(id);
  }

  List<String> subCategoriesFor(String category) {
    final parentId = _categoryId(category);
    return MenuTaxonomy.categories
        .where((item) => item.parentId == parentId)
        .map((item) => item.name)
        .toList();
  }

  String _categoryId(String category) => MenuTaxonomy.categories
      .firstWhere((item) => item.name == category,
          orElse: () => MenuCategory(category, category))
      .id;

  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  Future<bool> saveItem(MenuItemModel item) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _service.saveItem(item);

      // Reload so the newly created Firestore document and
      // server timestamps are reflected in the provider.
      _items = await _service.fetchMenuItems();

      return true;
    } catch (e) {
      errorMessage = 'Failed to save menu item.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleAvailability(
    MenuItemModel item,
  ) async {
    try {
      final newValue = !item.available;

      await _service.toggleAvailability(
        item.id,
        newValue,
      );

      final index = _items.indexWhere(
        (element) => element.id == item.id,
      );

      if (index != -1) {
        _items[index] = item.copyWith(
          available: newValue,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Failed to update availability.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    try {
      await _service.deleteItem(id);

      _items.removeWhere(
        (item) => item.id == id,
      );

      notifyListeners();
      return true;
    } catch (e) {
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
    try {
      await _service.updateDisplaySettings(
        id: item.id,
        showOnMobileApp: showOnMobileApp,
        featuredItem: featuredItem,
      );

      final index = _items.indexWhere(
        (element) => element.id == item.id,
      );

      if (index != -1) {
        _items[index] = item.copyWith(
          showOnMobileApp: showOnMobileApp,
          featuredItem: featuredItem,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Failed to update display settings.';
      notifyListeners();
      return false;
    }
  }
}
