// import 'package:flutter/material.dart';
// import '../core/theme/app_colors.dart';
// import '../core/theme/text_styles.dart';

// /// Represents one action that can be displayed inside [RdxActionMenuDialog].
// ///
// /// Everything is configurable:
// /// - icon
// /// - title
// /// - optional subtitle
// /// - icon color
// /// - text color
// /// - background color
// /// - callback
// /// - enabled/disabled state
// class RdxActionMenuItem {
//   final IconData icon;
//   final String title;
//   final String? subtitle;

//   final Color? iconColor;
//   final Color? textColor;
//   final Color? backgroundColor;

//   final VoidCallback? onTap;
//   final bool enabled;

//   const RdxActionMenuItem({
//     required this.icon,
//     required this.title,
//     this.subtitle,
//     this.iconColor,
//     this.textColor,
//     this.backgroundColor,
//     this.onTap,
//     this.enabled = true,
//   });
// }

// /// Reusable dialog for displaying a list of actions.
// ///
// /// The dialog contains no hardcoded business actions.
// /// Pass whatever actions are required by the screen.
// class RdxActionMenuDialog extends StatelessWidget {
//   final String title;
//   final String? subtitle;
//   final List<RdxActionMenuItem> items;

//   final double? width;
//   final EdgeInsetsGeometry? contentPadding;
//   final bool showCloseButton;

//   const RdxActionMenuDialog({
//     super.key,
//     required this.title,
//     required this.items,
//     this.subtitle,
//     this.width,
//     this.contentPadding,
//     this.showCloseButton = true,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);

//     return Dialog(
//       backgroundColor: colors.surface,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(14),
//         side: BorderSide(color: colors.border),
//       ),
//       child: ConstrainedBox(
//         constraints: BoxConstraints(
//           maxWidth: width ?? 360,
//         ),
//         child: Padding(
//           padding: contentPadding ??
//               const EdgeInsets.fromLTRB(
//                 20,
//                 18,
//                 20,
//                 12,
//               ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           title,
//                           style: AppTextStyles.heading(context).copyWith(
//                             fontSize: 18,
//                           ),
//                         ),
//                         if (subtitle != null) ...[
//                           const SizedBox(height: 4),
//                           Text(
//                             subtitle!,
//                             style: AppTextStyles.bodySecondary(context),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),
//                   if (showCloseButton)
//                     IconButton(
//                       onPressed: () => Navigator.of(context).pop(),
//                       icon: Icon(
//                         Icons.close_rounded,
//                         color: colors.textMuted,
//                         size: 20,
//                       ),
//                       tooltip: 'Close',
//                       splashRadius: 20,
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Divider(
//                 height: 1,
//                 color: colors.divider,
//               ),
//               const SizedBox(height: 8),
//               Flexible(
//                 child: ListView.separated(
//                   shrinkWrap: true,
//                   itemCount: items.length,
//                   separatorBuilder: (_, __) => const SizedBox(height: 4),
//                   itemBuilder: (context, index) {
//                     final item = items[index];

//                     return _RdxActionMenuTile(
//                       item: item,
//                       onSelected: () {
//                         if (!item.enabled || item.onTap == null) {
//                           return;
//                         }

//                         // Close the action menu first.
//                         Navigator.of(context).pop();

//                         // Execute the actual action after the dialog closes.
//                         item.onTap!();
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _RdxActionMenuTile extends StatelessWidget {
//   final RdxActionMenuItem item;
//   final VoidCallback onSelected;

//   const _RdxActionMenuTile({
//     required this.item,
//     required this.onSelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);

//     final isEnabled = item.enabled && item.onTap != null;

//     final iconColor =
//         item.iconColor ?? (isEnabled ? colors.textSecondary : colors.textMuted);

//     final textColor =
//         item.textColor ?? (isEnabled ? colors.textPrimary : colors.textMuted);

//     final backgroundColor = item.backgroundColor ?? Colors.transparent;

//     return Material(
//       color: backgroundColor,
//       borderRadius: BorderRadius.circular(8),
//       child: InkWell(
//         onTap: isEnabled ? onSelected : null,
//         borderRadius: BorderRadius.circular(8),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(
//             horizontal: 10,
//             vertical: 10,
//           ),
//           child: Row(
//             children: [
//               Icon(
//                 item.icon,
//                 size: 19,
//                 color: iconColor,
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       item.title,
//                       style: AppTextStyles.bodySecondary(context).copyWith(
//                         color: textColor,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     if (item.subtitle != null) ...[
//                       const SizedBox(height: 2),
//                       Text(
//                         item.subtitle!,
//                         style: AppTextStyles.label(context).copyWith(
//                           color: colors.textMuted,
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//               Icon(
//                 Icons.chevron_right_rounded,
//                 size: 18,
//                 color: colors.textMuted,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';

// import '../../core/theme/app_colors.dart';
// import '../../core/theme/text_styles.dart';

// class RdxActionMenuItem {
//   final IconData? icon;
//   final String? title;
//   final String? subtitle;

//   final Color? iconColor;
//   final Color? textColor;
//   final Color? backgroundColor;

//   final VoidCallback? onTap;
//   final bool enabled;

//   const RdxActionMenuItem({
//     this.icon,
//     this.title,
//     this.subtitle,
//     this.iconColor,
//     this.textColor,
//     this.backgroundColor,
//     this.onTap,
//     this.enabled = true,
//   });
// }

// class RdxActionMenuDialog extends StatelessWidget {
//   final List<RdxActionMenuItem> items;

//   /// Optional title.
//   /// If null, no title is shown.
//   final String? title;

//   /// Optional subtitle.
//   /// If null, no subtitle is shown.
//   final String? subtitle;

//   /// Bottom-right global position of the widget
//   /// that opened this menu.
//   final Offset? position;

//   /// Optional maximum width.
//   ///
//   /// The actual popup width remains content-driven.
//   final double? maxWidth;

//   /// Optional maximum height.
//   final double? maxHeight;

//   final EdgeInsetsGeometry contentPadding;
//   final EdgeInsetsGeometry itemPadding;

//   final bool showCloseButton;
//   final bool showDivider;

//   final Color? backgroundColor;
//   final Color? barrierColor;

//   final double borderRadius;
//   final double elevation;

//   const RdxActionMenuDialog({
//     super.key,
//     required this.items,
//     this.title,
//     this.subtitle,
//     this.position,
//     this.maxWidth,
//     this.maxHeight,
//     this.contentPadding = const EdgeInsets.all(5),
//     this.itemPadding = const EdgeInsets.symmetric(
//       horizontal: 12,
//       vertical: 10,
//     ),
//     this.showCloseButton = false,
//     this.showDivider = false,
//     this.backgroundColor,
//     this.barrierColor = Colors.transparent,
//     this.borderRadius = 9,
//     this.elevation = 8,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);

//     final menu = IntrinsicWidth(
//       child: ConstrainedBox(
//         constraints: BoxConstraints(
//           maxWidth: maxWidth ?? MediaQuery.sizeOf(context).width * 0.9,
//           maxHeight: maxHeight ?? MediaQuery.sizeOf(context).height * 0.7,
//         ),
//         child: Material(
//           color: backgroundColor ?? colors.surface,
//           elevation: elevation,
//           shadowColor: Colors.black26,
//           borderRadius: BorderRadius.circular(borderRadius),
//           clipBehavior: Clip.antiAlias,
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: contentPadding,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   if (title != null || subtitle != null || showCloseButton)
//                     _buildHeader(context),
//                   if ((title != null || subtitle != null || showCloseButton) &&
//                       showDivider)
//                     Divider(
//                       height: 1,
//                       color: colors.divider,
//                     ),
//                   ..._buildItems(context),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );

//     if (position == null) {
//       return Center(
//         child: menu,
//       );
//     }

//     return CustomSingleChildLayout(
//       delegate: _RdxActionMenuPositionDelegate(
//         position: position!,
//         screenSize: MediaQuery.sizeOf(context),
//         margin: 8,
//         gap: 4,
//       ),
//       child: menu,
//     );
//   }

//   Widget _buildHeader(BuildContext context) {
//     final colors = AppColors.of(context);

//     return Padding(
//       padding: const EdgeInsets.fromLTRB(
//         7,
//         5,
//         4,
//         5,
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (title != null || subtitle != null)
//             Flexible(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (title != null)
//                     Text(
//                       title!,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: AppTextStyles.section(context),
//                     ),
//                   if (subtitle != null) ...[
//                     const SizedBox(height: 2),
//                     Text(
//                       subtitle!,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: AppTextStyles.label(context).copyWith(
//                         color: colors.textMuted,
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           if (showCloseButton) ...[
//             const SizedBox(width: 8),
//             InkWell(
//               onTap: () => Navigator.of(context).pop(),
//               borderRadius: BorderRadius.circular(6),
//               child: const SizedBox(
//                 width: 28,
//                 height: 28,
//                 child: Icon(
//                   Icons.close,
//                   size: 18,
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   List<Widget> _buildItems(BuildContext context) {
//     final widgets = <Widget>[];

//     for (int index = 0; index < items.length; index++) {
//       final item = items[index];

//       widgets.add(
//         _RdxActionMenuTile(
//           item: item,
//           padding: itemPadding,
//           onTap: () {
//             if (!item.enabled) return;

//             Navigator.of(context).pop();

//             item.onTap?.call();
//           },
//         ),
//       );

//       if (showDivider && index < items.length - 1) {
//         widgets.add(
//           Divider(
//             height: 1,
//             color: AppColors.of(context).divider,
//           ),
//         );
//       }
//     }

//     return widgets;
//   }
// }

// class _RdxActionMenuPositionDelegate extends SingleChildLayoutDelegate {
//   final Offset position;

//   final Size screenSize;
//   final double margin;
//   final double gap;

//   const _RdxActionMenuPositionDelegate({
//     required this.position,
//     required this.screenSize,
//     required this.margin,
//     required this.gap,
//   });

//   @override
//   BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
//     return BoxConstraints(
//       minWidth: 0,
//       minHeight: 0,
//       maxWidth: screenSize.width - (margin * 2),
//       maxHeight: screenSize.height - (margin * 2),
//     );
//   }

//   @override
//   Offset getPositionForChild(
//     Size size,
//     Size childSize,
//   ) {
//     // Align popup's right edge with the button's right edge.
//     double left = position.dx - childSize.width;

//     // Open below the three-dot button.
//     double top = position.dy + gap;

//     // Keep popup inside left edge.
//     if (left < margin) {
//       left = margin;
//     }

//     // Keep popup inside right edge.
//     if (left + childSize.width > screenSize.width - margin) {
//       left = screenSize.width - childSize.width - margin;
//     }

//     // If there isn't enough room below,
//     // open above the three-dot button.
//     if (top + childSize.height > screenSize.height - margin) {
//       top = position.dy - childSize.height - gap;
//     }

//     // Keep popup inside top edge.
//     if (top < margin) {
//       top = margin;
//     }

//     return Offset(left, top);
//   }

//   @override
//   bool shouldRelayout(
//     _RdxActionMenuPositionDelegate oldDelegate,
//   ) {
//     return oldDelegate.position != position ||
//         oldDelegate.screenSize != screenSize;
//   }
// }

// class _RdxActionMenuTile extends StatelessWidget {
//   final RdxActionMenuItem item;
//   final EdgeInsetsGeometry padding;
//   final VoidCallback onTap;

//   const _RdxActionMenuTile({
//     required this.item,
//     required this.padding,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);

//     final textColor = item.enabled
//         ? (item.textColor ?? colors.textPrimary)
//         : colors.textMuted;

//     final iconColor = item.enabled
//         ? (item.iconColor ?? colors.textSecondary)
//         : colors.textMuted;

//     return Material(
//       color: item.backgroundColor ?? Colors.transparent,
//       child: InkWell(
//         onTap: item.enabled ? onTap : null,
//         borderRadius: BorderRadius.circular(7),
//         child: Padding(
//           padding: padding,
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (item.icon != null) ...[
//                 Icon(
//                   item.icon,
//                   size: 17,
//                   color: iconColor,
//                 ),
//                 const SizedBox(width: 10),
//               ],
//               Flexible(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if (item.title != null)
//                       Text(
//                         item.title!,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: AppTextStyles.bodySecondary(
//                           context,
//                         ).copyWith(
//                           color: textColor,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     if (item.subtitle != null) ...[
//                       const SizedBox(height: 2),
//                       Text(
//                         item.subtitle!,
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: AppTextStyles.label(
//                           context,
//                         ).copyWith(
//                           color: colors.textMuted,
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';

class RdxActionMenuItem {
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool enabled;

  const RdxActionMenuItem({
    this.icon,
    this.title,
    this.subtitle,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
    this.onTap,
    this.enabled = true,
  });
}

class RdxActionMenuDialog extends StatelessWidget {
  final List<RdxActionMenuItem> items;

  /// Optional title.
  /// If null, no title is shown.
  final String? title;

  /// Optional subtitle.
  /// If null, no subtitle is shown.
  final String? subtitle;

  /// Global top-left position of the widget
  /// that opened this menu.
  final Offset? position;

  /// Optional maximum width.
  ///
  /// The actual width remains content-driven.
  final double? maxWidth;

  /// Optional maximum height.
  final double? maxHeight;

  /// Padding around the complete menu.
  final EdgeInsetsGeometry contentPadding;

  /// Padding inside each action item.
  final EdgeInsetsGeometry itemPadding;

  final bool showCloseButton;
  final bool showDivider;

  final Color? backgroundColor;
  final Color? barrierColor;

  final double borderRadius;
  final double elevation;

  /// Distance between the three-dot button
  /// and the action menu.
  final double gap;

  const RdxActionMenuDialog({
    super.key,
    required this.items,
    this.title,
    this.subtitle,
    this.position,
    this.maxWidth,
    this.maxHeight,
    this.contentPadding = const EdgeInsets.all(5),
    this.itemPadding = const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 8,
    ),
    this.showCloseButton = false,
    this.showDivider = false,
    this.backgroundColor,
    this.barrierColor = Colors.transparent,
    this.borderRadius = 9,
    this.elevation = 8,
    this.gap = 6,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final menu = IntrinsicWidth(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 0,
          maxWidth: maxWidth ?? MediaQuery.sizeOf(context).width * 0.9,
          maxHeight: maxHeight ?? MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Material(
          color: backgroundColor ?? colors.surface,
          elevation: elevation,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(borderRadius),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Padding(
              padding: contentPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null || subtitle != null || showCloseButton)
                    _buildHeader(context),
                  if ((title != null || subtitle != null || showCloseButton) &&
                      showDivider)
                    Divider(
                      height: 1,
                      color: colors.divider,
                    ),
                  ..._buildItems(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // If no position is supplied, behave like a normal
    // centered dialog.
    if (position == null) {
      return Center(
        child: menu,
      );
    }

    // When position is supplied, position the menu
    // relative to the three-dot button.
    return CustomSingleChildLayout(
      delegate: _RdxActionMenuPositionDelegate(
        position: position!,
        screenSize: MediaQuery.sizeOf(context),
        margin: 8,
        gap: gap,
      ),
      child: menu,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        7,
        5,
        4,
        5,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || subtitle != null)
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.section(context),
                    ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label(context).copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (showCloseButton) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(6),
              child: const SizedBox(
                width: 28,
                height: 28,
                child: Icon(
                  Icons.close,
                  size: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildItems(BuildContext context) {
    final widgets = <Widget>[];

    for (int index = 0; index < items.length; index++) {
      final item = items[index];

      widgets.add(
        _RdxActionMenuTile(
          item: item,
          padding: itemPadding,
          onTap: () {
            if (!item.enabled) return;

            Navigator.of(context).pop();
            item.onTap?.call();
          },
        ),
      );

      if (showDivider && index < items.length - 1) {
        widgets.add(
          Divider(
            height: 1,
            color: AppColors.of(context).divider,
          ),
        );
      }
    }

    return widgets;
  }
}

class _RdxActionMenuPositionDelegate extends SingleChildLayoutDelegate {
  final Offset position;
  final Size screenSize;
  final double margin;
  final double gap;

  const _RdxActionMenuPositionDelegate({
    required this.position,
    required this.screenSize,
    required this.margin,
    required this.gap,
  });

  @override
  BoxConstraints getConstraintsForChild(
    BoxConstraints constraints,
  ) {
    return BoxConstraints(
      minWidth: 0,
      minHeight: 0,
      maxWidth: screenSize.width - (margin * 2),
      maxHeight: screenSize.height - (margin * 2),
    );
  }

  @override
  Offset getPositionForChild(
    Size size,
    Size childSize,
  ) {
    // ------------------------------------------------------------
    // OPEN TO THE LEFT OF THE THREE-DOT BUTTON
    // ------------------------------------------------------------
    double left = position.dx - childSize.width - gap;

    // Vertically center the popup with the three-dot button.
    double top = position.dy;

    // ------------------------------------------------------------
    // KEEP INSIDE LEFT EDGE
    // ------------------------------------------------------------
    if (left < margin) {
      left = margin;
    }

    // ------------------------------------------------------------
    // KEEP INSIDE RIGHT EDGE
    // ------------------------------------------------------------
    if (left + childSize.width > screenSize.width - margin) {
      left = screenSize.width - childSize.width - margin;
    }

    // ------------------------------------------------------------
    // KEEP INSIDE TOP EDGE
    // ------------------------------------------------------------
    if (top < margin) {
      top = margin;
    }

    // ------------------------------------------------------------
    // KEEP INSIDE BOTTOM EDGE
    // ------------------------------------------------------------
    if (top + childSize.height > screenSize.height - margin) {
      top = screenSize.height - childSize.height - margin;
    }

    return Offset(left, top);
  }

  @override
  bool shouldRelayout(
    _RdxActionMenuPositionDelegate oldDelegate,
  ) {
    return oldDelegate.position != position ||
        oldDelegate.screenSize != screenSize ||
        oldDelegate.gap != gap;
  }
}

class _RdxActionMenuTile extends StatelessWidget {
  final RdxActionMenuItem item;
  final EdgeInsetsGeometry padding;
  final VoidCallback onTap;

  const _RdxActionMenuTile({
    required this.item,
    required this.padding,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final textColor = item.enabled
        ? (item.textColor ?? colors.textPrimary)
        : colors.textMuted;

    final iconColor = item.enabled
        ? (item.iconColor ?? colors.textSecondary)
        : colors.textMuted;

    return Material(
      color: item.backgroundColor ?? Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: item.enabled ? onTap : null,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: 17,
                  color: iconColor,
                ),
                const SizedBox(width: 9),
              ],
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.title != null)
                      Text(
                        item.title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        // style: AppTextStyles.bodySecondary(
                        //   context,
                        // ).copyWith(
                        //   color: textColor,
                        //   fontWeight: FontWeight.w500,
                        // ),
                        style: AppTextStyles.label(context)
                            .copyWith(color: textColor),
                      ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label(
                          context,
                        ).copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
