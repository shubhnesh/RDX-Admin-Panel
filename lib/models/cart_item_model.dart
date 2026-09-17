import 'menu_item_model.dart';

/// A single add-on attached to a cart line (e.g. "Extra Cheese +₹40").
class CartAddOn {
  final String name;
  final double price;

  const CartAddOn({
    required this.name,
    required this.price,
  });

  String get displayLabel =>
      price > 0 ? '$name (+₹${price.toStringAsFixed(0)})' : name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartAddOn && other.name == name && other.price == price;

  @override
  int get hashCode => Object.hash(name, price);
}

/// One line in the active order/cart.
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

  /// Price of a single unit, including its selected add-ons.
  double get unitPrice =>
      menuItem.price + addOns.fold(0.0, (sum, a) => sum + a.price);

  double get subtotal => unitPrice * quantity;

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

/// Preset add-ons shown as quick-select checkboxes.
const List<CartAddOn> kQuickAddOns = [
  CartAddOn(name: 'Extra Cheese', price: 40),
  CartAddOn(name: 'Extra Spicy', price: 0),
  CartAddOn(name: 'Extra Sauce', price: 20),
  CartAddOn(name: 'No Onions', price: 0),
];

/// Preset spice level choices.
const List<String> kSpiceLevels = [
  'Mild',
  'Medium',
  'Hot',
  'Extra Hot',
];
