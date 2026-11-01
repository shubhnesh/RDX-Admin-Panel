import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/rewards_admin_models.dart';

class RewardsAdminService {
  RewardsAdminService({
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  static const int pageSize = 25;

  Future<bool> hasReadPermission() async =>
      _hasClaim('rewardsReadAdmin');

  Future<bool> hasConfigurationPermission() async =>
      _hasClaim('rewardsConfigAdmin');

  Future<void> _requireClaim(String claim) async {
    if (!await _hasClaim(claim)) {
      throw FirebaseFunctionsException(
        code: 'permission-denied',
        message: 'Your account is not authorized to perform this operation.',
      );
    }
  }

  Future<bool> _hasClaim(String claim) async {
    if (Firebase.apps.isEmpty) return false;
    final user = _auth.currentUser;
    if (user == null) return false;
    final token = await user.getIdTokenResult(true);
    return token.claims?[claim] == true;
  }

  Future<T> _call<T>(
    String name, {
    Map<String, dynamic> data = const {},
    String requiredClaim = 'rewardsReadAdmin',
    required T Function(Object? result) parse,
  }) async {
    await _requireClaim(requiredClaim);
    final result = await _functions.httpsCallable(name).call<Object?>(data);
    return parse(result.data);
  }

  Future<RewardConfiguration> fetchConfiguration() => _call(
        'getRewardConfiguration',
        parse: (result) =>
            RewardConfiguration.fromCallable(_asMap(result, 'configuration')),
      );

  Future<void> updateConfiguration(RewardConfiguration configuration) async {
    await _call<void>(
      'updateRewardConfiguration',
      requiredClaim: 'rewardsConfigAdmin',
      data: {
        'config': configuration.toCallableMap(),
        'requestId': _requestId(),
      },
      parse: (_) {},
    );
  }

  Future<List<FoodReward>> fetchFoodRewards() async {
    await _requireClaim('rewardsReadAdmin');
    final snapshot = await _firestore
        .collection('reward_catalog')
        .orderBy(FieldPath.documentId)
        .limit(100)
        .get();
    return snapshot.docs.map(FoodReward.fromFirestore).toList();
  }

  Future<void> createFoodReward(FoodReward reward) async {
    await _call<void>(
      'createFoodReward',
      requiredClaim: 'rewardsConfigAdmin',
      data: {
        'reward': reward.toCallableMap(),
        'requestId': _requestId(),
      },
      parse: (_) {},
    );
  }

  Future<void> updateFoodReward(FoodReward reward) async {
    await _call<void>(
      'updateFoodReward',
      requiredClaim: 'rewardsConfigAdmin',
      data: {
        'rewardId': reward.id,
        'patch': reward.toCallableMap(),
        'requestId': _requestId(),
      },
      parse: (_) {},
    );
  }

  Future<void> disableFoodReward(String rewardId) async {
    await _call<void>(
      'disableReward',
      requiredClaim: 'rewardsConfigAdmin',
      data: {
        'rewardId': rewardId,
        'requestId': _requestId(),
      },
      parse: (_) {},
    );
  }

  Future<RewardAnalytics> fetchAnalytics({
    required DateTime from,
    required DateTime to,
  }) =>
      _call(
        'fetchRewardAnalytics',
        data: {
          'range': {
            'from': from.toUtc().toIso8601String(),
            'to': to.toUtc().toIso8601String(),
          },
        },
        parse: (result) =>
            RewardAnalytics.fromMap(_asMap(result, 'analytics')),
      );

  Future<RewardPage<RewardTransaction>> fetchTransactions({
    String? type,
    String? cursor,
    String? search,
  }) =>
      _fetchPage(
        'fetchRewardTransactions',
        type: type,
        cursor: cursor,
        search: search,
        parse: RewardTransaction.fromMap,
      );

  Future<RewardPage<RewardReferralRecord>> fetchReferrals({
    String? status,
    String? cursor,
    String? search,
  }) =>
      _fetchPage(
        'fetchReferralRecords',
        status: status,
        cursor: cursor,
        search: search,
        parse: RewardReferralRecord.fromMap,
      );

  Future<RewardPage<RewardRedemptionRecord>> fetchRedemptions({
    String? status,
    String? cursor,
    String? search,
  }) =>
      _fetchPage(
        'fetchRedemptionRecords',
        status: status,
        cursor: cursor,
        search: search,
        parse: RewardRedemptionRecord.fromMap,
      );

  Future<RewardPage<T>> _fetchPage<T>(
    String function, {
    String? type,
    String? status,
    String? cursor,
    String? search,
    required T Function(Map<String, dynamic>) parse,
  }) =>
      _call(
        function,
        data: {
          'filters': {
            if (type != null) 'type': type,
            if (status != null) 'status': status,
            if (search != null && search.trim().isNotEmpty)
              'search': search.trim(),
          },
          'cursor': cursor,
          'limit': pageSize,
        },
        parse: (result) =>
            RewardPage<T>.fromCallable(_asMap(result, 'page'), parse),
      );

  static Map<String, dynamic> _asMap(Object? value, String field) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw FormatException('Response field "$field" must be an object.');
  }

  static String _requestId() {
    final random = Random.secure();
    final suffix = List.generate(
      24,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    return '${DateTime.now().toUtc().microsecondsSinceEpoch}-$suffix';
  }
}
