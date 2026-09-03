import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/rdx_header.dart';

/// Settings Suite — Restaurant Profile, contact, operating hours.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController addressController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;

  final Map<String, bool> _dayOpen = {
    'Monday': true,
    'Tuesday': true,
    'Wednesday': true,
    'Thursday': true,
    'Friday': true,
    'Saturday': true,
    'Sunday': false,
  };
  final Map<String, String> _openTime = {
    for (final d in [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ])
      d: '09:00',
  };
  final Map<String, String> _closeTime = {
    for (final d in [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ])
      d: '22:00',
  };

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
    final provider = context.read<SettingsProvider>();
    final ok = await provider.save(
      name: nameController.text,
      desc: descriptionController.text,
      addr: addressController.text,
      ph: phoneController.text,
      em: emailController.text,
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: RdxHeader(
        title: 'Settings Suite',
        actions: [
          ElevatedButton(
            onPressed: provider.isLoading ? null : _save,
            child: provider.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Changes'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: Responsive.pagePadding(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(colors, 'Restaurant Profile'),
              const SizedBox(height: 12),
              _buildProfileCard(colors),
              const SizedBox(height: 28),
              _sectionTitle(colors, 'Basic Information'),
              const SizedBox(height: 12),
              _buildBasicInfo(colors),
              const SizedBox(height: 28),
              _sectionTitle(colors, 'Location & Contact'),
              const SizedBox(height: 12),
              _buildLocationContact(colors),
              const SizedBox(height: 28),
              _sectionTitle(colors, 'Operating Hours'),
              const SizedBox(height: 12),
              _buildOperatingHours(colors),
              const SizedBox(height: 28),
              _sectionTitle(colors, 'Operational Rules'),
              const SizedBox(height: 12),
              _buildOperationalRules(provider, colors),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(AppColorScheme colors, String title) {
    return Text(
      title,
      style: TextStyle(
        color: colors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildProfileCard(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: const Icon(Icons.restaurant,
                size: 32, color: AppColors.primary),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameController.text.isEmpty
                      ? 'Restaurant Name'
                      : nameController.text,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload a square logo for best results (min 256×256)',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logo upload coming soon')),
                    );
                  },
                  icon: const Icon(Icons.upload_outlined, size: 16),
                  label: const Text('Change Logo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          CustomTextField(controller: nameController, label: 'Restaurant Name'),
          const SizedBox(height: 16),
          CustomTextField(
            controller: descriptionController,
            label: 'Description',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationContact(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          CustomTextField(controller: addressController, label: 'Address'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 480) {
                return Column(
                  children: [
                    CustomTextField(
                        controller: phoneController, label: 'Phone'),
                    const SizedBox(height: 16),
                    CustomTextField(
                        controller: emailController, label: 'Email'),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                      child: CustomTextField(
                          controller: phoneController, label: 'Phone')),
                  const SizedBox(width: 16),
                  Expanded(
                      child: CustomTextField(
                          controller: emailController, label: 'Email')),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOperatingHours(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: _dayOpen.keys.map((day) {
          final isOpen = _dayOpen[day]!;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    day,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch(
                  value: isOpen,
                  onChanged: (v) => setState(() => _dayOpen[day] = v),
                ),
                const SizedBox(width: 8),
                if (isOpen) ...[
                  _timeChip(colors, _openTime[day]!,
                      (t) => setState(() => _openTime[day] = t)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('–', style: TextStyle(color: colors.textMuted)),
                  ),
                  _timeChip(colors, _closeTime[day]!,
                      (t) => setState(() => _closeTime[day] = t)),
                ] else
                  Text(
                    'Closed',
                    style: TextStyle(color: colors.textMuted, fontSize: 13),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _timeChip(
      AppColorScheme colors, String time, ValueChanged<String> onChanged) {
    return InkWell(
      onTap: () async {
        final parts = time.split(':');
        final initial = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
        );
        final picked =
            await showTimePicker(context: context, initialTime: initial);
        if (picked != null) {
          final h = picked.hour.toString().padLeft(2, '0');
          final m = picked.minute.toString().padLeft(2, '0');
          onChanged('$h:$m');
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          time,
          style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildOperationalRules(
      SettingsProvider provider, AppColorScheme colors) {
    return Column(
      children: [
        _switchTile(
          colors,
          title: 'Auto-Accept Orders',
          subtitle: 'Automatically accept new orders without manual review',
          value: provider.autoAcceptOrders,
          onChanged: provider.toggleAutoAccept,
        ),
        _switchTile(
          colors,
          title: 'Require Manager Approval for Refunds',
          subtitle: 'Refunds above ₹500 require manager sign-off',
          value: provider.requireManagerApprovalForRefunds,
          onChanged: provider.toggleManagerApproval,
        ),
        _switchTile(
          colors,
          title: 'Keep Pricing Consistent',
          subtitle: 'Sync in-app pricing with delivery partner pricing',
          value: provider.keepPricingConsistent,
          onChanged: provider.toggleKeepPricing,
        ),
      ],
    );
  }

  Widget _switchTile(
    AppColorScheme colors, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
