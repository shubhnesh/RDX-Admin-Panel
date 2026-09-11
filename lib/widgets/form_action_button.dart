import 'package:flutter/material.dart';

import 'package:rdx_admin/core/theme/text_styles.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/responsive_size.dart';

/// Single form action button for Save / Discard footers.
///
/// Icons and colors are optional and can be customized by the screen.
class FormActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final double? height;
  final double? minWidth;

  // Optional icons.
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double? iconSize;

  // Optional colors.
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final Color? borderColor;

  // Optional disabled colors.
  final Color? disabledBackgroundColor;
  final Color? disabledTextColor;
  final Color? disabledIconColor;

  const FormActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.height,
    this.minWidth,
    this.leadingIcon,
    this.trailingIcon,
    this.iconSize,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.borderColor,
    this.disabledBackgroundColor,
    this.disabledTextColor,
    this.disabledIconColor,
  });

  const FormActionButton.save({
    super.key,
    this.label = 'Save',
    required this.onPressed,
    this.isLoading = false,
    this.height,
    this.minWidth,
    this.leadingIcon,
    this.trailingIcon,
    this.iconSize,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.borderColor,
    this.disabledBackgroundColor,
    this.disabledTextColor,
    this.disabledIconColor,
  }) : isPrimary = true;

  const FormActionButton.discard({
    super.key,
    this.label = 'Discard',
    required this.onPressed,
    this.isLoading = false,
    this.height,
    this.minWidth,
    this.leadingIcon,
    this.trailingIcon,
    this.iconSize,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.borderColor,
    this.disabledBackgroundColor,
    this.disabledTextColor,
    this.disabledIconColor,
  }) : isPrimary = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final btnHeight = height ?? context.h(44);

    // Default colors preserve the existing behavior.
    final defaultTextColor = isPrimary ? Colors.white : colors.textPrimary;

    final resolvedTextColor = textColor ?? defaultTextColor;

    final resolvedIconColor = iconColor ?? resolvedTextColor;

    final resolvedBackgroundColor =
        backgroundColor ?? (isPrimary ? AppColors.primary : Colors.transparent);

    final resolvedBorderColor = borderColor ??
        (isPrimary ? Colors.transparent : colors.textPrimary.withAlpha(75));

    final resolvedDisabledBackgroundColor = disabledBackgroundColor ??
        (isPrimary ? AppColors.primary.withOpacity(0.55) : Colors.transparent);

    final resolvedDisabledTextColor = disabledTextColor ??
        (isPrimary ? Colors.white70 : colors.textPrimary.withAlpha(120));

    final resolvedDisabledIconColor =
        disabledIconColor ?? resolvedDisabledTextColor;

    final textStyle = AppTextStyles.section(context).copyWith(
      color: isLoading ? resolvedTextColor : resolvedTextColor,
    );

    final child = isLoading
        ? SizedBox(
            height: context.h(18),
            width: context.h(18),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: resolvedIconColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  size: iconSize,
                  color: resolvedIconColor,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: textStyle,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(
                  trailingIcon,
                  size: iconSize,
                  color: resolvedIconColor,
                ),
              ],
            ],
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
            backgroundColor: resolvedBackgroundColor,
            foregroundColor: resolvedTextColor,
            disabledBackgroundColor: resolvedDisabledBackgroundColor,
            disabledForegroundColor: resolvedDisabledTextColor,
            elevation: 0,
            padding: EdgeInsets.symmetric(
              horizontal: context.w(16),
            ),
            shape: shape,
            minimumSize: Size(
              minWidth ?? 0,
              btnHeight,
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      height: btnHeight,
      width: minWidth,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: resolvedBackgroundColor,
          foregroundColor: resolvedTextColor,
          side: BorderSide(
            color: resolvedBorderColor,
            width: 1,
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: context.w(16),
          ),
          shape: shape,
          minimumSize: Size(
            minWidth ?? 0,
            btnHeight,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: child,
      ),
    );
  }
}
