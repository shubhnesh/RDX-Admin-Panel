import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive_size.dart';

/// Single form action button for Save / Discard footers.
///
/// - [isPrimary] `true`  → filled primary (orange), white text — use for **Save**
/// - [isPrimary] `false` → transparent, textPrimary label,
///   border = textPrimary @ 75% alpha — use for **Discard**
///
/// Prefer the named constructors; labels default to `"Save"` / `"Discard"`.
class FormActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final double? height;
  final double? minWidth;

  const FormActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.height,
    this.minWidth,
  });

  /// Primary (orange) Save button. Label defaults to `"Save"`.
  const FormActionButton.save({
    super.key,
    this.label = 'Save',
    required this.onPressed,
    this.isLoading = false,
    this.height,
    this.minWidth,
  }) : isPrimary = true;

  /// Secondary Discard button. Label defaults to `"Discard"`.
  const FormActionButton.discard({
    super.key,
    this.label = 'Discard',
    required this.onPressed,
    this.isLoading = false,
    this.height,
    this.minWidth,
  }) : isPrimary = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final btnHeight = height ?? context.h(44);

    final child = isLoading
        ? SizedBox(
            height: context.h(18),
            width: context.h(18),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isPrimary ? Colors.white : colors.textPrimary,
            ),
          )
        : Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            // style: TextStyle(
            //   fontSize: context.h(13),
            //   fontWeight: FontWeight.w600,
            // ),
            style: isPrimary
                ? AppTextStyles.label(context).copyWith(color: Colors.white)
                : AppTextStyles.label(context)
                    .copyWith(color: colors.textPrimary),
          );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(context.h(8)),
    );

    if (isPrimary) {
      return SizedBox(
        height: btnHeight,
        width: minWidth,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.55),
            disabledForegroundColor: Colors.white70,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: context.w(16)),
            shape: shape,
            minimumSize: Size(minWidth ?? 0, btnHeight),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: child,
        ),
      );
    }

    // Non-primary: transparent, textPrimary text, textPrimary @ 75% border
    return SizedBox(
      height: btnHeight,
      width: minWidth,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: colors.textPrimary,
          side: BorderSide(
            color: colors.textPrimary.withAlpha(75),
            width: 1,
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: context.w(16)),
          shape: shape,
          minimumSize: Size(minWidth ?? 0, btnHeight),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: child,
      ),
    );
  }
}
