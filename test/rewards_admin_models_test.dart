import 'package:flutter_test/flutter_test.dart';
import 'package:rdx_admin/models/rewards_admin_model.dart';

void main() {
  group('RewardConfiguration', () {
    test('parses the approved configuration response shape (bands)', () {
      final configuration = RewardConfiguration.fromCallable({
        'version': 3,
        'config': {
          'enabled': true,
          'earning': {
            'mode': 'bands',
            'eligibleSubtotalBasis': 'afterDiscountBeforeTax',
            'minimumOrderValuePaise': 10000,
            'bands': [
              {
                'minTotal': 0,
                'maxTotal': 499.99,
                'pointsMode': 'range',
                'minPts': 1,
                'maxPts': 4,
                'fixedPts': 1,
              },
              {
                'minTotal': 500,
                'maxTotal': null,
                'pointsMode': 'fixed',
                'minPts': 5,
                'maxPts': 5,
                'fixedPts': 5,
              },
            ],
          },
          'redemption': {
            'pointsPerRupee': 10,
            'minimumPoints': 100,
            'maximumOrderPercentage': 20,
          },
          'pointsValidityDays': null,
          'referrals': {
            'enabled': true,
            'referrerRewardPoints': 200,
            'newUserRewardPoints': 100,
            'qualifyingOrderMinimumValuePaise': 25000,
            'maximumRewardsPerCampaign': 500,
            'validFrom': '2026-10-01T00:00:00.000Z',
            'validUntil': null,
            'qualificationConditions': ['paid', 'delivered'],
          },
        },
      });

      expect(configuration.version, 3);
      expect(configuration.enabled, isTrue);
      expect(configuration.eligibleSubtotalBasis, 'afterDiscountBeforeTax');
      expect(configuration.minimumOrderValuePaise, 10000);
      expect(configuration.earningBands, hasLength(2));
      expect(configuration.earningBands[0].pointsMode, RewardBandPointsMode.range);
      expect(configuration.earningBands[0].minPts, 1);
      expect(configuration.earningBands[0].maxPts, 4);
      expect(configuration.earningBands[1].pointsMode, RewardBandPointsMode.fixed);
      expect(configuration.earningBands[1].fixedPts, 5);
      expect(configuration.redemptionPointsPerRupee, 10);
      expect(configuration.referrerRewardPoints, 200);
      expect(
        configuration.referralQualificationConditions,
        ['paid', 'delivered'],
      );
      expect(
        configuration.toCallableMap()['referrals']['newUserRewardPoints'],
        100,
      );
      expect(
        (configuration.toCallableMap()['earning'] as Map)['mode'],
        'bands',
      );
    });

    test('rejects an incomplete configuration instead of applying defaults',
        () {
      expect(
        () => RewardConfiguration.fromCallable({
          'version': 1,
          'config': {'enabled': true},
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('parses paged transactions and rejects unknown transaction types', () {
    final page = RewardPage<RewardTransaction>.fromCallable(
      {
        'items': [
          {
            'transactionId': 'txn_1',
            'userId': 'user_1',
            'points': 25,
            'type': 'earned',
            'createdAt': '2026-10-30T12:00:00Z',
            'orderId': 'order_1',
            'referralId': null,
            'description': 'Order reward',
          },
        ],
        'nextPageToken': 'cursor_2',
      },
      RewardTransaction.fromMap,
    );

    expect(page.items.single.points, 25);
    expect(page.items.single.type, RewardTransactionType.earned);
    expect(page.nextPageToken, 'cursor_2');
    expect(
      () => RewardTransaction.fromMap({
        'transactionId': 'txn_2',
        'userId': 'user_1',
        'points': 1,
        'type': 'unknown',
        'createdAt': '2026-10-30T12:00:00Z',
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('parses skipped referral records without a referrer or referral code',
      () {
    final referral = RewardReferralRecord.fromMap({
      'referralId': 'user_1',
      'referrerId': null,
      'referredUserId': 'user_1',
      'referralCode': null,
      'status': 'skipped',
      'createdAt': '2026-10-30T12:00:00Z',
      'qualifyingOrderId': null,
      'pointsAwarded': 0,
    });

    expect(referral.referrerId, isEmpty);
    expect(referral.referralCode, isEmpty);
    expect(referral.status, 'skipped');
  });

  test('RewardPriceBand summary and modes', () {
    final rangeBand = RewardPriceBand.fromMap({
      'minTotal': 0,
      'maxTotal': 499.99,
      'pointsMode': 'range',
      'minPts': 1,
      'maxPts': 4,
      'fixedPts': 1,
    });
    expect(rangeBand.pointsMode, RewardBandPointsMode.range);
    expect(rangeBand.summaryLabel, contains('1–4'));

    final fixedBand = RewardPriceBand.fromMap({
      'minTotal': 500,
      'maxTotal': null,
      'pointsMode': 'fixed',
      'minPts': 5,
      'maxPts': 5,
      'fixedPts': 5,
    });
    expect(fixedBand.pointsMode, RewardBandPointsMode.fixed);
    expect(fixedBand.maxTotal, isNull);
    expect(fixedBand.summaryLabel, contains('5 pts'));
  });
}
