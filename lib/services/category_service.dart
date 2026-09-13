import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category_model.dart';

/// Handles reading and writing menu categories (and their nested
/// subcategories) to Firestore. Mirrors the style of [MenuService].
class CategoryService {
  CategoryService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  static const maxSubcategories = 5;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('menu_categories');

  Future<List<CategoryModel>> fetchCategories() async {
    final snapshot = await _col.orderBy('name').get();
    return snapshot.docs.map(CategoryModel.fromFirestore).toList();
  }

  Stream<List<CategoryModel>> streamCategories() {
    return _col.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs.map(CategoryModel.fromFirestore).toList(),
        );
  }

  Future<CategoryModel> fetchCategoryById(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('Category ID cannot be empty.');
    }

    final doc = await _col.doc(id).get();

    if (!doc.exists) {
      throw Exception('Category not found.');
    }

    return CategoryModel.fromFirestore(doc);
  }

  /// Creates a category with up to [maxSubcategories] subcategories.
  ///
  /// Document IDs are readable slugs derived from the name (e.g.
  /// "Chineses" -> "chineses") to match the existing `menu_categories`
  /// naming convention, instead of Firestore's random auto-IDs. If the
  /// slug is already taken, a numeric suffix is appended. Subcategory IDs
  /// are namespaced under the category slug (e.g. "chineses-noodles").
  ///
  /// Empty/blank subcategory names are dropped since subcategories are
  /// optional.
  Future<String> createCategory({
    required String name,
    List<String> subcategoryNames = const [],
  }) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Category name cannot be empty.');
    }

    final cleanedSubcategoryNames =
        subcategoryNames.map((n) => n.trim()).where((n) => n.isNotEmpty).toList();

    if (cleanedSubcategoryNames.length > maxSubcategories) {
      throw ArgumentError(
        'A category can have at most $maxSubcategories subcategories.',
      );
    }

    final categorySlug = await _uniqueSlug(_slugify(trimmedName));

    final subcategories = cleanedSubcategoryNames
        .map((subName) => SubcategoryModel(
              id: '$categorySlug-${_slugify(subName)}',
              name: subName,
            ).toMap())
        .toList();

    await _col.doc(categorySlug).set({
      'name': trimmedName,
      'subcategories': subcategories,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    return categorySlug;
  }

  Future<void> updateCategory(CategoryModel category) async {
    if (category.id.trim().isEmpty) {
      throw ArgumentError('Cannot update a category without an ID.');
    }

    if (category.subcategories.length > maxSubcategories) {
      throw ArgumentError(
        'A category can have at most $maxSubcategories subcategories.',
      );
    }

    await _col.doc(category.id).update({
      'name': category.name,
      'subcategories': category.subcategories.map((s) => s.toMap()).toList(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategory(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('Cannot delete a category without an ID.');
    }

    await _col.doc(id).delete();
  }

  /// Converts a name into a URL/document-id-safe slug, e.g.
  /// "Mojito Coolers & Mocktails!" -> "mojito-coolers-mocktails".
  String _slugify(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9\s-]"), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    return slug.isEmpty ? 'category' : slug;
  }

  /// Appends `-2`, `-3`, ... to [baseSlug] until it no longer collides
  /// with an existing category document.
  Future<String> _uniqueSlug(String baseSlug) async {
    var slug = baseSlug;
    var suffix = 2;

    while ((await _col.doc(slug).get()).exists) {
      slug = '$baseSlug-$suffix';
      suffix++;
    }

    return slug;
  }
}
