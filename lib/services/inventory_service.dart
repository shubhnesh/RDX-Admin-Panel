import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item_model.dart';

class InventoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('inventory');

  Future<List<InventoryItemModel>> fetchInventory() async {
    final snap = await _col.orderBy('name').get();
    return snap.docs.map((d) => InventoryItemModel.fromFirestore(d)).toList();
  }

  Future<InventoryItemModel?> getItem(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return InventoryItemModel.fromFirestore(doc);
  }

  Future<void> updateQuantity(String id, double quantity) async {
    await _col.doc(id).update({
      'quantity': quantity,
      'last_updated': FieldValue.serverTimestamp(),
    });
  }

  Future<String> saveItem(InventoryItemModel item) async {
    final data = item.toJson();
    if (item.id.isEmpty) {
      final ref = await _col.add(data);
      return ref.id;
    } else {
      await _col.doc(item.id).set(data, SetOptions(merge: true));
      return item.id;
    }
  }

  Future<void> deleteItem(String id) async {
    await _col.doc(id).delete();
  }

  /// Returns only items that are below their minimum required level.
  Future<List<InventoryItemModel>> fetchLowStock() async {
    final all = await fetchInventory();
    return all.where((e) => e.needsRestock).toList();
  }
}
