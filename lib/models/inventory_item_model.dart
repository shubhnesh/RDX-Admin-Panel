import 'package:cloud_firestore/cloud_firestore.dart';

enum StockStatus { inStock, lowStock, outOfStock }

class InventoryItemModel {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final double lowStockThreshold;
  final DateTime lastUpdated;

  InventoryItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.lowStockThreshold,
    required this.lastUpdated,
  });

  StockStatus get status {
    if (quantity <= 0) return StockStatus.outOfStock;
    if (quantity <= lowStockThreshold) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  bool get isLowStock => status == StockStatus.lowStock;
  bool get isOutOfStock => status == StockStatus.outOfStock;

  factory InventoryItemModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>? ?? {};
    return InventoryItemModel.fromJson({...json, 'id': doc.id});
  }

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] ?? 'pcs',
      lowStockThreshold: (json['low_stock_threshold'] as num?)?.toDouble() ?? 5,
      lastUpdated: _parseTimestamp(json['last_updated']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'low_stock_threshold': lowStockThreshold,
        'last_updated': FieldValue.serverTimestamp(),
      };

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
