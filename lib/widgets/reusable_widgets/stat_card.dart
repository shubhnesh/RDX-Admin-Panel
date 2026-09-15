// import 'package:flutter/material.dart';

// import 'package:rdx_admin/core/theme/text_styles.dart';

// import '../../core/theme/app_colors.dart';
// import '../../core/utils/responsive_size.dart';

// class StatCard extends StatelessWidget {
//   final String label;
//   final String value;
//   final IconData icon;

//   /// Color used for the icon and progress indicator.
//   /// Defaults to the application's primary color.
//   final Color? accentColor;

//   /// Optional text shown below the value.
//   final String? subtitle;

//   /// Optional color for the subtitle.
//   /// Falls back to the theme secondary text color.
//   final Color? subtitleColor;

//   /// Optional icon displayed before the subtitle.
//   final IconData? subtitleIcon;

//   /// Optional progress value between 0 and 1.
//   ///
//   /// When provided, a progress indicator is displayed below the value.
//   final double? progress;

//   /// Controls the visual layout of the card.
//   ///
//   /// `true` uses the horizontal layout used by Notifications/Inventory.
//   /// `false` uses the compact dashboard/coupon layout.
//   final bool horizontal;

//   /// Minimum height of the card.
//   ///
//   /// Useful when cards are placed beside each other and need a consistent
//   /// minimum visual height.
//   final double? minHeight;

//   const StatCard({
//     super.key,
//     required this.label,
//     required this.value,
//     required this.icon,
//     this.accentColor,
//     this.subtitle,
//     this.subtitleColor,
//     this.subtitleIcon,
//     this.progress,
//     this.horizontal = false,
//     this.minHeight,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);
//     final color = accentColor ?? AppColors.primary;

//     return Container(
//       constraints: minHeight != null
//           ? BoxConstraints(minHeight: context.h(minHeight!))
//           : null,
//       padding: EdgeInsets.fromLTRB(
//         context.w(18),
//         context.h(16),
//         context.w(16),
//         context.h(15),
//       ),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(
//           horizontal ? context.h(14) : context.h(12),
//         ),
//         border: Border.all(
//           color: colors.border,
//         ),
//         boxShadow: horizontal
//             ? null
//             : [
//                 BoxShadow(
//                   color: Colors.black.withValues(alpha: 0.035),
//                   blurRadius: context.h(10),
//                   offset: Offset(0, context.h(3)),
//                 ),
//               ],
//       ),
//       child: horizontal
//           ? _buildHorizontalContent(
//               context,
//               colors,
//               color,
//             )
//           : _buildCompactContent(
//               context,
//               colors,
//               color,
//             ),
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // HORIZONTAL LAYOUT
//   // Used by Notifications and Inventory.
//   // ---------------------------------------------------------------------------

//   Widget _buildHorizontalContent(
//     BuildContext context,
//     AppColorScheme colors,
//     Color color,
//   ) {
//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 label,
//                 style: AppTextStyles.section(context).copyWith(
//                   color: colors.textMuted,
//                 ),
//               ),
//               SizedBox(height: context.h(6)),
//               Text(
//                 value,
//                 style: AppTextStyles.heading(context),
//               ),
//               if (subtitle != null) ...[
//                 SizedBox(height: context.h(6)),
//                 _buildSubtitle(
//                   context,
//                   colors,
//                 ),
//               ],
//             ],
//           ),
//         ),
//         SizedBox(width: context.w(12)),
//         _buildIconContainer(
//           context,
//           color,
//           size: 42,
//           iconSize: 20,
//           radius: 10,
//         ),
//       ],
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // COMPACT LAYOUT
//   // Used by Dashboard/Coupons where the existing card design is required.
//   // ---------------------------------------------------------------------------

//   Widget _buildCompactContent(
//     BuildContext context,
//     AppColorScheme colors,
//     Color color,
//   ) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: Text(
//                 label,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: AppTextStyles.section(context).copyWith(
//                   color: colors.textMuted,
//                 ),
//               ),
//             ),
//             _buildIconContainer(
//               context,
//               color,
//               size: 36,
//               iconSize: 20,
//               radius: 10,
//             ),
//           ],
//         ),
//         SizedBox(height: context.h(10)),
//         Text(
//           value,
//           style: AppTextStyles.heading(context).copyWith(
//             color: colors.textPrimary,
//           ),
//         ),
//         if (progress != null) ...[
//           SizedBox(height: context.h(11)),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(context.h(5)),
//             child: LinearProgressIndicator(
//               value: progress!.clamp(0.0, 1.0),
//               minHeight: context.h(6),
//               backgroundColor: colors.surfaceVariant,
//               valueColor: AlwaysStoppedAnimation<Color>(color),
//             ),
//           ),
//         ],
//         if (subtitle != null) ...[
//           SizedBox(height: context.h(8)),
//           _buildSubtitle(
//             context,
//             colors,
//           ),
//         ],
//       ],
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // SHARED SUBTITLE
//   // ---------------------------------------------------------------------------

//   Widget _buildSubtitle(
//     BuildContext context,
//     AppColorScheme colors,
//   ) {
//     final color = subtitleColor ?? colors.textSecondary;

//     return Row(
//       children: [
//         if (subtitleIcon != null) ...[
//           Icon(
//             subtitleIcon,
//             size: context.h(14),
//             color: color,
//           ),
//           SizedBox(width: context.w(4)),
//         ],
//         Expanded(
//           child: Text(
//             subtitle!,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: AppTextStyles.label(context).copyWith(
//               color: color,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // SHARED ICON CONTAINER
//   // ---------------------------------------------------------------------------

//   Widget _buildIconContainer(
//     BuildContext context,
//     Color color, {
//     required double size,
//     required double iconSize,
//     required double radius,
//   }) {
//     return Container(
//       width: context.w(size),
//       height: context.h(size),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: 0.14),
//         borderRadius: BorderRadius.circular(context.h(radius)),
//       ),
//       alignment: Alignment.center,
//       child: Icon(
//         icon,
//         color: color,
//         size: context.h(iconSize),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

import 'package:rdx_admin/core/theme/text_styles.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  /// Color used for the icon and progress indicator.
  /// Defaults to the application's primary color.
  final Color? accentColor;

  /// Optional text shown below the value.
  final String? subtitle;

  /// Optional color for the subtitle.
  /// Falls back to the theme secondary text color.
  final Color? subtitleColor;

  /// Optional icon displayed before the subtitle.
  final IconData? subtitleIcon;

  /// Optional progress value between 0 and 1.
  ///
  /// When provided, a progress indicator is displayed below the value.
  final double? progress;

  /// Controls the visual layout of the card.
  ///
  /// `true` uses the horizontal layout used by Notifications/Inventory.
  /// `false` uses the compact dashboard/coupon layout.
  final bool horizontal;

  /// Minimum height of the card.
  ///
  /// Useful when cards are placed beside each other and need a consistent
  /// minimum visual height.
  final double? minHeight;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor,
    this.subtitle,
    this.subtitleColor,
    this.subtitleIcon,
    this.progress,
    this.horizontal = false,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = accentColor ?? AppColors.primary;

    return Container(
      constraints: minHeight != null
          ? BoxConstraints(minHeight: context.h(minHeight!))
          : null,
      padding: EdgeInsets.fromLTRB(
        context.w(18),
        context.h(10), // was 16
        context.w(16),
        context.h(10), // was 15
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(
          horizontal ? context.h(14) : context.h(12),
        ),
        border: Border.all(
          color: colors.border,
        ),
        boxShadow: horizontal
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: context.h(10),
                  offset: Offset(0, context.h(3)),
                ),
              ],
      ),
      child: horizontal
          ? _buildHorizontalContent(
              context,
              colors,
              color,
            )
          : _buildCompactContent(
              context,
              colors,
              color,
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // HORIZONTAL LAYOUT
  // Used by Notifications and Inventory.
  // ---------------------------------------------------------------------------

  Widget _buildHorizontalContent(
    BuildContext context,
    AppColorScheme colors,
    Color color,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTextStyles.section(context).copyWith(
                  color: colors.textMuted,
                ),
              ),
              SizedBox(height: context.h(4)), // was 6
              Text(
                value,
                style: AppTextStyles.heading(context),
              ),
              if (subtitle != null) ...[
                SizedBox(height: context.h(4)), // was 6
                _buildSubtitle(
                  context,
                  colors,
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: context.w(12)),
        _buildIconContainer(
          context,
          color,
          size: 36, // was 42
          iconSize: 18, // was 20
          radius: 9,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // COMPACT LAYOUT
  // Used by Dashboard/Coupons where the existing card design is required.
  // ---------------------------------------------------------------------------

  Widget _buildCompactContent(
    BuildContext context,
    AppColorScheme colors,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.section(context).copyWith(
                  color: colors.textMuted,
                ),
              ),
            ),
            _buildIconContainer(
              context,
              color,
              size: 32, // was 36
              iconSize: 18, // was 20
              radius: 9,
            ),
          ],
        ),
        SizedBox(height: context.h(6)), // was 10
        Text(
          value,
          style: AppTextStyles.heading(context).copyWith(
            color: colors.textPrimary,
          ),
        ),
        if (progress != null) ...[
          SizedBox(height: context.h(8)), // was 11
          ClipRRect(
            borderRadius: BorderRadius.circular(context.h(5)),
            child: LinearProgressIndicator(
              value: progress!.clamp(0.0, 1.0),
              minHeight: context.h(5), // was 6
              backgroundColor: colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
        if (subtitle != null) ...[
          SizedBox(height: context.h(6)), // was 8
          _buildSubtitle(
            context,
            colors,
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED SUBTITLE
  // ---------------------------------------------------------------------------

  Widget _buildSubtitle(
    BuildContext context,
    AppColorScheme colors,
  ) {
    final color = subtitleColor ?? colors.textSecondary;

    return Row(
      children: [
        if (subtitleIcon != null) ...[
          Icon(
            subtitleIcon,
            size: context.h(14),
            color: color,
          ),
          SizedBox(width: context.w(4)),
        ],
        Expanded(
          child: Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label(context).copyWith(
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED ICON CONTAINER
  // ---------------------------------------------------------------------------

  Widget _buildIconContainer(
    BuildContext context,
    Color color, {
    required double size,
    required double iconSize,
    required double radius,
  }) {
    return Container(
      width: context.w(size),
      height: context.h(size),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(context.h(radius)),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: color,
        size: context.h(iconSize),
      ),
    );
  }
}