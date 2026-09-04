// import 'package:flutter/material.dart';
// import '../models/menu_item_model.dart';
// import '../services/menu_service.dart';

// class MenuProvider extends ChangeNotifier {
//   final MenuService _service;
//   MenuProvider(this._service);

//   List<MenuItemModel> _items = [];
//   bool isLoading = false;
//   String? errorMessage;

//   String selectedCategory = 'All';
//   String searchQuery = '';

//   List<String> get categories => ['All', ..._items.map((e) => e.category).toSet()];

//   List<MenuItemModel> get filteredItems {
//     return _items.where((item) {
//       final matchesCategory = selectedCategory == 'All' || item.category == selectedCategory;
//       final matchesSearch = item.name.toLowerCase().contains(searchQuery.toLowerCase());
//       return matchesCategory && matchesSearch;
//     }).toList();
//   }

//   Future<void> load() async {
//     isLoading = true;
//     errorMessage = null;
//     notifyListeners();
//     try {
//       _items = await _service.fetchMenuItems();
//     } catch (e) {
//       errorMessage = 'Failed to load menu.';
//     }
//     isLoading = false;
//     notifyListeners();
//   }

//   Future<MenuItemModel> getItemById(String id) => _service.fetchItemById(id);

//   /// Returns known subcategories for a category, used to populate the
//   /// subcategory dropdown on the edit-item screen.
//   List<String> subCategoriesFor(String category) {
//     final fromExisting = _items
//         .where((i) => i.category == category && i.subCategory.isNotEmpty)
//         .map((i) => i.subCategory)
//         .toSet()
//         .toList();
//     return fromExisting;
//   }

//   void setCategory(String category) {
//     selectedCategory = category;
//     notifyListeners();
//   }

//   void setSearchQuery(String query) {
//     searchQuery = query;
//     notifyListeners();
//   }

//   Future<void> toggleAvailability(MenuItemModel item) async {
//     await _service.toggleAvailability(item.id, !item.available);
//     await load();
//   }

//   Future<void> deleteItem(String id) async {
//     await _service.deleteItem(id);
//     await load();
//   }

//   Future<bool> saveItem(MenuItemModel item) async {
//     isLoading = true;
//     errorMessage = null;
//     notifyListeners();
//     try {
//       await _service.saveItem(item);
//       isLoading = false;
//       notifyListeners();
//       return true;
//     } catch (e) {
//       errorMessage = 'Failed to save item.';
//       isLoading = false;
//       notifyListeners();
//       return false;
//     }
//   }
// }

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
    final result = <String>{'All'};

    for (final item in _items) {
      if (item.category.trim().isNotEmpty) {
        result.add(item.category.trim());
      }
    }

    return result.toList();
  }

  List<MenuItemModel> get filteredItems {
    final query = searchQuery.trim().toLowerCase();

    return _items.where((item) {
      final matchesCategory =
          selectedCategory == 'All' || item.category == selectedCategory;

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
    final result = <String>{};

    for (final item in _items) {
      if (item.category == category && item.subCategory.trim().isNotEmpty) {
        result.add(item.subCategory.trim());
      }
    }

    return result.toList()..sort();
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
