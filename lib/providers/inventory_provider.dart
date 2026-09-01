import 'package:flutter/material.dart';
import '../models/inventory_item_model.dart';
import '../services/inventory_service.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryService _service;
  InventoryProvider(this._service);

  List<InventoryItemModel> items = [];
  bool isLoading = false;
  String? errorMessage;

  int get lowStockCount => items.where((e) => e.status == StockStatus.lowStock).length;
  int get outOfStockCount => items.where((e) => e.status == StockStatus.outOfStock).length;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      items = await _service.fetchInventory();
    } catch (e) {
      errorMessage = 'Failed to load inventory.';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> updateQuantity(String id, double quantity) async {
    await _service.updateQuantity(id, quantity);
    await load();
  }
}
