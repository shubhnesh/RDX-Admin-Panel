import 'menu_item_model.dart';

/// A chargeable extra attached to a cart line (e.g. "Extra Cheese +₹20").
/// Purely a cart/order-time concept — menu items don't define their own
/// add-ons in Firestore, so staff pick from a generic quick-list or type
/// a custom one at order time (see [kQuickAddOns] and the "custom add-on"
/// row in ItemCustomizeSheet).
class CartAddOn {
  final String name;
  final double price;

  const CartAddOn({required this.name, this.price = 0});

  String get displayLabel =>
      price > 0 ? '$name (+₹${price.toStringAsFixed(0)})' : name;
}

/// Generic quick-select add-ons offered for any menu item. Edit this list
/// to match what your kitchen actually offers.
const List<CartAddOn> kQuickAddOns = [
  CartAddOn(name: 'Extra Cheese', price: 20),
  CartAddOn(name: 'Extra Butter', price: 15),
  CartAddOn(name: 'Extra Gravy', price: 25),
  CartAddOn(name: 'Extra Bread/Papad', price: 10),
  CartAddOn(name: 'Extra Sauce', price: 10),
];

const List<String> kSpiceLevels = ['Mild', 'Medium', 'Spicy', 'Extra Spicy'];

/// One line in the cart: a menu item plus whatever customization was
/// chosen for it. Two adds of the SAME item with the SAME customization
/// merge into one line (quantity increments); different customizations
/// of the same item become separate lines — see [customizationKey].
class CartLineItem {
  final String id;
  final MenuItemModel menuItem;
  final int quantity;
  final String? spiceLevel;
  final List<CartAddOn> addOns;
  final String? notes;

  const CartLineItem({
    required this.id,
    required this.menuItem,
    required this.quantity,
    this.spiceLevel,
    this.addOns = const [],
    this.notes,
  });

  double get addOnsTotal => addOns.fold(0.0, (sum, a) => sum + a.price);
  double get unitPrice => menuItem.price + addOnsTotal;
  double get subtotal => unitPrice * quantity;

  /// Identifies "the same customization" so repeat adds merge instead of
  /// creating duplicate lines. Add-on names are sorted first so selecting
  /// the same two add-ons in a different order still matches.
  String get customizationKey {
    final sortedAddOns = addOns.map((a) => a.name).toList()..sort();
    return '${menuItem.id}|${spiceLevel ?? ''}|${sortedAddOns.join(',')}|${notes ?? ''}';
  }

  CartLineItem copyWith({
    int? quantity,
    String? spiceLevel,
    List<CartAddOn>? addOns,
    String? notes,
  }) {
    return CartLineItem(
      id: id,
      menuItem: menuItem,
      quantity: quantity ?? this.quantity,
      spiceLevel: spiceLevel ?? this.spiceLevel,
      addOns: addOns ?? this.addOns,
      notes: notes ?? this.notes,
    );
  }
}
