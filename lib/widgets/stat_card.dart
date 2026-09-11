// import 'package:flutter/material.dart';
// import 'package:rdx_admin/core/theme/text_styles.dart';
// import '../core/theme/app_colors.dart';

// class StatCard extends StatelessWidget {
//   final String label;
//   final String value;
//   final IconData icon;
//   final Color? accentColor;
//   final String? subtitle;
//   final Color? subtitleColor;
//   final IconData? subtitleIcon;
//   final double? progress;

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
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);
//     final color = accentColor ?? AppColors.primary;

//     return Container(
//       padding: const EdgeInsets.fromLTRB(18, 16, 18, 15),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: colors.border),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.035),
//             blurRadius: 10,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: Text(
//                   label,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: AppTextStyles.section(context).copyWith(
//                     color: colors.textMuted,
//                   ),
//                 ),
//               ),
//               Container(
//                 width: 36,
//                 height: 36,
//                 decoration: BoxDecoration(
//                   color: color.withValues(alpha: 0.14),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(icon, color: color, size: 20),
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           Text(
//             value,
//             style: AppTextStyles.heading(context).copyWith(
//               color: colors.textPrimary,
//             ),
//           ),
//           if (progress != null) ...[
//             const SizedBox(height: 11),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(5),
//               child: LinearProgressIndicator(
//                 value: progress!.clamp(0, 1),
//                 minHeight: 6,
//                 backgroundColor: colors.surfaceVariant,
//                 valueColor: AlwaysStoppedAnimation(color),
//               ),
//             ),
//           ],
//           if (subtitle != null) ...[
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 if (subtitleIcon != null) ...[
//                   Icon(
//                     subtitleIcon,
//                     size: 14,
//                     color: subtitleColor ?? colors.textSecondary,
//                   ),
//                   const SizedBox(width: 4),
//                 ],
//                 Expanded(
//                   child: Text(
//                     subtitle!,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: AppTextStyles.label(context).copyWith(
//                       color: subtitleColor ?? colors.textSecondary,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

import 'package:rdx_admin/core/theme/text_styles.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/responsive_size.dart';

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
      constraints:
          minHeight != null ? BoxConstraints(minHeight: minHeight!) : null,
      padding: horizontal
          ? EdgeInsets.fromLTRB(
              context.w(18),
              context.h(16),
              context.w(16),
              context.h(15),
            )
          : const EdgeInsets.fromLTRB(18, 16, 18, 15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(
          horizontal ? context.h(14) : 12,
        ),
        border: Border.all(
          color: colors.border,
        ),
        boxShadow: horizontal
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
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
              SizedBox(height: context.h(6)),
              Text(
                value,
                style: AppTextStyles.heading(context),
              ),
              if (subtitle != null) ...[
                SizedBox(height: context.h(6)),
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
          size: 42,
          iconSize: 20,
          radius: 10,
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
              size: 36,
              iconSize: 20,
              radius: 10,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: AppTextStyles.heading(context).copyWith(
            color: colors.textPrimary,
          ),
        ),
        if (progress != null) ...[
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress!.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 8),
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
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
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
      width: horizontal ? context.w(size) : size,
      height: horizontal ? context.h(size) : size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(
          horizontal ? context.h(radius) : radius,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: color,
        size: horizontal ? context.h(iconSize) : iconSize,
      ),
    );
  }
}
