import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rdx_admin/core/theme/text_styles.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/resuable_options/rdx_text_field.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/buttons/rdx_toggle_button.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';

/// Auto-inserts ":" after two digits are typed, and blocks anything
/// that isn't a digit or that colon. Produces "HH:mm" as the user types.
class _HHMMInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip everything except digits.
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Max 4 digits: HH + mm.
    if (digits.length > 4) {
      digits = digits.substring(0, 4);
    }

    // Clamp hour part as soon as we have 2 digits for it.
    if (digits.length >= 2) {
      var hour = int.parse(digits.substring(0, 2));
      if (hour > 23) hour = 23;
      digits = hour.toString().padLeft(2, '0') + digits.substring(2);
    }

    // Clamp minute part once fully typed.
    if (digits.length >= 4) {
      var minute = int.parse(digits.substring(2, 4));
      if (minute > 59) minute = 59;
      digits = digits.substring(0, 2) + minute.toString().padLeft(2, '0');
    }

    String formatted;
    if (digits.length <= 2) {
      formatted = digits;
    } else {
      formatted = '${digits.substring(0, 2)}:${digits.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

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

  Uint8List? _logoBytes;
  String? _logoName;
  bool _isUploadingLogo = false;

  // ── Operating hours state (24h "HH:mm") ─────────────────────────────
  bool _weekdaysOpenFlag = true;
  bool _weekendsOpenFlag = true;

  late String _weekdaysOpenTime;
  late String _weekdaysCloseTime;
  late String _weekendsOpenTime;
  late String _weekendsCloseTime;

  @override
  void initState() {
    super.initState();

    final settings = ref.read(settingsProvider);

    nameController = TextEditingController(text: settings.restaurantName);
    descriptionController = TextEditingController(text: settings.description);
    addressController = TextEditingController(text: settings.address);
    phoneController = TextEditingController(text: settings.phone);
    emailController = TextEditingController(text: settings.email);

    _weekdaysOpenFlag = settings.weekdays.isOpen;
    _weekendsOpenFlag = settings.weekends.isOpen;
    _weekdaysOpenTime = _to24h(settings.weekdays.open);
    _weekdaysCloseTime = _to24h(settings.weekdays.close);
    _weekendsOpenTime = _to24h(settings.weekends.open);
    _weekendsCloseTime = _to24h(settings.weekends.close);
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

  /// Converts a stored value ("08:00 AM" or "20:00") into 24h "HH:mm".
  String _to24h(String value) {
    final cleaned = value.trim().toUpperCase();
    final isPm = cleaned.endsWith('PM');
    final isAm = cleaned.endsWith('AM');
    if (!isPm && !isAm) return cleaned; // already 24h-ish
    final numeric = cleaned.substring(0, cleaned.length - 2).trim();
    final parts = numeric.split(':');
    var hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    if (isPm && hour != 12) hour += 12;
    if (isAm && hour == 12) hour = 0;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickLogo() async {
    if (_isUploadingLogo) return;

    setState(() {
      _isUploadingLogo = true;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (!mounted) return;

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isUploadingLogo = false;
        });
        return;
      }

      final file = result.files.single;
      const maxSizeInBytes = 2 * 1024 * 1024;

      if (file.size > maxSizeInBytes) {
        setState(() {
          _isUploadingLogo = false;
        });
        return;
      }

      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        setState(() {
          _isUploadingLogo = false;
        });

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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingLogo = false;
      });

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
          name: nameController.text,
          desc: descriptionController.text,
          addr: addressController.text,
          ph: phoneController.text,
          em: emailController.text,
          weekdaysHours: OperatingHours(
            open: _weekdaysOpenTime,
            close: _weekdaysCloseTime,
            isOpen: _weekdaysOpenFlag,
          ),
          weekendsHours: OperatingHours(
            open: _weekendsOpenTime,
            close: _weekendsCloseTime,
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
                                border: Border.all(
                                  color: colors.border,
                                ),
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
                                    style: AppTextStyles.bodySecondary(context),
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
                                            style:
                                                AppTextStyles.section(context)
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
                                      style:
                                          AppTextStyles.body(context).copyWith(
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
                            ),
                            const SizedBox(height: 12),
                            RdxTextField(
                              controller: descriptionController,
                              maxLength: 50,
                              label: 'Brief Description',
                              maxLines: 3,
                            ),
                          ],
                        ),
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
                            ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final narrow = constraints.maxWidth < 480;

                                final phone = RdxTextField(
                                  controller: phoneController,
                                  maxLength: 15,
                                  label: 'Support Phone',
                                );

                                final email = RdxTextField(
                                  controller: emailController,
                                  maxLength: 80,
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
                      _ProfileSection(
                        title: 'Operating Hours',
                        icon: Icons.access_time_outlined,
                        colors: colors,
                        child: Column(
                          children: [
                            _HoursRow(
                              label: 'Weekdays',
                              openText: _weekdaysOpenTime,
                              closeText: _weekdaysCloseTime,
                              isOpen: _weekdaysOpenFlag,
                              onChanged: (value) =>
                                  setState(() => _weekdaysOpenFlag = value),
                              onOpenChanged: (v) =>
                                  setState(() => _weekdaysOpenTime = v),
                              onCloseChanged: (v) =>
                                  setState(() => _weekdaysCloseTime = v),
                              colors: colors,
                            ),
                            _HoursRow(
                              label: 'Weekends',
                              openText: _weekendsOpenTime,
                              closeText: _weekendsCloseTime,
                              isOpen: _weekendsOpenFlag,
                              onChanged: (value) =>
                                  setState(() => _weekendsOpenFlag = value),
                              onOpenChanged: (v) =>
                                  setState(() => _weekendsOpenTime = v),
                              onCloseChanged: (v) =>
                                  setState(() => _weekendsCloseTime = v),
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

/// Tap to edit inline: shows plain text until tapped, then becomes
/// a masked "HH:mm" text field. Commits on submit or on losing focus.
class _ProfileTime extends StatefulWidget {
  final String text;
  final AppColorScheme colors;
  final ValueChanged<String>? onChanged;

  const _ProfileTime({
    required this.text,
    required this.colors,
    this.onChanged,
  });

  @override
  State<_ProfileTime> createState() => _ProfileTimeState();
}

class _ProfileTimeState extends State<_ProfileTime> {
  bool _editing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _ProfileTime oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && widget.text != oldWidget.text) {
      _controller.text = widget.text;
    }
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && _editing) {
      _commit();
    }
  }

  void _commit() {
    var value = _controller.text;
    final digits = value.replaceAll(':', '');
    if (digits.isEmpty) {
      value = widget.text;
    } else {
      final padded = digits.padRight(4, '0');
      value = '${padded.substring(0, 2)}:${padded.substring(2, 4)}';
    }
    _controller.text = value;
    setState(() => _editing = false);
    if (widget.onChanged != null) widget.onChanged!(value);
  }

  void _startEditing() {
    if (widget.onChanged == null) return;
    setState(() => _editing = true);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    // Single shared box decoration so editing vs. non-editing look identical,
    // with exactly one border drawn — never the TextField's own.
    final box = BoxDecoration(
      color: colors.background,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(
        color: _editing ? colors.primary : colors.border,
      ),
    );

    if (_editing) {
      return Container(
        height: 38,
        alignment: Alignment.center,
        decoration: box,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 5,
          inputFormatters: [_HHMMInputFormatter()],
          style: AppTextStyles.section(context).copyWith(
            color: colors.textPrimary,
          ),
          cursorColor: colors.primary,
          decoration: const InputDecoration(
            isCollapsed: true,
            counterText: '',
            filled: false,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
          ),
          onSubmitted: (_) => _commit(),
        ),
      );
    }

    return InkWell(
      onTap: _startEditing,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: box,
        child: Text(
          widget.text,
          style: AppTextStyles.section(context).copyWith(
            color: colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  final String label;
  final String openText;
  final String closeText;
  final bool isOpen;
  final ValueChanged<bool> onChanged;
  final ValueChanged<String> onOpenChanged;
  final ValueChanged<String> onCloseChanged;
  final AppColorScheme colors;

  const _HoursRow({
    required this.label,
    required this.openText,
    required this.closeText,
    required this.isOpen,
    required this.onChanged,
    required this.onOpenChanged,
    required this.onCloseChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    final times = Row(
      children: [
        Expanded(
          child: _ProfileTime(
            text: openText,
            colors: colors,
            onChanged: onOpenChanged,
          ),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: _ProfileTime(
            text: closeText,
            colors: colors,
            onChanged: onCloseChanged,
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
            child: _ProfileTime(
              text: openText,
              colors: colors,
              onChanged: onOpenChanged,
            ),
          ),
          SizedBox(width: context.w(12)),
          Expanded(
            child: _ProfileTime(
              text: closeText,
              colors: colors,
              onChanged: onCloseChanged,
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
