import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/seed_service.dart';

class SettingsProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SeedService _seedService = SeedService();

  bool isLoading = false;
  String? errorMessage;
  bool isSeeding = false;
  String? seedMessage;

  String restaurantName = 'RDX Restaurants';
  String description = 'Best in city, freshly made every morning.';
  String address = 'Chandigarh';
  String phone = '+91 98765 43210';
  String email = 'contact@rdxrestaurant.com';

  bool autoAcceptOrders = true;
  bool requireManagerApprovalForRefunds = true;
  bool keepPricingConsistent = false;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final doc = await _db.collection('settings').doc('restaurant').get();
      if (doc.exists) {
        final d = doc.data()!;
        restaurantName = d['restaurant_name'] ?? restaurantName;
        description = d['description'] ?? description;
        address = d['address'] ?? address;
        phone = d['phone'] ?? phone;
        email = d['email'] ?? email;
        autoAcceptOrders = d['auto_accept_orders'] ?? true;
        requireManagerApprovalForRefunds =
            d['require_manager_approval_for_refunds'] ?? true;
        keepPricingConsistent = d['keep_pricing_consistent'] ?? false;
      }
    } catch (e) {
      errorMessage = 'Failed to load settings';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> toggleAutoAccept(bool value) async {
    final previous = autoAcceptOrders;
    autoAcceptOrders = value;
    notifyListeners();
    await _persistToggle(
      field: 'auto_accept_orders',
      value: value,
      rollback: () => autoAcceptOrders = previous,
    );
  }

  Future<void> toggleManagerApproval(bool value) async {
    final previous = requireManagerApprovalForRefunds;
    requireManagerApprovalForRefunds = value;
    notifyListeners();
    await _persistToggle(
      field: 'require_manager_approval_for_refunds',
      value: value,
      rollback: () => requireManagerApprovalForRefunds = previous,
    );
  }

  Future<void> toggleKeepPricing(bool value) async {
    final previous = keepPricingConsistent;
    keepPricingConsistent = value;
    notifyListeners();
    await _persistToggle(
      field: 'keep_pricing_consistent',
      value: value,
      rollback: () => keepPricingConsistent = previous,
    );
  }

  Future<void> _persistToggle({
    required String field,
    required bool value,
    required void Function() rollback,
  }) async {
    try {
      await _db.collection('settings').doc('restaurant').set({
        field: value,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      rollback();
      errorMessage = 'Failed to save setting.';
      notifyListeners();
    }
  }

  Future<bool> save({
    required String name,
    required String desc,
    required String addr,
    required String ph,
    required String em,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _db.collection('settings').doc('restaurant').set({
        'restaurant_name': name,
        'description': desc,
        'address': addr,
        'phone': ph,
        'email': em,
        'auto_accept_orders': autoAcceptOrders,
        'require_manager_approval_for_refunds':
            requireManagerApprovalForRefunds,
        'keep_pricing_consistent': keepPricingConsistent,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      restaurantName = name;
      description = desc;
      address = addr;
      phone = ph;
      email = em;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Failed to save settings.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// One-click seed so client never needs Firebase console for data.
  Future<void> seedSampleData() async {
    isSeeding = true;
    seedMessage = null;
    notifyListeners();
    try {
      final already = await _seedService.isAlreadySeeded();
      if (already) {
        seedMessage = 'Data already exists. Seed skipped.';
      } else {
        await _seedService.seedAll();
        seedMessage = 'Sample data created successfully!';
      }
    } catch (e) {
      seedMessage = 'Seed failed: $e';
    }
    isSeeding = false;
    notifyListeners();
  }
}
