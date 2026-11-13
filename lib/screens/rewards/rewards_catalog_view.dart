part of 'rewards_management_screen.dart';

extension _RewardsCatalogView on _RewardsManagementScreenState {
  Widget _catalog(RewardsAdminProvider provider) {
    if (provider.isLoading && provider.foodRewards.isEmpty) {
      return const LoadingIndicator();
    }
    return _pageList(
      children: [
        _sectionTitle(
          'Food redemption catalog',
          'Rewards reference existing menu items.',
        ),
        if (provider.foodRewards.isEmpty)
          const EmptyState(
            message: 'Add a food reward linked to an existing menu item.',
          )
        else
          ...provider.foodRewards.map((reward) => _foodRewardCard(
                provider,
                reward,
              )),
        if (provider.errorMessage != null) _inlineError(provider.errorMessage!),
      ],
    );
  }

  Widget _catalogAddRewardButton(RewardsAdminProvider provider) =>
      FilledButton.icon(
        onPressed: provider.isMutating || provider.isLoading
            ? null
            : () => _editFoodReward(provider),
        icon: const Icon(Icons.add),
        label: const Text('Add reward'),
      );

  Widget _foodRewardCard(RewardsAdminProvider provider, FoodReward reward) {
    final colors = AppColors.of(context);
    return Card(
      margin: EdgeInsets.only(bottom: context.h(10)),
      child: Padding(
        padding: EdgeInsets.all(context.w(16)),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.restaurant, color: AppColors.primary),
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reward.name, style: AppTextStyles.section(context)),
                  SizedBox(height: context.h(4)),
                  Text(
                    '${_number(reward.pointsCost)} points · ${reward.available ? 'Available' : 'Disabled'}'
                    '${reward.stockLimit == null ? '' : ' · ${reward.stockLimit} stock'}'
                    ' · ${reward.usageCount} used',
                    style: AppTextStyles.caption(context).copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (provider.canConfigure) ...[
              IconButton(
                tooltip: 'Edit reward',
                onPressed: provider.isMutating
                    ? null
                    : () => _editFoodReward(provider, reward: reward),
                icon: const Icon(Icons.edit_outlined),
              ),
              if (reward.available)
                IconButton(
                  tooltip: 'Disable reward',
                  onPressed: provider.isMutating
                      ? null
                      : () => _disableFoodReward(provider, reward),
                  icon:
                      const Icon(Icons.block_outlined, color: AppColors.danger),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editFoodReward(
    RewardsAdminProvider provider, {
    FoodReward? reward,
  }) async {
    await provider.loadCatalog();
    if (!mounted) return;
    if (provider.errorMessage != null) {
      _showMessage('Unable to load reward catalog: ${provider.errorMessage}');
      return;
    }
    if (provider.menuItems.isEmpty) {
      _showMessage('Create a menu item before adding a food reward.');
      return;
    }
    final result = await showDialog<FoodReward>(
      context: context,
      builder: (context) => _FoodRewardDialog(
        items: provider.menuItems,
        existing: reward,
      ),
    );
    if (result == null || !mounted) return;
    try {
      await provider.saveFoodReward(result);
      if (mounted) _showMessage('Reward saved.');
    } catch (error) {
      if (mounted) _showMessage('Unable to save reward: $error');
    }
  }

  Future<void> _disableFoodReward(
    RewardsAdminProvider provider,
    FoodReward reward,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable this reward?'),
        content: Text(
          '${reward.name} will no longer be available for new redemptions. Existing redemption history will be retained.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    try {
      await provider.disableFoodReward(reward.id);
      if (mounted) _showMessage('Reward disabled.');
    } catch (error) {
      if (mounted) _showMessage('Unable to disable reward: $error');
    }
  }
}
