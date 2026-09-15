import 'package:cloud_firestore/cloud_firestore.dart';

enum StockStatus { inStock, lowStock, critical, outOfStock }

class InventoryItemModel {
  final String id;
  final String name;
  final String category;
  final double quantity;
  final double minRequired; // a.k.a. lowStockThreshold in older seed data
  final double maxCapacity;
  final String unit;
  final double unitCost;
  final double totalCost; // persisted: quantity * unitCost
  final DateTime? lastUpdated;
  final String? notes;

  const InventoryItemModel({
    required this.id,
    required this.name,
    this.category = 'Uncategorized',
    required this.quantity,
    required this.minRequired,
    this.maxCapacity = 0,
    required this.unit,
    this.unitCost = 0,
    this.totalCost = 0,
    this.lastUpdated,
    this.notes,
  });

  /// Alias kept for older call-sites / seed data that used `lowStockThreshold`.
  double get lowStockThreshold => minRequired;

  /// The correct total cost given current quantity/unitCost. Use this when
  /// you need a guaranteed-fresh value (e.g. right before saving); the
  /// stored [totalCost] field is what gets persisted/read from Firestore.
  double get computedTotalCost => quantity * unitCost;

  /// Percentage of max capacity currently held (0–100+).
  /// Falls back to minRequired-based estimate when maxCapacity is not set.
  double get stockPercent {
    if (maxCapacity > 0) return (quantity / maxCapacity) * 100;
    // When only a threshold exists, treat 2× threshold as a soft "full" level.
    if (minRequired > 0) return (quantity / (minRequired * 2)).clamp(0, 1.5) * 100;
    return quantity > 0 ? 100 : 0;
  }

  /// Amount short of the minimum required level (negative = surplus).
  double get shortage => minRequired - quantity;

  StockStatus get status {
    if (quantity <= 0) return StockStatus.outOfStock;
    if (quantity < minRequired * 0.25) return StockStatus.critical;
    if (quantity < minRequired) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  bool get needsRestock =>
      status == StockStatus.lowStock || status == StockStatus.critical;

  InventoryItemModel copyWith({
    String? id,
    String? name,
    String? category,
    double? quantity,
    double? minRequired,
    double? maxCapacity,
    String? unit,
    double? unitCost,
    double? totalCost,
    DateTime? lastUpdated,
    String? notes,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      minRequired: minRequired ?? this.minRequired,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      unit: unit ?? this.unit,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'min_required': minRequired,
      // Keep legacy key so older readers still work
      'low_stock_threshold': minRequired,
      'max_capacity': maxCapacity,
      'unit': unit,
      'unit_cost': unitCost,
      'total_cost': totalCost,
      'last_updated': lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : FieldValue.serverTimestamp(),
      if (notes != null) 'notes': notes,
    };
  }

  factory InventoryItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    // Prefer the new field; fall back to the legacy seed field.
    final minReq = (data['min_required'] as num?)?.toDouble() ??
        (data['low_stock_threshold'] as num?)?.toDouble() ??
        0;
    final quantity = (data['quantity'] as num?)?.toDouble() ?? 0;
    final unitCost = (data['unit_cost'] as num?)?.toDouble() ?? 0;
    return InventoryItemModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? 'Uncategorized',
      quantity: quantity,
      minRequired: minReq,
      maxCapacity: (data['max_capacity'] as num?)?.toDouble() ?? 0,
      unit: data['unit'] as String? ?? 'pcs',
      unitCost: unitCost,
      // Read the stored total cost; if it's missing (older docs), fall
      // back to computing it from quantity/unitCost so the UI never
      // shows a blank value.
      totalCost:
          (data['total_cost'] as num?)?.toDouble() ?? (quantity * unitCost),
      lastUpdated: (data['last_updated'] as Timestamp?)?.toDate(),
      notes: data['notes'] as String?,
    );
  }

  /// Empty template used by the Add Material form.
  factory InventoryItemModel.empty() => const InventoryItemModel(
        id: '',
        name: '',
        category: 'Dry Pantry',
        quantity: 0,
        minRequired: 0,
        maxCapacity: 0,
        unit: 'pcs',
        unitCost: 0,
        totalCost: 0,
      );
}
