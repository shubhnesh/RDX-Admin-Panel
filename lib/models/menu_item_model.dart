import 'package:cloud_firestore/cloud_firestore.dart';

enum DietaryType { veg, nonVeg, egg }

/// A menu item. Category/subcategory/preparation/regionality are all
/// resolved from Firestore-backed collections rather than hardcoded lists
/// — each `*Id` field links to a document, and the plain-name field
/// (`category`, `preparation`, etc.) is denormalized at save time so
/// cards can render without an extra lookup.
class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final String image;
  final bool isAvailable;
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
        isFeatured = isFeatured ?? featuredItem ?? false,
        dietaryType = dietaryType ??
            (isVeg == true ? DietaryType.veg : DietaryType.nonVeg),
        preparation = preparation ?? '',
        category = category ?? '',
        subCategory = subCategory ?? '',
        regionality = regionality ?? '';

  String get imageUrl => image;
  bool get available => isAvailable;
  bool get showOnMobileApp => true;
  bool get featuredItem => isFeatured;
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
        preparationId: preparationId,
        preparation: preparation,
        primaryCategoryId: primaryCategoryId,
        category: category,
        subCategoryId: subCategoryId,
        subCategory: subCategory,
        regionalityId: regionalityId,
        regionality: regionality,
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
      preparationId: json['preparation_id']?.toString() ?? '',
      preparation: json['preparation']?.toString() ?? '',
      primaryCategoryId: json['primary_category_id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      subCategoryId: json['sub_category_id']?.toString() ?? '',
      subCategory: json['sub_category']?.toString() ?? '',
      regionalityId: json['regionality_id']?.toString() ?? '',
      regionality: json['regionality']?.toString() ?? '',
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
        'preparation_id': preparationId,
        'preparation': preparation,
        'primary_category_id': primaryCategoryId,
        'category': category,
        'sub_category_id': subCategoryId,
        'sub_category': subCategory,
        'regionality_id': regionalityId,
        'regionality': regionality,
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

  static DateTime? _timestamp(dynamic value) => value is Timestamp
      ? value.toDate()
      : value is DateTime
          ? value
          : DateTime.tryParse(value?.toString() ?? '');
}
