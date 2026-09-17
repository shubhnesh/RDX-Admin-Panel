import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/cart_item_model.dart';
import '../models/menu_item_model.dart';

class CartNotifier extends StateNotifier<List<CartLineItem>> {
  CartNotifier() : super(const []);

  /// Adds a new line. Identical items (same menu item + spice level +
  /// add-ons + notes) are merged by bumping the quantity instead of
  /// creating a duplicate line.
  void addItem({
    required MenuItemModel menuItem,
    required int quantity,
    String? spiceLevel,
    List<CartAddOn> addOns = const [],
    String? notes,
  }) {
    final existingIndex = state.indexWhere((line) =>
        line.menuItem.id == menuItem.id &&
        line.spiceLevel == spiceLevel &&
        line.notes == notes &&
        _sameAddOns(line.addOns, addOns));

    if (existingIndex != -1) {
      final existing = state[existingIndex];
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == existingIndex)
            existing.copyWith(quantity: existing.quantity + quantity)
          else
            state[i],
      ];
      return;
    }

    state = [
      ...state,
      CartLineItem(
        id: '${menuItem.id}_${DateTime.now().microsecondsSinceEpoch}',
        menuItem: menuItem,
        quantity: quantity,
        spiceLevel: spiceLevel,
        addOns: addOns,
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

  bool _sameAddOns(List<CartAddOn> a, List<CartAddOn> b) {
    if (a.length != b.length) return false;
    for (final addOn in a) {
      if (!b.contains(addOn)) return false;
    }
    return true;
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartLineItem>>(
  (ref) => CartNotifier(),
);

/// Subtotal (before tax) of every line currently in the cart.
final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, line) => sum + line.subtotal);
});
