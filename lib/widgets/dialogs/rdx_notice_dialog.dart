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
  final String? cancelButtonLabel;
  final String? confirmButtonLabel;
  final Color? confirmButtonColor;

  const RdxNoticeDialog({
    super.key,
    this.title = 'Notice',
    required this.message,
    this.buttonLabel = 'OK',
    this.cancelButtonLabel,
    this.confirmButtonLabel,
    this.confirmButtonColor,
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

  /// Shows a confirmation dialog and returns true only when confirmed.
  static Future<bool?> showConfirmation(
    BuildContext context, {
    String title = 'Confirm',
    required String message,
    String cancelButtonLabel = 'Cancel',
    String confirmButtonLabel = 'Confirm',
    Color? confirmButtonColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => RdxNoticeDialog(
        title: title,
        message: message,
        cancelButtonLabel: cancelButtonLabel,
        confirmButtonLabel: confirmButtonLabel,
        confirmButtonColor: confirmButtonColor,
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
        if (confirmButtonLabel != null) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelButtonLabel ?? 'Cancel',
              style: AppTextStyles.label(context).copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmButtonLabel!,
              style: AppTextStyles.label(context).copyWith(
                color: confirmButtonColor ?? AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ] else
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
