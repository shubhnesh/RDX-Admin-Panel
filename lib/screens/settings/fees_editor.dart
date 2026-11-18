import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/providers/auth_provider.dart';
import 'package:rdx_admin/providers/settings_provider.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_header.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_text_field.dart';

/// Form to edit server-owned order fee configuration.
///
/// These values are the ONLY source of truth for GST, late-night,
/// long-distance, and delivery fees on orders. Cloud Functions read
/// them; the client never sends fee amounts when placing an order.
class FeesEditor extends ConsumerStatefulWidget {
  const FeesEditor({super.key});

  @override
  ConsumerState<FeesEditor> createState() => _FeesEditorState();
}

class _FeesEditorState extends ConsumerState<FeesEditor> {
  late final TextEditingController _gstCtrl;
  late final TextEditingController _lateFeeCtrl;
  late final TextEditingController _lateStartCtrl;
  late final TextEditingController _lateEndCtrl;
  late final TextEditingController _longDistanceCtrl;
  late final TextEditingController _deliveryCtrl;
  late final TextEditingController _freeAboveCtrl;
  bool _saving = false;

  void _log(String message) {
    if (kDebugMode) debugPrint('[FeesEditor] $message');
  }

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _log('Fee editor opened; initializing form from loaded settings.');
    _gstCtrl = TextEditingController(text: _num(s.gstPercent));
    _lateFeeCtrl = TextEditingController(text: _num(s.lateNightFee));
    _lateStartCtrl = TextEditingController(text: s.lateNightStart);
    _lateEndCtrl = TextEditingController(text: s.lateNightEnd);
    _longDistanceCtrl = TextEditingController(text: _num(s.longDistanceFee));
    _deliveryCtrl = TextEditingController(text: _num(s.deliveryFee));
    _freeAboveCtrl = TextEditingController(text: _num(s.freeDeliveryAbove));
  }

  String _num(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _gstCtrl.dispose();
    _lateFeeCtrl.dispose();
    _lateStartCtrl.dispose();
    _lateEndCtrl.dispose();
    _longDistanceCtrl.dispose();
    _deliveryCtrl.dispose();
    _freeAboveCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!ref.read(authProvider).permissions.canEditSettings) return;
    _log('Fee save requested.');
    if (_saving) {
      _log('Fee save ignored; another save is already in progress.');
      return;
    }

    final gst = double.tryParse(_gstCtrl.text.trim());
    final lateFee = double.tryParse(_lateFeeCtrl.text.trim());
    final longDist = double.tryParse(_longDistanceCtrl.text.trim());
    final delivery = double.tryParse(_deliveryCtrl.text.trim());
    final freeAboveText = _freeAboveCtrl.text.trim();
    final freeAbove =
        freeAboveText.isEmpty ? 0.0 : double.tryParse(freeAboveText);
    final start = _lateStartCtrl.text.trim();
    final end = _lateEndCtrl.text.trim();

    if (gst == null || gst < 0 || gst > 100) {
      _log('Fee save stopped: GST validation failed.');
      _snack('GST % must be between 0 and 100.');
      return;
    }
    if (lateFee == null || lateFee < 0) {
      _log('Fee save stopped: late-night fee validation failed.');
      _snack('Late night fee must be a non-negative number.');
      return;
    }
    if (longDist == null || longDist < 0) {
      _log('Fee save stopped: long-distance fee validation failed.');
      _snack('Long distance fee must be a non-negative number.');
      return;
    }
    if (delivery == null || delivery < 0) {
      _log('Fee save stopped: delivery fee validation failed.');
      _snack('Delivery fee must be a non-negative number.');
      return;
    }
    if (freeAbove == null || freeAbove < 0) {
      _log('Fee save stopped: free-delivery threshold validation failed.');
      _snack('Free delivery threshold must be a non-negative number.');
      return;
    }
    if (!_isHhMm(start) || !_isHhMm(end)) {
      _log('Fee save stopped: late-night time validation failed.');
      _snack('Late night times must be HH:MM (24h), e.g. 22:00.');
      return;
    }

    _log('Fee form validated; sending save request to SettingsProvider.');
    setState(() => _saving = true);
    final ok = await ref.read(settingsProvider).saveFees(
          gstPercent: gst,
          lateNightFee: lateFee,
          lateNightStart: start,
          lateNightEnd: end,
          longDistanceFee: longDist,
          deliveryFee: delivery,
          freeDeliveryAbove: freeAbove,
        );
    if (!mounted) {
      _log('Fee save response received after the editor was disposed.');
      return;
    }
    setState(() => _saving = false);
    _log(ok
        ? 'Fee save completed successfully.'
        : 'Fee save failed; SettingsProvider reported an error.');
    if (ok) {
      _snack('Fees saved. Orders will use these amounts from the server.');
      Navigator.of(context).pop();
    } else {
      _snack(
        ref.read(settingsProvider).errorMessage ?? 'Failed to save fees.',
      );
    }
  }

  bool _isHhMm(String value) {
    final m = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(value);
    return m != null;
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(authProvider).permissions.canEditSettings) {
      return const Scaffold(
        body: Center(child: Text('Only admins can edit order fees.')),
      );
    }
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const RdxHeader(
            title: 'Order Fees',
            subtitle: 'Edit fees charges',
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: Responsive.pagePadding(context, top: context.h(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionCard(
                    context,
                    colors: colors,
                    icon: Icons.receipt_long_outlined,
                    title: 'Tax',
                    children: [
                      RdxTextField(
                        controller: _gstCtrl,
                        label: 'GST %',
                        hint: 'e.g. 5',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: context.h(16)),
                  _sectionCard(
                    context,
                    colors: colors,
                    icon: Icons.local_shipping_outlined,
                    title: 'Delivery Fees',
                    children: [
                      RdxTextField(
                        controller: _deliveryCtrl,
                        label: 'Delivery fee (₹)',
                        hint: 'e.g. 0',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                      ),
                      SizedBox(height: context.h(16)),
                      RdxTextField(
                        controller: _freeAboveCtrl,
                        label: 'Free delivery above (₹)',
                        hint: 'e.g. 500',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: context.h(16)),
                  _sectionCard(
                    context,
                    colors: colors,
                    icon: Icons.route_outlined,
                    title: 'Long Distance Fee',
                    children: [
                      RdxTextField(
                        controller: _longDistanceCtrl,
                        label: 'Long distance fee (₹)',
                        hint: 'e.g. 29',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: context.h(16)),
                  _sectionCard(
                    context,
                    colors: colors,
                    icon: Icons.access_time_outlined,
                    title: 'Late Night Delivery',
                    children: [
                      RdxTextField(
                        controller: _lateFeeCtrl,
                        label: 'Late night fee (₹)',
                        hint: 'e.g. 5',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                      ),
                      SizedBox(height: context.h(16)),
                      LayoutBuilder(
                        builder: (context, c) {
                          final stack = c.maxWidth < 420;
                          final start = _LateNightTimeField(
                            label: 'Late night start',
                            value: _lateStartCtrl.text,
                            onChanged: (value) => setState(
                              () => _lateStartCtrl.text = value,
                            ),
                          );
                          final end = _LateNightTimeField(
                            label: 'Late night end',
                            value: _lateEndCtrl.text,
                            onChanged: (value) => setState(
                              () => _lateEndCtrl.text = value,
                            ),
                          );
                          if (stack) {
                            return Column(
                              children: [
                                start,
                                SizedBox(height: context.h(16)),
                                end,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: start),
                              SizedBox(width: context.w(16)),
                              Expanded(child: end),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: context.h(16)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: RdxActionButton.save(
                      label: 'Save fees',
                      minWidth: context.w(140),
                      isLoading: _saving,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required AppColorScheme colors,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.h(20)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(14)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: context.h(18), color: AppColors.primary),
              SizedBox(width: context.w(8)),
              Text(title, style: AppTextStyles.section(context)),
            ],
          ),
          SizedBox(height: context.h(16)),
          ...children,
        ],
      ),
    );
  }
}

class _LateNightTimeField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _LateNightTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final parsed = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(value);
    final displayValue =
        parsed == null ? value : _formatTime(_parseTime(value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySecondary(context)
              .copyWith(color: colors.textSecondary),
        ),
        SizedBox(height: context.h(6)),
        InkWell(
          borderRadius: BorderRadius.circular(context.h(5)),
          onTap: () async {
            final initialTime = parsed == null
                ? const TimeOfDay(hour: 22, minute: 0)
                : _parseTime(value);
            if (kDebugMode) {
              debugPrint(
                '[FeesEditor] $label time picker opened.',
              );
            }
            final selected = await showTimePicker(
              context: context,
              initialTime: initialTime,
            );
            if (selected == null) {
              if (kDebugMode) {
                debugPrint(
                  '[FeesEditor] $label time selection cancelled.',
                );
              }
              return;
            }
            if (kDebugMode) {
              debugPrint(
                '[FeesEditor] $label time selected.',
              );
            }
            onChanged(
              '${selected.hour.toString().padLeft(2, '0')}:'
              '${selected.minute.toString().padLeft(2, '0')}',
            );
          },
          child: Container(
            height: context.h(38),
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(context.h(5)),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              displayValue,
              style: AppTextStyles.section(context)
                  .copyWith(color: colors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
