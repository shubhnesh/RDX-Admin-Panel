import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Pure data-access layer for restaurant settings.
/// No UI or Riverpod dependencies — safe to unit-test in isolation.
///
/// Fees live in settings/fees. Only Cloud Functions use those values when
/// computing order totals. Clients may read for UI preview only.
class SettingsService {
  SettingsService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions;

  final FirebaseFirestore _db;
  final FirebaseFunctions? _functions;

  FirebaseFunctions get _cloudFunctions =>
      _functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  static const _restaurantDocId = 'restaurant';
  static const _feesDocId = 'fees';

  DocumentReference<Map<String, dynamic>> get _restaurantDoc =>
      _db.collection('settings').doc(_restaurantDocId);

  DocumentReference<Map<String, dynamic>> get _feesDoc =>
      _db.collection('settings').doc(_feesDocId);

  void _log(String message) {
    if (kDebugMode) debugPrint('[SettingsService] $message');
  }

  void _logFailure(String operation, Object error) {
    if (error is FirebaseFunctionsException) {
      _log('$operation failed (Functions code: ${error.code}).');
    } else if (error is FirebaseException) {
      _log('$operation failed (Firebase code: ${error.code}).');
    } else {
      _log('$operation failed (${error.runtimeType}).');
    }
  }

  Future<T> _logged<T>(
    String operation,
    Future<T> Function() request,
  ) async {
    _log('$operation: backend request started.');
    try {
      final result = await request();
      _log('$operation: backend request completed.');
      return result;
    } catch (error) {
      _logFailure(operation, error);
      rethrow;
    }
  }

  /// Loads the restaurant settings document. Returns null if it does not exist.
  Future<Map<String, dynamic>?> load() => _logged(
        'Load restaurant settings',
        () async {
          final snapshot = await _restaurantDoc.get();
          if (!snapshot.exists) return null;
          return snapshot.data();
        },
      );

  /// Updates restaurant identity through the admin-only Cloud Function.
  Future<void> saveProfile({
    required String name,
    required String description,
    required String address,
    required String phone,
    required String email,
  }) =>
      _logged(
        'Update restaurant profile',
        () => _cloudFunctions
            .httpsCallable('manageRestaurantSettings')
            .call<void>({
          'action': 'updateProfile',
          'profile': {
            'restaurant_name': name,
            'description': description,
            'address': address,
            'phone': phone,
            'email': email,
          },
        }),
      );

  Future<void> saveOperatingHours({
    required Map<String, dynamic> weekdays,
    required Map<String, dynamic> weekends,
  }) =>
      _logged(
        'Update restaurant operating hours',
        () => _cloudFunctions
            .httpsCallable('manageRestaurantSettings')
            .call<void>({
          'action': 'updateOperatingHours',
          'hours': {'weekdays': weekdays, 'weekends': weekends},
        }),
      );

  /// Convenience: update a single boolean toggle field.
  Future<void> updateToggle(String field, bool value) => _logged(
        'Update settings toggle "$field" to $value',
        () => _cloudFunctions
            .httpsCallable('manageRestaurantSettings')
            .call<void>({
          'action': 'updateToggle',
          'field': field,
          'value': value,
        }),
      );

  // ── Fees (settings/fees) ────────────────────────────────────────────────

  /// Loads fee config. Returns null if the document does not exist yet.
  Future<Map<String, dynamic>?> loadFees() => _logged(
        'Load order fees',
        () async {
          final snapshot = await _feesDoc.get();
          if (!snapshot.exists) return null;
          return snapshot.data();
        },
      );

  /// Updates fee configuration through the server-side validation callable.
  ///
  /// Expected keys (all numbers unless noted):
  /// - gst_percent
  /// - late_night_fee
  /// - late_night_start (string, e.g. "22:00")
  /// - late_night_end   (string, e.g. "06:00")
  /// - long_distance_fee
  /// - delivery_fee
  /// - free_delivery_above
  Future<void> saveFees(Map<String, dynamic> data) => _logged(
        'Update order fees (fields: ${data.keys.join(', ')})',
        () => _cloudFunctions.httpsCallable('updateOrderFees').call<void>({
          'action': 'updateFees',
          'fees': data,
        }),
      );

  /// Changes whether the Cloud Functions apply configured fees to orders.
  Future<void> setOrderFeesEnabled(bool enabled) => _logged(
        'Set order fees enabled to $enabled',
        () => _cloudFunctions.httpsCallable('updateOrderFees').call<void>({
          'action': 'setEnabled',
          'enabled': enabled,
        }),
      );

  /// Toggles late-night or long-distance fee application on settings/fees.
  ///
  /// [field] must be `late_night_delivery` or `long_distance_delivery`.
  Future<void> setFeeToggle(String field, bool value) => _logged(
        'Set fee toggle "$field" to $value',
        () => _cloudFunctions.httpsCallable('updateOrderFees').call<void>({
          'action': 'setToggle',
          'field': field,
          'value': value,
        }),
      );
}
