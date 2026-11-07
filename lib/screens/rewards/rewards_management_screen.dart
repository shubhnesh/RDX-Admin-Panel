import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/menu_item_model.dart';
import 'package:rdx_admin/models/rewards_admin_models.dart';
import 'package:rdx_admin/providers/rewards_admin_provider.dart';
import 'package:rdx_admin/widgets/reusable_widgets/empty_state.dart';
import 'package:rdx_admin/widgets/reusable_widgets/loading_indicator.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_header.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_search_bar.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_table.dart';
import 'package:rdx_admin/screens/rewards/rewards_overview_tab.dart';

part 'rewards_catalog_view.dart';
part 'rewards_records_view.dart';

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
    'Configuration',
    'Redemption catalog',
    'Referral settings',
    'Transactions',
    'Redemptions',
    'Referrals',
  ];

  final _configurationFormKey = GlobalKey<FormState>();
  final _earningRateController = TextEditingController();
  final _fixedRateController = TextEditingController();
  final _eligibleBasisController = TextEditingController();
  final _minimumOrderController = TextEditingController();
  final _conversionController = TextEditingController();
  final _minimumRedeemController = TextEditingController();
  final _maximumRedeemController = TextEditingController();
  final _validityController = TextEditingController();
  final _referrerPointsController = TextEditingController();
  final _newUserPointsController = TextEditingController();
  final _referralMinimumController = TextEditingController();
  final _referralLimitController = TextEditingController();
  final _referralValidFromController = TextEditingController();
  final _referralValidUntilController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _transactionSearchController = TextEditingController();
  final _referralSearchController = TextEditingController();
  final _redemptionSearchController = TextEditingController();

  RewardEarningMode _earningMode = RewardEarningMode.percentage;
  bool _rewardsEnabled = false;
  bool _referralsEnabled = false;
  bool _configurationLoaded = false;
  int? _loadedVersion;
  bool _configurationDirty = false;
  int _sectionIndex = 0;
  String _transactionSearch = '';
  String _referralSearch = '';
  String _redemptionSearch = '';
  String? _transactionType;
  String? _referralStatus;
  String? _redemptionStatus;

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
    _log('Step 1: initial rewards screen load started.');
    final provider = ref.read(rewardsAdminProvider);
    await provider.load();
    _log('Step 2: initial load permission result is ${provider.canRead}.');
    if (!mounted) {
      _log('Initial rewards load stopped: screen is no longer mounted.');
      return;
    }
    if (!provider.canRead) {
      _log('Initial transactions load skipped: read permission unavailable.');
      return;
    }
    _log('Step 3: loading initial transactions.');
    await provider.loadTransactions();
    _log('Step 4: initial rewards screen load completed.');
  }

  @override
  void dispose() {
    _earningRateController.dispose();
    _fixedRateController.dispose();
    _eligibleBasisController.dispose();
    _minimumOrderController.dispose();
    _conversionController.dispose();
    _minimumRedeemController.dispose();
    _maximumRedeemController.dispose();
    _validityController.dispose();
    _referrerPointsController.dispose();
    _newUserPointsController.dispose();
    _referralMinimumController.dispose();
    _referralLimitController.dispose();
    _referralValidFromController.dispose();
    _referralValidUntilController.dispose();
    _qualificationController.dispose();
    _transactionSearchController.dispose();
    _referralSearchController.dispose();
    _redemptionSearchController.dispose();
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
    _earningMode = config.earningMode;
    _earningRateController.text = config.percentageBps.toString();
    _fixedRateController.text = config.pointsPerRupee.toString();
    _eligibleBasisController.text = config.eligibleSubtotalBasis;
    _minimumOrderController.text = config.minimumOrderValuePaise.toString();
    _conversionController.text = config.redemptionPointsPerRupee.toString();
    _minimumRedeemController.text = config.minimumRedemptionPoints.toString();
    _maximumRedeemController.text =
        config.maximumRedemptionPercentage.toString();
    _validityController.text = config.pointsValidityDays?.toString() ?? '';
    _referralsEnabled = config.referralsEnabled;
    _referrerPointsController.text = config.referrerRewardPoints.toString();
    _newUserPointsController.text = config.newUserRewardPoints.toString();
    _referralMinimumController.text =
        config.referralMinimumOrderValuePaise.toString();
    _referralLimitController.text =
        config.referralMaximumRewards?.toString() ?? '';
    _referralValidFromController.text =
        config.referralValidFrom?.toIso8601String() ?? '';
    _referralValidUntilController.text =
        config.referralValidUntil?.toIso8601String() ?? '';
    _qualificationController.text =
        config.referralQualificationConditions.join('\n');
  }

  Future<void> _selectSection(int index) async {
    if (index == _sectionIndex) {
      _log('Section change skipped: ${_sections[index]} is already selected.');
      return;
    }
    _log('Section change requested: ${_sections[index]}.');
    if (_configurationDirty && !await _confirmDiscardChanges()) {
      _log('Section change cancelled; unsaved configuration retained.');
      return;
    }
    if (!mounted) return;
    if (_configurationDirty) {
      final config = ref.read(rewardsAdminProvider).configuration;
      if (config != null) _initializeConfiguration(config, force: true);
    }

    setState(() {
      _sectionIndex = index;
      _configurationDirty = false;
    });

    _log('Section selected: ${_sections[index]}.');
    final provider = ref.read(rewardsAdminProvider);
    switch (index) {
      case 2:
        await provider.loadCatalog();
      case 4:
        await provider.loadTransactions(type: _transactionType);
      case 5:
        await provider.loadRedemptions(status: _redemptionStatus);
      case 6:
        await provider.loadReferrals(status: _referralStatus);
      default:
        break;
    }
  }

  Future<void> _handleBack() async {
    _log('Rewards back action requested.');
    if (_configurationDirty && !await _confirmDiscardChanges()) {
      _log('Back navigation cancelled; unsaved configuration retained.');
      return;
    }
    if (!mounted) return;
    if (_configurationDirty) {
      final config = ref.read(rewardsAdminProvider).configuration;
      if (config != null) _initializeConfiguration(config, force: true);
    }

    final onBack = widget.onBack;
    if (onBack != null) {
      _log('Returning to parent route.');
      onBack();
    } else {
      _log('Attempting Navigator.maybePop for rewards screen.');
      await Navigator.of(context).maybePop();
    }
  }

  Future<bool> _confirmDiscardChanges() async {
    _log('Requesting confirmation to discard unsaved configuration.');
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unsaved changes?'),
        content: const Text(
          'Your reward configuration edits have not been saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    _log('Discard confirmation result: ${discard == true}.');
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
      body: Column(
        children: [
          RdxHeader(
            title: 'Rewards management',
            subtitle: 'Manage points, redemptions and referrals',
            showBackButton: true,
            onBack: _handleBack,
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: provider.isLoading ? null : _refreshCurrent,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          _sectionSelector(context, colors),
          Expanded(
            child: _body(provider),
          ),
        ],
      ),
    );
  }

  Widget _sectionSelector(BuildContext context, AppColorScheme colors) =>
      SizedBox(
        height: 54,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.pageHorizontal(context),
            vertical: 6,
          ),
          itemCount: _sections.length,
          separatorBuilder: (_, __) => SizedBox(width: context.w(8)),
          itemBuilder: (context, index) => ChoiceChip(
            label: Text(_sections[index]),
            selected: _sectionIndex == index,
            selectedColor: AppColors.primary.withValues(alpha: 0.12),
            side: BorderSide(
              color: _sectionIndex == index ? AppColors.primary : colors.border,
            ),
            labelStyle: AppTextStyles.label(context).copyWith(
              color: _sectionIndex == index
                  ? AppColors.primaryDark
                  : colors.textSecondary,
            ),
            onSelected: (_) => _selectSection(index),
          ),
        ),
      );

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
        _sectionIndex < 4) {
      return _errorState(provider.errorMessage!, provider.load);
    }

    return switch (_sectionIndex) {
      0 => RewardsOverviewTab(
          provider: provider,
          onRefresh: _refreshCurrent,
        ),
      1 => _configuration(provider),
      2 => _catalog(provider),
      3 => _referralSettings(provider),
      4 => _transactions(provider),
      5 => _redemptions(provider),
      _ => _referrals(provider),
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

  Widget _configuration(RewardsAdminProvider provider) {
    final config = provider.configuration;
    if (config == null || !_configurationLoaded) {
      return _errorState(
        provider.errorMessage ?? 'Reward configuration is unavailable.',
        provider.load,
      );
    }
    if (!provider.canConfigure) {
      return _pageList(
        children: [
          _informationCard(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Configuration access required',
            message:
                'Your account can view reward information but cannot change reward configuration.',
          ),
          _buildConfigurationForm(config, provider, readOnly: true),
        ],
      );
    }
    return _pageList(
      children: [
        _buildConfigurationForm(config, provider),
      ],
    );
  }

  Widget _buildConfigurationForm(
    RewardConfiguration config,
    RewardsAdminProvider provider, {
    bool readOnly = false,
  }) {
    final enabled = _switchCard(
      title: 'Rewards program',
      subtitle: 'Allow eligible customers to earn and redeem points.',
      value: _rewardsEnabled,
      enabled: !readOnly && !provider.isMutating,
      onChanged: (value) => setState(() {
        _rewardsEnabled = value;
        _configurationDirty = true;
      }),
    );
    return Form(
      key: _configurationFormKey,
      onChanged: () => setState(() => _configurationDirty = true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          enabled,
          _sectionTitle('Earning rules', 'Version ${config.version}'),
          _panel(
            child: Column(
              children: [
                _field(
                  label: 'Eligible subtotal basis',
                  controller: _eligibleBasisController,
                  enabled: !readOnly && !provider.isMutating,
                  validator: _requiredText,
                  helper:
                      'Use the exact basis value accepted by the rewards backend.',
                ),
                SizedBox(height: context.h(12)),
                DropdownButtonFormField<RewardEarningMode>(
                  value: _earningMode,
                  decoration: const InputDecoration(labelText: 'Earning mode'),
                  items: const [
                    DropdownMenuItem(
                      value: RewardEarningMode.percentage,
                      child: Text('Percentage of eligible subtotal'),
                    ),
                    DropdownMenuItem(
                      value: RewardEarningMode.fixedRate,
                      child: Text('Fixed points per rupee'),
                    ),
                  ],
                  onChanged: readOnly || provider.isMutating
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _earningMode = value;
                            _configurationDirty = true;
                          });
                        },
                ),
                SizedBox(height: context.h(12)),
                if (_earningMode == RewardEarningMode.percentage)
                  _field(
                    label: 'Percentage rate (basis points)',
                    controller: _earningRateController,
                    enabled: !readOnly && !provider.isMutating,
                    validator: (value) => _integer(value, min: 0, max: 10000),
                    helper: '100 basis points equals 1%.',
                  )
                else
                  _field(
                    label: 'Points per rupee',
                    controller: _fixedRateController,
                    enabled: !readOnly && !provider.isMutating,
                    validator: (value) => _integer(value, min: 0),
                  ),
                SizedBox(height: context.h(12)),
                _field(
                  label: 'Minimum qualifying order (paise)',
                  controller: _minimumOrderController,
                  enabled: !readOnly && !provider.isMutating,
                  validator: (value) => _integer(value, min: 0),
                ),
              ],
            ),
          ),
          _sectionTitle(
              'Redemption rules', 'Limits are enforced by the backend'),
          _panel(
            child: Column(
              children: [
                _field(
                  label: 'Points per rupee',
                  controller: _conversionController,
                  enabled: !readOnly && !provider.isMutating,
                  validator: (value) => _integer(value, min: 1),
                ),
                SizedBox(height: context.h(12)),
                _field(
                  label: 'Minimum redemption points',
                  controller: _minimumRedeemController,
                  enabled: !readOnly && !provider.isMutating,
                  validator: (value) => _integer(value, min: 0),
                ),
                SizedBox(height: context.h(12)),
                _field(
                  label: 'Maximum order discount (%)',
                  controller: _maximumRedeemController,
                  enabled: !readOnly && !provider.isMutating,
                  validator: (value) => _integer(value, min: 0, max: 100),
                ),
                SizedBox(height: context.h(12)),
                _field(
                  label: 'Points validity in days (optional)',
                  controller: _validityController,
                  enabled: !readOnly && !provider.isMutating,
                  validator: (value) => _optionalInteger(value, min: 1),
                  helper: 'Leave blank when points do not expire.',
                ),
              ],
            ),
          ),
          if (!readOnly) ...[
            SizedBox(height: context.h(16)),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: provider.isMutating || !_configurationDirty
                    ? null
                    : () => _saveConfiguration(config, provider),
                icon: provider.isMutating
                    ? SizedBox(
                        width: context.w(16),
                        height: context.w(16),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  provider.isMutating ? 'Saving...' : 'Save configuration',
                ),
              ),
            ),
          ],
          if (provider.errorMessage != null)
            _inlineError(provider.errorMessage!),
        ],
      ),
    );
  }

  Widget _referralSettings(RewardsAdminProvider provider) {
    final config = provider.configuration;
    if (config == null || !_configurationLoaded) {
      return _errorState(
        provider.errorMessage ?? 'Referral configuration is unavailable.',
        provider.load,
      );
    }
    return _pageList(
      children: [
        _informationCard(
          icon: Icons.info_outline,
          title: 'How referral rewards work',
          message:
              'A referral is attributed once. Rewards are issued only after the new customer completes a qualifying order that is both delivered and paid. The backend prevents self-referrals and duplicate bonuses.',
        ),
        if (!provider.canConfigure)
          _informationCard(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Configuration access required',
            message:
                'Your account does not have permission to change referral settings.',
          ),
        Form(
          key: _configurationFormKey,
          onChanged: () => setState(() => _configurationDirty = true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _switchCard(
                title: 'Referral program',
                subtitle: 'Enable or pause referral attribution and rewards.',
                value: _referralsEnabled,
                enabled: provider.canConfigure && !provider.isMutating,
                onChanged: (value) => setState(() {
                  _referralsEnabled = value;
                  _configurationDirty = true;
                }),
              ),
              _panel(
                child: Column(
                  children: [
                    _field(
                      label: 'Existing customer reward (points)',
                      controller: _referrerPointsController,
                      enabled: provider.canConfigure && !provider.isMutating,
                      validator: (value) => _integer(value, min: 0),
                    ),
                    SizedBox(height: context.h(12)),
                    _field(
                      label: 'New customer reward (points)',
                      controller: _newUserPointsController,
                      enabled: provider.canConfigure && !provider.isMutating,
                      validator: (value) => _integer(value, min: 0),
                    ),
                    SizedBox(height: context.h(12)),
                    _field(
                      label: 'Qualifying order minimum (paise)',
                      controller: _referralMinimumController,
                      enabled: provider.canConfigure && !provider.isMutating,
                      validator: (value) => _integer(value, min: 0),
                    ),
                    SizedBox(height: context.h(12)),
                    _field(
                      label: 'Maximum referrals for campaign (optional)',
                      controller: _referralLimitController,
                      enabled: provider.canConfigure && !provider.isMutating,
                      validator: (value) => _optionalInteger(value, min: 1),
                    ),
                    SizedBox(height: context.h(12)),
                    _field(
                      label: 'Campaign starts (ISO-8601, optional)',
                      controller: _referralValidFromController,
                      enabled: provider.canConfigure && !provider.isMutating,
                      validator: _optionalDate,
                    ),
                    SizedBox(height: context.h(12)),
                    _field(
                      label: 'Campaign ends (ISO-8601, optional)',
                      controller: _referralValidUntilController,
                      enabled: provider.canConfigure && !provider.isMutating,
                      validator: _optionalDate,
                    ),
                    SizedBox(height: context.h(12)),
                    _field(
                      label: 'Qualification conditions (one per line)',
                      controller: _qualificationController,
                      enabled: provider.canConfigure && !provider.isMutating,
                      maxLines: 4,
                      validator: _requiredText,
                      helper:
                          'Conditions are passed to the backend without client-side interpretation.',
                    ),
                  ],
                ),
              ),
              if (provider.canConfigure) ...[
                SizedBox(height: context.h(16)),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: provider.isMutating || !_configurationDirty
                        ? null
                        : () => _saveConfiguration(config, provider),
                    icon: provider.isMutating
                        ? SizedBox(
                            width: context.w(16),
                            height: context.w(16),
                            child:
                                const CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      provider.isMutating
                          ? 'Saving...'
                          : 'Save referral settings',
                    ),
                  ),
                ),
              ],
              if (provider.errorMessage != null)
                _inlineError(provider.errorMessage!),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveConfiguration(
    RewardConfiguration previous,
    RewardsAdminProvider provider,
  ) async {
    _log('Step 1: rewards configuration save requested.');
    if (!_configurationFormKey.currentState!.validate()) {
      _log('Step 2: save stopped because form validation failed.');
      return;
    }
    final starts = _parseOptionalDate(_referralValidFromController.text);
    final ends = _parseOptionalDate(_referralValidUntilController.text);
    if (starts != null && ends != null && !ends.isAfter(starts)) {
      _log('Step 2: save stopped because referral date range is invalid.');
      _showMessage('Referral campaign end must be after its start.');
      return;
    }
    _log('Step 2: configuration validated; requesting save confirmation.');
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save reward configuration?'),
        content: Text(
          'This publishes a new configuration version based on version ${previous.version}. Existing ledger transactions will not be changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (accepted != true) {
      _log('Configuration save cancelled in confirmation dialog.');
      return;
    }
    if (!mounted) return;
    _log('Step 3: save confirmed; building configuration request.');

    final updated = RewardConfiguration(
      version: previous.version,
      enabled: _rewardsEnabled,
      earningMode: _earningMode,
      percentageBps: int.parse(_earningRateController.text.trim()),
      pointsPerRupee: int.parse(_fixedRateController.text.trim()),
      eligibleSubtotalBasis: _eligibleBasisController.text.trim(),
      minimumOrderValuePaise: int.parse(_minimumOrderController.text.trim()),
      redemptionPointsPerRupee: int.parse(_conversionController.text.trim()),
      minimumRedemptionPoints: int.parse(_minimumRedeemController.text.trim()),
      maximumRedemptionPercentage:
          int.parse(_maximumRedeemController.text.trim()),
      pointsValidityDays: _parseOptionalInt(_validityController.text),
      referralsEnabled: _referralsEnabled,
      referrerRewardPoints: int.parse(_referrerPointsController.text.trim()),
      newUserRewardPoints: int.parse(_newUserPointsController.text.trim()),
      referralMinimumOrderValuePaise:
          int.parse(_referralMinimumController.text.trim()),
      referralMaximumRewards: _parseOptionalInt(_referralLimitController.text),
      referralValidFrom: _parseOptionalDate(_referralValidFromController.text),
      referralValidUntil:
          _parseOptionalDate(_referralValidUntilController.text),
      referralQualificationConditions: _qualificationController.text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(),
    );

    try {
      await provider.saveConfiguration(updated);
      if (!mounted) return;
      setState(() => _configurationDirty = false);
      _log('Step 4: configuration save completed successfully.');
      _showMessage('Reward configuration saved.');
    } catch (error) {
      _logFailure('Configuration save', error);
      if (mounted) _showMessage('Unable to save configuration: $error');
    }
  }

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
    _log('Refresh requested for ${_sections[_sectionIndex]}.');
    final provider = ref.read(rewardsAdminProvider);
    switch (_sectionIndex) {
      case 0:
        await provider.load();
        if (provider.canRead) await provider.loadTransactions();
      case 1:
      case 3:
        await provider.load();
      case 2:
        await provider.loadCatalog();
      case 4:
        await provider.loadTransactions(type: _transactionType);
      case 5:
        await provider.loadRedemptions(status: _redemptionStatus);
      case 6:
        await provider.loadReferrals(status: _referralStatus);
    }
    _log('Refresh completed for ${_sections[_sectionIndex]}.');
  }

  Widget _sectionTitle(String title, String subtitle) => Padding(
        padding: EdgeInsets.only(bottom: context.h(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.section(context)),
            SizedBox(height: context.h(3)),
            Text(subtitle, style: AppTextStyles.caption(context)),
          ],
        ),
      );

  Widget _panel({required Widget child}) => Card(
        child: Padding(
          padding: EdgeInsets.all(context.w(18)),
          child: child,
        ),
      );

  Widget _informationCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    final colors = AppColors.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.w(16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.section(context)),
                  SizedBox(height: context.h(5)),
                  Text(
                    message,
                    style: AppTextStyles.bodySecondary(context).copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchCard({
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) =>
      Card(
        child: SwitchListTile(
          value: value,
          onChanged: enabled ? onChanged : null,
          title: Text(title, style: AppTextStyles.section(context)),
          subtitle: Text(subtitle, style: AppTextStyles.caption(context)),
          activeColor: AppColors.primary,
        ),
      );

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    bool enabled = true,
    int maxLines = 1,
    String? helper,
  }) =>
      TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: maxLines == 1 ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      );

  Widget _inlineError(String message) => Padding(
        padding: EdgeInsets.only(top: context.h(8)),
        child: Text(
          message,
          style:
              AppTextStyles.caption(context).copyWith(color: AppColors.danger),
        ),
      );

  String? _requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  String? _integer(String? value, {required int min, int? max}) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) return 'Enter a whole number.';
    if (parsed < min) return 'Enter a value of at least $min.';
    if (max != null && parsed > max)
      return 'Enter a value no greater than $max.';
    return null;
  }

  String? _optionalInteger(String? value, {required int min}) =>
      value == null || value.trim().isEmpty ? null : _integer(value, min: min);

  String? _optionalDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim()) == null
        ? 'Enter a valid ISO-8601 date or leave blank.'
        : null;
  }

  int? _parseOptionalInt(String value) =>
      value.trim().isEmpty ? null : int.parse(value.trim());

  DateTime? _parseOptionalDate(String value) =>
      value.trim().isEmpty ? null : DateTime.parse(value.trim());

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

  String _transactionLabel(RewardTransactionType type) => switch (type) {
        RewardTransactionType.earned => 'Earned',
        RewardTransactionType.redeemed => 'Redeemed',
        RewardTransactionType.referralBonus => 'Referral bonus',
        RewardTransactionType.reversal => 'Reversal',
        RewardTransactionType.adjustment => 'Adjustment',
      };

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _updateState(VoidCallback callback) => setState(callback);
}

class _FoodRewardDialog extends StatefulWidget {
  const _FoodRewardDialog({
    required this.items,
    this.existing,
  });

  final List<MenuItemModel> items;
  final FoodReward? existing;

  @override
  State<_FoodRewardDialog> createState() => _FoodRewardDialogState();
}

class _FoodRewardDialogState extends State<_FoodRewardDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _pointsController;
  late final TextEditingController _stockController;
  late final TextEditingController _validFromController;
  late final TextEditingController _validUntilController;
  late String _menuItemId;
  late bool _available;

  @override
  void initState() {
    super.initState();
    final reward = widget.existing;
    _menuItemId = widget.items.any((item) => item.id == reward?.menuItemId)
        ? reward!.menuItemId
        : widget.items.first.id;
    _pointsController =
        TextEditingController(text: reward?.pointsCost.toString() ?? '');
    _stockController =
        TextEditingController(text: reward?.stockLimit?.toString() ?? '');
    _validFromController = TextEditingController(
      text: reward?.validFrom?.toIso8601String() ?? '',
    );
    _validUntilController = TextEditingController(
      text: reward?.validUntil?.toIso8601String() ?? '',
    );
    _available = reward?.available ?? true;
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _stockController.dispose();
    _validFromController.dispose();
    _validUntilController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add food reward' : 'Edit reward'),
      content: SizedBox(
        width: width > 620 ? 500 : width * 0.82,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _menuItemId,
                  decoration: const InputDecoration(labelText: 'Menu item'),
                  items: widget.items
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child:
                              Text(item.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _menuItemId = value);
                  },
                ),
                SizedBox(height: context.h(12)),
                TextFormField(
                  controller: _pointsController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Points required'),
                  validator: (value) {
                    final points = int.tryParse(value?.trim() ?? '');
                    return points == null || points < 1
                        ? 'Enter a positive whole number.'
                        : null;
                  },
                ),
                SizedBox(height: context.h(12)),
                TextFormField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stock limit (optional)',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final stock = int.tryParse(value.trim());
                    return stock == null || stock < 0
                        ? 'Enter zero or a positive whole number.'
                        : null;
                  },
                ),
                SizedBox(height: context.h(12)),
                TextFormField(
                  controller: _validFromController,
                  decoration: const InputDecoration(
                    labelText: 'Available from (ISO-8601, optional)',
                  ),
                  validator: _dateValidator,
                ),
                SizedBox(height: context.h(12)),
                TextFormField(
                  controller: _validUntilController,
                  decoration: const InputDecoration(
                    labelText: 'Available until (ISO-8601, optional)',
                  ),
                  validator: _dateValidator,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _available,
                  title: const Text('Available for redemption'),
                  onChanged: (value) => setState(() => _available = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  String? _dateValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim()) == null
        ? 'Enter an ISO-8601 date or leave blank.'
        : null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final menuItem = widget.items.firstWhere((item) => item.id == _menuItemId);
    final starts = _validFromController.text.trim();
    final ends = _validUntilController.text.trim();
    if (starts.isNotEmpty &&
        ends.isNotEmpty &&
        !DateTime.parse(ends).isAfter(DateTime.parse(starts))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Availability end must be after start.')),
      );
      return;
    }
    Navigator.pop(
      context,
      FoodReward(
        id: widget.existing?.id ?? '',
        menuItemId: menuItem.id,
        name: menuItem.name,
        pointsCost: int.parse(_pointsController.text.trim()),
        available: _available,
        stockLimit: _stockController.text.trim().isEmpty
            ? null
            : int.parse(_stockController.text.trim()),
        validFrom: starts.isEmpty ? null : DateTime.parse(starts),
        validUntil: ends.isEmpty ? null : DateTime.parse(ends),
        usageCount: widget.existing?.usageCount ?? 0,
      ),
    );
  }
}
