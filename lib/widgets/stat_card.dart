import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import '../core/theme/app_colors.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? accentColor;
  final String? subtitle;
  final Color? subtitleColor;
  final IconData? subtitleIcon;
  final double? progress;

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
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = accentColor ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
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
                value: progress!.clamp(0, 1),
                minHeight: 6,
                backgroundColor: colors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (subtitleIcon != null) ...[
                  Icon(
                    subtitleIcon,
                    size: 14,
                    color: subtitleColor ?? colors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label(context).copyWith(
                      color: subtitleColor ?? colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
