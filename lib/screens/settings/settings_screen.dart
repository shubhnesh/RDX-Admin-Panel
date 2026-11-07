import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/screens/settings/operating_hours_editor.dart';
import 'package:rdx_admin/screens/settings/fees_editor.dart';
import '../../widgets/buttons/rdx_toggle_button.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  final VoidCallback? onRewards;
  final VoidCallback? onUserManagement;
  final VoidCallback? onSupport;
  final VoidCallback? onLogout;

  const SettingsScreen({
    super.key,
    this.onRewards,
    this.onUserManagement,
    this.onSupport,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final provider = ref.watch(settingsProvider);
    final auth = ref.watch(authProvider);
    final canEdit = auth.permissions.canEditSettings;
    final canViewRewards = auth.permissions.canViewRewards;
    final canManageUsers = auth.permissions.canManageUsers;

    return Scaffold(
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        padding: Responsive.pagePadding(context, top: context.h(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('System Settings',
                          style: AppTextStyles.heading(context)),
                      SizedBox(height: context.h(4)),
                      Text(
                          canEdit
                              ? 'Manage essential configuration for your restaurant operations.'
                              : 'Restaurant information and operating settings.',
                          style: AppTextStyles.bodySecondary(context)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(18)),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final identity =
                    _IdentityCard(colors: colors, canEdit: canEdit);
                final hours = _SettingsCard(
                  title: 'Operating Hours',
                  icon: Icons.access_time_outlined,
                  colors: colors,
                  child: OperatingHoursEditor(canEdit: canEdit),
                );
                final fees = _OrderFeesSettings(
                  provider: provider,
                  colors: colors,
                  canEdit: canEdit,
                );
                final supportAccount = _SupportAccountCard(
                  colors: colors,
                  onRewards: canViewRewards ? onRewards : null,
                  onUserManagement: canManageUsers ? onUserManagement : null,
                  onSupport: onSupport,
                  onLogout: onLogout,
                  showRewards: canViewRewards,
                  showUserManagement: canManageUsers,
                );

                if (compact) {
                  return Column(children: [
                    identity,
                    SizedBox(height: context.h(14)),
                    fees,
                    SizedBox(height: context.h(14)),
                    hours,
                    SizedBox(height: context.h(14)),
                    supportAccount,
                  ]);
                }
                return Column(children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(children: [
                          identity,
                          SizedBox(height: context.h(14)),
                          fees,
                          SizedBox(height: context.h(14)),
                          hours,
                          SizedBox(height: context.h(14)),
                          supportAccount,
                        ]),
                      ),
                    ],
                  ),
                ]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportAccountCard extends StatelessWidget {
  final AppColorScheme colors;
  final VoidCallback? onRewards;
  final VoidCallback? onUserManagement;
  final VoidCallback? onSupport;
  final VoidCallback? onLogout;
  final bool showRewards;
  final bool showUserManagement;

  const _SupportAccountCard({
    required this.colors,
    required this.onRewards,
    required this.onUserManagement,
    required this.onSupport,
    required this.onLogout,
    this.showRewards = true,
    this.showUserManagement = false,
  });

  @override
  Widget build(BuildContext context) => _SettingsCard(
        title: 'Support & Account',
        icon: Icons.manage_accounts_outlined,
        colors: colors,
        child: Column(
          children: [
            if (showRewards) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.stars_outlined,
                  size: 20,
                  color: colors.textSecondary,
                ),
                title: Text(
                  'Rewards',
                  style: AppTextStyles.section(context)
                      .copyWith(color: colors.textPrimary),
                ),
                subtitle: Text(
                  'Manage points, redemptions and referral rewards.',
                  style: AppTextStyles.bodySecondary(context),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: colors.textMuted,
                ),
                onTap: onRewards,
              ),
              Divider(height: context.h(1), color: colors.divider),
            ],
            if (showUserManagement) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.manage_accounts_outlined,
                  size: 20,
                  color: colors.textSecondary,
                ),
                title: Text(
                  'User management',
                  style: AppTextStyles.section(context)
                      .copyWith(color: colors.textPrimary),
                ),
                subtitle: Text(
                  'Create accounts and assign admin or staff access.',
                  style: AppTextStyles.bodySecondary(context),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: colors.textMuted,
                ),
                onTap: onUserManagement,
              ),
              Divider(height: context.h(1), color: colors.divider),
            ],
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.support_agent_outlined,
                size: 20,
                color: colors.textSecondary,
              ),
              title: Text(
                'Support',
                style: AppTextStyles.section(context)
                    .copyWith(color: colors.textPrimary),
              ),
              subtitle: Text(
                'Get help with your account or restaurant setup.',
                style: _smallScreenTextStyle(
                  context,
                  AppTextStyles.bodySecondary(context),
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: colors.textMuted,
              ),
              onTap: onSupport,
            ),
            Divider(height: context.h(1), color: colors.divider),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.exit_to_app_rounded,
                size: 20,
                color: Color(0xFFE05151),
              ),
              title: const Text(
                'Log out',
                style: TextStyle(
                  color: Color(0xFFE05151),
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Sign out of your account.',
                style: _smallScreenTextStyle(
                  context,
                  AppTextStyles.bodySecondary(context),
                ),
              ),
              onTap: onLogout,
            ),
          ],
        ),
      );
}

class _IdentityCard extends ConsumerWidget {
  final AppColorScheme colors;
  final bool canEdit;
  const _IdentityCard({required this.colors, required this.canEdit});

  void _log(String message) {
    if (kDebugMode) debugPrint('[SettingsScreen] $message');
  }

  Future<void> _openProfile(BuildContext context) async {
    _log('Restaurant profile action tapped.');
    await Navigator.of(context).pushNamed(AppRoutes.restaurantProfile);
    _log('Returned from restaurant profile.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    return _SettingsCard(
      title: 'Restaurant Identity',
      icon: Icons.storefront_outlined,
      colors: colors,
      trailing: canEdit
          ? TextButton(
              onPressed: () => _openProfile(context),
              child: const Text('Edit Restaurant Profile'),
            )
          : null,
      child: Column(children: [
        _LabeledInput(
            label: 'Restaurant Name',
            value: settings.restaurantName,
            colors: colors),
        SizedBox(height: context.h(10)),
        _LabeledInput(
            label: 'Primary Address', value: settings.address, colors: colors),
        SizedBox(height: context.h(10)),
        Row(children: [
          Expanded(
              child: _LabeledInput(
                  label: 'Support Email',
                  value: settings.email,
                  colors: colors)),
          SizedBox(width: context.w(10)),
          Expanded(
              child: _LabeledInput(
                  label: 'Contact Phone',
                  value: settings.phone,
                  colors: colors))
        ]),
      ]),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final AppColorScheme colors;
  final Widget child;
  final Widget? trailing;
  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.colors,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.w(12),
        context.h(12),
        context.w(12),
        context.h(14),
      ),
      decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(context.h(8)),
          border: Border.all(color: colors.border)),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Row(children: [
              Icon(icon, size: context.h(18), color: AppColors.primary),
              SizedBox(width: context.w(8)),
              Flexible(
                child: Text(title,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.section(context)
                        .copyWith(color: colors.textPrimary)),
              ),
            ]),
          ),
          if (trailing != null) trailing!,
        ]),
        SizedBox(height: context.h(10)),
        Divider(height: context.h(1), color: colors.divider),
        SizedBox(height: context.h(10)),
        child
      ]));
}

class _LabeledInput extends StatelessWidget {
  final String label;
  final String value;
  final AppColorScheme colors;
  const _LabeledInput(
      {required this.label, required this.value, required this.colors});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _FieldLabel(label, colors),
        SizedBox(height: context.h(6)),
        _SettingsInput(value: value, colors: colors)
      ]);
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final AppColorScheme colors;
  const _FieldLabel(this.label, this.colors);
  @override
  Widget build(BuildContext context) => Text(label,
      style: AppTextStyles.bodySecondary(context)
          .copyWith(color: colors.textSecondary));
}

class _SettingsInput extends StatelessWidget {
  final String value;
  final AppColorScheme colors;
  const _SettingsInput({required this.value, required this.colors});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: context.w(10),
          vertical: context.h(9),
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(context.h(5)),
          border: Border.all(color: colors.border),
        ),
        child: Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body(context)
                .copyWith(color: colors.textSecondary)),
      );
}

class _OrderFeesSettings extends StatelessWidget {
  final SettingsProvider provider;
  final AppColorScheme colors;
  final bool canEdit;

  const _OrderFeesSettings({
    required this.provider,
    required this.colors,
    required this.canEdit,
  });

  void _log(String message) {
    if (kDebugMode) debugPrint('[SettingsScreen] $message');
  }

  @override
  Widget build(BuildContext context) => _SettingsCard(
        title: 'Order fees',
        icon: Icons.payments_outlined,
        colors: colors,
        trailing: canEdit
            ? TextButton(
                onPressed: () => _editFees(context),
                child: const Text('Edit fees charges'),
              )
            : null,
        child: Column(
          children: [
            _FeeValueTile(
              title: 'GST',
              value: '${_formatFeeValue(provider.gstPercent)}%',
              colors: colors,
            ),
            _FeeValueTile(
              title: 'Delivery fee',
              value: '₹${_formatFeeValue(provider.deliveryFee)}',
              colors: colors,
            ),
            _FeeValueTile(
              title: 'Long distance fee (optional at checkout)',
              value: '₹${_formatFeeValue(provider.longDistanceFee)}',
              colors: colors,
            ),
            if (canEdit)
              _RuleTile(
                title:
                    'Late Night Delivery (₹${_formatFeeValue(provider.lateNightFee)})',
                value: provider.lateNightDelivery,
                onChanged: _toggleLateNightDelivery,
                colors: colors,
              )
            else
              _FeeValueTile(
                title: 'Late night delivery',
                value:
                    '${provider.lateNightDelivery ? 'On' : 'Off'} · ₹${_formatFeeValue(provider.lateNightFee)}',
                colors: colors,
              ),
          ],
        ),
      );

  Future<void> _toggleLateNightDelivery(bool value) async {
    _log('Late-night delivery toggle tapped: $value.');
    await provider.toggleLateNightDelivery(value);
    _log(provider.errorMessage == null
        ? 'Late-night delivery toggle finished.'
        : 'Late-night delivery toggle failed.');
  }

  Future<void> _editFees(BuildContext context) async {
    _log('Edit order fees action tapped.');
    await provider.load();
    if (!context.mounted) return;
    if (provider.errorMessage != null) {
      _log('Fee editor opening stopped; settings refresh failed.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage!)),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const FeesEditor(),
      ),
    );
    _log('Returned from order fee editor.');
  }

  String _formatFeeValue(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}

class _RuleTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppColorScheme colors;

  const _RuleTile({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(8)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodySecondary(context)
                    .copyWith(color: colors.textPrimary),
              ),
            ),
            RdxToggleButton(value: value, onChanged: onChanged),
          ],
        ),
      );
}

class _FeeValueTile extends StatelessWidget {
  final String title;
  final String value;
  final AppColorScheme colors;

  const _FeeValueTile({
    required this.title,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(8)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: _smallScreenTextStyle(
                  context,
                  AppTextStyles.bodySecondary(context),
                ).copyWith(color: colors.textPrimary),
              ),
            ),
            Text(
              value,
              style: _smallScreenTextStyle(
                context,
                AppTextStyles.bodySecondary(context),
              ).copyWith(color: colors.textPrimary),
            ),
          ],
        ),
      );
}

TextStyle _smallScreenTextStyle(BuildContext context, TextStyle style) {
  if (MediaQuery.sizeOf(context).width >= 600) return style;
  return style.copyWith(fontSize: (style.fontSize ?? 14) + 1.5);
}
