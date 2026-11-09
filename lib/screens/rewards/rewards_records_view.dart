part of 'rewards_management_screen.dart';

extension _RewardsRecordsView on _RewardsManagementScreenState {
  Widget _transactions(RewardsAdminProvider provider) {
    final filtered = provider.transactions.where((item) {
      final query = _transactionSearch.toLowerCase();
      return query.isEmpty ||
          item.userId.toLowerCase().contains(query) ||
          (item.orderId?.toLowerCase().contains(query) ?? false) ||
          (item.referralId?.toLowerCase().contains(query) ?? false) ||
          item.description.toLowerCase().contains(query);
    }).toList();

    return _recordPage(
      title: 'Reward transactions',
      subtitle:
          'Read-only ledger; records are created automatically by reward activity.',
      headerAction: provider.canConfigure
          ? OutlinedButton.icon(
              onPressed: provider.isMutating || provider.isLoading
                  ? null
                  : () => _reconcileOrderRewards(provider),
              icon: const Icon(Icons.sync),
              label: const Text('Sync delivered order'),
            )
          : null,
      searchHint: 'Search user, order, referral or description',
      onSearch: (value) => _updateState(() => _transactionSearch = value),
      searchController: _transactionSearchController,
      onSearchSubmit: () => provider.loadTransactions(
        type: _transactionType,
        search: _transactionSearch,
      ),
      filter: _transactionType,
      filterOptions: const {
        'earned': 'Earned',
        'redeemed': 'Redeemed',
        'referral_bonus': 'Referral bonus',
        'reversal': 'Reversal',
        'adjustment': 'Adjustment',
      },
      onFilter: (value) {
        _updateState(() => _transactionType = value);
        provider.loadTransactions(type: value, search: _transactionSearch);
      },
      loading: provider.isLoading,
      onRefresh: () => provider.loadTransactions(
        type: _transactionType,
        search: _transactionSearch,
      ),
      emptyTitle: 'No transactions found',
      emptyMessage:
          'A qualifying paid and delivered order, checkout redemption, or referral bonus creates these records automatically. They are not entered manually.',
      hasItems: filtered.isNotEmpty,
      table: _transactionTable(filtered),
      onNextPage: provider.hasMoreTransactions
          ? () => provider.loadTransactions(
                type: _transactionType,
                nextPage: true,
              )
          : null,
      error: provider.errorMessage,
    );
  }

  Widget _redemptions(RewardsAdminProvider provider) {
    final filtered = provider.redemptions.where((item) {
      final query = _redemptionSearch.toLowerCase();
      return query.isEmpty ||
          item.userId.toLowerCase().contains(query) ||
          item.rewardName.toLowerCase().contains(query) ||
          (item.orderId?.toLowerCase().contains(query) ?? false);
    }).toList();
    return _recordPage(
      title: 'Redemptions',
      subtitle: 'Read-only history of points spent at customer checkout.',
      searchHint: 'Search customer, reward or order',
      onSearch: (value) => _updateState(() => _redemptionSearch = value),
      searchController: _redemptionSearchController,
      onSearchSubmit: () => provider.loadRedemptions(
        status: _redemptionStatus,
        search: _redemptionSearch,
      ),
      filter: _redemptionStatus,
      filterOptions: const {
        'reserved': 'Reserved',
        'completed': 'Completed',
        'released': 'Released',
        'reversed': 'Reversed',
      },
      onFilter: (value) {
        _updateState(() => _redemptionStatus = value);
        provider.loadRedemptions(status: value, search: _redemptionSearch);
      },
      loading: provider.isLoading,
      onRefresh: () => provider.loadRedemptions(
        status: _redemptionStatus,
        search: _redemptionSearch,
      ),
      emptyTitle: 'No redemptions found',
      emptyMessage:
          'A record appears when a customer spends points at checkout. Redemption history is not entered manually.',
      hasItems: filtered.isNotEmpty,
      table: _redemptionTable(filtered),
      onNextPage: provider.hasMoreRedemptions
          ? () => provider.loadRedemptions(
                status: _redemptionStatus,
                nextPage: true,
              )
          : null,
      error: provider.errorMessage,
    );
  }

  Widget _referrals(RewardsAdminProvider provider) {
    final filtered = provider.referrals.where((item) {
      final query = _referralSearch.toLowerCase();
      return query.isEmpty ||
          item.referrerId.toLowerCase().contains(query) ||
          item.referredUserId.toLowerCase().contains(query) ||
          item.referralCode.toLowerCase().contains(query) ||
          (item.qualifyingOrderId?.toLowerCase().contains(query) ?? false);
    }).toList();
    return _recordPage(
      title: 'Referral management',
      subtitle: 'Read-only history of customer referral attributions.',
      searchHint: 'Search customer, code or qualifying order',
      onSearch: (value) => _updateState(() => _referralSearch = value),
      searchController: _referralSearchController,
      onSearchSubmit: () => provider.loadReferrals(
        status: _referralStatus,
        search: _referralSearch,
      ),
      filter: _referralStatus,
      filterOptions: const {
        'pending': 'Pending',
        'qualified': 'Qualified',
        'reversed': 'Reversed',
        'rejected': 'Rejected',
      },
      onFilter: (value) {
        _updateState(() => _referralStatus = value);
        provider.loadReferrals(status: value, search: _referralSearch);
      },
      loading: provider.isLoading,
      onRefresh: () => provider.loadReferrals(
        status: _referralStatus,
        search: _referralSearch,
      ),
      emptyTitle: 'No referral records found',
      emptyMessage:
          'A record appears after a customer applies another customer’s referral code. The bonus is issued after the qualifying order is paid and delivered.',
      hasItems: filtered.isNotEmpty,
      table: _referralTable(filtered),
      onNextPage: provider.hasMoreReferrals
          ? () => provider.loadReferrals(
                status: _referralStatus,
                nextPage: true,
              )
          : null,
      error: provider.errorMessage,
    );
  }

  Widget _recordPage({
    required String title,
    required String subtitle,
    Widget? headerAction,
    required String searchHint,
    required TextEditingController searchController,
    required ValueChanged<String> onSearch,
    required VoidCallback onSearchSubmit,
    required String? filter,
    required Map<String, String> filterOptions,
    required ValueChanged<String?> onFilter,
    required bool loading,
    required Future<void> Function() onRefresh,
    required String emptyTitle,
    required String emptyMessage,
    required bool hasItems,
    required Widget table,
    required VoidCallback? onNextPage,
    String? error,
  }) =>
      _pageList(
        children: [
          if (headerAction == null)
            _sectionTitle(title, subtitle)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle(title, subtitle),
                Align(
                  alignment: Alignment.centerRight,
                  child: headerAction,
                ),
              ],
            ),
          Wrap(
            spacing: context.w(12),
            runSpacing: context.h(10),
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: Responsive.isMobile(context)
                    ? MediaQuery.sizeOf(context).width -
                        2 * Responsive.pageHorizontal(context)
                    : context.w(380),
                child: RdxSearchBar(
                  controller: searchController,
                  hintText: searchHint,
                  height: RdxSearchBar.standardHeight(context),
                  onChanged: onSearch,
                  onSubmitted: (_) => onSearchSubmit(),
                ),
              ),
              SizedBox(
                width: context.w(190),
                child: DropdownButtonFormField<String?>(
                  value: filter,
                  decoration: const InputDecoration(
                    labelText: 'Filter',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All'),
                    ),
                    ...filterOptions.entries.map(
                      (entry) => DropdownMenuItem<String?>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    ),
                  ],
                  onChanged: onFilter,
                ),
              ),
              IconButton(
                tooltip: 'Refresh records',
                onPressed: loading ? null : onRefresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (error != null) _inlineError(error),
          SizedBox(height: context.h(12)),
          if (loading && !hasItems)
            const LoadingIndicator()
          else if (!hasItems)
            EmptyState(message: '$emptyTitle. $emptyMessage')
          else
            table,
          if (onNextPage != null)
            Align(
              alignment: Alignment.center,
              child: OutlinedButton.icon(
                onPressed: loading ? null : onNextPage,
                icon: const Icon(Icons.expand_more),
                label: Text(loading ? 'Loading...' : 'Load more'),
              ),
            ),
        ],
      );

  Future<void> _reconcileOrderRewards(
    RewardsAdminProvider provider,
  ) async {
    final controller = TextEditingController();
    final orderId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync a delivered order'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Order ID',
            hintText: 'Enter the customer order ID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Sync'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (orderId == null || orderId.isEmpty || !mounted) return;

    try {
      final result = await ref
          .read(rewardsAdminServiceProvider)
          .reconcileOrderRewards(orderId);
      await provider.load();
      await provider.loadTransactions(
        type: _transactionType,
        search: _transactionSearch,
      );
      if (!mounted) return;
      if (result.pointsEarned > 0) {
        _showMessage(
          result.reason == 'already_awarded'
              ? 'This order was already credited with ${result.pointsEarned} points.'
              : 'Order synced. ${result.pointsEarned} points were credited.',
        );
      } else {
        final message = switch (result.reason) {
          'order_not_eligible' =>
            'No points credited. The order must be both paid and delivered.',
          'no_customer' =>
            'No points credited. This order is not linked to a customer account.',
          'rewards_disabled' =>
            'No points credited. Enable the rewards program in Configuration.',
          'below_threshold' =>
            'No points credited. Check the minimum order and earning rate in Configuration.',
          'item_allocation_unavailable' =>
            'No points credited. This older order lacks the server-calculated item discount details needed for your item-specific rules.',
          _ => 'No points were credited for this order.',
        };
        _showMessage(message);
      }
    } catch (error) {
      if (mounted) _showMessage('Unable to sync order rewards: $error');
    }
  }

  Widget _transactionTable(List<RewardTransaction> items) => SizedBox(
        height: context.h(390),
        child: RdxTable(
          columns: const [
            RdxTableColumn(title: 'User', minWidth: 170),
            RdxTableColumn(title: 'Type', minWidth: 125),
            RdxTableColumn(title: 'Points', minWidth: 100),
            RdxTableColumn(title: 'Order', minWidth: 150),
            RdxTableColumn(title: 'Referral', minWidth: 150),
            RdxTableColumn(title: 'Created', minWidth: 155),
            RdxTableColumn(title: 'Description', minWidth: 200),
          ],
          rows: [
            for (final item in items)
              [
                _cell(item.userId),
                _cell(_transactionLabel(item.type)),
                _cell(item.points > 0 ? '+${item.points}' : '${item.points}'),
                _cell(item.orderId ?? '—'),
                _cell(item.referralId ?? '—'),
                _cell(_date(item.createdAt)),
                _cell(item.description.isEmpty ? '—' : item.description),
              ],
          ],
        ),
      );

  Widget _redemptionTable(List<RewardRedemptionRecord> items) => SizedBox(
        height: context.h(390),
        child: RdxTable(
          columns: const [
            RdxTableColumn(title: 'Customer', minWidth: 170),
            RdxTableColumn(title: 'Reward', minWidth: 180),
            RdxTableColumn(title: 'Points used', minWidth: 110),
            RdxTableColumn(title: 'Order', minWidth: 160),
            RdxTableColumn(title: 'Date', minWidth: 155),
            RdxTableColumn(title: 'Status', minWidth: 120),
          ],
          rows: [
            for (final item in items)
              [
                _cell(item.userId),
                _cell(item.rewardName),
                _cell(_number(item.pointsUsed)),
                _cell(item.orderId ?? '—'),
                _cell(_date(item.createdAt)),
                _cell(item.status),
              ],
          ],
        ),
      );

  Widget _referralTable(List<RewardReferralRecord> items) => SizedBox(
        height: context.h(390),
        child: RdxTable(
          columns: const [
            RdxTableColumn(title: 'Referrer', minWidth: 160),
            RdxTableColumn(title: 'Referred customer', minWidth: 180),
            RdxTableColumn(title: 'Code', minWidth: 130),
            RdxTableColumn(title: 'Status', minWidth: 120),
            RdxTableColumn(title: 'Qualifying order', minWidth: 160),
            RdxTableColumn(title: 'Points awarded', minWidth: 130),
            RdxTableColumn(title: 'Referral date', minWidth: 155),
          ],
          rows: [
            for (final item in items)
              [
                _cell(item.referrerId),
                _cell(item.referredUserId),
                _cell(item.referralCode),
                _cell(item.status),
                _cell(item.qualifyingOrderId ?? '—'),
                _cell(_number(item.pointsAwarded)),
                _cell(_date(item.createdAt)),
              ],
          ],
        ),
      );

  Widget _cell(String text) => Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(8)),
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context),
        ),
      );
}
