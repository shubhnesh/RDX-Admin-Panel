import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final provider = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        padding: Responsive.pagePadding(context, top: 16),
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
                          style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                          'Manage essential configuration for your restaurant operations.',
                          style: TextStyle(
                              color: colors.textSecondary, fontSize: 10)),
                    ],
                  ),
                ),
                OutlinedButton(onPressed: () {}, child: const Text('Discard')),
                const SizedBox(width: 8),
                ElevatedButton(
                    onPressed: () {}, child: const Text('Save Changes')),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final identity = _IdentityCard(colors: colors);
                final rules = _RulesCard(provider: provider, colors: colors);
                final hours = _HoursCard(colors: colors);
                if (compact) {
                  return Column(children: [
                    identity,
                    const SizedBox(height: 14),
                    hours,
                    const SizedBox(height: 14),
                    rules
                  ]);
                }
                return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          flex: 3,
                          child: Column(children: [
                            identity,
                            const SizedBox(height: 14),
                            rules
                          ])),
                      const SizedBox(width: 14),
                      Expanded(child: hours)
                    ]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final AppColorScheme colors;
  const _IdentityCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    return _SettingsCard(
      title: 'Restaurant Identity',
      icon: Icons.storefront_outlined,
      colors: colors,
      child: Column(children: [
        _LabeledInput(
            label: 'Restaurant Name',
            value: settings.restaurantName,
            colors: colors),
        const SizedBox(height: 10),
        _LabeledInput(
            label: 'Primary Address', value: settings.address, colors: colors),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _LabeledInput(
                  label: 'Support Email',
                  value: settings.email,
                  colors: colors)),
          const SizedBox(width: 10),
          Expanded(
              child: _LabeledInput(
                  label: 'Contact Phone',
                  value: settings.phone,
                  colors: colors))
        ]),
        const SizedBox(height: 10),
        Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.restaurantProfile),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text('Open Restaurant Profile'))),
      ]),
    );
  }
}

class _HoursCard extends StatelessWidget {
  final AppColorScheme colors;
  const _HoursCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return _SettingsCard(
      title: 'Operating Hours',
      icon: Icons.access_time,
      colors: colors,
      trailing: const Text('SYSTEM ONLINE',
          style: TextStyle(color: AppColors.success, fontSize: 8)),
      child: Column(children: [
        for (final day in days)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                SizedBox(
                    width: 30,
                    child: Text(day,
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 10))),
                Switch(
                    value: day != 'Sat' && day != 'Sun',
                    onChanged: (_) {},
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                const SizedBox(width: 4),
                Expanded(
                    child: _TimeBox(
                        text: day == 'Sat' || day == 'Sun'
                            ? 'CLOSED'
                            : '10:00 AM',
                        colors: colors)),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('to')),
                Expanded(
                    child: _TimeBox(
                        text: day == 'Sat' || day == 'Sun'
                            ? 'CLOSED'
                            : '10:00 PM',
                        colors: colors))
              ]))
      ]),
    );
  }
}

class _RulesCard extends StatelessWidget {
  final SettingsProvider provider;
  final AppColorScheme colors;
  const _RulesCard({required this.provider, required this.colors});

  @override
  Widget build(BuildContext context) => _SettingsCard(
      title: 'Core Operational Rules',
      icon: Icons.tune,
      colors: colors,
      child: Column(children: [
        _RuleTile(
            title: 'Auto-Dispatch Orders',
            subtitle:
                'Automatically assign accepted orders to available riders within a 2km radius.',
            value: provider.autoAcceptOrders,
            onChanged: provider.toggleAutoAccept,
            colors: colors),
        _RuleTile(
            title: 'Require Manager Approval for Refunds',
            subtitle:
                'Prevent auto-refunds on canceled orders exceeding \$50.00.',
            value: provider.requireManagerApprovalForRefunds,
            onChanged: provider.toggleManagerApproval,
            colors: colors),
        _RuleTile(
            title: 'Source Pricing Automation',
            subtitle: 'Enable dynamic pricing adjustments during peak hours.',
            value: provider.keepPricingConsistent,
            onChanged: provider.toggleKeepPricing,
            colors: colors),
      ]));
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final AppColorScheme colors;
  final Widget child;
  final Widget? trailing;
  const _SettingsCard(
      {required this.title,
      required this.icon,
      required this.colors,
      required this.child,
      this.trailing});

  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border)),
      child: Column(children: [
        Row(children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          if (trailing != null) trailing!
        ]),
        const SizedBox(height: 10),
        Divider(height: 1, color: colors.divider),
        const SizedBox(height: 10),
        child
      ]));
}

class _RuleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppColorScheme colors;
  const _RuleTile(
      {required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged,
      required this.colors});

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(color: colors.textPrimary, fontSize: 10)),
          const SizedBox(height: 3),
          Text(subtitle,
              style: TextStyle(color: colors.textSecondary, fontSize: 8))
        ])),
        Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)
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
        const SizedBox(height: 6),
        _SettingsInput(value: value, colors: colors)
      ]);
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final AppColorScheme colors;
  const _FieldLabel(this.label, this.colors);
  @override
  Widget build(BuildContext context) =>
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 8));
}

class _SettingsInput extends StatelessWidget {
  final String value;
  final AppColorScheme colors;
  const _SettingsInput({required this.value, required this.colors});
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: colors.border)),
      child: Text(value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: colors.textSecondary, fontSize: 9)));
}

class _TimeBox extends StatelessWidget {
  final String text;
  final AppColorScheme colors;
  const _TimeBox({required this.text, required this.colors});
  @override
  Widget build(BuildContext context) => Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
      decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.border)),
      child: Text(text,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: colors.textSecondary, fontSize: 8)));
}
