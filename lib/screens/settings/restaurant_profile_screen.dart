import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/custom_text_field.dart';

class RestaurantProfileScreen extends StatefulWidget {
  const RestaurantProfileScreen({super.key});

  @override
  State<RestaurantProfileScreen> createState() =>
      _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends State<RestaurantProfileScreen> {
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController addressController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    nameController = TextEditingController(text: settings.restaurantName);
    descriptionController = TextEditingController(text: settings.description);
    addressController = TextEditingController(text: settings.address);
    phoneController = TextEditingController(text: settings.phone);
    emailController = TextEditingController(text: settings.email);
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await context.read<SettingsProvider>().save(
          name: nameController.text,
          desc: descriptionController.text,
          addr: addressController.text,
          ph: phoneController.text,
          em: emailController.text,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(ok ? 'Settings saved' : 'Failed to save settings')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final provider = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        padding: Responsive.pagePadding(context, top: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Text('Restaurant Profile',
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: provider.isLoading ? null : _save,
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
                Text('Configure RDX Admin platform details.',
                    style:
                        TextStyle(color: colors.textSecondary, fontSize: 10)),
                const SizedBox(height: 18),
                _ProfileSection(
                  title: 'Brand Identity',
                  colors: colors,
                  child: Row(
                    children: [
                      Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.background,
                              border: Border.all(color: colors.border)),
                          child: const Icon(Icons.restaurant,
                              color: AppColors.primary)),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const Text('Brand Identity',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('Recommended size: 512x512px. Max 2MB.',
                                style: TextStyle(
                                    color: colors.textSecondary, fontSize: 9)),
                            const SizedBox(height: 8),
                            OutlinedButton(
                                onPressed: () {},
                                child: const Text('Upload New'))
                          ])),
                    ],
                  ),
                ),
                _ProfileSection(
                  title: 'Basic Information',
                  colors: colors,
                  child: Column(children: [
                    CustomTextField(
                        controller: nameController, label: 'Restaurant Name'),
                    const SizedBox(height: 12),
                    CustomTextField(
                        controller: descriptionController,
                        label: 'Brief Description',
                        maxLines: 2)
                  ]),
                ),
                _ProfileSection(
                  title: 'Location & Contact',
                  colors: colors,
                  child: Column(children: [
                    CustomTextField(
                        controller: addressController,
                        label: 'Primary Address'),
                    const SizedBox(height: 12),
                    LayoutBuilder(builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 480;
                      final phone = CustomTextField(
                          controller: phoneController, label: 'Support Phone');
                      final email = CustomTextField(
                          controller: emailController, label: 'Support Email');
                      return narrow
                          ? Column(children: [
                              phone,
                              const SizedBox(height: 12),
                              email
                            ])
                          : Row(children: [
                              Expanded(child: phone),
                              const SizedBox(width: 12),
                              Expanded(child: email)
                            ]);
                    })
                  ]),
                ),
                _ProfileSection(
                  title: 'Operating Hours',
                  colors: colors,
                  child: Column(children: [
                    for (final day in ['Weekdays', 'Weekends'])
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(children: [
                            Expanded(
                                child: Text(day,
                                    style: TextStyle(
                                        color: colors.textSecondary,
                                        fontSize: 10))),
                            Expanded(
                                child: _ProfileTime(
                                    text: day == 'Weekdays'
                                        ? '08:00 AM'
                                        : '10:00 AM',
                                    colors: colors)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _ProfileTime(
                                    text: day == 'Weekdays'
                                        ? '11:00 PM'
                                        : '02:00 AM',
                                    colors: colors)),
                            Switch(
                                value: true,
                                onChanged: (_) {},
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap)
                          ]))
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final AppColorScheme colors;
  final Widget child;
  const _ProfileSection(
      {required this.title, required this.colors, required this.child});
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        child
      ]));
}

class _ProfileTime extends StatelessWidget {
  final String text;
  final AppColorScheme colors;
  const _ProfileTime({required this.text, required this.colors});
  @override
  Widget build(BuildContext context) => Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: colors.border)),
      child: Text(text,
          style: TextStyle(color: colors.textSecondary, fontSize: 9)));
}
