import 'package:cloud_firestore/cloud_firestore.dart';

enum DietaryType { veg, nonVeg, egg }

/// A single size option with its own price (e.g. Small / ₹120).
class MenuItemSize {
  final String name;
  final double price;

  const MenuItemSize({
    required this.name,
    required this.price,
  });

  factory MenuItemSize.fromJson(Map<String, dynamic> json) => MenuItemSize(
        name: json['name']?.toString() ?? '',
        price: MenuItemModel._parseDouble(json['price']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
      };
}

/// A menu item. Category/subcategory/preparation/regionality are all
/// resolved from Firestore-backed collections rather than hardcoded lists
/// — each `*Id` field links to a document, and the plain-name field
/// (`category`, `preparation`, etc.) is denormalized at save time so
/// cards can render without an extra lookup.
///
/// When [sizes] is non-empty the item uses size-based pricing; [price]
/// is then the lowest size price (for list/card display).
class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final String image;
  final bool isAvailable;
  final bool showOnMobileApp;
  final bool isFeatured;
  final int sortOrder;
  final DietaryType dietaryType;
  final String preparationId;
  final String preparation;
  final String primaryCategoryId;
  final String category;
  final String subCategoryId;
  final String subCategory;
  final String regionalityId;
  final String regionality;
  final double price;
  final List<MenuItemSize> sizes;
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
    this.preparationId = '',
    String? preparation,
    this.primaryCategoryId = '',
    String? category,
    this.subCategoryId = '',
    String? subCategory,
    this.regionalityId = '',
    String? regionality,
    this.price = 0,
    this.sizes = const [],
    this.tags = const [],
    this.ingredients = const [],
    this.createdAt,
    this.updatedAt,
    String? imageUrl,
    bool? available,
    bool? featuredItem,
    bool? isVeg,
    bool? showOnMobileApp,
  })  : image = image ?? imageUrl ?? '',
        isAvailable = isAvailable ?? available ?? true,
        showOnMobileApp = showOnMobileApp ?? true,
        isFeatured = isFeatured ?? featuredItem ?? false,
        dietaryType = dietaryType ??
            (isVeg == true ? DietaryType.veg : DietaryType.nonVeg),
        preparation = preparation ?? '',
        category = category ?? '',
        subCategory = subCategory ?? '',
        regionality = regionality ?? '';

  String get imageUrl => image;
  bool get available => isAvailable;
  bool get featuredItem => isFeatured;
  bool get isVeg => dietaryType == DietaryType.veg;
  bool get hasSizes => sizes.isNotEmpty;

  MenuItemModel copyWith({
    bool? available,
    bool? featuredItem,
    bool? isAvailable,
    bool? showOnMobileApp,
    bool? isFeatured,
    List<String>? ingredients,
    List<MenuItemSize>? sizes,
    double? price,
  }) =>
      MenuItemModel(
        id: id,
        name: name,
        description: description,
        image: image,
        isAvailable: isAvailable ?? available ?? this.isAvailable,
        showOnMobileApp: showOnMobileApp ?? this.showOnMobileApp,
        isFeatured: isFeatured ?? featuredItem ?? this.isFeatured,
        sortOrder: sortOrder,
        dietaryType: dietaryType,
        preparationId: preparationId,
        preparation: preparation,
        primaryCategoryId: primaryCategoryId,
        category: category,
        subCategoryId: subCategoryId,
        subCategory: subCategory,
        regionalityId: regionalityId,
        regionality: regionality,
        price: price ?? this.price,
        sizes: sizes ?? this.sizes,
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
    final sizes = _sizes(json['sizes']);
    final price = sizes.isEmpty
        ? _parseDouble(json['price'])
        : sizes.map((size) => size.price).reduce(
              (lowest, current) => current < lowest ? current : lowest,
            );

    return MenuItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString() ?? json['image_url']?.toString() ?? '',
      isAvailable:
          _parseBool(json['is_available'] ?? json['available']) ?? true,
      showOnMobileApp: _parseBool(
            json['show_on_mobile_app'] ?? json['showOnMobileApp'],
          ) ??
          true,
      isFeatured: _parseBool(json['is_featured']) == true ||
          _parseBool(json['featured_item']) == true,
      sortOrder: _parseInt(json['sort_order']),
      dietaryType: _enumValue(DietaryType.values, json['dietary_type']) ??
          (json['is_veg'] == true ? DietaryType.veg : DietaryType.nonVeg),
      preparationId: json['preparation_id']?.toString() ?? '',
      preparation: json['preparation']?.toString() ?? '',
      primaryCategoryId: json['primary_category_id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      subCategoryId: json['sub_category_id']?.toString() ?? '',
      subCategory: json['sub_category']?.toString() ?? '',
      regionalityId: json['regionality_id']?.toString() ?? '',
      regionality: json['regionality']?.toString() ?? '',
      price: price,
      sizes: sizes,
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
        'show_on_mobile_app': showOnMobileApp,
        'is_featured': isFeatured,
        'sort_order': sortOrder,
        'dietary_type': dietaryType.name,
        'preparation_id': preparationId,
        'preparation': preparation,
        'primary_category_id': primaryCategoryId,
        'category': category,
        'sub_category_id': subCategoryId,
        'sub_category': subCategory,
        'regionality_id': regionalityId,
        'regionality': regionality,
        if (sizes.isEmpty) 'price': price,
        'sizes': sizes.map((s) => s.toJson()).toList(),
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

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().trim() ?? '') ?? 0;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '') ?? 0;
  }

  static bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
          return true;
        case 'false':
          return false;
      }
    }
    return null;
  }

  static List<String> _strings(dynamic value) => value is List
      ? value
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList()
      : const [];

  static List<MenuItemSize> _sizes(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => MenuItemSize.fromJson(Map<String, dynamic>.from(e)))
        .where((s) => s.name.trim().isNotEmpty)
        .toList();
  }

  static DateTime? _timestamp(dynamic value) => value is Timestamp
      ? value.toDate()
      : value is DateTime
          ? value
          : DateTime.tryParse(value?.toString() ?? '');
}
