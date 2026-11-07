import 'package:cloud_firestore/cloud_firestore.dart';

enum RewardEarningMode { percentage, fixedRate }

enum RewardTransactionType {
  earned,
  redeemed,
  referralBonus,
  reversal,
  adjustment,
}

class RewardConfiguration {
  const RewardConfiguration({
    required this.version,
    required this.enabled,
    required this.earningMode,
    required this.percentageBps,
    required this.pointsPerRupee,
    required this.eligibleSubtotalBasis,
    required this.minimumOrderValuePaise,
    required this.redemptionPointsPerRupee,
    required this.minimumRedemptionPoints,
    required this.maximumRedemptionPercentage,
    required this.pointsValidityDays,
    required this.referralsEnabled,
    required this.referrerRewardPoints,
    required this.newUserRewardPoints,
    required this.referralMinimumOrderValuePaise,
    required this.referralMaximumRewards,
    required this.referralValidFrom,
    required this.referralValidUntil,
    required this.referralQualificationConditions,
  });

  final int version;
  final bool enabled;
  final RewardEarningMode earningMode;
  final int percentageBps;
  final int pointsPerRupee;
  final String eligibleSubtotalBasis;
  final int minimumOrderValuePaise;
  final int redemptionPointsPerRupee;
  final int minimumRedemptionPoints;
  final int maximumRedemptionPercentage;
  final int? pointsValidityDays;
  final bool referralsEnabled;
  final int referrerRewardPoints;
  final int newUserRewardPoints;
  final int referralMinimumOrderValuePaise;
  final int? referralMaximumRewards;
  final DateTime? referralValidFrom;
  final DateTime? referralValidUntil;
  final List<String> referralQualificationConditions;

  factory RewardConfiguration.fromCallable(Map<String, dynamic> response) {
    final config = _requiredMap(response, 'config');
    final earning = _requiredMap(config, 'earning');
    final redemption = _requiredMap(config, 'redemption');
    final referrals = _requiredMap(config, 'referrals');
    final mode = _requiredString(earning, 'mode');

    return RewardConfiguration(
      version: _requiredInt(response, 'version'),
      enabled: _requiredBool(config, 'enabled'),
      earningMode: switch (mode) {
        'percentage' => RewardEarningMode.percentage,
        'fixedRate' => RewardEarningMode.fixedRate,
        _ => throw FormatException('Unknown reward earning mode: $mode'),
      },
      percentageBps: _requiredInt(earning, 'percentageBps'),
      pointsPerRupee: _requiredInt(earning, 'pointsPerRupee'),
      eligibleSubtotalBasis: _requiredString(earning, 'eligibleSubtotalBasis'),
      minimumOrderValuePaise: _requiredInt(earning, 'minimumOrderValuePaise'),
      redemptionPointsPerRupee: _requiredInt(redemption, 'pointsPerRupee'),
      minimumRedemptionPoints: _requiredInt(redemption, 'minimumPoints'),
      maximumRedemptionPercentage:
          _requiredInt(redemption, 'maximumOrderPercentage'),
      pointsValidityDays: _optionalInt(config, 'pointsValidityDays'),
      referralsEnabled: _requiredBool(referrals, 'enabled'),
      referrerRewardPoints: _requiredInt(referrals, 'referrerRewardPoints'),
      newUserRewardPoints: _requiredInt(referrals, 'newUserRewardPoints'),
      referralMinimumOrderValuePaise:
          _requiredInt(referrals, 'qualifyingOrderMinimumValuePaise'),
      referralMaximumRewards:
          _optionalInt(referrals, 'maximumRewardsPerCampaign'),
      referralValidFrom: _optionalDate(referrals, 'validFrom'),
      referralValidUntil: _optionalDate(referrals, 'validUntil'),
      referralQualificationConditions:
          _requiredStringList(referrals, 'qualificationConditions'),
    );
  }

  Map<String, dynamic> toCallableMap() => {
        'enabled': enabled,
        'earning': {
          'mode': earningMode.name,
          'percentageBps': percentageBps,
          'pointsPerRupee': pointsPerRupee,
          'eligibleSubtotalBasis': eligibleSubtotalBasis,
          'minimumOrderValuePaise': minimumOrderValuePaise,
        },
        'redemption': {
          'pointsPerRupee': redemptionPointsPerRupee,
          'minimumPoints': minimumRedemptionPoints,
          'maximumOrderPercentage': maximumRedemptionPercentage,
        },
        'pointsValidityDays': pointsValidityDays,
        'referrals': {
          'enabled': referralsEnabled,
          'referrerRewardPoints': referrerRewardPoints,
          'newUserRewardPoints': newUserRewardPoints,
          'qualifyingOrderMinimumValuePaise': referralMinimumOrderValuePaise,
          'maximumRewardsPerCampaign': referralMaximumRewards,
          'validFrom': referralValidFrom?.toIso8601String(),
          'validUntil': referralValidUntil?.toIso8601String(),
          'qualificationConditions': referralQualificationConditions,
        },
      };
}

class FoodReward {
  const FoodReward({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.pointsCost,
    required this.available,
    this.stockLimit,
    this.validFrom,
    this.validUntil,
    this.usageCount = 0,
  });

  final String id;
  final String menuItemId;
  final String name;
  final int pointsCost;
  final bool available;
  final int? stockLimit;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final int usageCount;

  factory FoodReward.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return FoodReward(
      id: document.id,
      menuItemId: _requiredString(data, 'menuItemId'),
      name: _requiredString(data, 'name'),
      pointsCost: _requiredInt(data, 'pointsCost'),
      available: _requiredBool(data, 'available'),
      stockLimit: _optionalInt(data, 'stockLimit'),
      validFrom: _optionalDate(data, 'validFrom'),
      validUntil: _optionalDate(data, 'validUntil'),
      usageCount: _requiredInt(data, 'usageCount'),
    );
  }

  Map<String, dynamic> toCallableMap() => {
        'menuItemId': menuItemId,
        'name': name,
        'pointsCost': pointsCost,
        'available': available,
        'stockLimit': stockLimit,
        'validFrom': validFrom?.toIso8601String(),
        'validUntil': validUntil?.toIso8601String(),
      };
}

class RewardTransaction {
  const RewardTransaction({
    required this.id,
    required this.userId,
    required this.points,
    required this.type,
    required this.createdAt,
    this.orderId,
    this.referralId,
    this.description = '',
    this.status,
  });

  final String id;
  final String userId;
  final int points;
  final RewardTransactionType type;
  final DateTime createdAt;
  final String? orderId;
  final String? referralId;
  final String description;
  final String? status;

  factory RewardTransaction.fromMap(Map<String, dynamic> data) =>
      RewardTransaction(
        id: _requiredString(data, 'transactionId'),
        userId: _requiredString(data, 'userId'),
        points: _requiredInt(data, 'points'),
        type: _transactionType(_requiredString(data, 'type')),
        createdAt: _requiredDate(data, 'createdAt'),
        orderId: _optionalString(data, 'orderId'),
        referralId: _optionalString(data, 'referralId'),
        description: _optionalString(data, 'description') ?? '',
        status: _optionalString(data, 'status'),
      );
}

class RewardReferralRecord {
  const RewardReferralRecord({
    required this.id,
    required this.referrerId,
    required this.referredUserId,
    required this.referralCode,
    required this.status,
    required this.createdAt,
    this.qualifyingOrderId,
    this.pointsAwarded = 0,
  });

  final String id;
  final String referrerId;
  final String referredUserId;
  final String referralCode;
  final String status;
  final DateTime createdAt;
  final String? qualifyingOrderId;
  final int pointsAwarded;

  factory RewardReferralRecord.fromMap(Map<String, dynamic> data) =>
      RewardReferralRecord(
        id: _requiredString(data, 'referralId'),
        referrerId: _requiredString(data, 'referrerId'),
        referredUserId: _requiredString(data, 'referredUserId'),
        referralCode: _requiredString(data, 'referralCode'),
        status: _requiredString(data, 'status'),
        createdAt: _requiredDate(data, 'createdAt'),
        qualifyingOrderId: _optionalString(data, 'qualifyingOrderId'),
        pointsAwarded: _optionalInt(data, 'pointsAwarded') ?? 0,
      );
}

class RewardRedemptionRecord {
  const RewardRedemptionRecord({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.rewardName,
    required this.pointsUsed,
    required this.status,
    required this.createdAt,
    this.orderId,
  });

  final String id;
  final String userId;
  final String rewardId;
  final String rewardName;
  final int pointsUsed;
  final String status;
  final DateTime createdAt;
  final String? orderId;

  factory RewardRedemptionRecord.fromMap(Map<String, dynamic> data) =>
      RewardRedemptionRecord(
        id: _requiredString(data, 'redemptionId'),
        userId: _requiredString(data, 'userId'),
        rewardId: _requiredString(data, 'rewardId'),
        rewardName: _requiredString(data, 'rewardName'),
        pointsUsed: _requiredInt(data, 'pointsUsed'),
        status: _requiredString(data, 'status'),
        createdAt: _requiredDate(data, 'createdAt'),
        orderId: _optionalString(data, 'orderId'),
      );
}

class RewardAnalytics {
  const RewardAnalytics({
    required this.totalPointsIssued,
    required this.totalPointsRedeemed,
    required this.outstandingPointsLiability,
    required this.activeRewardCampaigns,
    required this.usersWithBalances,
    required this.totalReferralRewardsIssued,
    required this.successfulReferrals,
    required this.totalRedemptions,
  });

  final int totalPointsIssued;
  final int totalPointsRedeemed;
  final int outstandingPointsLiability;
  final int activeRewardCampaigns;
  final int usersWithBalances;
  final int totalReferralRewardsIssued;
  final int successfulReferrals;
  final int totalRedemptions;

  factory RewardAnalytics.fromMap(Map<String, dynamic> data) => RewardAnalytics(
        totalPointsIssued: _requiredInt(data, 'totalPointsIssued'),
        totalPointsRedeemed: _requiredInt(data, 'totalPointsRedeemed'),
        outstandingPointsLiability:
            _requiredInt(data, 'outstandingPointsLiability'),
        activeRewardCampaigns: _requiredInt(data, 'activeRewardCampaigns'),
        usersWithBalances: _requiredInt(data, 'usersWithBalances'),
        totalReferralRewardsIssued:
            _requiredInt(data, 'totalReferralRewardsIssued'),
        successfulReferrals: _requiredInt(data, 'successfulReferrals'),
        totalRedemptions: _requiredInt(data, 'totalRedemptions'),
      );
}

class RewardPage<T> {
  const RewardPage({required this.items, this.nextPageToken});

  final List<T> items;
  final String? nextPageToken;

  factory RewardPage.fromCallable(
    Map<String, dynamic> response,
    T Function(Map<String, dynamic>) parse,
  ) {
    final rawItems = response['items'];
    if (rawItems is! List) {
      throw const FormatException('Response field "items" must be a list.');
    }

    final token = _optionalString(response, 'nextPageToken');
    return RewardPage<T>(
      items: rawItems.map((item) => parse(_asMap(item, 'items[]'))).toList(),
      nextPageToken: token,
    );
  }
}

Map<String, dynamic> _requiredMap(
  Map<String, dynamic> data,
  String field,
) =>
    _asMap(data[field], field);

Map<String, dynamic> _asMap(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('Response field "$field" must be an object.');
}

String _requiredString(Map<String, dynamic> data, String field) {
  final value = data[field];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw FormatException('Response field "$field" must be a non-empty string.');
}

String? _optionalString(Map<String, dynamic> data, String field) {
  final value = data[field];
  if (value == null) return null;
  if (value is String) return value.trim().isEmpty ? null : value.trim();
  throw FormatException('Response field "$field" must be a string or null.');
}

int _requiredInt(Map<String, dynamic> data, String field) {
  final value = data[field];
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw FormatException('Response field "$field" must be an integer.');
}

int? _optionalInt(Map<String, dynamic> data, String field) {
  final value = data[field];
  if (value == null) return null;
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw FormatException('Response field "$field" must be an integer or null.');
}

bool _requiredBool(Map<String, dynamic> data, String field) {
  final value = data[field];
  if (value is bool) return value;
  throw FormatException('Response field "$field" must be a boolean.');
}

List<String> _requiredStringList(Map<String, dynamic> data, String field) {
  final value = data[field];
  if (value is List && value.every((item) => item is String)) {
    return value.cast<String>();
  }
  throw FormatException('Response field "$field" must be a string list.');
}

DateTime _requiredDate(Map<String, dynamic> data, String field) {
  final value = _dateValue(data[field], field);
  if (value != null) return value;
  throw FormatException('Response field "$field" must be a timestamp.');
}

DateTime? _optionalDate(Map<String, dynamic> data, String field) =>
    _dateValue(data[field], field);

DateTime? _dateValue(Object? value, String field) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('Response field "$field" must be a timestamp or null.');
}

RewardTransactionType _transactionType(String value) => switch (value) {
      'earned' => RewardTransactionType.earned,
      'redeemed' => RewardTransactionType.redeemed,
      'referral_bonus' => RewardTransactionType.referralBonus,
      'reversal' => RewardTransactionType.reversal,
      'adjustment' => RewardTransactionType.adjustment,
      _ => throw FormatException('Unknown reward transaction type: $value'),
    };
