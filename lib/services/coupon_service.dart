import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon_model.dart';

class CouponService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('coupons');

  Future<List<CouponModel>> fetchCoupons() async {
    final snap = await _col.orderBy('start_date', descending: true).get();
    return snap.docs.map((d) => CouponModel.fromFirestore(d)).toList();
  }

  Future<void> createCoupon(CouponModel coupon) async {
    await _col.add(coupon.toJson());
  }

  Future<void> updateCoupon(CouponModel coupon) async {
    await _col.doc(coupon.id).set(coupon.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteCoupon(String id) async {
    await _col.doc(id).delete();
  }
}
