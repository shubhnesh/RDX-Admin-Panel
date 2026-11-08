import 'package:cloud_firestore/cloud_firestore.dart';

/// A subcategory nested inside a [CategoryModel].
class SubcategoryModel {
  final String id;
  final String name;

  const SubcategoryModel({
    required this.id,
    required this.name,
  });

  factory SubcategoryModel.fromMap(Map<String, dynamic> map) {
    return SubcategoryModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
      };

  @override
  bool operator ==(Object other) => other is SubcategoryModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A menu category stored in the `menu_categories` collection.
///
/// Subcategories are embedded directly on the category document — this
/// avoids an extra collection/query round-trip and keeps them naturally
/// scoped to their parent category. There is no hard upper limit; users
/// add them one at a time via the category dialog.
class CategoryModel {
  final String id;
  final String name;
  final List<SubcategoryModel> subcategories;

  const CategoryModel({
    required this.id,
    required this.name,
    this.subcategories = const [],
  });

  factory CategoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    final rawSubs = data['subcategories'];
    final List<SubcategoryModel> subs = [];
    if (rawSubs is List) {
      for (final raw in rawSubs) {
        if (raw is Map) {
          try {
            subs.add(
              SubcategoryModel.fromMap(Map<String, dynamic>.from(raw)),
            );
          } catch (_) {
            // skip malformed subcategory entries
          }
        }
      }
    }

    return CategoryModel(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      subcategories: subs,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'subcategories': subcategories.map((s) => s.toMap()).toList(),
      };

  @override
  bool operator ==(Object other) => other is CategoryModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
