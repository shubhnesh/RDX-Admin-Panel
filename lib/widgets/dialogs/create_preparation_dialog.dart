import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/resuable_options/rdx_text_field.dart';

/// Dialog for typing a single preparation style name (e.g. "Tandoori").
///
/// This dialog does NOT write to Firestore — it just validates and
/// returns the trimmed name via `Navigator.pop`. The caller decides what
/// to do with it:
/// - From the menu item form, the name is held locally and only turned
///   into a real `PreparationService.createPreparation` call once the
///   item itself is saved.
/// - From the manage-taxonomy screen, editing an existing preparation
///   calls `PreparationService.updatePreparation` immediately.
class CreatePreparationDialog extends StatefulWidget {
  const CreatePreparationDialog({super.key, this.initialValue});

  final String? initialValue;

  static Future<String?> show(BuildContext context, {String? initialValue}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreatePreparationDialog(initialValue: initialValue),
    );
  }

  @override
  State<CreatePreparationDialog> createState() =>
      _CreatePreparationDialogState();
}

class _CreatePreparationDialogState extends State<CreatePreparationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.initialValue ?? '');

  bool get _editing => widget.initialValue != null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _name.text.trim());
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.h(12)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.w(380)),
        child: Padding(
          padding: EdgeInsets.all(context.h(20)),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editing ? 'Edit Preparation Style' : 'Add Preparation Style',
                  style: AppTextStyles.section(context)
                      .copyWith(color: colors.textPrimary),
                ),
                SizedBox(height: context.h(6)),
                if (!_editing)
                  Text(
                    'e.g. Tandoori, Gravy, Steam. Saved along with this '
                    'item once you submit the form.',
                    style: AppTextStyles.bodyTertiary(context)
                        .copyWith(color: colors.textMuted),
                  ),
                SizedBox(height: context.h(16)),
                RdxTextField(
                  controller: _name,
                  label: 'Preparation Style',
                  hint: 'e.g. Tandoori',
                  onSubmitted: (_) => _save(),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Required'
                      : null,
                ),
                SizedBox(height: context.h(18)),
                Row(
                  children: [
                    Expanded(
                      child: RdxActionButton.save(onPressed: _save),
                    ),
                    SizedBox(width: context.w(10)),
                    Expanded(
                      child: RdxActionButton.discard(
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
