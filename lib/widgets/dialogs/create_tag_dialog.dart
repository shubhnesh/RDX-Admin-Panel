import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/resuable_options/rdx_text_field.dart';

/// Dialog for typing a single custom tag name.
///
/// Like the other taxonomy dialogs, this one only collects and validates
/// the name — it never calls Firestore itself. Only the 4 fixed built-in
/// tags (Featured, Bestseller, New, Popular) are excluded from being
/// created here; the caller is responsible for enforcing that and the
/// max-4-custom-tags limit via [TagService].
class CreateTagDialog extends StatefulWidget {
  const CreateTagDialog({super.key, this.initialValue});

  final String? initialValue;

  static Future<String?> show(BuildContext context, {String? initialValue}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateTagDialog(initialValue: initialValue),
    );
  }

  @override
  State<CreateTagDialog> createState() => _CreateTagDialogState();
}

class _CreateTagDialogState extends State<CreateTagDialog> {
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
                  _editing ? 'Edit Tag' : 'Create Tag',
                  style: AppTextStyles.section(context)
                      .copyWith(color: colors.textPrimary),
                ),
                SizedBox(height: context.h(6)),
                if (!_editing)
                  Text(
                    'Custom tags are saved right away so they can be '
                    'reused on other items.',
                    style: AppTextStyles.bodyTertiary(context)
                        .copyWith(color: colors.textMuted),
                  ),
                SizedBox(height: context.h(16)),
                RdxTextField(
                  controller: _name,
                  label: 'Tag Name',
                  hint: 'e.g. Chef\'s Special',
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
