import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemOption {
  final String id;
  final String name;
  final double extraPrice;
  final bool included;

  const MenuItemOption({
    required this.id,
    required this.name,
    this.extraPrice = 0,
    this.included = false,
  });

  factory MenuItemOption.fromJson(Map<String, dynamic> json) {
    return MenuItemOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      extraPrice: (json['extra_price'] as num?)?.toDouble() ?? 0,
      included: json['included'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'extra_price': extraPrice,
      'included': included,
    };
  }

  MenuItemOption copyWith({
    String? id,
    String? name,
    double? extraPrice,
    bool? included,
  }) {
    return MenuItemOption(
      id: id ?? this.id,
      name: name ?? this.name,
      extraPrice: extraPrice ?? this.extraPrice,
      included: included ?? this.included,
    );
  }
}

class MenuItemCustomizationGroup {
  final String id;
  final String title;
  final bool required;
  final List<MenuItemOption> options;

  const MenuItemCustomizationGroup({
    required this.id,
    required this.title,
    this.required = false,
    this.options = const [],
  });

  factory MenuItemCustomizationGroup.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawOptions = json['options'];

    return MenuItemCustomizationGroup(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      required: json['required'] == true,
      options: rawOptions is List
          ? rawOptions
              .whereType<Map>()
              .map(
                (e) => MenuItemOption.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'required': required,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }

  MenuItemCustomizationGroup copyWith({
    String? id,
    String? title,
    bool? required,
    List<MenuItemOption>? options,
  }) {
    return MenuItemCustomizationGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      required: required ?? this.required,
      options: options ?? this.options,
    );
  }
}

enum ItemSize {
  small,
  medium,
  large,
}

extension ItemSizeX on ItemSize {
  String get label {
    switch (this) {
      case ItemSize.small:
        return 'Small';
      case ItemSize.medium:
        return 'Medium';
      case ItemSize.large:
        return 'Large';
    }
  }

  static ItemSize fromString(String? value) {
    return ItemSize.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ItemSize.medium,
    );
  }
}

class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String subCategory;
  final String imageUrl;

  final bool available;
  final bool showOnMobileApp;
  final bool featuredItem;
  final bool isVeg;

  final List<MenuItemCustomizationGroup> customizations;
  final List<String> majorIngredients;

  final ItemSize selectedSize;
  final Map<ItemSize, String> portionQuantities;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  static const int maxMajorIngredients = 5;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.subCategory = '',
    this.imageUrl = '',
    this.available = true,
    this.showOnMobileApp = true,
    this.featuredItem = false,
    this.isVeg = false,
    this.customizations = const [],
    this.majorIngredients = const [],
    this.selectedSize = ItemSize.medium,
    this.portionQuantities = const {
      ItemSize.small: '',
      ItemSize.medium: '',
      ItemSize.large: '',
    },
    this.createdAt,
    this.updatedAt,
  });

  MenuItemModel copyWith({
    String? name,
    String? description,
    double? price,
    String? category,
    String? subCategory,
    String? imageUrl,
    bool? available,
    bool? showOnMobileApp,
    bool? featuredItem,
    bool? isVeg,
    List<MenuItemCustomizationGroup>? customizations,
    List<String>? majorIngredients,
    ItemSize? selectedSize,
    Map<ItemSize, String>? portionQuantities,
  }) {
    return MenuItemModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      imageUrl: imageUrl ?? this.imageUrl,
      available: available ?? this.available,
      showOnMobileApp: showOnMobileApp ?? this.showOnMobileApp,
      featuredItem: featuredItem ?? this.featuredItem,
      isVeg: isVeg ?? this.isVeg,
      customizations: customizations ?? this.customizations,
      majorIngredients: majorIngredients ?? this.majorIngredients,
      selectedSize: selectedSize ?? this.selectedSize,
      portionQuantities: portionQuantities ?? this.portionQuantities,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory MenuItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();

    final json =
        data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

    json['id'] = doc.id;

    return MenuItemModel.fromJson(json);
  }

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    final rawPortions = json['portion_quantities'];

    final portions = rawPortions is Map
        ? Map<String, dynamic>.from(rawPortions)
        : <String, dynamic>{};

    final rawCustomizations = json['customizations'];

    final customizationList = rawCustomizations is List
        ? rawCustomizations
            .whereType<Map>()
            .map(
              (e) => MenuItemCustomizationGroup.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList()
        : <MenuItemCustomizationGroup>[];

    final rawIngredients = json['major_ingredients'];

    final ingredients = rawIngredients is List
        ? rawIngredients
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .take(maxMajorIngredients)
            .toList()
        : <String>[];

    return MenuItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      category: json['category']?.toString() ?? 'Uncategorized',
      subCategory: json['sub_category']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      available: json['available'] != false,
      showOnMobileApp: json['show_on_mobile_app'] != false,
      featuredItem: json['featured_item'] == true,
      isVeg: json['is_veg'] == true,
      customizations: customizationList,
      majorIngredients: ingredients,
      selectedSize: ItemSizeX.fromString(
        json['selected_size']?.toString(),
      ),
      portionQuantities: {
        ItemSize.small: portions['small']?.toString() ?? '',
        ItemSize.medium: portions['medium']?.toString() ?? '',
        ItemSize.large: portions['large']?.toString() ?? '',
      },
      createdAt: _parseTimestamp(json['created_at']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  /// Firestore document data excluding server-managed timestamps.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'sub_category': subCategory,
      'image_url': imageUrl,
      'available': available,
      'show_on_mobile_app': showOnMobileApp,
      'featured_item': featuredItem,
      'is_veg': isVeg,
      'customizations': customizations.map((e) => e.toJson()).toList(),
      'major_ingredients': majorIngredients.take(maxMajorIngredients).toList(),
      'selected_size': selectedSize.name,
      'portion_quantities': {
        'small': portionQuantities[ItemSize.small] ?? '',
        'medium': portionQuantities[ItemSize.medium] ?? '',
        'large': portionQuantities[ItemSize.large] ?? '',
      },
    };
  }

  Map<String, dynamic> toJson() => toFirestore();

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
