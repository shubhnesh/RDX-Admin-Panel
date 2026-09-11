// import 'package:flutter/material.dart';
// import 'package:rdx_admin/core/theme/text_styles.dart';
// import '../core/theme/app_colors.dart';
// import '../core/utils/responsive_size.dart';
// import 'app_back_button.dart';

// /// Shared inline page heading used throughout the admin screens.
// class RdxHeader extends StatelessWidget implements PreferredSizeWidget {
//   final String title;
//   final String? subtitle;
//   final bool showBackButton;

//   const RdxHeader({
//     super.key,
//     required this.title,
//     this.subtitle,
//     this.showBackButton = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);
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
//           if (showBackButton) ...[
//             Padding(
//               padding: EdgeInsets.only(
//                 right: context.w(12),
//                 top: context.h(2),
//               ),
//               child: AppBackButton(
//                 onPressed: () => Navigator.of(context).maybePop(),
//               ),
//             ),
//           ],
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(title, style: AppTextStyles.heading(context)),
//                 if (subtitle != null) ...[
//                   SizedBox(height: context.h(4)),
//                   Text(
//                     subtitle!,
//                     style: AppTextStyles.caption(context)
//                         .copyWith(color: colors.textMuted),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Size get preferredSize => const Size.fromHeight(76);
// }
import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive_size.dart';
import 'app_back_button.dart';

/// Shared inline page heading used throughout the admin screens.
class RdxHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final List<Widget>? actions; // ← this was missing

  const RdxHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.actions, // ← and here
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        Responsive.pageHorizontal(context),
        context.h(16),
        Responsive.pageHorizontal(context),
        context.h(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBackButton) ...[
            Padding(
              padding: EdgeInsets.only(
                right: context.w(12),
                top: context.h(2),
              ),
              child: AppBackButton(
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.heading(context)),
                if (subtitle != null) ...[
                  SizedBox(height: context.h(4)),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySecondary(context),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) ...[
            SizedBox(width: context.w(12)),
            ...actions!,
          ],
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(76);
}
