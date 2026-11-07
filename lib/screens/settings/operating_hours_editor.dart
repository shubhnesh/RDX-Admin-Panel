import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/widgets/buttons/rdx_toggle_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
import '../../providers/settings_provider.dart';

class OperatingHoursEditor extends ConsumerStatefulWidget {
  final bool canEdit;

  const OperatingHoursEditor({super.key, this.canEdit = false});

  @override
  ConsumerState<OperatingHoursEditor> createState() =>
      _OperatingHoursEditorState();
}

class _OperatingHoursEditorState extends ConsumerState<OperatingHoursEditor> {
  late String _weekdaysOpen;
  late String _weekdaysClose;
  late String _weekendsOpen;
  late String _weekendsClose;
  late bool _weekdaysEnabled;
  late bool _weekendsEnabled;
  bool _saving = false;
  Future<void> _saveQueue = Future<void>.value();

  void _log(String message) {
    if (kDebugMode) debugPrint('[OperatingHoursEditor] $message');
  }

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _weekdaysOpen = _to12h(settings.weekdays.open, true);
    _weekdaysClose = _to12h(settings.weekdays.close, false);
    _weekendsOpen = _to12h(settings.weekends.open, true);
    _weekendsClose = _to12h(settings.weekends.close, false);
    _weekdaysEnabled = settings.weekdays.isOpen;
    _weekendsEnabled = settings.weekends.isOpen;
  }

  String _to12h(String value, bool opening) {
    final cleaned = value.trim().toUpperCase();
    final isPm = cleaned.endsWith('PM');
    final isAm = cleaned.endsWith('AM');
    final numeric = isPm || isAm
        ? cleaned.substring(0, cleaned.length - 2).trim()
        : cleaned;
    final parts = numeric.split(':');
    var hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    if (isPm && hour != 12) hour += 12;
    if (isAm && hour == 12) hour = 0;
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final suffix = opening ? 'AM' : 'PM';
    return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $suffix';
  }

  Future<void> _save() {
    final weekdays = OperatingHours(
      open: _weekdaysOpen,
      close: _weekdaysClose,
      isOpen: _weekdaysEnabled,
    );
    final weekends = OperatingHours(
      open: _weekendsOpen,
      close: _weekendsClose,
      isOpen: _weekendsEnabled,
    );

    final save = _saveQueue.then((_) async {
      if (!mounted) return;
      setState(() => _saving = true);
      final ok = await ref.read(settingsProvider).saveOperatingHours(
            weekdaysHours: weekdays,
            weekendsHours: weekends,
          );
      if (!mounted) return;
      setState(() => _saving = false);
      _log(ok
          ? 'Operating-hours save completed.'
          : 'Operating-hours save failed.');
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save operating hours')),
        );
      }
    });
    _saveQueue = save;
    return save;
  }

  void _updateWeekdaysEnabled(bool value) {
    setState(() => _weekdaysEnabled = value);
    unawaited(_save());
  }

  void _updateWeekendsEnabled(bool value) {
    setState(() => _weekendsEnabled = value);
    unawaited(_save());
  }

  void _updateWeekdaysOpen(String value) {
    setState(() => _weekdaysOpen = value);
    unawaited(_save());
  }

  void _updateWeekdaysClose(String value) {
    setState(() => _weekdaysClose = value);
    unawaited(_save());
  }

  void _updateWeekendsOpen(String value) {
    setState(() => _weekendsOpen = value);
    unawaited(_save());
  }

  void _updateWeekendsClose(String value) {
    setState(() => _weekendsClose = value);
    unawaited(_save());
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      children: [
        if (widget.canEdit)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(bottom: context.h(8)),
              child: Text(
                'Turn a schedule off to edit its hours. Changes save automatically.',
                style: AppTextStyles.label(context)
                    .copyWith(color: colors.textSecondary),
              ),
            ),
          ),
        _HoursRow(
          label: 'Weekdays',
          openText: _weekdaysOpen,
          closeText: _weekdaysClose,
          isOpen: _weekdaysEnabled,
          canEdit: widget.canEdit,
          colors: colors,
          onChanged: _updateWeekdaysEnabled,
          onOpenChanged: _updateWeekdaysOpen,
          onCloseChanged: _updateWeekdaysClose,
        ),
        _HoursRow(
          label: 'Weekends',
          openText: _weekendsOpen,
          closeText: _weekendsClose,
          isOpen: _weekendsEnabled,
          canEdit: widget.canEdit,
          colors: colors,
          onChanged: _updateWeekendsEnabled,
          onOpenChanged: _updateWeekendsOpen,
          onCloseChanged: _updateWeekendsClose,
        ),
        if (_saving)
          Padding(
            padding: EdgeInsets.only(top: context.h(8)),
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: context.h(14),
                    height: context.h(14),
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: context.w(8)),
                  Text(
                    'Saving...',
                    style: AppTextStyles.label(context)
                        .copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HHMMInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    if (digits.length >= 2) {
      var hour = int.tryParse(digits.substring(0, 2)) ?? 1;
      if (hour < 1) hour = 1;
      if (hour > 12) hour = 12;
      digits = hour.toString().padLeft(2, '0') + digits.substring(2);
    }
    if (digits.length >= 4) {
      var minute = int.tryParse(digits.substring(2, 4)) ?? 0;
      if (minute > 59) minute = 59;
      digits = digits.substring(0, 2) + minute.toString().padLeft(2, '0');
    }
    final text = digits.length <= 2
        ? digits
        : '${digits.substring(0, 2)}:${digits.substring(2)}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _HoursRow extends StatelessWidget {
  final String label;
  final String openText;
  final String closeText;
  final bool isOpen;
  final bool canEdit;
  final AppColorScheme colors;
  final ValueChanged<bool> onChanged;
  final ValueChanged<String> onOpenChanged;
  final ValueChanged<String> onCloseChanged;

  const _HoursRow({
    required this.label,
    required this.openText,
    required this.closeText,
    required this.isOpen,
    required this.canEdit,
    required this.colors,
    required this.onChanged,
    required this.onOpenChanged,
    required this.onCloseChanged,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    final times = Row(
      children: [
        Expanded(
          child: _ProfileTime(
            text: openText,
            opening: true,
            enabled: canEdit && !isOpen,
            colors: colors,
            onChanged: onOpenChanged,
          ),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: _ProfileTime(
            text: closeText,
            opening: false,
            enabled: canEdit && !isOpen,
            colors: colors,
            onChanged: onCloseChanged,
          ),
        ),
      ],
    );
    final toggle =
        canEdit ? RdxToggleButton(value: isOpen, onChanged: onChanged) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: narrow
          ? Column(
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
                    if (toggle != null) toggle,
                  ],
                ),
                const SizedBox(height: 8),
                times,
              ],
            )
          : Row(
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
                  flex: 3,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: context.w(420)),
                      child: times,
                    ),
                  ),
                ),
                if (toggle != null)
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: toggle,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ProfileTime extends StatefulWidget {
  final String text;
  final bool opening;
  final bool enabled;
  final AppColorScheme colors;
  final ValueChanged<String> onChanged;

  const _ProfileTime({
    required this.text,
    required this.opening,
    required this.enabled,
    required this.colors,
    required this.onChanged,
  });

  @override
  State<_ProfileTime> createState() => _ProfileTimeState();
}

class _ProfileTimeState extends State<_ProfileTime> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text.split(' ').first);
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && _editing) _commit();
  }

  void _commit() {
    final digits = _controller.text.replaceAll(':', '');
    final fallback = widget.text.split(' ').first.replaceAll(':', '');
    final padded = (digits.isEmpty ? fallback : digits).padRight(4, '0');
    var hour = int.tryParse(padded.substring(0, 2)) ?? 1;
    if (hour < 1) hour = 1;
    if (hour > 12) hour = 12;
    final minute = int.tryParse(padded.substring(2, 4)) ?? 0;
    final value =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} ${widget.opening ? 'AM' : 'PM'}';
    _controller.text = value;
    setState(() => _editing = false);
    widget.onChanged(value);
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
    final box = BoxDecoration(
      color: widget.colors.background,
      borderRadius: BorderRadius.circular(context.h(5)),
      border: Border.all(color: widget.colors.border),
    );
    if (_editing) {
      return Container(
        height: context.h(38),
        alignment: Alignment.center,
        decoration: box,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 5,
          inputFormatters: [_HHMMInputFormatter()],
          style: AppTextStyles.section(context)
              .copyWith(color: widget.colors.textPrimary),
          decoration: const InputDecoration(
            isCollapsed: true,
            counterText: '',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onSubmitted: (_) => _commit(),
        ),
      );
    }
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      onTap: widget.enabled
          ? () {
              setState(() => _editing = true);
              _controller.text = widget.text.split(' ').first;
              _controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _controller.text.length,
              );
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _focusNode.requestFocus());
            }
          : null,
      child: Container(
        height: context.h(38),
        alignment: Alignment.center,
        decoration: box,
        child: Text(
          widget.text,
          style: _smallScreenTextStyle(
            context,
            AppTextStyles.section(context),
          ).copyWith(color: widget.colors.textSecondary),
        ),
      ),
    );
  }
}

TextStyle _smallScreenTextStyle(BuildContext context, TextStyle style) {
  if (MediaQuery.sizeOf(context).width >= 600) return style;
  return style.copyWith(fontSize: (style.fontSize ?? 14) + 1.5);
}
