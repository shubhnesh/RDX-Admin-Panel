import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';

/// Simple notice / validation dialog with a title, message, and OK action.
///
/// Prefer [RdxNoticeDialog.show] so callers don't need to build the widget.
class RdxNoticeDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonLabel;

  const RdxNoticeDialog({
    super.key,
    this.title = 'Notice',
    required this.message,
    this.buttonLabel = 'OK',
  });

  /// Shows a notice dialog and completes when the user dismisses it.
  static Future<void> show(
    BuildContext context, {
    String title = 'Notice',
    required String message,
    String buttonLabel = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => RdxNoticeDialog(
        title: title,
        message: message,
        buttonLabel: buttonLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text(
        title,
        style: AppTextStyles.section(context).copyWith(
          color: colors.textPrimary,
        ),
      ),
      content: Text(
        message,
        style: AppTextStyles.body(context).copyWith(
          color: colors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            buttonLabel,
            style: AppTextStyles.label(context).copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
