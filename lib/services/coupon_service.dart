import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon_model.dart';

class CouponService {
  CouponService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('coupons');

  Future<List<CouponModel>> fetchCoupons() async {
    final snap = await _col.get();
    final coupons = snap.docs.map(CouponModel.fromFirestore).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    return coupons;
  }

  Stream<List<CouponModel>> streamCoupons() {
    return _col.snapshots().map((snapshot) {
      final coupons = snapshot.docs.map(CouponModel.fromFirestore).toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
      return coupons;
    });
  }

  Future<void> createCoupon(CouponModel coupon) async {
    // Use the coupon code as the document ID so the collection
    // shows readable names (e.g. SUMMER60) instead of random IDs.
    await _col.doc(coupon.id).set(coupon.toJson());
  }

  Future<void> updateCoupon(CouponModel coupon) async {
    await _col.doc(coupon.id).set(coupon.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteCoupon(String id) async {
    await _col.doc(id).delete();
  }
}
