import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/rewards_admin_models.dart';
import 'package:rdx_admin/providers/rewards_admin_provider.dart';
import 'package:rdx_admin/widgets/reusable_widgets/empty_state.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_table.dart';

class RewardsOverviewTab extends StatelessWidget {
  const RewardsOverviewTab({
    required this.provider,
    required this.onRefresh,
    super.key,
  });

  final RewardsAdminProvider provider;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final stats = provider.analytics;
    if (stats == null) {
      return Center(
        child: Padding(
          padding: Responsive.pagePadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                provider.errorMessage ?? 'Reward analytics are unavailable.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.h(12)),
              OutlinedButton(onPressed: onRefresh, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: Responsive.pagePadding(context, bottom: 28),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(context.w(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How to use rewards',
                      style: AppTextStyles.section(context)),
                  SizedBox(height: context.h(8)),
                  Text(
                    '1. Set and save earning and redemption rules in Configuration. '
                    'Use the global earning rate for every item, then add an '
                    'override for selected menu items if needed. Set referral '
                    'rewards in Referral settings.\n'
                    '2. Add food items and their point cost in Redemption catalog. '
                    'A catalog item does not grant points when it is ordered.\n'
                    '3. Customers earn points on eligible customer orders only '
                    'after payment is marked paid and the order is marked delivered. '
                    'The configured rate and minimum order value determine the points. '
                    'Eligible item discounts are calculated from server-validated order lines.\n'
                    '4. Transactions, redemptions, and referrals are automatic '
                    'history records, not records to create manually. Transactions '
                    'appear after an earn, checkout redemption, or referral bonus. '
                    'Referral records appear after a customer applies a referral code.\n'
                    '5. Refresh the customer app wallet after delivery to see the '
                    'updated balance. Referral customers must apply a code before '
                    'meeting the configured qualification conditions.',
                    style: AppTextStyles.caption(context),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.h(16)),
          _MetricGrid(
            items: [
              _Metric(
                label: 'Lifetime points issued',
                value: _number(stats.totalPointsIssued),
                icon: Icons.add_circle_outline,
                hint: 'All-time credited points',
              ),
              _Metric(
                label: 'Lifetime points redeemed',
                value: _number(stats.totalPointsRedeemed),
                icon: Icons.redeem,
                hint: 'All-time redeemed points',
              ),
              _Metric(
                label: 'Outstanding points',
                value: _number(stats.outstandingPointsLiability),
                icon: Icons.account_balance_wallet_outlined,
                hint: 'Current balance liability',
              ),
              _Metric(
                label: 'Users with balances',
                value: _number(stats.usersWithBalances),
                icon: Icons.people_outline,
                hint: 'Customers with a wallet balance',
              ),
              _Metric(
                label: 'Active reward campaigns',
                value: _number(stats.activeRewardCampaigns),
                icon: Icons.campaign_outlined,
                hint: 'Currently available campaigns',
              ),
              _Metric(
                label: 'Referral points issued',
                value: _number(stats.totalReferralRewardsIssued),
                icon: Icons.group_add_outlined,
                hint: 'Lifetime referral bonuses',
              ),
              _Metric(
                label: 'Successful referrals',
                value: _number(stats.successfulReferrals),
                icon: Icons.verified_outlined,
                hint: 'Qualified referrals',
              ),
              _Metric(
                label: 'Redemptions',
                value: _number(stats.totalRedemptions),
                icon: Icons.card_giftcard_outlined,
                hint: 'Lifetime completed redemptions',
              ),
            ],
          ),
          SizedBox(height: context.h(20)),
          Text('Recent reward activity', style: AppTextStyles.section(context)),
          SizedBox(height: context.h(4)),
          Text(
            'Latest ledger entries, newest first',
            style: AppTextStyles.caption(context),
          ),
          SizedBox(height: context.h(12)),
          if (provider.transactions.isEmpty)
            const EmptyState(
              message: 'Reward transactions will appear here when available.',
            )
          else
            _RecentTransactions(
              items: provider.transactions.take(8).toList(),
            ),
          if (provider.errorMessage != null) ...[
            SizedBox(height: context.h(10)),
            Text(
              provider.errorMessage!,
              style: AppTextStyles.caption(context)
                  .copyWith(color: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.hint,
  });

  final String label;
  final String value;
  final IconData icon;
  final String hint;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<_Metric> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: Responsive.statColumns(context, max: 4),
      crossAxisSpacing: context.w(12),
      mainAxisSpacing: context.h(12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: Responsive.isMobile(context) ? 1.65 : 2.25,
      children: [
        for (final item in items) _MetricCard(item: item),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item});

  final _Metric item;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.w(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(item.icon, color: AppColors.primary, size: 20),
                SizedBox(width: context.w(7)),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.heading(context).copyWith(
                fontSize: context.sp(23),
              ),
            ),
            Text(
              item.hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context)
                  .copyWith(color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.items});

  final List<RewardTransaction> items;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: context.h(300),
        child: RdxTable(
          columns: const [
            RdxTableColumn(title: 'User', minWidth: 160),
            RdxTableColumn(title: 'Type', minWidth: 125),
            RdxTableColumn(title: 'Points', minWidth: 100),
            RdxTableColumn(title: 'Order', minWidth: 145),
            RdxTableColumn(title: 'Created', minWidth: 155),
          ],
          rows: [
            for (final item in items)
              [
                _cell(context, item.userId),
                _cell(context, _typeName(item.type)),
                _cell(
                  context,
                  item.points > 0 ? '+${item.points}' : '${item.points}',
                ),
                _cell(context, item.orderId ?? '—'),
                _cell(context, _date(item.createdAt)),
              ],
          ],
        ),
      );
}

Widget _cell(BuildContext context, String value) => Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(8)),
      child: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption(context),
      ),
    );

String _typeName(RewardTransactionType type) => switch (type) {
      RewardTransactionType.earned => 'Earned',
      RewardTransactionType.redeemed => 'Redeemed',
      RewardTransactionType.referralBonus => 'Referral bonus',
      RewardTransactionType.reversal => 'Reversal',
      RewardTransactionType.adjustment => 'Adjustment',
    };

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String _number(int value) => value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
