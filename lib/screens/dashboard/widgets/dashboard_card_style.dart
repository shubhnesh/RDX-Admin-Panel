import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';

/// Single shared look for every dashboard sub-module card.
class DashboardCardStyle {
  DashboardCardStyle._();

  static const double radius = 16;
  static const Color salesAccent = AppColors.primary;
  static const Color ordersAccent = Color(0xFF22C55E);
  static const Color averageOrderValueAccent = Color(0xFF3B82F6);

  /// Lighter shadow so cards don't feel heavy stacked in sections.
  static List<BoxShadow> get shadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 5,
          offset: const Offset(0, 1),
        ),
      ];

  static BoxDecoration decoration(BuildContext context) {
    final colors = AppColors.of(context);
    return BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: colors.border),
      boxShadow: shadow,
    );
  }

  /// Sub-module title — smaller than [DashboardSection] module heading.
  static TextStyle title(BuildContext context) {
    return AppTextStyles.label(context).copyWith(
      fontSize: context.h(16),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    );
  }

  static TextStyle description(BuildContext context) {
    return AppTextStyles.caption(context).copyWith(
      color: AppColors.of(context).textSecondary,
      fontSize: context.h(14),
    );
  }

  static Widget periodBadge(BuildContext context, String label) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(4),
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.label(context).copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
