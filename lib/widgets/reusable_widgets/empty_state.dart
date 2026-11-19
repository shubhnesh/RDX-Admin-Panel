import 'package:flutter/material.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import '../../core/theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyState(
      {super.key, required this.message, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: context.h(48).clamp(32.0, 56.0),
            color: colors.textMuted,
          ),
          SizedBox(height: context.h(12)),
          Text(
            message,
            style: AppTextStyles.body(context),
          ),
        ],
      ),
    );
  }
}
