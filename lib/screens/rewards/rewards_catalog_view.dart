part of 'rewards_management_screen.dart';

extension _RewardsCatalogView on _RewardsManagementScreenState {
  Widget _catalog(RewardsAdminProvider provider) {
    if (provider.isLoading && provider.foodRewards.isEmpty) {
      return const LoadingIndicator();
    }
    return _pageList(
      children: [
        if (provider.foodRewards.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.h(20)),
            decoration: BoxDecoration(
              color: AppColors.of(context).surface,
              borderRadius: BorderRadius.circular(context.h(8)),
              border: Border.all(color: AppColors.of(context).border),
            ),
            child: const EmptyState(
              message: 'Add a food reward linked to an existing menu item.',
            ),
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
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Add reward'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: context.w(14),
            vertical: context.h(10),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.h(8)),
          ),
        ),
      );

  Widget _foodRewardCard(RewardsAdminProvider provider, FoodReward reward) {
    final colors = AppColors.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: context.h(10)),
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: context.w(44),
            height: context.w(44),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(context.h(10)),
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              color: AppColors.primary,
              size: context.h(22),
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: AppTextStyles.section(context)
                      .copyWith(color: colors.textPrimary),
                ),
                SizedBox(height: context.h(6)),
                Wrap(
                  spacing: context.w(6),
                  runSpacing: context.h(4),
                  children: [
                    _metaChip(
                      context,
                      colors,
                      '${_number(reward.pointsCost)} pts',
                      AppColors.primary,
                    ),
                    _metaChip(
                      context,
                      colors,
                      reward.available ? 'Available' : 'Disabled',
                      reward.available
                          ? const Color(0xFF16A05A)
                          : AppColors.danger,
                    ),
                    if (reward.stockLimit != null)
                      _metaChip(
                        context,
                        colors,
                        '${reward.stockLimit} stock',
                        colors.textMuted,
                      ),
                    _metaChip(
                      context,
                      colors,
                      '${reward.usageCount} used',
                      colors.textMuted,
                    ),
                  ],
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
              icon: Icon(
                Icons.edit_outlined,
                size: context.h(20),
                color: colors.textSecondary,
              ),
            ),
            if (reward.available)
              IconButton(
                tooltip: 'Disable reward',
                onPressed: provider.isMutating
                    ? null
                    : () => _disableFoodReward(provider, reward),
                icon: Icon(
                  Icons.block_outlined,
                  size: context.h(20),
                  color: AppColors.danger,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _metaChip(
    BuildContext context,
    AppColorScheme colors,
    String label,
    Color accent,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(8),
        vertical: context.h(3),
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(context.h(6)),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(context).copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
          fontSize: context.sp(10),
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
