import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item_model.dart';

class InventoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('inventory');

  Future<List<InventoryItemModel>> fetchInventory() async {
    final snap = await _col.orderBy('name').get();
    return snap.docs.map((d) => InventoryItemModel.fromFirestore(d)).toList();
  }

  Future<void> updateQuantity(String id, double quantity) async {
    await _col.doc(id).update({
      'quantity': quantity,
      'last_updated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveItem(InventoryItemModel item) async {
    final data = item.toJson();
    if (item.id.isEmpty) {
      await _col.add(data);
    } else {
      await _col.doc(item.id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> deleteItem(String id) async {
    await _col.doc(id).delete();
  }
}
