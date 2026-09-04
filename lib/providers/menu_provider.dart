import 'package:flutter/material.dart';
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

  List<String> get categories =>
      ['All', ..._items.map((e) => e.category).toSet()];

  List<MenuItemModel> get filteredItems {
    return _items.where((item) {
      final matchesCategory =
          selectedCategory == 'All' || item.category == selectedCategory;
      final matchesSearch =
          item.name.toLowerCase().contains(searchQuery.toLowerCase());
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
    }
    isLoading = false;
    notifyListeners();
  }

  Future<MenuItemModel> getItemById(String id) => _service.fetchItemById(id);

  /// Returns known subcategories for a category, used to populate the
  /// subcategory dropdown on the edit-item screen.
  List<String> subCategoriesFor(String category) {
    final fromExisting = _items
        .where((i) => i.category == category && i.subCategory.isNotEmpty)
        .map((i) => i.subCategory)
        .toSet()
        .toList();
    return fromExisting;
  }

  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  Future<void> toggleAvailability(MenuItemModel item) async {
    await _service.toggleAvailability(item.id, !item.available);
    await load();
  }

  Future<void> deleteItem(String id) async {
    await _service.deleteItem(id);
    await load();
  }

  Future<bool> saveItem(MenuItemModel item) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.saveItem(item);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Failed to save item.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
