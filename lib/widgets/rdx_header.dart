import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Shared top bar used at the top of every admin screen's content area.
class RdxHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;

  const RdxHeader({super.key, required this.title, this.showBack = false, this.actions});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          if (showBack) ...[
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 18, color: colors.textPrimary),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          ...?actions,
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 16,
            backgroundColor: colors.surfaceVariant,
            child: Icon(Icons.person, size: 18, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
