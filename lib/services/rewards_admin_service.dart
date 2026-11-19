import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/rewards_admin_model.dart';

class RewardReconciliationResult {
  const RewardReconciliationResult({
    required this.pointsEarned,
    required this.reason,
  });

  final int pointsEarned;
  final String reason;
}

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

  /// Rows fetched per request (tables load more on demand).
  static const int pageSize = 10;

  void _log(String message) {
    if (kDebugMode) debugPrint('[Rewards] $message');
  }

  // ---- Change tracking ----------------------------------------------------

  /// Emits per-area change counters. A counter only goes up when something
  /// in that area is added, edited or removed (see rewardsVersion.js), so the
  /// app re-fetches only what actually changed. One tiny document.
  Stream<Map<String, int>> watchVersions() {
    return _firestore.doc('rewards_meta/state').snapshots().map((snap) {
      final data = snap.data() ?? const <String, dynamic>{};
      int read(String key) => (data[key] as num?)?.toInt() ?? 0;
      return {
        'ledger': read('ledger'),
        'referrals': read('referrals'),
        'redemptions': read('redemptions'),
        'catalog': read('catalog'),
        'config': read('config'),
      };
    });
  }

  // ---- Permissions --------------------------------------------------------

  Future<bool> hasReadPermission() async {
    _log('Checking rewards read permission.');
    final allowed = await _hasClaim('rewardsReadAdmin');
    _log('Rewards read permission ${allowed ? 'granted' : 'not granted'}.');
    return allowed;
  }

  Future<bool> hasConfigurationPermission() async {
    _log('Checking rewards configuration permission.');
    final allowed = await _hasClaim('rewardsConfigAdmin');
    _log(
      'Rewards configuration permission ${allowed ? 'granted' : 'not granted'}.',
    );
    return allowed;
  }

  Future<void> _requireClaim(String claim) async {
    if (!await _hasClaim(claim)) {
      _log('Required permission claim is missing: $claim.');
      throw FirebaseFunctionsException(
        code: 'permission-denied',
        message: 'Your account is not authorized to perform this operation.',
      );
    }
  }

  /// Uses the locally stored token first (works offline). Only when the claim
  /// is missing does it force a network refresh, in case claims were updated.
  Future<bool> _hasClaim(String claim) async {
    if (Firebase.apps.isEmpty) {
      _log('Permission check unavailable: Firebase is not initialized.');
      return false;
    }
    final user = _auth.currentUser;
    if (user == null) {
      _log('Permission check denied: no signed-in user.');
      return false;
    }

    bool allowed(IdTokenResult token) {
      final claims = token.claims;
      final isRewardsClaim =
          claim == 'rewardsReadAdmin' || claim == 'rewardsConfigAdmin';
      return claims?[claim] == true ||
          (isRewardsClaim && claims?['role'] == 'admin');
    }

    try {
      if (allowed(await user.getIdTokenResult())) return true;
      return allowed(await user.getIdTokenResult(true));
    } on FirebaseAuthException catch (error) {
      _log('Permission claim lookup failed (Auth code: ${error.code}).');
      rethrow;
    }
  }

  // ---- Callable plumbing --------------------------------------------------

  Future<T> _call<T>(
    String name, {
    Map<String, dynamic> data = const {},
    String requiredClaim = 'rewardsReadAdmin',
    required T Function(Object? result) parse,
  }) async {
    _log('$name started.');
    try {
      await _requireClaim(requiredClaim);
      final result = await _functions.httpsCallable(name).call<Object?>(data);
      final parsed = parse(result.data);
      _log('$name completed.');
      return parsed;
    } on FirebaseFunctionsException catch (error) {
      _log('$name failed (Functions code: ${error.code}).');
      rethrow;
    } on FirebaseException catch (error) {
      _log('$name failed (Firebase code: ${error.code}).');
      rethrow;
    } catch (error) {
      _log('$name failed (${error.runtimeType}).');
      rethrow;
    }
  }

  // ---- Raw fetchers (JSON maps, so the provider can cache them) -----------

  Future<Map<String, dynamic>> fetchConfigurationRaw() => _call(
        'getRewardConfiguration',
        parse: (result) => _asMap(result, 'configuration'),
      );

  Future<Map<String, dynamic>> fetchAnalyticsRaw({
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
        parse: (result) => _asMap(result, 'analytics'),
      );

  /// One page ([pageSize] rows) of transactions / referrals / redemptions.
  Future<Map<String, dynamic>> fetchPageRaw(
    String function, {
    String? type,
    String? status,
    String? cursor,
    String? search,
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
        parse: (result) => _asMap(result, 'page'),
      );

  // ---- Typed fetchers (kept for existing callers) -------------------------

  Future<RewardConfiguration> fetchConfiguration() async =>
      RewardConfiguration.fromCallable(await fetchConfigurationRaw());

  Future<RewardAnalytics> fetchAnalytics({
    required DateTime from,
    required DateTime to,
  }) async =>
      RewardAnalytics.fromMap(await fetchAnalyticsRaw(from: from, to: to));

  Future<RewardPage<RewardTransaction>> fetchTransactions({
    String? type,
    String? cursor,
    String? search,
  }) async =>
      RewardPage<RewardTransaction>.fromCallable(
        await fetchPageRaw(
          'fetchRewardTransactions',
          type: type,
          cursor: cursor,
          search: search,
        ),
        RewardTransaction.fromMap,
      );

  Future<RewardPage<RewardReferralRecord>> fetchReferrals({
    String? status,
    String? cursor,
    String? search,
  }) async =>
      RewardPage<RewardReferralRecord>.fromCallable(
        await fetchPageRaw(
          'fetchReferralRecords',
          status: status,
          cursor: cursor,
          search: search,
        ),
        RewardReferralRecord.fromMap,
      );

  Future<RewardPage<RewardRedemptionRecord>> fetchRedemptions({
    String? status,
    String? cursor,
    String? search,
  }) async =>
      RewardPage<RewardRedemptionRecord>.fromCallable(
        await fetchPageRaw(
          'fetchRedemptionRecords',
          status: status,
          cursor: cursor,
          search: search,
        ),
        RewardRedemptionRecord.fromMap,
      );

  // ---- Catalog ------------------------------------------------------------

  Future<List<FoodReward>> fetchFoodRewards() async {
    const operation = 'fetchFoodRewards';
    _log('$operation started.');
    try {
      await _requireClaim('rewardsReadAdmin');
      final snapshot = await _firestore
          .collection('reward_catalog')
          .orderBy(FieldPath.documentId)
          .limit(100)
          .get();
      final rewards = snapshot.docs.map(FoodReward.fromFirestore).toList();
      _log('$operation parsed ${rewards.length} catalog records.');
      return rewards;
    } on FirebaseException catch (error) {
      _log('$operation failed (Firebase code: ${error.code}).');
      rethrow;
    } catch (error) {
      _log('$operation failed (${error.runtimeType}).');
      rethrow;
    }
  }

  // ---- Mutations ----------------------------------------------------------

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

  Future<RewardReconciliationResult> reconcileOrderRewards(
    String orderId,
  ) =>
      _call(
        'reconcileOrderRewards',
        requiredClaim: 'rewardsConfigAdmin',
        data: {'orderId': orderId.trim()},
        parse: (result) {
          final response = _asMap(result, 'reconciliation');
          final points = response['reward_points_earned'];
          final reason = response['reason'];
          if (points is! int || reason is! String) {
            throw const FormatException(
              'Reconciliation response has an unsupported format.',
            );
          }
          return RewardReconciliationResult(
            pointsEarned: points,
            reason: reason,
          );
        },
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
