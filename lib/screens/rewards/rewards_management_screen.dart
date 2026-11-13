import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_dropdown.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_text_field.dart';
import 'package:rdx_admin/widgets/buttons/rdx_toggle_button.dart';
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
  List<RewardItemEarningRule> _earningItemRules = [];
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
    _earningItemRules = List.of(config.itemEarningRules);
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
      case 1:
        if (provider.menuItems.isEmpty) await provider.loadMenuItems();
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
    final transactionData =
        _sectionIndex == 4 ? _transactionViewData(provider) : null;
    final headerActions = <Widget>[];
    if (_sectionIndex == 2 && provider.canConfigure) {
      headerActions.add(_catalogAddRewardButton(provider));
    } else if (_sectionIndex == 4 && transactionData != null) {
      headerActions.add(
        _transactionHeader(provider, transactionData.filtered),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            RdxHeader(
              title: 'Rewards management',
              subtitle: 'Manage points, redemptions and referrals',
              showBackButton: true,
              onBack: _handleBack,
              actions: headerActions,
            ),
            Expanded(
              child: _sectionsLayout(
                context,
                colors,
                provider,
                transactionData,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Wide screens: left-side section list + content (same pattern as the
  /// Inventory categories panel). Narrow screens fall back to the chips.
  Widget _sectionsLayout(
    BuildContext context,
    AppColorScheme colors,
    RewardsAdminProvider provider,
    _TransactionViewData? transactionData,
  ) {
    final body = _body(provider, transactionData: transactionData);
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
          // Top/bottom match the content's own padding so both line up.
          padding: EdgeInsets.fromLTRB(
            pagePad.left,
            contentPad.top,
            0,
            contentPad.bottom,
          ),
          child: SizedBox(
            width: 220,
            child: _sectionPanel(context, colors),
          ),
        ),
        // The content keeps its own page padding, which also acts as the
        // gap between the panel and the content.
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
                fontSize: Responsive.isNarrow(context)
                    ? context.h(12).clamp(11.0, 13.0)
                    : context.h(13).clamp(12.0, 14.0),
                letterSpacing: 0.3,
              ),
            ),
          ),
          Divider(height: 1, color: colors.divider),
          Expanded(
            child: Scrollbar(
              child: ListView(
                primary: false,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: EdgeInsets.zero,
                children: [
                  for (var index = 0; index < _sections.length; index++)
                    _sectionTile(context, colors, index),
                ],
              ),
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
          child: Row(
            children: [
              Expanded(
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
              if (selected) ...[
                SizedBox(width: context.w(6)),
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primary,
                  size: context.h(17),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionSelector(BuildContext context, AppColorScheme colors) {
    final pagePad = context.defaultScreenPadding();
    final gap = context.h(20);
    final contentTop = Responsive.pagePadding(context, bottom: 28)
        .resolve(Directionality.of(context))
        .top;
    final bottomGap = gap > contentTop ? gap - contentTop : 0.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        pagePad.left,
        context.h(12),
        pagePad.right,
        bottomGap,
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

  Widget _body(
    RewardsAdminProvider provider, {
    _TransactionViewData? transactionData,
  }) {
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
      4 => _transactions(provider, transactionData!),
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
          SizedBox(height: context.h(16)),
          _panel(
            title: 'Earning rules',
            icon: Icons.trending_up_outlined,
            child: Column(
              children: [
                _field(
                  label: 'Eligible subtotal basis',
                  controller: _eligibleBasisController,
                  enabled: !readOnly && !provider.isMutating,
                  validator: _eligibleSubtotalBasis,
                  helper: 'Order item subtotal after discounts, before tax.',
                ),
                SizedBox(height: context.h(12)),
                _modeDropdown(
                  label: 'Earning mode',
                  value: _earningMode,
                  percentageLabel: 'Percentage of eligible subtotal',
                  enabled: !readOnly && !provider.isMutating,
                  onChanged: (value) => setState(() {
                    _earningMode = value;
                    _configurationDirty = true;
                  }),
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
          SizedBox(height: context.h(16)),
          LayoutBuilder(builder: (context, c) {
            final redemption = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _panel(
            title: 'Redemption rules',
            icon: Icons.redeem_outlined,
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
              ],
            );
            final overrides = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _earningItemRulesPanel(provider, readOnly: readOnly),
              ],
            );
            if (c.maxWidth < 700) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  redemption,
                  SizedBox(height: context.h(16)),
                  overrides,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: redemption),
                SizedBox(width: context.w(16)),
                Expanded(child: overrides),
              ],
            );
          }),
          if (!readOnly) ...[
            SizedBox(height: context.h(16)),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: context.w(200),
                child: RdxActionButton.save(
                  isLoading: provider.isMutating,
                  onPressed: provider.isMutating || !_configurationDirty
                      ? null
                      : () => _saveConfiguration(config, provider),
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
    final readOnly = !provider.canConfigure;
    return _pageList(
      children: [
        _informationCard(
          icon: Icons.info_outline,
          title: 'How referral rewards work',
          message:
              'A referral is attributed once. Rewards are issued when the new customer’s first qualifying order meets the selected paid/delivered conditions. The backend prevents self-referrals and duplicate bonuses.',
        ),
        if (readOnly)
          _informationCard(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Configuration access required',
            message:
                'Your account does not have permission to change referral settings.',
          ),
        _buildReferralForm(config, provider, readOnly: readOnly),
      ],
    );
  }

  /// Same structure as [_buildConfigurationForm]: switch card, then bordered
  /// panels (full width, side by side on wide screens), then the save button.
  Widget _buildReferralForm(
    RewardConfiguration config,
    RewardsAdminProvider provider, {
    bool readOnly = false,
  }) {
    final editable = !readOnly && !provider.isMutating;
    return Form(
      key: _configurationFormKey,
      onChanged: () => setState(() => _configurationDirty = true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _switchCard(
            title: 'Referral program',
            subtitle: 'Enable or pause referral attribution and rewards.',
            value: _referralsEnabled,
            enabled: editable,
            onChanged: (value) => setState(() {
              _referralsEnabled = value;
              _configurationDirty = true;
            }),
          ),
          SizedBox(height: context.h(16)),
          LayoutBuilder(builder: (context, c) {
            final rewards = _panel(
              title: 'Referral rewards',
              icon: Icons.group_add_outlined,
              child: Column(
                children: [
                  _field(
                    label: 'Existing customer reward (points)',
                    controller: _referrerPointsController,
                    enabled: editable,
                    validator: (value) => _integer(value, min: 0),
                  ),
                  SizedBox(height: context.h(12)),
                  _field(
                    label: 'New customer reward (points)',
                    controller: _newUserPointsController,
                    enabled: editable,
                    validator: (value) => _integer(value, min: 0),
                  ),
                  SizedBox(height: context.h(12)),
                  _field(
                    label: 'Qualifying order minimum (paise)',
                    controller: _referralMinimumController,
                    enabled: editable,
                    validator: (value) => _integer(value, min: 0),
                  ),
                  SizedBox(height: context.h(12)),
                  _field(
                    label: 'Maximum referrals for campaign (optional)',
                    controller: _referralLimitController,
                    enabled: editable,
                    validator: (value) => _optionalInteger(value, min: 1),
                  ),
                ],
              ),
            );
            final campaign = _panel(
              title: 'Campaign & qualification',
              icon: Icons.event_available_outlined,
              child: Column(
                children: [
                  _field(
                    label: 'Campaign starts (ISO-8601, optional)',
                    controller: _referralValidFromController,
                    enabled: editable,
                    validator: _optionalDate,
                  ),
                  SizedBox(height: context.h(12)),
                  _field(
                    label: 'Campaign ends (ISO-8601, optional)',
                    controller: _referralValidUntilController,
                    enabled: editable,
                    validator: _optionalDate,
                  ),
                  SizedBox(height: context.h(12)),
                  _field(
                    label: 'Qualification conditions (one per line)',
                    controller: _qualificationController,
                    enabled: editable,
                    maxLines: 4,
                    validator: _referralConditions,
                    helper:
                        'Use paid and/or delivered, one per line. All listed conditions must be met.',
                  ),
                ],
              ),
            );
            if (c.maxWidth < 700) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  rewards,
                  SizedBox(height: context.h(16)),
                  campaign,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: rewards),
                SizedBox(width: context.w(16)),
                Expanded(child: campaign),
              ],
            );
          }),
          if (!readOnly) ...[
            SizedBox(height: context.h(16)),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: context.w(200),
                child: RdxActionButton.save(
                  isLoading: provider.isMutating,
                  onPressed: provider.isMutating || !_configurationDirty
                      ? null
                      : () => _saveConfiguration(config, provider),
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

  Widget _earningItemRulesPanel(
    RewardsAdminProvider provider, {
    required bool readOnly,
  }) {
    if (provider.menuItems.isEmpty) {
      return _panel(
        title: 'Per-item overrides',
        icon: Icons.restaurant_menu_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'No menu items are available for item-specific rules.',
              style: AppTextStyles.bodySecondary(context),
            ),
            SizedBox(height: context.h(8)),
            Align(
              alignment: Alignment.centerLeft,
              child: RdxActionButton(
                label: 'Load menu items',
                onPressed: readOnly || provider.isLoading
                    ? null
                    : provider.loadMenuItems,
                isPrimary: true,
                height: context.h(35).clamp(30.0, 35.0),
                minWidth: context.w(120),
              ),
            ),
          ],
        ),
      );
    }

    final visibleIds = provider.menuItems.map((item) => item.id).toSet();
    final missingRules = _earningItemRules
        .where((rule) => !visibleIds.contains(rule.menuItemId))
        .toList();

    return _panel(
      title: 'Per-item overrides',
      icon: Icons.restaurant_menu_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in provider.menuItems) ...[
            _itemEarningRule(item, readOnly: readOnly, provider: provider),
            const Divider(height: 1),
          ],
          for (final rule in missingRules)
            ListTile(
              title: Text('Unavailable menu item (${rule.menuItemId})'),
              subtitle: const Text(
                'This saved override is retained until you remove it.',
              ),
              trailing: readOnly
                  ? null
                  : IconButton(
                      tooltip: 'Remove item override',
                      onPressed: () => setState(() {
                        _earningItemRules.removeWhere(
                          (itemRule) => itemRule.menuItemId == rule.menuItemId,
                        );
                        _configurationDirty = true;
                      }),
                      icon: const Icon(Icons.delete_outline),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _itemEarningRule(
    MenuItemModel item, {
    required bool readOnly,
    required RewardsAdminProvider provider,
  }) {
    RewardItemEarningRule? rule;
    for (final candidate in _earningItemRules) {
      if (candidate.menuItemId == item.id) {
        rule = candidate;
        break;
      }
    }
    final currentRule = rule;
    final editable = !readOnly && !provider.isMutating;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(8)),
      child: Column(
        children: [
          Opacity(
            opacity: editable ? 1 : 0.5,
            child: IgnorePointer(
              ignoring: !editable,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTextStyles.bodySecondary(context).copyWith(
                            color: AppColors.of(context).textPrimary,
                          ),
                        ),
                        SizedBox(height: context.h(2)),
                        Text(
                          currentRule == null
                              ? 'Uses the global earning rule'
                              : 'Uses an item-specific earning override',
                          style: AppTextStyles.caption(context).copyWith(
                            color: AppColors.of(context).textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: context.w(8)),
                  RdxToggleButton(
                    value: currentRule != null,
                    onChanged: (enabled) => setState(() {
                      if (enabled) {
                        _earningItemRules.add(
                          RewardItemEarningRule(
                            menuItemId: item.id,
                            mode: _earningMode,
                            percentageBps:
                                int.tryParse(_earningRateController.text) ?? 0,
                            pointsPerRupee:
                                int.tryParse(_fixedRateController.text) ?? 0,
                          ),
                        );
                      } else {
                        _earningItemRules.removeWhere(
                          (candidate) => candidate.menuItemId == item.id,
                        );
                      }
                      _configurationDirty = true;
                    }),
                  ),
                ],
              ),
            ),
          ),
          if (currentRule != null) ...[
            SizedBox(height: context.h(10)),
            _modeDropdown(
              key: ValueKey('item-mode-${item.id}-${currentRule.mode.name}'),
              label: 'Item earning mode',
              value: currentRule.mode,
              percentageLabel: 'Percentage of item subtotal',
              enabled: editable,
              onChanged: (mode) => setState(() {
                _replaceItemRule(currentRule.copyWith(mode: mode));
                _configurationDirty = true;
              }),
            ),
            SizedBox(height: context.h(10)),
            _RewardTextField(
              key: ValueKey('item-rate-${item.id}-${currentRule.mode.name}'),
              initialValue: currentRule.mode == RewardEarningMode.percentage
                  ? currentRule.percentageBps.toString()
                  : currentRule.pointsPerRupee.toString(),
              enabled: editable,
              label: currentRule.mode == RewardEarningMode.percentage
                  ? 'Percentage rate (basis points)'
                  : 'Points per rupee',
              helper: currentRule.mode == RewardEarningMode.percentage
                  ? '100 basis points equals 1%.'
                  : null,
              validator: (value) => _integer(
                value,
                min: 0,
                max: currentRule.mode == RewardEarningMode.percentage
                    ? 10000
                    : null,
              ),
              onChanged: (value) {
                final rate = int.tryParse(value.trim());
                if (rate == null) return;
                _replaceItemRule(
                  currentRule.mode == RewardEarningMode.percentage
                      ? currentRule.copyWith(percentageBps: rate)
                      : currentRule.copyWith(pointsPerRupee: rate),
                );
                if (!_configurationDirty) {
                  setState(() => _configurationDirty = true);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  void _replaceItemRule(RewardItemEarningRule updated) {
    final index = _earningItemRules.indexWhere(
      (rule) => rule.menuItemId == updated.menuItemId,
    );
    if (index >= 0) _earningItemRules[index] = updated;
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
      itemEarningRules: List.of(_earningItemRules),
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
        await provider.load();
        await provider.loadMenuItems();
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

  Widget _sectionTitle(String title, String subtitle) {
    final colors = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: context.h(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.section(context)
                .copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: context.h(3)),
          Text(
            subtitle,
            style: AppTextStyles.caption(context)
                .copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  /// Bordered surface panel matching CreateMenuScreen styling.
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
                  style: AppTextStyles.bodyTertiary(context).copyWith(
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Panel with the same title + toggle row used by CreateMenuScreen.
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
      child: _switch(
        title,
        value,
        enabled ? onChanged : null,
        subtitle: subtitle,
      ),
    );
  }

  /// Title + toggle hugging each other, subtitle below — copied from
  /// CreateMenuScreen._switch (uses [RdxToggleButton]).
  Widget _switch(
    String title,
    bool value,
    ValueChanged<bool>? onChanged, {
    String? subtitle,
  }) {
    final colors = AppColors.of(context);
    return Opacity(
      opacity: onChanged == null ? 0.5 : 1,
      child: IgnorePointer(
        ignoring: onChanged == null,
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
                RdxToggleButton(
                  value: value,
                  onChanged: onChanged ?? (_) {},
                ),
              ],
            ),
            if (subtitle != null) ...[
              SizedBox(height: context.h(4)),
              Text(
                subtitle,
                style: AppTextStyles.caption(context)
                    .copyWith(color: colors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _modeDropdown({
    Key? key,
    required String label,
    required RewardEarningMode value,
    required String percentageLabel,
    required bool enabled,
    required ValueChanged<RewardEarningMode> onChanged,
  }) =>
      IgnorePointer(
        key: key,
        ignoring: !enabled,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: RdxDropdown<RewardEarningMode>(
            label: label,
            value: value,
            items: RewardEarningMode.values,
            labelBuilder: (mode) => mode == RewardEarningMode.percentage
                ? percentageLabel
                : 'Fixed points per rupee',
            hint: 'Select $label',
            onChanged: (mode) {
              if (mode != null) onChanged(mode);
            },
            searchable: false,
          ),
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
      _RewardTextField(
        controller: controller,
        label: label,
        enabled: enabled,
        maxLines: maxLines,
        helper: helper,
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

  String? _eligibleSubtotalBasis(String? value) =>
      value?.trim() == 'afterDiscountBeforeTax'
          ? null
          : 'Use afterDiscountBeforeTax.';

  String? _referralConditions(String? value) {
    final conditions = (value ?? '')
        .split('\n')
        .map((condition) => condition.trim())
        .where((condition) => condition.isNotEmpty)
        .toList();
    if (conditions.isEmpty ||
        conditions.any(
          (condition) => condition != 'paid' && condition != 'delivered',
        )) {
      return 'Use paid and/or delivered, one per line.';
    }
    return null;
  }

  String? _integer(String? value, {required int min, int? max}) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) return 'Enter a whole number.';
    if (parsed < min) return 'Enter a value of at least $min.';
    if (max != null && parsed > max) {
      return 'Enter a value no greater than $max.';
    }
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

// ─── Section filter chip (same look as MenuScreen's _FilterChip) ──────

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

/// [RdxTextField] (same look as CreateMenuScreen) wrapped in a [FormField]
/// so the existing validators still run on `Form.validate()`.
class _RewardTextField extends StatefulWidget {
  const _RewardTextField({
    super.key,
    required this.label,
    required this.validator,
    this.controller,
    this.initialValue,
    this.enabled = true,
    this.maxLines = 1,
    this.helper,
    this.onChanged,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final bool enabled;
  final int maxLines;
  final String? helper;
  final String? Function(String?) validator;
  final ValueChanged<String>? onChanged;

  @override
  State<_RewardTextField> createState() => _RewardTextFieldState();
}

class _RewardTextFieldState extends State<_RewardTextField> {
  late final TextEditingController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return FormField<String>(
      validator: (_) => widget.validator(_controller.text),
      builder: (state) => Opacity(
        opacity: widget.enabled ? 1 : 0.5,
        child: IgnorePointer(
          ignoring: !widget.enabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RdxTextField(
                controller: _controller,
                label: widget.label,
                hint: widget.label,
                maxLines: widget.maxLines,
                keyboardType: widget.maxLines == 1
                    ? TextInputType.number
                    : TextInputType.multiline,
                textCapitalization: TextCapitalization.none,
                onChanged: (value) {
                  widget.onChanged?.call(value);
                  if (state.hasError) state.validate();
                },
              ),
              if (state.hasError)
                Padding(
                  padding: EdgeInsets.only(top: context.h(4)),
                  child: Text(
                    state.errorText!,
                    style: AppTextStyles.caption(context)
                        .copyWith(color: AppColors.danger),
                  ),
                )
              else if (widget.helper != null)
                Padding(
                  padding: EdgeInsets.only(top: context.h(4)),
                  child: Text(
                    widget.helper!,
                    style: AppTextStyles.caption(context)
                        .copyWith(color: colors.textMuted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}