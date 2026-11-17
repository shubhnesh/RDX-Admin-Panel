import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/rewards_admin_model.dart';
import 'package:rdx_admin/providers/rewards_admin_provider.dart';
import 'package:rdx_admin/widgets/dialogs/rdx_notice_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/empty_state.dart';
import 'package:rdx_admin/widgets/reusable_widgets/loading_indicator.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_header.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_dropdown.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_text_field.dart';
import 'package:rdx_admin/widgets/buttons/rdx_toggle_button.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_search_bar.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_table.dart';
import 'package:rdx_admin/screens/rewards/rewards_overview_tab.dart';

/// Simplified Rewards management.
///
/// Only three jobs:
/// 1. Set order-price bands → how many points an order earns (fixed or random range)
/// 2. Set simple referral points (referrer / new user)
/// 3. View activity (points issued / redeemed / referral bonuses)
class RewardsManagementScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const RewardsManagementScreen({super.key, this.onBack});

  @override
  ConsumerState<RewardsManagementScreen> createState() =>
      _RewardsManagementScreenState();
}

class _RewardsManagementScreenState
    extends ConsumerState<RewardsManagementScreen> {
  static const _sections = [
    'Overview',
    'Earning rules',
    'Referral',
    'Activity',
  ];

  final _configurationFormKey = GlobalKey<FormState>();
  final _referrerPointsController = TextEditingController();
  final _newUserPointsController = TextEditingController();
  final _transactionSearchController = TextEditingController();

  List<RewardPriceBand> _earningBands = [];
  bool _rewardsEnabled = false;
  bool _referralsEnabled = false;
  bool _configurationLoaded = false;
  int? _loadedVersion;
  bool _configurationDirty = false;
  int _sectionIndex = 0;
  String _transactionSearch = '';
  String? _transactionType;

  void _log(String message) {
    if (kDebugMode) debugPrint('[RewardsScreen] $message');
  }

  void _logFailure(String operation, Object error) {
    if (error is FirebaseFunctionsException) {
      _log('$operation failed (Functions code: ${error.code}).');
    } else if (error is FirebaseException) {
      _log('$operation failed (Firebase code: ${error.code}).');
    } else {
      _log('$operation failed (${error.runtimeType}).');
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadInitial);
  }

  Future<void> _loadInitial() async {
    _log('Initial rewards load started.');
    final provider = ref.read(rewardsAdminProvider);
    await provider.load();
    if (!mounted) return;
    if (!provider.canRead) return;
    await provider.loadTransactions();
    _log('Initial rewards load completed.');
  }

  @override
  void dispose() {
    _referrerPointsController.dispose();
    _newUserPointsController.dispose();
    _transactionSearchController.dispose();
    super.dispose();
  }

  void _initializeConfiguration(
    RewardConfiguration config, {
    bool force = false,
  }) {
    if (!force && _loadedVersion == config.version) return;
    _loadedVersion = config.version;
    _configurationLoaded = true;
    _configurationDirty = false;
    _rewardsEnabled = config.enabled;
    _earningBands = List.of(config.earningBands);
    _referralsEnabled = config.referralsEnabled;
    _referrerPointsController.text = config.referrerRewardPoints.toString();
    _newUserPointsController.text = config.newUserRewardPoints.toString();
  }

  Future<void> _selectSection(int index) async {
    if (index == _sectionIndex) return;
    if (_configurationDirty && !await _confirmDiscardChanges()) return;
    if (!mounted) return;
    if (_configurationDirty) {
      final config = ref.read(rewardsAdminProvider).configuration;
      if (config != null) _initializeConfiguration(config, force: true);
    }

    setState(() {
      _sectionIndex = index;
      _configurationDirty = false;
    });

    final provider = ref.read(rewardsAdminProvider);
    if (index == 3) {
      await provider.loadTransactions(type: _transactionType);
    }
  }

  Future<void> _handleBack() async {
    if (_configurationDirty && !await _confirmDiscardChanges()) return;
    if (!mounted) return;
    if (_configurationDirty) {
      final config = ref.read(rewardsAdminProvider).configuration;
      if (config != null) _initializeConfiguration(config, force: true);
    }
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
    } else {
      await Navigator.of(context).maybePop();
    }
  }

  Future<bool> _confirmDiscardChanges() async {
    final discard = await RdxNoticeDialog.showConfirmation(
      context,
      title: 'Discard unsaved changes?',
      message: 'Your reward configuration edits have not been saved.',
      cancelButtonLabel: 'Keep editing',
      confirmButtonLabel: 'Discard',
    );
    return discard == true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(rewardsAdminProvider);
    final colors = AppColors.of(context);
    final config = provider.configuration;
    if (config != null) _initializeConfiguration(config);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            RdxHeader(
              title: 'Rewards',
              subtitle: 'Points by order total · referrals · activity',
              showBackButton: true,
              onBack: _handleBack,
            ),
            Expanded(
              child: _sectionsLayout(context, colors, provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionsLayout(
    BuildContext context,
    AppColorScheme colors,
    RewardsAdminProvider provider,
  ) {
    final body = _body(provider);
    final showSidebar = MediaQuery.sizeOf(context).width >= 1000;

    if (!showSidebar) {
      return Column(
        children: [
          _sectionSelector(context, colors),
          Expanded(child: body),
        ],
      );
    }

    final pagePad = context.defaultScreenPadding();
    final contentPad = Responsive.pagePadding(context, bottom: 28)
        .resolve(Directionality.of(context));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            pagePad.left,
            contentPad.top,
            0,
            contentPad.bottom,
          ),
          child: SizedBox(
            width: 200,
            child: _sectionPanel(context, colors),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _sectionPanel(BuildContext context, AppColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: context.h(48),
            width: double.infinity,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: context.w(14)),
            color: colors.surfaceVariant.withValues(alpha: 0.35),
            child: Text(
              'SECTIONS',
              style: AppTextStyles.label(context).copyWith(
                color: colors.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Divider(height: 1, color: colors.divider),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (var index = 0; index < _sections.length; index++)
                  _sectionTile(context, colors, index),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTile(BuildContext context, AppColorScheme colors, int index) {
    final selected = _sectionIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: selected ? null : () => _selectSection(index),
        child: Container(
          constraints: BoxConstraints(minHeight: context.h(46)),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: context.w(12),
            vertical: context.h(10),
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
              bottom: BorderSide(color: colors.divider),
            ),
          ),
          child: Text(
            _sections[index],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySecondary(context).copyWith(
              color: selected ? AppColors.primary : colors.textPrimary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionSelector(BuildContext context, AppColorScheme colors) {
    final pagePad = context.defaultScreenPadding();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        pagePad.left,
        context.h(12),
        pagePad.right,
        context.h(8),
      ),
      child: Wrap(
        spacing: context.w(8),
        runSpacing: context.h(8),
        children: [
          for (var index = 0; index < _sections.length; index++)
            _SectionFilterChip(
              label: _sections[index],
              selected: _sectionIndex == index,
              colors: colors,
              onTap: () => _selectSection(index),
            ),
        ],
      ),
    );
  }

  Widget _body(RewardsAdminProvider provider) {
    if (provider.isLoading &&
        provider.configuration == null &&
        provider.errorMessage == null) {
      return const LoadingIndicator();
    }
    if (!provider.canRead && provider.errorMessage != null) {
      return _errorState(provider.errorMessage!, provider.load);
    }
    if (provider.errorMessage != null &&
        provider.configuration == null &&
        _sectionIndex < 3) {
      return _errorState(provider.errorMessage!, provider.load);
    }

    return switch (_sectionIndex) {
      0 => RewardsOverviewTab(
          provider: provider,
          onRefresh: _refreshCurrent,
        ),
      1 => _earningRules(provider),
      2 => _referralSettings(provider),
      _ => _activity(provider),
    };
  }

  Widget _errorState(String message, VoidCallback onRetry) => Center(
        child: Padding(
          padding: Responsive.pagePadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 38, color: AppColors.danger),
              SizedBox(height: context.h(12)),
              Text(message, textAlign: TextAlign.center),
              SizedBox(height: context.h(12)),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );

  // ─── Earning rules (core feature) ────────────────────────────────────────

  Widget _earningRules(RewardsAdminProvider provider) {
    final config = provider.configuration;
    if (config == null || !_configurationLoaded) {
      return _errorState(
        provider.errorMessage ?? 'Reward configuration is unavailable.',
        provider.load,
      );
    }
    final readOnly = !provider.canConfigure;

    return _pageList(
      children: [
        _informationCard(
          icon: Icons.info_outline,
          title: 'How points are earned',
          message:
              'When a customer app order is marked paid and delivered, the server looks at the order amount (after discounts, before tax) and awards points from the matching price band. Use a fixed amount, or a min–max range for a random amount.',
        ),
        if (readOnly)
          _informationCard(
            icon: Icons.admin_panel_settings_outlined,
            title: 'View only',
            message:
                'Your account can view rules but cannot change them.',
          ),
        _switchCard(
          title: 'Rewards program',
          subtitle: 'Turn points earning and redemption on or off.',
          value: _rewardsEnabled,
          enabled: !readOnly && !provider.isMutating,
          onChanged: (value) => setState(() {
            _rewardsEnabled = value;
            _configurationDirty = true;
          }),
        ),
        SizedBox(height: context.h(16)),
        _panel(
          title: 'Order price bands',
          icon: Icons.trending_up_outlined,
          headerTrailing: readOnly
              ? null
              : TextButton.icon(
                  onPressed: provider.isMutating || _earningBands.length >= 5
                      ? null
                      : _addBand,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add band'),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Up to 5 bands. Amounts are in ₹ on the discounted item total.',
                style: AppTextStyles.caption(context)
                    .copyWith(color: AppColors.of(context).textMuted),
              ),
              SizedBox(height: context.h(12)),
              if (_earningBands.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: context.h(16)),
                  child: Text(
                    'No bands yet. Add at least one so orders can earn points.',
                    style: AppTextStyles.bodySecondary(context),
                  ),
                )
              else
                for (var i = 0; i < _earningBands.length; i++) ...[
                  if (i > 0) SizedBox(height: context.h(12)),
                  _bandCard(i, readOnly: readOnly, mutating: provider.isMutating),
                ],
            ],
          ),
        ),
        if (!readOnly) ...[
          SizedBox(height: context.h(16)),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: context.w(180),
              child: RdxActionButton.save(
                isLoading: provider.isMutating,
                onPressed: provider.isMutating || !_configurationDirty
                    ? null
                    : () => _saveEarningRules(config, provider),
              ),
            ),
          ),
        ],
        if (provider.errorMessage != null) _inlineError(provider.errorMessage!),
      ],
    );
  }

  Widget _bandCard(int index, {required bool readOnly, required bool mutating}) {
    final band = _earningBands[index];
    final colors = AppColors.of(context);
    final isFixed = band.pointsMode == RewardBandPointsMode.fixed;

    return Container(
      padding: EdgeInsets.all(context.h(12)),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Band ${index + 1}',
                style: AppTextStyles.label(context)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (!readOnly)
                IconButton(
                  tooltip: 'Remove band',
                  onPressed: mutating
                      ? null
                      : () => setState(() {
                            _earningBands = List.of(_earningBands)
                              ..removeAt(index);
                            _configurationDirty = true;
                          }),
                  icon: Icon(Icons.close_rounded,
                      size: 20, color: AppColors.danger),
                ),
            ],
          ),
          SizedBox(height: context.h(8)),
          Row(
            children: [
              Expanded(
                child: _numField(
                  label: 'From ₹',
                  value: band.minTotal,
                  enabled: !readOnly && !mutating,
                  onChanged: (v) {
                    _earningBands = List.of(_earningBands);
                    _earningBands[index] =
                        band.copyWith(minTotal: v);
                    _configurationDirty = true;
                    setState(() {});
                  },
                ),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: _numField(
                  label: 'To ₹',
                  value: band.maxTotal,
                  allowNull: true,
                  enabled: !readOnly && !mutating,
                  onChanged: (v) {
                    _earningBands = List.of(_earningBands);
                    _earningBands[index] = band.copyWith(
                      maxTotal: v,
                      clearMaxTotal: v == null,
                    );
                    _configurationDirty = true;
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(10)),
          RdxDropdown<RewardBandPointsMode>(
            value: band.pointsMode,
            items: const [
              RewardBandPointsMode.fixed,
              RewardBandPointsMode.range,
            ],
            labelBuilder: (mode) => switch (mode) {
              RewardBandPointsMode.fixed => 'Fixed',
              RewardBandPointsMode.range => 'Random range',
            },
            label: 'Points mode',
            enabled: !readOnly && !mutating,
            isDense: true,
            onChanged: (mode) {
              if (mode == null) return;
              setState(() {
                _earningBands = List.of(_earningBands);
                if (mode == RewardBandPointsMode.fixed) {
                  _earningBands[index] = band.copyWith(
                    pointsMode: RewardBandPointsMode.fixed,
                    fixedPts: band.minPts,
                    minPts: band.minPts,
                    maxPts: band.minPts,
                  );
                } else {
                  _earningBands[index] = band.copyWith(
                    pointsMode: RewardBandPointsMode.range,
                  );
                }
                _configurationDirty = true;
              });
            },
          ),
          SizedBox(height: context.h(10)),
          if (isFixed)
            _intField(
              label: 'Points to award',
              value: band.fixedPts,
              enabled: !readOnly && !mutating,
              onChanged: (v) {
                _earningBands = List.of(_earningBands);
                _earningBands[index] = band.copyWith(
                  fixedPts: v,
                  minPts: v,
                  maxPts: v,
                );
                _configurationDirty = true;
                setState(() {});
              },
            )
          else
            Row(
              children: [
                Expanded(
                  child: _intField(
                    label: 'Min points',
                    value: band.minPts,
                    enabled: !readOnly && !mutating,
                    onChanged: (v) {
                      _earningBands = List.of(_earningBands);
                      final max = band.maxPts < v ? v : band.maxPts;
                      _earningBands[index] = band.copyWith(
                        minPts: v,
                        maxPts: max,
                      );
                      _configurationDirty = true;
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(width: context.w(10)),
                Expanded(
                  child: _intField(
                    label: 'Max points',
                    value: band.maxPts,
                    enabled: !readOnly && !mutating,
                    onChanged: (v) {
                      _earningBands = List.of(_earningBands);
                      final min = band.minPts > v ? v : band.minPts;
                      _earningBands[index] = band.copyWith(
                        minPts: min,
                        maxPts: v,
                      );
                      _configurationDirty = true;
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          SizedBox(height: context.h(6)),
          Text(
            band.summaryLabel,
            style: AppTextStyles.caption(context)
                .copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  void _addBand() {
    if (_earningBands.length >= 5) return;
    final lastMax = _earningBands.isEmpty
        ? 0.0
        : (_earningBands.last.maxTotal ?? _earningBands.last.minTotal + 100);
    setState(() {
      _earningBands = [
        ..._earningBands,
        RewardPriceBand(
          minTotal: lastMax + 1,
          maxTotal: null,
          pointsMode: RewardBandPointsMode.range,
          minPts: 1,
          maxPts: 5,
          fixedPts: 1,
        ),
      ];
      _configurationDirty = true;
    });
  }

  Future<void> _saveEarningRules(
    RewardConfiguration previous,
    RewardsAdminProvider provider,
  ) async {
    if (_earningBands.isEmpty) {
      RdxNoticeDialog.show(context, title: 'Invalid input', message: 'Add at least one price band.');
      return;
    }
    if (_earningBands.length > 5) {
      RdxNoticeDialog.show(context, title: 'Invalid input', message: 'At most 5 bands allowed.');
      return;
    }

    final accepted = await RdxNoticeDialog.showConfirmation(
      context,
      title: 'Save earning rules?',
      message:
          'New orders will use these bands. Past ledger entries are unchanged.',
      confirmButtonLabel: 'Save',
    );
    if (accepted != true || !mounted) return;

    // 1 point = ₹1 always. Conversion is not configurable in admin.
    final updated = RewardConfiguration(
      version: previous.version,
      enabled: _rewardsEnabled,
      eligibleSubtotalBasis: previous.eligibleSubtotalBasis,
      minimumOrderValuePaise: previous.minimumOrderValuePaise,
      earningBands: List.of(_earningBands),
      redemptionPointsPerRupee: 1,
      minimumRedemptionPoints: previous.minimumRedemptionPoints,
      maximumRedemptionPercentage: previous.maximumRedemptionPercentage,
      pointsValidityDays: previous.pointsValidityDays,
      referralsEnabled: previous.referralsEnabled,
      referrerRewardPoints: previous.referrerRewardPoints,
      newUserRewardPoints: previous.newUserRewardPoints,
      referralMinimumOrderValuePaise: previous.referralMinimumOrderValuePaise,
      referralMaximumRewards: previous.referralMaximumRewards,
      referralValidFrom: previous.referralValidFrom,
      referralValidUntil: previous.referralValidUntil,
      referralQualificationConditions:
          previous.referralQualificationConditions,
    );

    try {
      await provider.saveConfiguration(updated);
      if (!mounted) return;
      setState(() => _configurationDirty = false);
      _showMessage('Earning rules saved.');
    } catch (error) {
      _logFailure('Earning rules save', error);
      if (mounted) _showMessage('Unable to save: $error');
    }
  }

  // ─── Referral (simple) ───────────────────────────────────────────────────

  Widget _referralSettings(RewardsAdminProvider provider) {
    final config = provider.configuration;
    if (config == null || !_configurationLoaded) {
      return _errorState(
        provider.errorMessage ?? 'Referral configuration is unavailable.',
        provider.load,
      );
    }
    final readOnly = !provider.canConfigure;

    return _pageList(
      children: [
        _informationCard(
          icon: Icons.info_outline,
          title: 'How referrals work',
          message:
              'A new customer applies a friend’s code once. Both get the points you set below when the new customer reaches the home screen (after signup). Self-referrals and duplicates are blocked by the server.',
        ),
        if (readOnly)
          _informationCard(
            icon: Icons.admin_panel_settings_outlined,
            title: 'View only',
            message: 'Your account cannot change referral settings.',
          ),
        _switchCard(
          title: 'Referral rewards',
          subtitle: 'Allow customers to share codes and earn bonus points.',
          value: _referralsEnabled,
          enabled: !readOnly && !provider.isMutating,
          onChanged: (value) => setState(() {
            _referralsEnabled = value;
            _configurationDirty = true;
          }),
        ),
        SizedBox(height: context.h(16)),
        _panel(
          title: 'Points',
          icon: Icons.card_giftcard_outlined,
          child: Column(
            children: [
              _field(
                label: 'Points for the referrer (friend who shared)',
                controller: _referrerPointsController,
                enabled: !readOnly && !provider.isMutating,
                validator: (v) => _integer(v, min: 0),
              ),
              SizedBox(height: context.h(12)),
              _field(
                label: 'Points for the new customer',
                controller: _newUserPointsController,
                enabled: !readOnly && !provider.isMutating,
                validator: (v) => _integer(v, min: 0),
              ),
            ],
          ),
        ),
        if (!readOnly) ...[
          SizedBox(height: context.h(16)),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: context.w(180),
              child: RdxActionButton.save(
                isLoading: provider.isMutating,
                onPressed: provider.isMutating || !_configurationDirty
                    ? null
                    : () => _saveReferralSettings(config, provider),
              ),
            ),
          ),
        ],
        if (provider.errorMessage != null) _inlineError(provider.errorMessage!),
      ],
    );
  }

  Future<void> _saveReferralSettings(
    RewardConfiguration previous,
    RewardsAdminProvider provider,
  ) async {
    final referrer = int.tryParse(_referrerPointsController.text.trim());
    final referred = int.tryParse(_newUserPointsController.text.trim());
    if (referrer == null || referrer < 0 || referred == null || referred < 0) {
      RdxNoticeDialog.show(context, title: 'Invalid input', message: 'Enter whole numbers for points (0 or more).');
      return;
    }

    final accepted = await RdxNoticeDialog.showConfirmation(
      context,
      title: 'Save referral settings?',
      message: 'New referrals will use these point amounts.',
      confirmButtonLabel: 'Save',
    );
    if (accepted != true || !mounted) return;

    // 1 point = ₹1 always. Conversion is not configurable in admin.
    final updated = RewardConfiguration(
      version: previous.version,
      enabled: previous.enabled,
      eligibleSubtotalBasis: previous.eligibleSubtotalBasis,
      minimumOrderValuePaise: previous.minimumOrderValuePaise,
      earningBands: previous.earningBands,
      redemptionPointsPerRupee: 1,
      minimumRedemptionPoints: previous.minimumRedemptionPoints,
      maximumRedemptionPercentage: previous.maximumRedemptionPercentage,
      pointsValidityDays: previous.pointsValidityDays,
      referralsEnabled: _referralsEnabled,
      referrerRewardPoints: referrer,
      newUserRewardPoints: referred,
      referralMinimumOrderValuePaise: previous.referralMinimumOrderValuePaise,
      referralMaximumRewards: previous.referralMaximumRewards,
      referralValidFrom: previous.referralValidFrom,
      referralValidUntil: previous.referralValidUntil,
      referralQualificationConditions:
          previous.referralQualificationConditions,
    );

    try {
      await provider.saveConfiguration(updated);
      if (!mounted) return;
      setState(() => _configurationDirty = false);
      _showMessage('Referral settings saved.');
    } catch (error) {
      _logFailure('Referral settings save', error);
      if (mounted) _showMessage('Unable to save: $error');
    }
  }

  // ─── Activity (tracking only) ────────────────────────────────────────────

  Widget _activity(RewardsAdminProvider provider) {
    final query = _transactionSearch.trim().toLowerCase();
    final filtered = provider.transactions.where((item) {
      final matchesSearch = query.isEmpty ||
          item.userId.toLowerCase().contains(query) ||
          (item.orderId?.toLowerCase().contains(query) ?? false) ||
          item.description.toLowerCase().contains(query);
      final matchesType = _transactionType == null ||
          _transactionTypeKey(item.type) == _transactionType;
      return matchesSearch && matchesType;
    }).toList();

    return Padding(
      padding: Responsive.pagePadding(context, bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (provider.analytics != null) ...[
            _activitySummary(provider),
            SizedBox(height: context.h(12)),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final searchHeight = RdxSearchBar.standardHeight(context);
              final dropdownWidth = context.w(160).clamp(140.0, 180.0);
              final row = Row(
                children: [
                  SizedBox(
                    width: dropdownWidth,
                    child: RdxDropdown<String>(
                      value: _transactionType ?? 'all',
                      items: const ['all', 'earned', 'redeemed', 'referral_bonus'],
                      labelBuilder: (v) => switch (v) {
                        'all' => 'All types',
                        'earned' => 'Earned',
                        'redeemed' => 'Redeemed',
                        'referral_bonus' => 'Referral',
                        _ => v,
                      },
                      hint: 'All types',
                      height: searchHeight,
                      onChanged: (value) {
                        final type =
                            value == null || value == 'all' ? null : value;
                        setState(() => _transactionType = type);
                        provider.loadTransactions(
                          type: type,
                          search: _transactionSearch,
                        );
                      },
                    ),
                  ),
                  SizedBox(width: context.w(10)),
                  Expanded(
                    child: RdxSearchBar(
                      controller: _transactionSearchController,
                      hintText: 'Search user or order',
                      height: searchHeight,
                      onChanged: (value) =>
                          setState(() => _transactionSearch = value),
                    ),
                  ),
                ],
              );
              return constraints.maxWidth >= 480
                  ? row
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(width: 480, child: row),
                    );
            },
          ),
          if (provider.errorMessage != null) ...[
            SizedBox(height: context.h(10)),
            _inlineError(provider.errorMessage!),
          ],
          SizedBox(height: context.h(10)),
          if (provider.isLoading && filtered.isEmpty)
            const Expanded(child: Center(child: LoadingIndicator()))
          else if (filtered.isEmpty)
            const Expanded(
              child: Center(
                child: EmptyState(
                  message:
                      'No activity yet. Points appear here after a paid delivered order, a checkout redemption, or a referral bonus.',
                ),
              ),
            )
          else ...[
            Expanded(child: _transactionTable(filtered)),
            if (provider.hasMoreTransactions) ...[
              SizedBox(height: context.h(8)),
              Align(
                alignment: Alignment.center,
                child: OutlinedButton.icon(
                  onPressed: provider.isLoading
                      ? null
                      : () => provider.loadTransactions(
                            type: _transactionType,
                            search: _transactionSearch,
                            nextPage: true,
                          ),
                  icon: const Icon(Icons.expand_more_rounded, size: 18),
                  label: Text(
                    provider.isLoading ? 'Loading…' : 'Load more',
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _activitySummary(RewardsAdminProvider provider) {
    final a = provider.analytics!;
    return GridView.count(
      crossAxisCount: Responsive.statColumns(context, max: 4),
      crossAxisSpacing: context.w(12),
      mainAxisSpacing: context.h(12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: Responsive.isMobile(context) ? 1.8 : 2.3,
      children: [
        _metricCard('Issued', _number(a.totalPointsIssued), Icons.add_circle_outline),
        _metricCard('Redeemed', _number(a.totalPointsRedeemed), Icons.redeem),
        _metricCard(
          'Outstanding',
          _number(a.outstandingPointsLiability),
          Icons.account_balance_wallet_outlined,
        ),
        _metricCard(
          'Referrals',
          _number(a.successfulReferrals),
          Icons.group_add_outlined,
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, IconData icon) {
    final colors = AppColors.of(context);
    return Container(
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              SizedBox(width: context.w(6)),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context)
                      .copyWith(color: colors.textSecondary),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(6)),
          Text(
            value,
            style: AppTextStyles.section(context)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _transactionTable(List<RewardTransaction> items) {
    return RdxTable(
      showFooter: false,
      columns: const [
        RdxTableColumn(title: 'USER', minWidth: 140, flex: 1.2),
        RdxTableColumn(title: 'TYPE', minWidth: 110, flex: 0.9),
        RdxTableColumn(title: 'POINTS', minWidth: 90, flex: 0.7),
        RdxTableColumn(title: 'ORDER', minWidth: 120, flex: 1),
        RdxTableColumn(title: 'WHEN', minWidth: 140, flex: 1),
      ],
      rows: [
        for (final item in items)
          [
            _plainCell(_shortId(item.userId)),
            _typeBadge(item.type),
            _pointsCell(item.points),
            _plainCell(item.orderId ?? '—'),
            _plainCell(_date(item.createdAt)),
          ],
      ],
    );
  }

  Widget _typeBadge(RewardTransactionType type) {
    final label = switch (type) {
      RewardTransactionType.earned => 'Earned',
      RewardTransactionType.redeemed => 'Redeemed',
      RewardTransactionType.referralBonus => 'Referral',
      RewardTransactionType.reversal => 'Reversal',
      RewardTransactionType.adjustment => 'Adjustment',
    };
    final color = switch (type) {
      RewardTransactionType.earned ||
      RewardTransactionType.referralBonus =>
        const Color(0xFF16A05A),
      RewardTransactionType.redeemed => const Color(0xFFF39A24),
      _ => AppColors.of(context).textSecondary,
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(8),
        vertical: context.h(3),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(context).copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _pointsCell(int points) {
    final positive = points >= 0;
    return Text(
      positive ? '+$points' : '$points',
      style: AppTextStyles.caption(context).copyWith(
        color: positive ? const Color(0xFF16A05A) : AppColors.danger,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _plainCell(String text) => Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(8)),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context),
        ),
      );

  // ─── Shared helpers ──────────────────────────────────────────────────────

  Widget _pageList({required List<Widget> children}) => RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshCurrent,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: Responsive.pagePadding(context, bottom: 28),
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) SizedBox(height: context.h(16)),
              children[index],
            ],
          ],
        ),
      );

  Future<void> _refreshCurrent() async {
    final provider = ref.read(rewardsAdminProvider);
    switch (_sectionIndex) {
      case 0:
        await provider.load();
        if (provider.canRead) await provider.loadTransactions();
      case 1:
      case 2:
        await provider.load();
      case 3:
        await provider.loadTransactions(type: _transactionType);
    }
  }

  Widget _panel({
    required Widget child,
    String? title,
    IconData? icon,
    Widget? headerTrailing,
  }) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.h(14)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: context.h(18), color: AppColors.primary),
                  SizedBox(width: context.w(8)),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.section(context)
                        .copyWith(color: colors.textPrimary),
                  ),
                ),
                if (headerTrailing != null) headerTrailing,
              ],
            ),
            SizedBox(height: context.h(16)),
          ],
          child,
        ],
      ),
    );
  }

  Widget _informationCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.w(14),
        vertical: context.h(12),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EA),
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: context.h(18), color: AppColors.primary),
          SizedBox(width: context.w(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label(context).copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: context.h(4)),
                Text(
                  message,
                  style: AppTextStyles.bodyTertiary(context)
                      .copyWith(color: colors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchCard({
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.h(14)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(8)),
        border: Border.all(color: colors.border),
      ),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: IgnorePointer(
          ignoring: !enabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodySecondary(context).copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: context.w(8)),
                  RdxToggleButton(value: value, onChanged: onChanged),
                ],
              ),
              SizedBox(height: context.h(4)),
              Text(
                subtitle,
                style: AppTextStyles.caption(context)
                    .copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    bool enabled = true,
  }) {
    return FormField<String>(
      validator: (_) => validator(controller.text),
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(
            opacity: enabled ? 1 : 0.5,
            child: IgnorePointer(
              ignoring: !enabled,
              child: RdxTextField(
                controller: controller,
                label: label,
                hint: label,
                keyboardType: TextInputType.number,
                textCapitalization: TextCapitalization.none,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (_) {
                  _configurationDirty = true;
                  if (state.hasError) state.validate();
                },
              ),
            ),
          ),
          if (state.hasError)
            Padding(
              padding: EdgeInsets.only(top: context.h(4)),
              child: Text(
                state.errorText!,
                style: AppTextStyles.caption(context)
                    .copyWith(color: AppColors.danger),
              ),
            ),
        ],
      ),
    );
  }

  Widget _numField({
    required String label,
    required double? value,
    required ValueChanged<double?> onChanged,
    bool allowNull = false,
    bool enabled = true,
  }) {
    // Order totals are entered as whole rupees (integers); stored as double.
    final controller = TextEditingController(
      text: value == null ? '' : value.round().toString(),
    );
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: RdxTextField(
          controller: controller,
          label: label,
          hint: allowNull ? 'Optional' : '0',
          keyboardType: TextInputType.number,
          textCapitalization: TextCapitalization.none,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (raw) {
            final t = raw.trim();
            if (t.isEmpty && allowNull) {
              onChanged(null);
              return;
            }
            final v = int.tryParse(t);
            if (v != null && v >= 0) onChanged(v.toDouble());
          },
        ),
      ),
    );
  }

  Widget _intField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    bool enabled = true,
  }) {
    final controller = TextEditingController(text: value.toString());
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: RdxTextField(
          controller: controller,
          label: label,
          hint: '0',
          keyboardType: TextInputType.number,
          textCapitalization: TextCapitalization.none,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (raw) {
            final v = int.tryParse(raw.trim());
            if (v != null && v >= 0) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _inlineError(String message) => Padding(
        padding: EdgeInsets.only(top: context.h(8)),
        child: Text(
          message,
          style:
              AppTextStyles.caption(context).copyWith(color: AppColors.danger),
        ),
      );

  String? _integer(String? value, {required int min}) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) return 'Enter a whole number.';
    if (parsed < min) return 'Enter a value of at least $min.';
    return null;
  }

  String _number(int value) => value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );

  String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _shortId(String id) {
    if (id.length <= 14) return id;
    return '${id.substring(0, 8)}…${id.substring(id.length - 4)}';
  }

  String _transactionTypeKey(RewardTransactionType type) => switch (type) {
        RewardTransactionType.earned => 'earned',
        RewardTransactionType.redeemed => 'redeemed',
        RewardTransactionType.referralBonus => 'referral_bonus',
        RewardTransactionType.reversal => 'reversal',
        RewardTransactionType.adjustment => 'adjustment',
      };

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final AppColorScheme colors;
  final VoidCallback onTap;

  const _SectionFilterChip({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.h(20)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(8),
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : colors.surface,
          borderRadius: BorderRadius.circular(context.h(20)),
          border: Border.all(
            color: selected ? AppColors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: selected
              ? AppTextStyles.label(context).copyWith(color: Colors.white)
              : AppTextStyles.label(context)
                  .copyWith(color: colors.textSecondary),
        ),
      ),
    );
  }
}