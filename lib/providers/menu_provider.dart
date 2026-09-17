import 'package:flutter_riverpod/legacy.dart';

import '../models/menu_item_model.dart';
import '../services/menu_service.dart';

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

  Future<MenuItemModel> getItemById(String id) => _service.fetchItemById(id);

  Future<bool> saveItem(MenuItemModel item) async {
    try {
      await _service.saveItem(item);
      await load();
      return true;
    } catch (_) {
      state = state.copyWith(errorMessage: 'Failed to save menu item.');
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    try {
      await _service.deleteItem(id);
      state = state.copyWith(
        items: state.items.where((item) => item.id != id).toList(),
      );
      return true;
    } catch (_) {
      state = state.copyWith(errorMessage: 'Failed to delete menu item.');
      return false;
    }
  }

  Future<void> toggleAvailability(MenuItemModel item) async {
    await _service.toggleAvailability(item.id, !item.available);
    final updated = state.items
        .map((i) => i.id == item.id ? i.copyWith(available: !item.available) : i)
        .toList();
    state = state.copyWith(items: updated);
  }
}

final menuServiceProvider = Provider<MenuService>((ref) => MenuService());

final menuNotifierProvider = StateNotifierProvider<MenuNotifier, MenuState>(
  (ref) => MenuNotifier(ref.watch(menuServiceProvider)),
);
