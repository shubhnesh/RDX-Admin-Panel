import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../models/inventory_item_model.dart';

class InventoryService {
  InventoryService({FirebaseFunctions? functions, FirebaseFirestore? firestore})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1'),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  HttpsCallable get _callable => _functions.httpsCallable('manageInventory');

  void _log(String message) {
    if (kDebugMode) debugPrint('[InventoryService] $message');
  }

  /// Emits the inventory "version" number whenever ANY inventory change
  /// happens (add / use / edit / delete). One tiny document, so it is cheap,
  /// and Firestore keeps it working across reconnects.
  Stream<int> watchVersion() {
    return _firestore.doc('inventory_meta/state').snapshots().map(
          (snap) => (snap.data()?['version'] as num?)?.toInt() ?? 0,
        );
  }

  /// One page of items (server-side filtered, ordered by item id).
  Future<Map<String, dynamic>> fetchPage({
    required String period,
    required String search,
    required String category,
    required String stockLevel,
    required int limit,
    String? cursor,
  }) async {
    final response = await _callable.call<Map<dynamic, dynamic>>({
      'action': 'getInventoryPage',
      'period': period,
      'search': search,
      'category': category,
      'stock_level': stockLevel,
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    });
    return Map<String, dynamic>.from(response.data);
  }

  /// Aggregate stats + category list (needs a full scan, so it is only
  /// requested when the inventory version actually changed).
  Future<Map<String, dynamic>> fetchStats({required String period}) async {
    final response = await _callable.call<Map<dynamic, dynamic>>({
      'action': 'getInventoryStats',
      'period': period,
    });
    return Map<String, dynamic>.from(response.data);
  }

  /// Legacy full read (kept so other callers don't break).
  Future<Map<String, dynamic>> fetchInventoryData({
    required String period,
    required String search,
    required String category,
    required String stockLevel,
  }) async {
    try {
      final response = await _callable.call<Map<dynamic, dynamic>>({
        'action': 'getInventoryData',
        'period': period,
        'search': search,
        'category': category,
        'stock_level': stockLevel,
      });
      return Map<String, dynamic>.from(response.data);
    } on FirebaseFunctionsException catch (error) {
      _log('getInventoryData failed (${error.code}): ${error.message}');
      rethrow;
    }
  }

  Future<InventoryStockHistoryPage> fetchStockHistory(
    String id, {
    String? cursor,
  }) async {
    final response = await _callable.call<Map<dynamic, dynamic>>({
      'action': 'getStockHistory',
      'id': id,
      if (cursor != null) 'cursor_id': cursor,
    });
    final data = Map<String, dynamic>.from(response.data);
    final entries = (data['entries'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (entry) => InventoryStockHistoryEntry.fromCloud(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList();
    return InventoryStockHistoryPage(
      entries: entries,
      nextCursor: data['next_cursor']?.toString(),
    );
  }

  Future<void> addStock(
    String id,
    double quantity, {
    required double purchaseCost,
  }) async {
    await _mutate('addStock', {
      'id': id,
      'quantity': quantity,
      'purchase_cost': purchaseCost,
    });
  }

  Future<void> useStock(String id, double quantity) async {
    await _mutate('useStock', {'id': id, 'quantity': quantity});
  }

  Future<String> saveItem(InventoryItemModel item) async {
    final response = await _mutate('saveItem', {
      'item': {
        'id': item.id,
        'name': item.name,
        'category': item.category,
        'quantity': item.quantity,
        'min_required': item.minRequired,
        'max_capacity': item.maxCapacity,
        'unit': item.unit,
        'portion_size': item.portionSize,
        'portion_unit': item.portionUnit,
        'unit_cost': item.unitCost,
        'total_cost': item.totalCost,
      },
    });
    final id = response['id']?.toString();
    if (id == null || id.isEmpty) {
      throw StateError('Inventory Cloud Function did not return an item ID.');
    }
    return id;
  }

  Future<void> deleteItem(String id) async {
    await _mutate('deleteItem', {'id': id});
  }

  Future<Map<String, dynamic>> _mutate(
    String action,
    Map<String, dynamic> payload,
  ) async {
    _log('$action started.');
    try {
      final response = await _callable.call<Map<dynamic, dynamic>>({
        'action': action,
        ...payload,
      });
      _log('$action completed successfully.');
      return Map<String, dynamic>.from(response.data);
    } on FirebaseFunctionsException catch (error) {
      _log('$action failed (${error.code}): ${error.message}');
      rethrow;
    }
  }
}
