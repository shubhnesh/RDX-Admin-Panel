class MenuItemModel {
  final String id;
  final String name;
  final double price;
  final String category;
  final bool available;
  final String? description;
  final String? imageUrl;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.available = true,
    this.description,
    this.imageUrl,
  });

  factory MenuItemModel.fromJson(String id, Map<String, dynamic> json) {
    return MenuItemModel(
      id: id,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? 'Uncategorized',
      available: json['available'] as bool? ?? true,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'available': available,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }

  MenuItemModel copyWith({
    String? name,
    double? price,
    String? category,
    bool? available,
    String? description,
    String? imageUrl,
  }) {
    return MenuItemModel(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      available: available ?? this.available,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
