// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/menu_item_model.dart';

// class MenuService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   CollectionReference get _col => _db.collection('menu_items');

//   Future<List<MenuItemModel>> fetchMenuItems() async {
//     final snap = await _col.orderBy('name').get();
//     return snap.docs.map((d) => MenuItemModel.fromFirestore(d)).toList();
//   }

//   Stream<List<MenuItemModel>> streamMenuItems() {
//     return _col.orderBy('name').snapshots().map(
//           (snap) => snap.docs.map((d) => MenuItemModel.fromFirestore(d)).toList(),
//         );
//   }

//   Future<MenuItemModel> fetchItemById(String id) async {
//     final doc = await _col.doc(id).get();
//     if (!doc.exists) throw Exception('Menu item not found');
//     return MenuItemModel.fromFirestore(doc);
//   }

//   Future<void> saveItem(MenuItemModel item) async {
//     final data = item.toJson();
//     if (item.id.isEmpty) {
//       data['created_at'] = FieldValue.serverTimestamp();
//       await _col.add(data);
//     } else {
//       await _col.doc(item.id).set(data, SetOptions(merge: true));
//     }
//   }

//   Future<void> deleteItem(String id) async {
//     await _col.doc(id).delete();
//   }

//   Future<void> toggleAvailability(String id, bool available) async {
//     await _col.doc(id).update({
//       'available': available,
//       'updated_at': FieldValue.serverTimestamp(),
//     });
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/menu_item_model.dart';

class MenuService {
  MenuService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('menu_items');

  Future<List<MenuItemModel>> fetchMenuItems() async {
    final snapshot = await _col.orderBy('name').get();

    return snapshot.docs.map(MenuItemModel.fromFirestore).toList();
  }

  Stream<List<MenuItemModel>> streamMenuItems() {
    return _col.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs.map(MenuItemModel.fromFirestore).toList(),
        );
  }

  Future<MenuItemModel> fetchItemById(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('Menu item ID cannot be empty.');
    }

    final doc = await _col.doc(id).get();

    if (!doc.exists) {
      throw Exception('Menu item not found.');
    }

    return MenuItemModel.fromFirestore(doc);
  }

  /// Creates a new menu item.
  ///
  /// Firestore generates the document ID.
  Future<String> createItem(MenuItemModel item) async {
    final doc = _col.doc();

    final data = item.toFirestore();

    data['created_at'] = FieldValue.serverTimestamp();
    data['updated_at'] = FieldValue.serverTimestamp();

    await doc.set(data);

    return doc.id;
  }

  /// Updates an existing menu item.
  ///
  /// created_at is intentionally NOT touched.
  Future<void> updateItem(MenuItemModel item) async {
    if (item.id.trim().isEmpty) {
      throw ArgumentError(
        'Cannot update a menu item without an ID.',
      );
    }

    final data = item.toFirestore();

    data['updated_at'] = FieldValue.serverTimestamp();

    await _col.doc(item.id).update(data);
  }

  /// Creates or updates depending on whether the item has an ID.
  Future<String?> saveItem(MenuItemModel item) async {
    if (item.id.trim().isEmpty) {
      return createItem(item);
    }

    await updateItem(item);

    return item.id;
  }

  Future<void> deleteItem(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError(
        'Cannot delete a menu item without an ID.',
      );
    }

    await _col.doc(id).delete();
  }

  Future<void> toggleAvailability(
    String id,
    bool available,
  ) async {
    if (id.trim().isEmpty) {
      throw ArgumentError(
        'Cannot change availability without an ID.',
      );
    }

    await _col.doc(id).update({
      'available': available,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateDisplaySettings({
    required String id,
    required bool showOnMobileApp,
    required bool featuredItem,
  }) async {
    if (id.trim().isEmpty) {
      throw ArgumentError(
        'Cannot update display settings without an ID.',
      );
    }

    await _col.doc(id).update({
      'show_on_mobile_app': showOnMobileApp,
      'featured_item': featuredItem,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
