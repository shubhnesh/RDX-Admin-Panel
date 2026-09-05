import 'package:cloud_firestore/cloud_firestore.dart';

enum DietaryType { veg, nonVeg, egg }

enum PreparationStyle { dry, gravy, fried, steam, tandoori, creamy, other }

class MenuCategory {
  final String id;
  final String name;
  final String? parentId;
  const MenuCategory(this.id, this.name, {this.parentId});
}

class MenuTaxonomy {
  static const categories = <MenuCategory>[
    MenuCategory('beverages', 'Beverages'),
    MenuCategory('combos-thalis', 'Combos & Thalis'),
    MenuCategory('starters', 'Starters'),
    MenuCategory('rolls', 'Rolls'),
    MenuCategory('momos', 'Momos'),
    MenuCategory('noodles', 'Noodles'),
    MenuCategory('fried-rice', 'Fried Rice'),
    MenuCategory('thukpa-thenthuk', 'Thukpa & Thenthuk'),
    MenuCategory('chopsuey', 'Chopsuey'),
    MenuCategory('soups', 'Soups'),
    MenuCategory('fries-sides', 'Fries & Sides'),
    MenuCategory('pasta', 'Pasta'),
    MenuCategory('burgers', 'Burgers'),
    MenuCategory('sandwiches', 'Sandwiches'),
    MenuCategory('shakes', 'Shakes', parentId: 'beverages'),
    MenuCategory('coolers-mocktails', 'Coolers & Mocktails',
        parentId: 'beverages'),
    MenuCategory('veg-starters', 'Veg Starters', parentId: 'starters'),
    MenuCategory('non-veg-starters', 'Non-Veg Starters', parentId: 'starters'),
    MenuCategory('kathi-rolls', 'Kathi Rolls', parentId: 'rolls'),
    MenuCategory('chicken-rolls', 'Chicken Rolls', parentId: 'rolls'),
    MenuCategory('regular-momos', 'Regular Momos', parentId: 'momos'),
    MenuCategory('momo-platters', 'Momo Platters', parentId: 'momos'),
  ];

  static String nameFor(String id) => categories
      .firstWhere((category) => category.id == id,
          orElse: () => MenuCategory('', id))
      .name;

  static List<MenuCategory> get mainCategories =>
      categories.where((category) => category.parentId == null).toList();

  static Set<String> descendantsOf(String parentId) {
    final result = <String>{parentId};
    var changed = true;
    while (changed) {
      changed = false;
      for (final category in categories) {
        if (category.parentId != null &&
            result.contains(category.parentId) &&
            result.add(category.id)) {
          changed = true;
        }
      }
    }
    return result;
  }
}

class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final String image;
  final bool isAvailable;
  final bool isFeatured;
  final int sortOrder;
  final DietaryType dietaryType;
  final PreparationStyle preparationStyle;
  final String primaryCategoryId;
  final double price;
  final List<String> tags;
  final List<String> ingredients;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    String? image,
    bool? isAvailable,
    bool? isFeatured,
    this.sortOrder = 0,
    DietaryType? dietaryType,
    this.preparationStyle = PreparationStyle.other,
    String? primaryCategoryId,
    this.price = 0,
    this.tags = const [],
    this.ingredients = const [],
    this.createdAt,
    this.updatedAt,
    String? category,
    String? subCategory,
    String? imageUrl,
    bool? available,
    bool? featuredItem,
    bool? isVeg,
    bool? showOnMobileApp,
  })  : image = image ?? imageUrl ?? '',
        isAvailable = isAvailable ?? available ?? true,
        isFeatured = isFeatured ?? featuredItem ?? false,
        dietaryType = dietaryType ??
            (isVeg == true ? DietaryType.veg : DietaryType.nonVeg),
        primaryCategoryId = primaryCategoryId ?? _categoryId(category);

  String get imageUrl => image;
  bool get available => isAvailable;
  bool get showOnMobileApp => true;
  bool get featuredItem => isFeatured;
  String get category => MenuTaxonomy.nameFor(primaryCategoryId);
  String get subCategory => '';
  bool get isVeg => dietaryType == DietaryType.veg;

  MenuItemModel copyWith({
    bool? available,
    bool? showOnMobileApp,
    bool? featuredItem,
    bool? isAvailable,
    bool? isFeatured,
    List<String>? ingredients,
  }) =>
      MenuItemModel(
        id: id,
        name: name,
        description: description,
        image: image,
        isAvailable: isAvailable ?? available ?? this.isAvailable,
        isFeatured: isFeatured ?? featuredItem ?? this.isFeatured,
        sortOrder: sortOrder,
        dietaryType: dietaryType,
        preparationStyle: preparationStyle,
        primaryCategoryId: primaryCategoryId,
        price: price,
        tags: tags,
        ingredients: ingredients ?? this.ingredients,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory MenuItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    final json =
        data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    json['id'] = doc.id;
    return MenuItemModel.fromJson(json);
  }

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString() ?? json['image_url']?.toString() ?? '',
      isAvailable: json['is_available'] != false && json['available'] != false,
      isFeatured: json['is_featured'] == true || json['featured_item'] == true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      dietaryType: _enumValue(DietaryType.values, json['dietary_type']) ??
          (json['is_veg'] == true ? DietaryType.veg : DietaryType.nonVeg),
      preparationStyle:
          _enumValue(PreparationStyle.values, json['preparation_style']) ??
              PreparationStyle.other,
      primaryCategoryId: json['primary_category_id']?.toString() ??
          _categoryId(json['category']?.toString()),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      tags: _strings(json['tags']),
      ingredients: _strings(json['ingredients']),
      createdAt: _timestamp(json['created_at']),
      updatedAt: _timestamp(json['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'image': image,
        'is_available': isAvailable,
        'is_featured': isFeatured,
        'sort_order': sortOrder,
        'dietary_type': dietaryType.name,
        'preparation_style': preparationStyle.name,
        'primary_category_id': primaryCategoryId,
        'price': price,
        'tags': tags,
        'ingredients': ingredients,
      };

  Map<String, dynamic> toJson() => toFirestore();

  static T? _enumValue<T extends Enum>(List<T> values, dynamic value) {
    for (final item in values) {
      if (item.name == value) return item;
    }
    return null;
  }

  static List<String> _strings(dynamic value) => value is List
      ? value
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList()
      : const [];

  static String _categoryId(String? category) => MenuTaxonomy.categories
      .firstWhere(
          (item) => item.name.toLowerCase() == (category ?? '').toLowerCase(),
          orElse: () => MenuTaxonomy.categories.first)
      .id;

  static DateTime? _timestamp(dynamic value) => value is Timestamp
      ? value.toDate()
      : value is DateTime
          ? value
          : DateTime.tryParse(value?.toString() ?? '');
}
