import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item_model.dart';
import '../models/menu_item_model.dart';

/// Holds the in-progress order's cart. Lives for as long as the
/// ProviderScope (i.e. app-wide) so it survives navigating from
/// PlaceOrderScreen -> CheckoutScreen and back without needing to pass
/// it through constructors.
class CartNotifier extends StateNotifier<List<CartLineItem>> {
  CartNotifier() : super([]);

  /// Adds [quantity] of [menuItem] with the given customization. If a
  /// line with the exact same item + customization already exists, its
  /// quantity is incremented instead of creating a duplicate line.
  void addItem({
    required MenuItemModel menuItem,
    required int quantity,
    String? spiceLevel,
    List<CartAddOn> addOns = const [],
    String? notes,
  }) {
    final candidateKey = CartLineItem(
      id: '',
      menuItem: menuItem,
      quantity: quantity,
      spiceLevel: spiceLevel,
      addOns: addOns,
      notes: notes,
    ).customizationKey;

    final existingIndex =
        state.indexWhere((line) => line.customizationKey == candidateKey);

    if (existingIndex != -1) {
      final existing = state[existingIndex];
      final updated = existing.copyWith(quantity: existing.quantity + quantity);
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == existingIndex) updated else state[i],
      ];
      return;
    }

    state = [
      ...state,
      CartLineItem(
        id: '${menuItem.id}-${DateTime.now().microsecondsSinceEpoch}',
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

  /// Total quantity of a given menu item across all its customized lines
  /// — used to show a "3 in cart" badge on the ordering card.
  int quantityForMenuItem(String menuItemId) {
    return state
        .where((line) => line.menuItem.id == menuItemId)
        .fold(0, (sum, line) => sum + line.quantity);
  }

  void clear() => state = [];
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartLineItem>>(
  (ref) => CartNotifier(),
);

final cartCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, line) => sum + line.quantity);
});

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, line) => sum + line.subtotal);
});
