import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rdx_admin/core/theme/text_styles.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/resuable_options/rdx_text_field.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/buttons/rdx_toggle_button.dart';
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

  // Operating hours display strings (e.g. "08:00 AM")
  String _weekdaysOpen = '08:00 AM';
  String _weekdaysClose = '11:00 PM';
  String _weekendsOpen = '10:00 AM';
  String _weekendsClose = '02:00 AM';

  Uint8List? _logoBytes;
  String? _logoName;
  bool _isUploadingLogo = false;

  bool _weekdaysOpenFlag = true;
  bool _weekendsOpenFlag = true;

  @override
  void initState() {
    super.initState();

    final settings = ref.read(settingsProvider);

    nameController = TextEditingController(text: settings.restaurantName);
    descriptionController =
        TextEditingController(text: settings.description);
    addressController = TextEditingController(text: settings.address);
    phoneController = TextEditingController(text: settings.phone);
    emailController = TextEditingController(text: settings.email);

    _weekdaysOpen = settings.weekdays.open;
    _weekdaysClose = settings.weekdays.close;
    _weekendsOpen = settings.weekends.open;
    _weekendsClose = settings.weekends.close;
    _weekdaysOpenFlag = settings.weekdays.isOpen;
    _weekendsOpenFlag = settings.weekends.isOpen;
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

  /// Parse "08:00 AM" / "2:00 PM" style strings into TimeOfDay.
  TimeOfDay _parseTime(String text) {
    final cleaned = text.trim().toUpperCase();
    final isPm = cleaned.contains('PM');
    final isAm = cleaned.contains('AM');
    final digits =
        cleaned.replaceAll(RegExp(r'[^0-9:]'), '').split(':');
    if (digits.isEmpty || digits.first.isEmpty) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
    var hour = int.tryParse(digits[0]) ?? 9;
    final minute = digits.length > 1 ? (int.tryParse(digits[1]) ?? 0) : 0;
    if (isPm && hour < 12) hour += 12;
    if (isAm && hour == 12) hour = 0;
    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

  /// Format TimeOfDay as "08:00 AM".
  String _formatTime(TimeOfDay t) {
    final hour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final h = hour12.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  Future<void> _pickTime({
    required String current,
    required ValueChanged<String> onPicked,
  }) async {
    final initial = _parseTime(current);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      onPicked(_formatTime(picked));
    }
  }

  Future<void> _pickLogo() async {
    if (_isUploadingLogo) return;

    setState(() => _isUploadingLogo = true);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (!mounted) return;

      if (result == null || result.files.isEmpty) {
        setState(() => _isUploadingLogo = false);
        return;
      }

      final file = result.files.single;
      const maxSizeInBytes = 2 * 1024 * 1024;

      if (file.size > maxSizeInBytes) {
        setState(() => _isUploadingLogo = false);
        return;
      }

      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        setState(() => _isUploadingLogo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to read the selected image.',
              style: AppTextStyles.bodySecondary(context).copyWith(
                color: Colors.white,
              ),
            ),
          ),
        );
        return;
      }

      setState(() {
        _logoBytes = bytes;
        _logoName = file.name;
        _isUploadingLogo = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUploadingLogo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to select logo. Please try again.',
            style: AppTextStyles.bodySecondary(context).copyWith(
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    final ok = await ref.read(settingsProvider).save(
          name: nameController.text.trim(),
          desc: descriptionController.text.trim(),
          addr: addressController.text.trim(),
          ph: phoneController.text.trim(),
          em: emailController.text.trim(),
          weekdaysHours: OperatingHours(
            open: _weekdaysOpen,
            close: _weekdaysClose,
            isOpen: _weekdaysOpenFlag,
          ),
          weekendsHours: OperatingHours(
            open: _weekendsOpen,
            close: _weekendsClose,
            isOpen: _weekendsOpenFlag,
          ),
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Settings saved' : 'Failed to save settings',
          style: AppTextStyles.bodySecondary(context).copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final provider = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          RdxHeader(
            title: 'Restaurant Profile',
            showBackButton: true,
            actions: [
              RdxActionButton.save(
                isLoading: provider.isLoading,
                onPressed: _save,
              ),
              SizedBox(width: context.w(10)),
              RdxActionButton.discard(
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: Responsive.pagePadding(context, top: 8, bottom: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Brand Identity ──────────────────────────────────
                      _ProfileSection(
                        title: 'Brand Identity',
                        icon: Icons.image_outlined,
                        colors: colors,
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.background,
                                border: Border.all(color: colors.border),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _logoBytes != null
                                  ? Image.memory(
                                      _logoBytes!,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.restaurant,
                                      color: AppColors.primary,
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Brand Identity',
                                    style:
                                        AppTextStyles.bodySecondary(context),
                                  ),
                                  Text(
                                    'Recommended size: 512x512px. Max 2MB.',
                                    style: AppTextStyles.body(context),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton(
                                    onPressed: _pickLogo,
                                    child: _isUploadingLogo
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            _logoBytes != null
                                                ? 'Change Logo'
                                                : 'Upload New',
                                            style: AppTextStyles.section(
                                                    context)
                                                .copyWith(
                                              color: colors.primary,
                                            ),
                                          ),
                                  ),
                                  if (_logoName != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _logoName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.body(context)
                                          .copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Basic Information ───────────────────────────────
                      _ProfileSection(
                        title: 'Basic Information',
                        icon: Icons.description_outlined,
                        colors: colors,
                        child: Column(
                          children: [
                            RdxTextField(
                              controller: nameController,
                              label: 'Restaurant Name',
                            ),
                            const SizedBox(height: 12),
                            RdxTextField(
                              controller: descriptionController,
                              label: 'Brief Description',
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),

                      // ── Location & Contact ──────────────────────────────
                      _ProfileSection(
                        title: 'Location & Contact',
                        icon: Icons.location_on_outlined,
                        colors: colors,
                        child: Column(
                          children: [
                            RdxTextField(
                              controller: addressController,
                              label: 'Primary Address',
                            ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final narrow = constraints.maxWidth < 480;
                                final phone = RdxTextField(
                                  controller: phoneController,
                                  label: 'Support Phone',
                                );
                                final email = RdxTextField(
                                  controller: emailController,
                                  label: 'Support Email',
                                );
                                return narrow
                                    ? Column(
                                        children: [
                                          phone,
                                          const SizedBox(height: 12),
                                          email,
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(child: phone),
                                          const SizedBox(width: 12),
                                          Expanded(child: email),
                                        ],
                                      );
                              },
                            ),
                          ],
                        ),
                      ),

                      // ── Operating Hours (tappable time boxes) ───────────
                      _ProfileSection(
                        title: 'Operating Hours',
                        icon: Icons.access_time_outlined,
                        colors: colors,
                        child: Column(
                          children: [
                            _HoursRow(
                              label: 'Weekdays',
                              openText: _weekdaysOpen,
                              closeText: _weekdaysClose,
                              isOpen: _weekdaysOpenFlag,
                              onChanged: (v) =>
                                  setState(() => _weekdaysOpenFlag = v),
                              onPickOpen: () => _pickTime(
                                current: _weekdaysOpen,
                                onPicked: (t) =>
                                    setState(() => _weekdaysOpen = t),
                              ),
                              onPickClose: () => _pickTime(
                                current: _weekdaysClose,
                                onPicked: (t) =>
                                    setState(() => _weekdaysClose = t),
                              ),
                              colors: colors,
                            ),
                            _HoursRow(
                              label: 'Weekends',
                              openText: _weekendsOpen,
                              closeText: _weekendsClose,
                              isOpen: _weekendsOpenFlag,
                              onChanged: (v) =>
                                  setState(() => _weekendsOpenFlag = v),
                              onPickOpen: () => _pickTime(
                                current: _weekendsOpen,
                                onPicked: (t) =>
                                    setState(() => _weekendsOpen = t),
                              ),
                              onPickClose: () => _pickTime(
                                current: _weekendsClose,
                                onPicked: (t) =>
                                    setState(() => _weekendsClose = t),
                              ),
                              colors: colors,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section card
// ─────────────────────────────────────────────────────────────────────────────
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
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
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
                  style: AppTextStyles.section(context).copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tappable time box (same look as original, opens time picker on tap)
// ─────────────────────────────────────────────────────────────────────────────
class _TimeBox extends StatelessWidget {
  final String text;
  final bool enabled;
  final VoidCallback? onTap;
  final AppColorScheme colors;

  const _TimeBox({
    required this.text,
    required this.enabled,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(5),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.section(context).copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                if (enabled) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: colors.textSecondary.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hours row — same layout as original screenshot, boxes now tappable
// ─────────────────────────────────────────────────────────────────────────────
class _HoursRow extends ConsumerWidget {
  final String label;
  final String openText;
  final String closeText;
  final bool isOpen;
  final ValueChanged<bool> onChanged;
  final VoidCallback onPickOpen;
  final VoidCallback onPickClose;
  final AppColorScheme colors;

  const _HoursRow({
    required this.label,
    required this.openText,
    required this.closeText,
    required this.isOpen,
    required this.onChanged,
    required this.onPickOpen,
    required this.onPickClose,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final narrow = MediaQuery.sizeOf(context).width < 520;

    final times = Row(
      children: [
        Expanded(
          child: _TimeBox(
            text: openText,
            enabled: isOpen,
            onTap: onPickOpen,
            colors: colors,
          ),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: _TimeBox(
            text: closeText,
            enabled: isOpen,
            onTap: onPickClose,
            colors: colors,
          ),
        ),
      ],
    );
    final toggle = RdxToggleButton(value: isOpen, onChanged: onChanged);

    if (narrow) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodySecondary(context)
                        .copyWith(color: colors.textSecondary),
                  ),
                ),
                toggle,
              ],
            ),
            const SizedBox(height: 8),
            times,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodySecondary(context)
                  .copyWith(color: colors.textSecondary),
            ),
          ),
          Expanded(
            child: _TimeBox(
              text: openText,
              enabled: isOpen,
              onTap: onPickOpen,
              colors: colors,
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: _TimeBox(
              text: closeText,
              enabled: isOpen,
              onTap: onPickClose,
              colors: colors,
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(alignment: Alignment.centerRight, child: toggle),
          ),
        ],
      ),
    );
  }
}
