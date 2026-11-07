// import 'package:flutter/material.dart';
// import 'package:rdx_admin/core/theme/text_styles.dart';
// import '../../core/theme/app_colors.dart';
// import '../../core/utils/responsive_size.dart';
// import '../buttons/app_back_button.dart';

// /// Shared inline page heading used throughout the admin screens.
// class RdxHeader extends StatelessWidget implements PreferredSizeWidget {
//   final String title;
//   final String? subtitle;
//   final bool showBackButton;
//   final List<Widget>? actions;

//   /// Optional override for the back button.
//   /// When null, defaults to [Navigator.maybePop].
//   final VoidCallback? onBack;

//   const RdxHeader({
//     super.key,
//     required this.title,
//     this.subtitle,
//     this.showBackButton = false,
//     this.actions,
//     this.onBack,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);
//     final narrow = MediaQuery.sizeOf(context).width < 700;

//     final titleBlock = Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(title, style: AppTextStyles.heading(context)),
//         if (subtitle != null) ...[
//           SizedBox(height: context.h(4)),
//           Text(
//             subtitle!,
//             style: AppTextStyles.bodySecondary(context),
//           ),
//         ],
//       ],
//     );

//     final back = showBackButton
//         ? Padding(
//             padding: EdgeInsets.only(
//               right: context.w(12),
//               top: context.h(2),
//             ),
//             child: AppBackButton(
//               onPressed: onBack ?? () => Navigator.of(context).maybePop(),
//             ),
//           )
//         : null;

//     final actionWidgets = actions ?? const <Widget>[];

//     if (narrow && actionWidgets.isNotEmpty) {
//       return Container(
//         padding: EdgeInsets.fromLTRB(
//           Responsive.pageHorizontal(context),
//           context.h(16),
//           Responsive.pageHorizontal(context),
//           context.h(8),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (back != null) back,
//                 Expanded(child: titleBlock),
//               ],
//             ),
//             SizedBox(height: context.h(12)),
//             Wrap(
//               spacing: context.w(10),
//               runSpacing: context.h(8),
//               alignment: WrapAlignment.end,
//               children: actionWidgets,
//             ),
//           ],
//         ),
//       );
//     }

//     return Container(
//       padding: EdgeInsets.fromLTRB(
//         Responsive.pageHorizontal(context),
//         context.h(16),
//         Responsive.pageHorizontal(context),
//         context.h(8),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (back != null) back,
//           Expanded(child: titleBlock),
//           if (actionWidgets.isNotEmpty) ...[
//             SizedBox(width: context.w(12)),
//             ...actionWidgets,
//           ],
//         ],
//       ),
//     );
//   }

//   @override
//   Size get preferredSize => const Size.fromHeight(76);
// }
import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
import '../buttons/app_back_button.dart';

/// Shared inline page heading used throughout the admin screens.
class RdxHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final List<Widget>? actions;

  /// Optional override for the back button.
  /// When null, defaults to [Navigator.maybePop].
  final VoidCallback? onBack;

  const RdxHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.actions,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 700;
    final mobile = Responsive.isMobile(context);

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: mobile ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: mobile
              ? AppTextStyles.heading(context).copyWith(
                  fontSize: context.h(20).clamp(18.0, 21.0),
                )
              : AppTextStyles.heading(context),
        ),
        if (subtitle != null && !mobile) ...[
          SizedBox(height: context.h(4)),
          Text(subtitle!, style: AppTextStyles.bodySecondary(context)),
        ] else if (subtitle != null) ...[
          SizedBox(height: context.h(1)),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context),
          ),
        ],
      ],
    );

    final back = showBackButton
        ? Padding(
            padding: EdgeInsets.only(
              right: context.w(mobile ? 8 : 12),
              top: mobile ? 0 : context.h(2),
            ),
            child: AppBackButton(
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            ),
          )
        : null;

    final actionWidgets = actions ?? const <Widget>[];

    final trailing = actionWidgets;

    if (mobile) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          Responsive.pageHorizontal(context),
          context.h(4),
          Responsive.pageHorizontal(context),
          context.h(2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (back != null) back,
            Expanded(child: titleBlock),
            if (trailing.isNotEmpty) ...[
              SizedBox(width: context.w(6)),
              ...trailing,
            ],
          ],
        ),
      );
    }

    if (narrow && trailing.isNotEmpty) {
      return Container(
        padding: EdgeInsets.fromLTRB(
          Responsive.pageHorizontal(context),
          context.h(mobile ? 8 : 16),
          Responsive.pageHorizontal(context),
          context.h(mobile ? 4 : 8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (back != null) back,
                Expanded(child: titleBlock),
              ],
            ),
            SizedBox(height: context.h(mobile ? 8 : 12)),
            Wrap(
              spacing: context.w(10),
              runSpacing: context.h(8),
              alignment: WrapAlignment.end,
              children: trailing,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        Responsive.pageHorizontal(context),
        context.h(mobile ? 8 : 16),
        Responsive.pageHorizontal(context),
        context.h(mobile ? 4 : 8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (back != null) back,
          Expanded(child: titleBlock),
          if (trailing.isNotEmpty) ...[
            SizedBox(width: context.w(12)),
            ...trailing,
          ],
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(76);
}
