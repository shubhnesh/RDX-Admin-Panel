import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/rewards_admin_model.dart';
import 'package:rdx_admin/providers/rewards_admin_provider.dart';
import 'package:rdx_admin/widgets/reusable_widgets/empty_state.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_table.dart';

/// Simple overview: key numbers + short how-to + recent activity.
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
        padding: Responsive.pagePadding(context, bottom: context.h(28)),
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.w(16)),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(context.h(8)),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: context.h(18), color: AppColors.primary),
                    SizedBox(width: context.w(8)),
                    Text(
                      'Quick guide',
                      style: AppTextStyles.bodyLargeSemi(context).copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(8)),
                Text(
                  '1. Open Earning rules → set price bands (e.g. ₹0–499 → 1–4 pts, ₹500+ → 5–9 pts). Use fixed or random range.\n'
                  '2. Open Referral → set points for the sharer and the new customer.\n'
                  '3. 1 point always equals ₹1 at checkout — nothing to configure for that.\n'
                  '4. Customers earn points only on app orders that are paid and delivered. Activity shows every earn, redeem, and referral bonus.',
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.of(context).primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(16)),
          _MetricGrid(
            items: [
              _Metric(
                label: 'Points issued',
                value: _number(stats.totalPointsIssued),
                icon: Icons.add_circle_outline,
                hint: 'All-time credited',
              ),
              _Metric(
                label: 'Points redeemed',
                value: _number(stats.totalPointsRedeemed),
                icon: Icons.redeem,
                hint: 'All-time spent',
              ),
              _Metric(
                label: 'Outstanding',
                value: _number(stats.outstandingPointsLiability),
                icon: Icons.account_balance_wallet_outlined,
                hint: 'Current balances',
              ),
              _Metric(
                label: 'Users with balance',
                value: _number(stats.usersWithBalances),
                icon: Icons.people_outline,
                hint: 'Active wallets',
              ),
              _Metric(
                label: 'Referral points',
                value: _number(stats.totalReferralRewardsIssued),
                icon: Icons.group_add_outlined,
                hint: 'Referral bonuses',
              ),
              _Metric(
                label: 'Successful referrals',
                value: _number(stats.successfulReferrals),
                icon: Icons.verified_outlined,
                hint: 'Completed invites',
              ),
            ],
          ),
          SizedBox(height: context.h(20)),
          Text('Recent activity', style: AppTextStyles.bodyLargeSemi(context)),
          SizedBox(height: context.h(4)),
          Text(
            'Latest ledger entries',
            style: AppTextStyles.caption(context),
          ),
          SizedBox(height: context.h(12)),
          if (provider.transactions.isEmpty)
            const EmptyState(
              message: 'Activity will appear after the first earn or redemption.',
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
      crossAxisCount: Responsive.statColumns(context, max: 3),
      crossAxisSpacing: context.w(12),
      mainAxisSpacing: context.h(12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: Responsive.isMobile(context) ? 1.65 : 2.2,
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
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, color: AppColors.primary, size: context.h(20)),
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
            style: AppTextStyles.h2(context).copyWith(
              fontSize: context.sp(22),
              color: colors.textPrimary,
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
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.items});

  final List<RewardTransaction> items;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: context.h(280),
        child: RdxTable(
          columns: [
            RdxTableColumn(title: 'User', minWidth: context.w(140)),
            RdxTableColumn(title: 'Type', minWidth: context.w(110)),
            RdxTableColumn(title: 'Points', minWidth: context.w(90)),
            RdxTableColumn(title: 'When', minWidth: context.w(140)),
          ],
          rows: [
            for (final item in items)
              [
                _cell(context, item.userId.length > 14
                    ? '${item.userId.substring(0, 8)}…'
                    : item.userId),
                _cell(context, _typeName(item.type)),
                _cell(
                  context,
                  item.points > 0 ? '+${item.points}' : '${item.points}',
                ),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption(context),
      ),
    );

String _typeName(RewardTransactionType type) => switch (type) {
      RewardTransactionType.earned => 'Earned',
      RewardTransactionType.redeemed => 'Redeemed',
      RewardTransactionType.referralBonus => 'Referral',
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
