// // // import 'package:flutter/material.dart';
// // // import 'package:rdx_admin/core/theme/text_styles.dart';
// // // import '../core/theme/app_colors.dart';
// // // import '../core/utils/responsive_size.dart';

// // // /// Single form action button for Save / Discard footers.
// // // ///
// // // /// - [isPrimary] `true`  → filled primary (orange), white text — use for **Save**
// // // /// - [isPrimary] `false` → transparent, textPrimary label,
// // // ///   border = textPrimary @ 75% alpha — use for **Discard**
// // // ///
// // // /// Prefer the named constructors; labels default to `"Save"` / `"Discard"`.
// // // class FormActionButton extends StatelessWidget {
// // //   final String label;
// // //   final VoidCallback? onPressed;
// // //   final bool isPrimary;
// // //   final bool isLoading;
// // //   final double? height;
// // //   final double? minWidth;

// // //   const FormActionButton({
// // //     super.key,
// // //     required this.label,
// // //     required this.onPressed,
// // //     this.isPrimary = true,
// // //     this.isLoading = false,
// // //     this.height,
// // //     this.minWidth,
// // //   });

// // //   /// Primary (orange) Save button. Label defaults to `"Save"`.
// // //   const FormActionButton.save({
// // //     super.key,
// // //     this.label = 'Save',
// // //     required this.onPressed,
// // //     this.isLoading = false,
// // //     this.height,
// // //     this.minWidth,
// // //   }) : isPrimary = true;

// // //   /// Secondary Discard button. Label defaults to `"Discard"`.
// // //   const FormActionButton.discard({
// // //     super.key,
// // //     this.label = 'Discard',
// // //     required this.onPressed,
// // //     this.isLoading = false,
// // //     this.height,
// // //     this.minWidth,
// // //   }) : isPrimary = false;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final colors = AppColors.of(context);
// // //     final btnHeight = height ?? context.h(44);

// // //     final child = isLoading
// // //         ? SizedBox(
// // //             height: context.h(18),
// // //             width: context.h(18),
// // //             child: CircularProgressIndicator(
// // //               strokeWidth: 2,
// // //               color: isPrimary ? Colors.white : colors.textPrimary,
// // //             ),
// // //           )
// // //         : Text(
// // //             label,
// // //             maxLines: 1,
// // //             overflow: TextOverflow.ellipsis,
// // //             textAlign: TextAlign.center,
// // //             style: isPrimary
// // //                 ? AppTextStyles.bodySecondary(context)
// // //                     .copyWith(color: Colors.white)
// // //                 : AppTextStyles.bodySecondary(context)
// // //                     .copyWith(color: colors.textSecondary),
// // //           );

// // //     final shape = RoundedRectangleBorder(
// // //       borderRadius: BorderRadius.circular(context.h(8)),
// // //     );

// // //     if (isPrimary) {
// // //       return SizedBox(
// // //         height: btnHeight,
// // //         width: minWidth,
// // //         child: ElevatedButton(
// // //           onPressed: isLoading ? null : onPressed,
// // //           style: ElevatedButton.styleFrom(
// // //             backgroundColor: AppColors.primary,
// // //             foregroundColor: Colors.white,
// // //             disabledBackgroundColor: AppColors.primary.withOpacity(0.55),
// // //             disabledForegroundColor: Colors.white70,
// // //             elevation: 0,
// // //             padding: EdgeInsets.symmetric(horizontal: context.w(16)),
// // //             shape: shape,
// // //             minimumSize: Size(minWidth ?? 0, btnHeight),
// // //             tapTargetSize: MaterialTapTargetSize.shrinkWrap,
// // //           ),
// // //           child: child,
// // //         ),
// // //       );
// // //     }

// // //     // Non-primary: transparent, textPrimary text, textPrimary @ 75% border
// // //     return SizedBox(
// // //       height: btnHeight,
// // //       width: minWidth,
// // //       child: OutlinedButton(
// // //         onPressed: isLoading ? null : onPressed,
// // //         style: OutlinedButton.styleFrom(
// // //           backgroundColor: Colors.transparent,
// // //           foregroundColor: colors.textPrimary,
// // //           side: BorderSide(
// // //             color: colors.textPrimary.withAlpha(75),
// // //             width: 1,
// // //           ),
// // //           elevation: 0,
// // //           padding: EdgeInsets.symmetric(horizontal: context.w(16)),
// // //           shape: shape,
// // //           minimumSize: Size(minWidth ?? 0, btnHeight),
// // //           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
// // //         ),
// // //         child: child,
// // //       ),
// // //     );
// // //   }
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:rdx_admin/core/theme/text_styles.dart';
// // import '../core/theme/app_colors.dart';
// // import '../core/utils/responsive_size.dart';

// // /// Single form action button for Save / Discard footers.
// // ///
// // /// - [isPrimary] `true`  → filled primary (orange), white text — use for **Save**
// // /// - [isPrimary] `false` → transparent, textPrimary label,
// // ///   border = textPrimary @ 75% alpha — use for **Discard**
// // ///
// // /// Prefer the named constructors; labels default to `"Save"` / `"Discard"`.
// // class FormActionButton extends StatelessWidget {
// //   final String label;
// //   final VoidCallback? onPressed;
// //   final bool isPrimary;
// //   final bool isLoading;
// //   final double? height;
// //   final double? minWidth;

// //   const FormActionButton({
// //     super.key,
// //     required this.label,
// //     required this.onPressed,
// //     this.isPrimary = true,
// //     this.isLoading = false,
// //     this.height,
// //     this.minWidth,
// //   });

// //   /// Primary (orange) Save button. Label defaults to `"Save"`.
// //   const FormActionButton.save({
// //     super.key,
// //     this.label = 'Save',
// //     required this.onPressed,
// //     this.isLoading = false,
// //     this.height,
// //     this.minWidth,
// //   }) : isPrimary = true;

// //   /// Secondary Discard button. Label defaults to `"Discard"`.
// //   const FormActionButton.discard({
// //     super.key,
// //     this.label = 'Discard',
// //     required this.onPressed,
// //     this.isLoading = false,
// //     this.height,
// //     this.minWidth,
// //   }) : isPrimary = false;

// //   @override
// //   Widget build(BuildContext context) {
// //     final colors = AppColors.of(context);
// //     final btnHeight = height ?? context.h(44);

// //     final child = isLoading
// //         ? SizedBox(
// //             height: context.h(18),
// //             width: context.h(18),
// //             child: CircularProgressIndicator(
// //               strokeWidth: 2,
// //               color: isPrimary ? Colors.white : colors.textPrimary,
// //             ),
// //           )
// //         : Text(
// //             label,
// //             maxLines: 1,
// //             overflow: TextOverflow.ellipsis,
// //             textAlign: TextAlign.center,
// //             style: isPrimary
// //                 ? AppTextStyles.section(context).copyWith(color: Colors.white)
// //                 : AppTextStyles.section(context)
// //                     .copyWith(color: colors.textPrimary),
// //           );

// //     final shape = RoundedRectangleBorder(
// //       borderRadius: BorderRadius.circular(context.h(8)),
// //     );

// //     if (isPrimary) {
// //       return SizedBox(
// //         height: btnHeight,
// //         width: minWidth,
// //         child: ElevatedButton(
// //           onPressed: isLoading ? null : onPressed,
// //           style: ElevatedButton.styleFrom(
// //             backgroundColor: AppColors.primary,
// //             foregroundColor: Colors.white,
// //             disabledBackgroundColor: AppColors.primary.withOpacity(0.55),
// //             disabledForegroundColor: Colors.white70,
// //             elevation: 0,
// //             padding: EdgeInsets.symmetric(horizontal: context.w(16)),
// //             shape: shape,
// //             minimumSize: Size(minWidth ?? 0, btnHeight),
// //             tapTargetSize: MaterialTapTargetSize.shrinkWrap,
// //           ),
// //           child: child,
// //         ),
// //       );
// //     }

// //     // Non-primary: transparent, textPrimary text, textPrimary @ 75% border
// //     return SizedBox(
// //       height: btnHeight,
// //       width: minWidth,
// //       child: OutlinedButton(
// //         onPressed: isLoading ? null : onPressed,
// //         style: OutlinedButton.styleFrom(
// //           backgroundColor: Colors.transparent,
// //           foregroundColor: colors.textPrimary,
// //           side: BorderSide(
// //             color: colors.textPrimary.withAlpha(75),
// //             width: 1,
// //           ),
// //           elevation: 0,
// //           padding: EdgeInsets.symmetric(horizontal: context.w(16)),
// //           shape: shape,
// //           minimumSize: Size(minWidth ?? 0, btnHeight),
// //           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
// //         ),
// //         child: child,
// //       ),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';

// import 'package:rdx_admin/core/theme/text_styles.dart';

// import '../core/theme/app_colors.dart';
// import '../core/utils/responsive_size.dart';

// /// Single form action button for Save / Discard footers.
// ///
// /// - [isPrimary] `true`  → filled primary (orange), white text — use for **Save**
// /// - [isPrimary] `false` → transparent, textPrimary label,
// ///   border = textPrimary @ 75% alpha — use for **Discard**
// ///
// /// Icons are optional and can be provided by the screen using
// /// [leadingIcon] or [trailingIcon].
// ///
// /// Prefer the named constructors; labels default to `"Save"` / `"Discard"`.
// class FormActionButton extends StatelessWidget {
//   final String label;
//   final VoidCallback? onPressed;
//   final bool isPrimary;
//   final bool isLoading;
//   final double? height;
//   final double? minWidth;

//   // Optional icon chosen by the screen using this widget.
//   final IconData? leadingIcon;
//   final IconData? trailingIcon;
//   final double? iconSize;

//   const FormActionButton({
//     super.key,
//     required this.label,
//     required this.onPressed,
//     this.isPrimary = true,
//     this.isLoading = false,
//     this.height,
//     this.minWidth,
//     this.leadingIcon,
//     this.trailingIcon,
//     this.iconSize,
//   });

//   /// Primary (orange) Save button. Label defaults to `"Save"`.
//   const FormActionButton.save({
//     super.key,
//     this.label = 'Save',
//     required this.onPressed,
//     this.isLoading = false,
//     this.height,
//     this.minWidth,
//     this.leadingIcon,
//     this.trailingIcon,
//     this.iconSize,
//   }) : isPrimary = true;

//   /// Secondary Discard button. Label defaults to `"Discard"`.
//   const FormActionButton.discard({
//     super.key,
//     this.label = 'Discard',
//     required this.onPressed,
//     this.isLoading = false,
//     this.height,
//     this.minWidth,
//     this.leadingIcon,
//     this.trailingIcon,
//     this.iconSize,
//   }) : isPrimary = false;

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);
//     final btnHeight = height ?? context.h(44);

//     final textStyle = isPrimary
//         ? AppTextStyles.section(context).copyWith(
//             color: Colors.white,
//           )
//         : AppTextStyles.section(context).copyWith(
//             color: colors.textPrimary,
//           );

//     final iconColor = isPrimary ? Colors.white : colors.textPrimary;

//     final child = isLoading
//         ? SizedBox(
//             height: context.h(18),
//             width: context.h(18),
//             child: CircularProgressIndicator(
//               strokeWidth: 2,
//               color: isPrimary ? Colors.white : colors.textPrimary,
//             ),
//           )
//         : Row(
//             mainAxisSize: MainAxisSize.min,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               if (leadingIcon != null) ...[
//                 Icon(
//                   leadingIcon,
//                   size: iconSize,
//                   color: iconColor,
//                 ),
//                 const SizedBox(width: 8),
//               ],
//               Flexible(
//                 child: Text(
//                   label,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   textAlign: TextAlign.center,
//                   style: textStyle,
//                 ),
//               ),
//               if (trailingIcon != null) ...[
//                 const SizedBox(width: 8),
//                 Icon(
//                   trailingIcon,
//                   size: context.h(18),
//                   color: iconColor,
//                 ),
//               ],
//             ],
//           );

//     final shape = RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(context.h(8)),
//     );

//     if (isPrimary) {
//       return SizedBox(
//         height: btnHeight,
//         width: minWidth,
//         child: ElevatedButton(
//           onPressed: isLoading ? null : onPressed,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppColors.primary,
//             foregroundColor: Colors.white,
//             disabledBackgroundColor: AppColors.primary.withOpacity(0.55),
//             disabledForegroundColor: Colors.white70,
//             elevation: 0,
//             padding: EdgeInsets.symmetric(
//               horizontal: context.w(16),
//             ),
//             shape: shape,
//             minimumSize: Size(
//               minWidth ?? 0,
//               btnHeight,
//             ),
//             tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//           ),
//           child: child,
//         ),
//       );
//     }

//     // Non-primary: transparent, textPrimary text,
//     // textPrimary @ 75% border
//     return SizedBox(
//       height: btnHeight,
//       width: minWidth,
//       child: OutlinedButton(
//         onPressed: isLoading ? null : onPressed,
//         style: OutlinedButton.styleFrom(
//           backgroundColor: Colors.transparent,
//           foregroundColor: colors.textPrimary,
//           side: BorderSide(
//             color: colors.textPrimary.withAlpha(75),
//             width: 1,
//           ),
//           elevation: 0,
//           padding: EdgeInsets.symmetric(
//             horizontal: context.w(16),
//           ),
//           shape: shape,
//           minimumSize: Size(
//             minWidth ?? 0,
//             btnHeight,
//           ),
//           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//         ),
//         child: child,
//       ),
//     );
//   }
// }

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
