import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/reusable_widgets/rdx_text_field.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';

class RestaurantProfileScreen extends ConsumerStatefulWidget {
  const RestaurantProfileScreen({super.key});

  @override
  ConsumerState<RestaurantProfileScreen> createState() =>
      _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState
    extends ConsumerState<RestaurantProfileScreen> {
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController addressController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;

  @override
  void initState() {
    super.initState();

    final settings = ref.read(settingsProvider);

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
    if (!ref.read(authProvider).permissions.canEditSettings) return;
    final ok = await ref.read(settingsProvider).save(
          name: nameController.text,
          desc: descriptionController.text,
          addr: addressController.text,
          ph: phoneController.text,
          em: emailController.text
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Settings saved' : 'Failed to save settings',
          style: AppTextStyles.body(context).copyWith(
            color: AppColors.white
          )
        )
      )
    );

    if (ok) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final provider = ref.watch(settingsProvider);
    final canEdit = ref.watch(authProvider).permissions.canEditSettings;
    final buttonWidth = context.w(160);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const RdxHeader(
            title: 'Restaurant Profile',
            showBackButton: true
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                Responsive.pageHorizontal(context),
                context.h(8),
                Responsive.pageHorizontal(context),
                context.h(32)
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: context.w(860)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileSection(
                        title: 'Basic Information',
                        icon: Icons.description_outlined,
                        colors: colors,
                        child: Column(
                          children: [
                            RdxTextField(
                              controller: nameController,
                              maxLength: 25,
                              label: 'Restaurant Name',
                              enabled: canEdit
                            ),
                            SizedBox(height: context.h(12)),
                            RdxTextField(
                              controller: descriptionController,
                              maxLength: 300,
                              label: 'Brief Description',
                              maxLines: 3,
                              enabled: canEdit
                            ),
                          ]
                        )
                      ),
                      _ProfileSection(
                        title: 'Location & Contact',
                        icon: Icons.location_on_outlined,
                        colors: colors,
                        child: Column(
                          children: [
                            RdxTextField(
                              controller: addressController,
                              maxLength: 80,
                              label: 'Primary Address',
                              maxLines: 3,
                              enabled: canEdit
                            ),
                            SizedBox(height: context.h(12)),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final narrow = constraints.maxWidth < 480;

                                final phone = RdxTextField(
                                  controller: phoneController,
                                  maxLength: 10,
                                  label: 'Phone Number',
                                  enabled: canEdit
                                );

                                final email = RdxTextField(
                                  controller: emailController,
                                  maxLength: 80,
                                  label: 'Email',
                                  enabled: canEdit
                                );

                                return narrow
                                    ? Column(
                                        children: [
                                          phone,
                                          SizedBox(height: context.h(12)),
                                          email,
                                        ]
                                      )
                                    : Row(
                                        children: [
                                          Expanded(child: phone),
                                          SizedBox(width: context.w(12)),
                                          Expanded(child: email),
                                        ]
                                      );
                              }
                            ),
                          ]
                        )
                      ),
                      SizedBox(height: context.h(4)),
                      if (canEdit)
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: buttonWidth,
                            child: RdxActionButton.save(
                              label: 'Save',
                              minWidth: buttonWidth,
                              isLoading: provider.isLoading,
                              onPressed: provider.isLoading ? null : _save
                            )
                          )
                        ),
                    ]
                  )
                )
              )
            )
          ),
        ]
      )
    );
  }
}

class _ProfileSection extends ConsumerWidget {
  final String title;
  final IconData icon;
  final AppColorScheme colors;
  final Widget child;

  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.colors,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: context.h(14)),
        padding: EdgeInsets.all(context.h(14)),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: context.h(18), color: AppColors.primary),
                SizedBox(width: context.w(8)),
                Text(
                  title,
                  style: AppTextStyles.bodyLargeSemi(context).copyWith(
                    color: colors.textPrimary
                  )
                ),
              ]
            ),
            SizedBox(height: context.h(12)),
            child,
          ]
        )
      );
}
