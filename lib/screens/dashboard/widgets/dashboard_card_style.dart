import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';

/// Single shared look for every dashboard sub-module card.
///
/// Typography follows STYLE_GUIDE:
/// - Card title → [AppTextStyles.bodyLargeSemi]
/// - Card description → [AppTextStyles.body]
/// - Period badge → [AppTextStyles.bodySemi] + primary color
class DashboardCardStyle {
  DashboardCardStyle._();

  static const double radius = 16;
  static const Color salesAccent = AppColors.primary;
  static const Color ordersAccent = AppColors.success;
  static const Color averageOrderValueAccent = AppColors.info;

  /// Lighter shadow so cards don't feel heavy stacked in sections.
  static List<BoxShadow> get shadow => [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.04),
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

  /// Sub-module title — maps to bodyLargeSemi (section / card title role).
  static TextStyle title(BuildContext context) {
    return AppTextStyles.bodyLargeSemi(context);
  }

  /// Supporting line under the title — body role.
  static TextStyle description(BuildContext context) {
    return AppTextStyles.body(context).copyWith(color: AppColors.of(context).textSecondary,
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
        style: AppTextStyles.bodySemi(context).copyWith(color: AppColors.primary),
      ),
    );
  }
}
