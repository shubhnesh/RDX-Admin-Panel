import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive_size.dart';

/// Shared top bar used at the top of every admin screen's content area.
class RdxHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const RdxHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      height: 48,
      padding:
          EdgeInsets.symmetric(horizontal: Responsive.pageHorizontal(context)),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.arrow_back_ios_new,
                size: 17, color: colors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: AppTextStyles.heading(context),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}
