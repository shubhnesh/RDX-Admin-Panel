import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/resuable_options/rdx_text_field.dart';

/// Dialog for typing a single regionality name (e.g. "Punjabi").
///
/// This dialog does NOT write to Firestore. It just validates and returns
/// the trimmed name via `Navigator.pop`. The caller (the menu item form)
/// is responsible for holding it locally and creating it in
/// `menu_regionalities` — via `RegionalityService.createRegionality` —
/// only once the menu item itself is actually saved, since a regionality
/// only makes sense attached to a dish.
class CreateRegionalityDialog extends StatefulWidget {
  const CreateRegionalityDialog({super.key, this.initialValue});

  final String? initialValue;

  static Future<String?> show(BuildContext context, {String? initialValue}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateRegionalityDialog(initialValue: initialValue),
    );
  }

  @override
  State<CreateRegionalityDialog> createState() =>
      _CreateRegionalityDialogState();
}

class _CreateRegionalityDialogState extends State<CreateRegionalityDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.initialValue ?? '');

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
                  'Add Regionality',
                  style: AppTextStyles.section(context)
                      .copyWith(color: colors.textPrimary),
                ),
                SizedBox(height: context.h(6)),
                Text(
                  'e.g. Punjabi, Indo-Chinese, South Indian. Saved along '
                  'with this item once you submit the form.',
                  style: AppTextStyles.bodyTertiary(context)
                      .copyWith(color: colors.textMuted),
                ),
                SizedBox(height: context.h(16)),
                RdxTextField(
                  controller: _name,
                  label: 'Regionality',
                  hint: 'e.g. Punjabi',
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
