import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item_model.dart';
import '../models/menu_item_model.dart';

export '../models/cart_item_model.dart';

/// Holds the active order cart as an immutable list of [CartLineItem].
class CartNotifier extends StateNotifier<List<CartLineItem>> {
  CartNotifier() : super(const []);

  void addItem({
    required MenuItemModel menuItem,
    int quantity = 1,
    String? size,
    double? sizePrice,
    String? spiceLevel,
    List<CartAddOn> addOns = const [],
    String? notes,
  }) {
    // Same item + same size + same options → bump quantity instead of
    // adding a duplicate line.
    final existing = state.indexWhere((l) =>
        l.menuItem.id == menuItem.id &&
        l.size == size &&
        l.spiceLevel == spiceLevel &&
        (l.notes ?? '') == (notes ?? '') &&
        listEquals(l.addOns, addOns));
    if (existing != -1) {
      updateQuantity(state[existing].id, state[existing].quantity + quantity);
      return;
    }
    final id =
        '${menuItem.id}_${DateTime.now().microsecondsSinceEpoch}';
    state = [
      ...state,
      CartLineItem(
        id: id,
        menuItem: menuItem,
        quantity: quantity,
        size: size,
        sizePrice: sizePrice,
        spiceLevel: spiceLevel,
        addOns: List<CartAddOn>.from(addOns),
        notes: notes,
      ),
    ];
  }

  void updateQuantity(String lineId, int quantity) {
    if (quantity <= 0) {
      removeLine(lineId);
      return;
    }
    state = [
      for (final line in state)
        if (line.id == lineId) line.copyWith(quantity: quantity) else line,
    ];
  }

  void removeLine(String lineId) {
    state = state.where((line) => line.id != lineId).toList();
  }

  void clear() {
    state = const [];
  }

  int quantityForMenuItem(String menuItemId) {
    return state
        .where((line) => line.menuItem.id == menuItemId)
        .fold<int>(0, (sum, line) => sum + line.quantity);
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartLineItem>>(
  (ref) => CartNotifier(),
);

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold<double>(0, (sum, line) => sum + line.subtotal);
});
