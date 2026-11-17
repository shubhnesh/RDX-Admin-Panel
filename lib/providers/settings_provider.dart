import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rdx_admin/services/settings_service.dart';

/// Domain model for operating hours of one period (e.g. weekdays / weekends).
class OperatingHours {
  const OperatingHours({
    required this.open,
    required this.close,
    this.isOpen = true,
  });

  final String open; // e.g. "08:00 AM"
  final String close; // e.g. "11:00 PM"
  final bool isOpen;

  OperatingHours copyWith({
    String? open,
    String? close,
    bool? isOpen,
  }) {
    return OperatingHours(
      open: open ?? this.open,
      close: close ?? this.close,
      isOpen: isOpen ?? this.isOpen,
    );
  }

  Map<String, dynamic> toMap() => {
        'open': open,
        'close': close,
        'is_open': isOpen,
      };

  factory OperatingHours.fromMap(
    Map<String, dynamic>? map, {
    required String defaultOpen,
    required String defaultClose,
    bool defaultIsOpen = true,
  }) {
    if (map == null) {
      return OperatingHours(
        open: defaultOpen,
        close: defaultClose,
        isOpen: defaultIsOpen,
      );
    }
    return OperatingHours(
      open: map['open'] as String? ?? defaultOpen,
      close: map['close'] as String? ?? defaultClose,
      isOpen: map['is_open'] as bool? ?? defaultIsOpen,
    );
  }
}

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({SettingsService? service})
      : _service = service ?? SettingsService() {
    load();
  }

  final SettingsService _service;

  void _log(String message) {
    if (kDebugMode) debugPrint('[SettingsProvider] $message');
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

  bool isLoading = false;
  String? errorMessage;

  // ── Identity ────────────────────────────────────────────────────────────
  String restaurantName = 'RDX Fast Foods';
  String description = 'Best in city, freshly made every morning.';
  String address = 'Chandigarh';
  String phone = '+91 98765 43210';
  String email = 'contact@rdxrestaurant.com';

  // ── Operational rules ───────────────────────────────────────────────────
  bool autoAcceptOrders = true;
  bool requireManagerApprovalForRefunds = true;
  bool keepPricingConsistent = false;
  bool lateNightDelivery = false;
  bool longDistanceDelivery = true;

  // ── Operating hours ─────────────────────────────────────────────────────
  OperatingHours weekdays = const OperatingHours(
    open: '08:00 AM',
    close: '11:00 PM',
    isOpen: true,
  );
  OperatingHours weekends = const OperatingHours(
    open: '10:00 AM',
    close: '02:00 PM',
    isOpen: true,
  );

  // ── Fees (source of truth: settings/fees — server only for order totals) ─
  double gstPercent = 0;
  double lateNightFee = 0;
  String lateNightStart = '22:00';
  String lateNightEnd = '06:00';
  double longDistanceFee = 0;
  double deliveryFee = 0;
  double freeDeliveryAbove = 0;
  bool orderFeesEnabled = false;

  bool isLateNightDeliveryTime([DateTime? now]) {
    final current = now ?? DateTime.now();
    final hours = current.weekday >= DateTime.saturday ? weekends : weekdays;
    if (!hours.isOpen) return false;
    final close = _minutes(hours.close);
    final open = _minutes(hours.open);
    final currentMinutes = current.hour * 60 + current.minute;
    if (close > open) return currentMinutes >= close;
    return currentMinutes >= close && currentMinutes < open;
  }

  int _minutes(String value) {
    final normalized = value.trim().toUpperCase();
    final isPm = normalized.endsWith('PM');
    final isAm = normalized.endsWith('AM');
    final clock = isPm || isAm
        ? normalized.substring(0, normalized.length - 2).trim()
        : normalized;
    final parts = clock.split(':');
    var hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    if (isPm && hour != 12) hour += 12;
    if (isAm && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  // ── Load ────────────────────────────────────────────────────────────────
  Future<void> load() async {
    _log('Settings load started.');
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _log('Loading restaurant settings.');
      final d = await _service.load();
      if (d != null) {
        restaurantName = d['restaurant_name'] as String? ?? restaurantName;
        description = d['description'] as String? ?? description;
        address = d['address'] as String? ?? address;
        phone = d['phone'] as String? ?? phone;
        email = d['email'] as String? ?? email;

        autoAcceptOrders = d['auto_accept_orders'] as bool? ?? true;
        requireManagerApprovalForRefunds =
            d['require_manager_approval_for_refunds'] as bool? ?? true;
        keepPricingConsistent = d['keep_pricing_consistent'] as bool? ?? false;
        lateNightDelivery = d['late_night_delivery'] as bool? ?? false;
        longDistanceDelivery = d['long_distance_delivery'] as bool? ?? true;

        weekdays = OperatingHours.fromMap(
          d['weekdays'] as Map<String, dynamic>?,
          defaultOpen: '08:00 AM',
          defaultClose: '11:00 PM',
        );
        weekends = OperatingHours.fromMap(
          d['weekends'] as Map<String, dynamic>?,
          defaultOpen: '10:00 AM',
          defaultClose: '02:00 PM',
        );
      }

      _log('Loading order fee configuration.');
      final fees = await _service.loadFees();
      orderFeesEnabled = false;
      if (fees != null) {
        orderFeesEnabled = fees['fees_enabled'] as bool? ?? false;
        gstPercent = (fees['gst_percent'] as num?)?.toDouble() ?? 0;
        lateNightFee = (fees['late_night_fee'] as num?)?.toDouble() ?? 0;
        lateNightStart = fees['late_night_start'] as String? ?? lateNightStart;
        lateNightEnd = fees['late_night_end'] as String? ?? lateNightEnd;
        longDistanceFee = (fees['long_distance_fee'] as num?)?.toDouble() ?? 0;
        deliveryFee = (fees['delivery_fee'] as num?)?.toDouble() ?? 0;
        freeDeliveryAbove =
            (fees['free_delivery_above'] as num?)?.toDouble() ?? 0;
        // Fee-section toggles live on settings/fees (source of truth for orders).
        if (fees.containsKey('late_night_delivery')) {
          lateNightDelivery = fees['late_night_delivery'] == true;
        }
        if (fees.containsKey('long_distance_delivery')) {
          longDistanceDelivery = fees['long_distance_delivery'] == true;
        }
      }
      _log(
        'Settings load completed (restaurant document: ${d != null}, '
        'fee document: ${fees != null}).',
      );
    } catch (error) {
      _logFailure('Settings load', error);
      errorMessage = 'Failed to load settings';
    }

    isLoading = false;
    notifyListeners();
  }

  // ── Toggles ─────────────────────────────────────────────────────────────
  Future<void> toggleAutoAccept(bool value) async {
    _log('Auto-accept toggle requested: $value.');
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
    _log('Manager approval toggle requested: $value.');
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
    _log('Keep-pricing toggle requested: $value.');
    final previous = keepPricingConsistent;
    keepPricingConsistent = value;
    notifyListeners();
    await _persistToggle(
      field: 'keep_pricing_consistent',
      value: value,
      rollback: () => keepPricingConsistent = previous,
    );
  }

  Future<void> toggleLateNightDelivery(bool value) async {
    _log('Late-night delivery toggle requested: $value.');
    final previous = lateNightDelivery;
    lateNightDelivery = value;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.setFeeToggle('late_night_delivery', value);
      _log('Late-night delivery toggle completed.');
    } catch (error) {
      _logFailure('Late-night delivery toggle', error);
      lateNightDelivery = previous;
      errorMessage = 'Failed to update late-night delivery.';
      notifyListeners();
    }
  }

  Future<void> toggleLongDistanceDelivery(bool value) async {
    _log('Long-distance delivery toggle requested: $value.');
    final previous = longDistanceDelivery;
    longDistanceDelivery = value;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.setFeeToggle('long_distance_delivery', value);
      _log('Long-distance delivery toggle completed.');
    } catch (error) {
      _logFailure('Long-distance delivery toggle', error);
      longDistanceDelivery = previous;
      errorMessage = 'Failed to update long-distance delivery.';
      notifyListeners();
    }
  }

  Future<void> toggleOrderFees(bool value) async {
    _log('Order-fees enabled update requested: $value.');
    final previous = orderFeesEnabled;
    orderFeesEnabled = value;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.setOrderFeesEnabled(value);
      _log('Order-fees enabled update completed.');
    } catch (error) {
      _logFailure('Order-fees enabled update', error);
      orderFeesEnabled = previous;
      errorMessage = 'Failed to update order fees: $error';
      notifyListeners();
    }
  }

  Future<bool> saveOperatingHours({
    required OperatingHours weekdaysHours,
    required OperatingHours weekendsHours,
  }) async {
    _log('Operating-hours save requested.');
    try {
      await _service.saveOperatingHours(
        weekdays: weekdaysHours.toMap(),
        weekends: weekendsHours.toMap(),
      );
      weekdays = weekdaysHours;
      weekends = weekendsHours;
      notifyListeners();
      _log('Operating-hours save completed.');
      return true;
    } catch (error) {
      _logFailure('Operating-hours save', error);
      errorMessage = 'Failed to save operating hours.';
      notifyListeners();
      return false;
    }
  }

  /// Saves fee config through the server-side validation callable.
  Future<bool> saveFees({
    required double gstPercent,
    required double lateNightFee,
    required String lateNightStart,
    required String lateNightEnd,
    required double longDistanceFee,
    required double deliveryFee,
    double freeDeliveryAbove = 0,
  }) async {
    _log('Order-fees save requested.');
    errorMessage = null;
    try {
      await _service.saveFees({
        'gst_percent': gstPercent,
        'late_night_fee': lateNightFee,
        'late_night_start': lateNightStart.trim(),
        'late_night_end': lateNightEnd.trim(),
        'long_distance_fee': longDistanceFee,
        'delivery_fee': deliveryFee,
        'free_delivery_above': freeDeliveryAbove,
        'late_night_delivery': lateNightDelivery,
        'long_distance_delivery': longDistanceDelivery,
      });
      this.gstPercent = gstPercent;
      this.lateNightFee = lateNightFee;
      this.lateNightStart = lateNightStart.trim();
      this.lateNightEnd = lateNightEnd.trim();
      this.longDistanceFee = longDistanceFee;
      this.deliveryFee = deliveryFee;
      this.freeDeliveryAbove = freeDeliveryAbove;
      notifyListeners();
      _log('Order-fees save completed.');
      return true;
    } catch (error) {
      _logFailure('Order-fees save', error);
      errorMessage = 'Failed to save fees: $error';
      notifyListeners();
      return false;
    }
  }

  Future<void> _persistToggle({
    required String field,
    required bool value,
    required void Function() rollback,
  }) async {
    errorMessage = null;
    _log('Settings toggle "$field" update started.');
    try {
      await _service.updateToggle(field, value);
      _log('Settings toggle "$field" update completed.');
    } catch (error) {
      _logFailure('Settings toggle "$field" update', error);
      rollback();
      errorMessage = 'Failed to save setting.';
      notifyListeners();
    }
  }

  // ── Full save (identity + hours) ────────────────────────────────────────
  Future<bool> save({
    required String name,
    required String desc,
    required String addr,
    required String ph,
    required String em,
    OperatingHours? weekdaysHours,
    OperatingHours? weekendsHours,
  }) async {
    _log('Restaurant settings save requested.');
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _service.saveProfile(
        name: name,
        description: desc,
        address: addr,
        phone: ph,
        email: em,
      );
      if (weekdaysHours != null && weekendsHours != null) {
        await _service.saveOperatingHours(
          weekdays: weekdaysHours.toMap(),
          weekends: weekendsHours.toMap(),
        );
      }

      restaurantName = name;
      description = desc;
      address = addr;
      phone = ph;
      email = em;
      if (weekdaysHours != null) weekdays = weekdaysHours;
      if (weekendsHours != null) weekends = weekendsHours;

      isLoading = false;
      notifyListeners();
      _log('Restaurant settings save completed.');
      return true;
    } catch (error) {
      _logFailure('Restaurant settings save', error);
      errorMessage = 'Failed to save settings.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

/// Riverpod provider wrapping [SettingsProvider].
final settingsProvider = ChangeNotifierProvider<SettingsProvider>(
  (ref) => SettingsProvider(),
);
