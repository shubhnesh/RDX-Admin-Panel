import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item_model.dart';

class MenuService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('menu_items');

  Future<List<MenuItemModel>> fetchMenuItems() async {
    final snap = await _col.orderBy('name').get();
    return snap.docs.map((d) => MenuItemModel.fromFirestore(d)).toList();
  }

  Stream<List<MenuItemModel>> streamMenuItems() {
    return _col.orderBy('name').snapshots().map(
          (snap) =>
              snap.docs.map((d) => MenuItemModel.fromFirestore(d)).toList(),
        );
  }

  Future<MenuItemModel> fetchItemById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) throw Exception('Menu item not found');
    return MenuItemModel.fromFirestore(doc);
  }

  Future<void> saveItem(MenuItemModel item) async {
    final data = item.toJson();
    if (item.id.isEmpty) {
      data['created_at'] = FieldValue.serverTimestamp();
      await _col.add(data);
    } else {
      await _col.doc(item.id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> deleteItem(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> toggleAvailability(String id, bool available) async {
    await _col.doc(id).update({
      'available': available,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
