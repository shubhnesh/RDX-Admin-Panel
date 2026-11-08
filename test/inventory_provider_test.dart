import 'package:flutter_test/flutter_test.dart';
import 'package:rdx_admin/models/inventory_item_model.dart';
import 'package:rdx_admin/providers/inventory_provider.dart';
import 'package:rdx_admin/services/inventory_service.dart';

void main() {
  group('InventoryProvider automatic refresh', () {
    late _FakeInventoryService service;
    late InventoryProvider provider;

    setUp(() {
      service = _FakeInventoryService();
      provider = InventoryProvider(
        service,
        refreshInterval: const Duration(milliseconds: 25),
      );
    });

    tearDown(() {
      provider.dispose();
    });

    test('refreshes changed items and preserves unchanged item instances',
        () async {
      service.response = _response(riceQuantity: 10);
      await provider.load();

      final originalRice =
          provider.items.firstWhere((item) => item.id == 'rice');
      final originalFlour =
          provider.items.firstWhere((item) => item.id == 'flour');
      final fetchCount = service.fetchCount;
      var notifications = 0;
      provider.addListener(() => notifications++);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(notifications, 0);

      service.response = _response(riceQuantity: 7);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(service.fetchCount, greaterThanOrEqualTo(fetchCount + 1));
      expect(notifications, 1);
      expect(
        provider.items.firstWhere((item) => item.id == 'rice').quantity,
        7,
      );
      expect(
        identical(
          provider.items.firstWhere((item) => item.id == 'rice'),
          originalRice,
        ),
        isFalse,
      );
      expect(
        identical(
          provider.items.firstWhere((item) => item.id == 'flour'),
          originalFlour,
        ),
        isTrue,
      );
      expect(
        identical(
          provider.filteredItems.firstWhere((item) => item.id == 'flour'),
          originalFlour,
        ),
        isTrue,
      );
      expect(provider.isLoading, isFalse);
    });

    test('category changes filter loaded items immediately without fetching',
        () async {
      await provider.load();
      final fetchCount = service.fetchCount;
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setCategory('Baking');

      expect(notified, isTrue);
      expect(provider.selectedCategory, 'Baking');
      expect(provider.filteredItems.map((item) => item.id), ['sugar']);
      expect(service.fetchCount, fetchCount);
    });

    test('search and stock filters apply immediately to loaded items',
        () async {
      await provider.load();

      provider.setSearch('sug');
      expect(provider.filteredItems.map((item) => item.id), ['sugar']);

      provider.setSearch('');
      provider.setStockLevelFilter('Critical');
      expect(provider.filteredItems.map((item) => item.id), ['sugar']);
    });
  });
}

class _FakeInventoryService implements InventoryService {
  Map<String, dynamic> response = _response(riceQuantity: 10);
  int fetchCount = 0;

  @override
  Future<Map<String, dynamic>> fetchInventoryData({
    required String period,
    required String search,
    required String category,
    required String stockLevel,
  }) async {
    fetchCount++;
    return response;
  }

  @override
  Future<InventoryStockHistoryPage> fetchStockHistory(
    String id, {
    String? cursor,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> addStock(
    String id,
    double quantity, {
    required double purchaseCost,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> useStock(String id, double quantity) =>
      throw UnimplementedError();

  @override
  Future<String> saveItem(InventoryItemModel item) =>
      throw UnimplementedError();

  @override
  Future<void> deleteItem(String id) => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _response({required double riceQuantity}) {
  final items = [
    {
      'id': 'rice',
      'name': 'Rice',
      'category': 'Dry Goods',
      'quantity': riceQuantity,
      'min_required': 5,
      'max_capacity': 20,
      'unit': 'kg',
      'unit_cost': 2,
      'total_cost': riceQuantity * 2,
      'status': 'in_stock',
    },
    {
      'id': 'flour',
      'name': 'Flour',
      'category': 'Dry Goods',
      'quantity': 8,
      'min_required': 5,
      'max_capacity': 20,
      'unit': 'kg',
      'unit_cost': 3,
      'total_cost': 24,
      'status': 'in_stock',
    },
    {
      'id': 'sugar',
      'name': 'Sugar',
      'category': 'Baking',
      'quantity': 1,
      'min_required': 5,
      'max_capacity': 20,
      'unit': 'kg',
      'unit_cost': 3,
      'total_cost': 3,
      'status': 'critical',
      'added_in_period': false,
      'used_in_period': false,
    },
  ];

  return {
    'items': items,
    'filtered_items': items,
    'categories': ['Baking', 'Dry Goods'],
    'stats': {
      'expenditure': 44,
      'total_items': 3,
      'added_item_count': 0,
      'used_item_count': 0,
      'needs_restock_count': 1,
    },
  };
}
