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

  /// Blunt quantity overwrite (kept for backward compatibility with any
  /// existing call-sites). Prefer [addStock] / [useStock] for restocking
  /// and consumption — this method recomputes total_cost from scratch
  /// using the *current* unit cost, which is only correct if you truly
  /// mean "this is the new total quantity, re-priced at today's rate".
  Future<void> updateQuantity(String id, double quantity) async {
    final doc = await _col.doc(id).get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final unitCost = (data['unit_cost'] as num?)?.toDouble() ?? 0;

    await _col.doc(id).update({
      'quantity': quantity,
      'unit_cost': unitCost,
      'total_cost': quantity * unitCost,
      'last_updated': FieldValue.serverTimestamp(),
    });
  }

  /// Restocking. Adds [addedQuantity] to the current quantity, and adds
  /// (addedQuantity * current unit cost) to the *existing* total_cost —
  /// it never recomputes the whole stock at the new/current unit price.
  /// This is what keeps older stock's cost basis intact when the market
  /// price moves.
  Future<void> addStock(String id, double addedQuantity) async {
    if (addedQuantity <= 0) return;
    if (addedQuantity > 5000) {
      throw ArgumentError('Cannot add more than 5000 units at once');
    }
    final doc = await _col.doc(id).get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final currentQty = (data['quantity'] as num?)?.toDouble() ?? 0;
    final unitCost = (data['unit_cost'] as num?)?.toDouble() ?? 0;
    final currentTotalCost =
        (data['total_cost'] as num?)?.toDouble() ?? (currentQty * unitCost);

    final addedCost = addedQuantity * unitCost;

    await _col.doc(id).update({
      'quantity': currentQty + addedQuantity,
      'total_cost': currentTotalCost + addedCost,
      'last_updated': FieldValue.serverTimestamp(),
    });
  }

  /// Consumption. Subtracts [usedQuantity] from the current quantity.
  /// total_cost is left untouched on purpose — using material that was
  /// already bought and paid for isn't a new financial transaction, so
  /// it must not reduce the recorded cost of the (remaining) stock.
  Future<void> useStock(String id, double usedQuantity) async {
    if (usedQuantity <= 0) return;
    final doc = await _col.doc(id).get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final currentQty = (data['quantity'] as num?)?.toDouble() ?? 0;
    if (usedQuantity > currentQty) {
      throw ArgumentError('Cannot use more than current stock');
    }
    final newQty = currentQty - usedQuantity;

    await _col.doc(id).update({
      'quantity': newQty < 0 ? 0 : newQty,
      // total_cost intentionally omitted from this update.
      'last_updated': FieldValue.serverTimestamp(),
    });
  }

  /// Creating vs editing behave differently on purpose:
  /// - New item (empty id): total_cost is computed fresh as
  ///   quantity * unitCost — this is the material's initial cost basis.
  /// - Existing item (edit): total_cost is taken as-is from [item]
  ///   (the caller is expected to pass along the existing total_cost
  ///   unchanged), so editing name/category/unit cost/min/max through
  ///   the form never silently re-prices stock that was already bought.
  ///   Stock quantity changes belong to [addStock] / [useStock], not to
  ///   this general-purpose save.
  Future<String> saveItem(InventoryItemModel item) async {
    final isNew = item.id.isEmpty;
    final itemToSave =
        isNew ? item.copyWith(totalCost: item.computedTotalCost) : item;
    final data = itemToSave.toJson();
    if (isNew) {
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
