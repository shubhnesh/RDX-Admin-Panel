enum StockStatus { inStock, lowStock, critical, outOfStock }

class InventoryStockHistoryEntry {
  final String id;
  final String type;
  final double quantity;
  final DateTime? occurredAt;
  final double stockBefore;
  final double stockAfter;
  final double? purchaseCost;
  final double? unitCost;
  final double? totalCost;

  const InventoryStockHistoryEntry({
    required this.id,
    required this.type,
    required this.quantity,
    required this.occurredAt,
    required this.stockBefore,
    required this.stockAfter,
    this.purchaseCost,
    this.unitCost,
    this.totalCost,
  });

  factory InventoryStockHistoryEntry.fromCloud(Map<String, dynamic> data) {
    double number(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    double? nullableNumber(dynamic value) =>
        value == null ? null : number(value);
    final dateValue = data['occurred_at'];

    return InventoryStockHistoryEntry(
      id: data['id']?.toString() ?? '',
      type: data['type']?.toString() ?? 'unknown',
      quantity: number(data['quantity']),
      occurredAt:
          dateValue is String ? DateTime.tryParse(dateValue)?.toLocal() : null,
      stockBefore: number(data['stock_before']),
      stockAfter: number(data['stock_after']),
      purchaseCost: nullableNumber(data['purchase_cost']),
      unitCost: nullableNumber(data['unit_cost']),
      totalCost: nullableNumber(data['total_cost']),
    );
  }
}

class InventoryStockHistoryPage {
  final List<InventoryStockHistoryEntry> entries;
  final String? nextCursor;

  const InventoryStockHistoryPage({
    required this.entries,
    required this.nextCursor,
  });

  bool get hasMore => nextCursor != null;
}

class InventoryItemModel {
  final String id;
  final String name;
  final String category;
  final double quantity;
  final double minRequired;
  final double maxCapacity;
  final String unit;
  final double portionSize;
  final String? portionUnit;
  final double unitCost;
  final double totalCost;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastAddedAt;
  final DateTime? lastUsedAt;
  final DateTime? initialStockAt;
  final double? initialStockQty;
  final double? lastAddedQty;
  final double? lastAddedCost;
  final double? lastAddedStockBefore;
  final double? lastUsedQty;
  final double? lastUsedStockBefore;
  final double totalAdded;
  final double totalUsed;
  final String? notes;
  final StockStatus status;
  final double stockPercent;
  final double stockFillFraction;
  final bool addedInPeriod;
  final bool usedInPeriod;
  final String recentAction;

  const InventoryItemModel({
    required this.id,
    required this.name,
    this.category = 'Uncategorized',
    required this.quantity,
    required this.minRequired,
    this.maxCapacity = 0,
    required this.unit,
    this.portionSize = 0,
    this.portionUnit,
    this.unitCost = 0,
    this.totalCost = 0,
    this.createdAt,
    this.updatedAt,
    this.lastAddedAt,
    this.lastUsedAt,
    this.initialStockAt,
    this.initialStockQty,
    this.lastAddedQty,
    this.lastAddedCost,
    this.lastAddedStockBefore,
    this.lastUsedQty,
    this.lastUsedStockBefore,
    this.totalAdded = 0,
    this.totalUsed = 0,
    this.notes,
    this.status = StockStatus.inStock,
    this.stockPercent = 0,
    this.stockFillFraction = 0,
    this.addedInPeriod = false,
    this.usedInPeriod = false,
    this.recentAction = 'none',
  });

  DateTime? get lastUpdated => updatedAt;

  factory InventoryItemModel.fromCloud(Map<String, dynamic> data) {
    double number(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    double? nullableNumber(dynamic value) =>
        value == null ? null : number(value);

    DateTime? date(dynamic value) =>
        value is String ? DateTime.tryParse(value)?.toLocal() : null;

    final createdAt = date(data['created_at']);
    final lastAddedAt = date(data['last_added_at']);
    final lastAddedQty = nullableNumber(data['last_added_qty']);
    final initialStockQty = nullableNumber(data['initial_stock_qty']) ??
        (createdAt != null &&
                lastAddedAt != null &&
                createdAt.isAtSameMomentAs(lastAddedAt)
            ? lastAddedQty
            : null);

    return InventoryItemModel(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Uncategorized',
      quantity: number(data['quantity']),
      minRequired: number(data['min_required']),
      maxCapacity: number(data['max_capacity']),
      unit: data['unit']?.toString() ?? 'pcs',
      portionSize: number(data['portion_size']),
      portionUnit: data['portion_unit']?.toString(),
      unitCost: number(data['unit_cost']),
      totalCost: number(data['total_cost']),
      createdAt: createdAt,
      updatedAt: date(data['updated_at']),
      lastAddedAt: lastAddedAt,
      lastUsedAt: date(data['last_used_at']),
      initialStockAt: date(data['initial_stock_at']) ?? createdAt,
      initialStockQty: initialStockQty,
      lastAddedQty: lastAddedQty,
      lastAddedCost: nullableNumber(data['last_added_cost']),
      lastAddedStockBefore: nullableNumber(data['last_added_stock_before']),
      lastUsedQty: nullableNumber(data['last_used_qty']),
      lastUsedStockBefore: nullableNumber(data['last_used_stock_before']),
      totalAdded: number(data['total_added']),
      totalUsed: number(data['total_used']),
      notes: data['notes']?.toString(),
      status: switch (data['status']) {
        'low_stock' => StockStatus.lowStock,
        'critical' => StockStatus.critical,
        'out_of_stock' => StockStatus.outOfStock,
        _ => StockStatus.inStock,
      },
      stockPercent: number(data['stock_percent']),
      stockFillFraction: number(data['stock_fill_fraction']),
      addedInPeriod: data['added_in_period'] == true,
      usedInPeriod: data['used_in_period'] == true,
      recentAction: data['recent_action']?.toString() ?? 'none',
    );
  }

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
