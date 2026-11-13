import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coupon_model.dart';
import '../services/coupon_service.dart';

class CouponProvider extends ChangeNotifier {
  final CouponService _service;
  CouponProvider(this._service);

  List<CouponModel> _coupons = [];
  bool isLoading = false;
  String? errorMessage;
  CouponStatus? statusFilter; // null = All
  StreamSubscription<List<CouponModel>>? _subscription;
  bool _hasReceivedSnapshot = false;

  List<CouponModel> get filteredCoupons {
    if (statusFilter == null) return _coupons;
    return _coupons.where((c) => c.status == statusFilter).toList();
  }

  int get activeCount =>
      _coupons.where((c) => c.status == CouponStatus.active).length;

  Future<void> load() async {
    if (_subscription != null) return;

    isLoading = !_hasReceivedSnapshot;
    errorMessage = null;
    notifyListeners();
    try {
      _subscription = _service.streamCoupons().listen(
        _onCouponsChanged,
        onError: (Object error) {
          _subscription = null;
          isLoading = false;
          errorMessage = 'Failed to load coupons: $error';
          notifyListeners();
        },
        onDone: () {
          _subscription = null;
          isLoading = false;
          errorMessage = 'Coupon updates stopped unexpectedly.';
          notifyListeners();
        },
        cancelOnError: true,
      );
    } catch (e) {
      errorMessage = 'Failed to load coupons: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  void _onCouponsChanged(List<CouponModel> coupons) {
    final wasLoading = isLoading;
    final hadError = errorMessage != null;
    final hadSnapshot = _hasReceivedSnapshot;
    final oldById = {for (final coupon in _coupons) coupon.id: coupon};
    final List<CouponModel> updatedCoupons = coupons.map<CouponModel>((coupon) {
      final previous = oldById[coupon.id];
      return previous != null && _sameCoupon(previous, coupon)
          ? previous
          : coupon;
    }).toList(growable: false);

    final changed = updatedCoupons.length != _coupons.length ||
        List.generate(updatedCoupons.length, (index) {
          return !identical(updatedCoupons[index], _coupons[index]);
        }).any((value) => value);

    _hasReceivedSnapshot = true;
    isLoading = false;
    errorMessage = null;
    if (changed) {
      _coupons = updatedCoupons;
    }
    if (changed || wasLoading || hadError || !hadSnapshot) {
      notifyListeners();
    }
  }

  bool _sameCoupon(CouponModel a, CouponModel b) {
    return a.id == b.id &&
        a.code == b.code &&
        a.description == b.description &&
        a.discountType == b.discountType &&
        a.discountValue == b.discountValue &&
        a.minOrderValue == b.minOrderValue &&
        a.usageLimit == b.usageLimit &&
        a.usageCount == b.usageCount &&
        a.startDate == b.startDate &&
        a.endDate == b.endDate &&
        a.status == b.status &&
        a.imageUrl == b.imageUrl &&
        a.applicableSubCategoryId == b.applicableSubCategoryId &&
        a.applicableItemId == b.applicableItemId &&
        _sameStrings(a.applicableCategories, b.applicableCategories) &&
        _sameStrings(a.applicableSubCategories, b.applicableSubCategories);
  }

  bool _sameStrings(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  void setStatusFilter(CouponStatus? status) {
    statusFilter = status;
    notifyListeners();
  }

  Future<void> _resumeUpdatesIfNeeded() async {
    if (_subscription == null) {
      await load();
    } else if (errorMessage != null) {
      errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> deleteCoupon(String id) async {
    await _service.deleteCoupon(id);
    await _resumeUpdatesIfNeeded();
  }

  Future<bool> createCoupon(CouponModel coupon) async {
    try {
      await _service.createCoupon(coupon);
      await _resumeUpdatesIfNeeded();
      return true;
    } catch (e) {
      errorMessage = 'Failed to create coupon.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCoupon(CouponModel coupon) async {
    try {
      await _service.updateCoupon(coupon);
      await _resumeUpdatesIfNeeded();
      return true;
    } catch (e) {
      errorMessage = 'Failed to update coupon.';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Riverpod provider wrapping [CouponProvider].
final couponProvider = ChangeNotifierProvider<CouponProvider>(
  (ref) => CouponProvider(CouponService()),
);
