import 'package:flutter/material.dart';

/// Semantic colors that adapt to the active theme.
/// Prefer `AppColors.of(context)` in widgets so light/dark both work.
class AppColors {
  AppColors._();

  // ─── Brand (shared) ───────────────────────────────────────────────
  static const Color primary = Color(0xFFE3384B);
  static const Color primaryDark = Color(0xFFB82838);

  static const Color success = Color(0xFF3CCB7F);
  static const Color warning = Color(0xFFE8A33D);
  static const Color danger = Color(0xFFE3384B);
  static const Color info = Color(0xFF4C8DE0);

  static const Color statusPending = warning;
  static const Color statusPreparing = info;
  static const Color statusReady = success;
  static const Color statusCancelled = Color(0xFF8A5458);
  static const Color statusDelivered = Color(0xFF6B8E6B);

  // ─── Dark palette (default) ───────────────────────────────────────
  static const Color darkBackground = Color(0xFF1A0E10);
  static const Color darkSurface = Color(0xFF241316);
  static const Color darkSurfaceVariant = Color(0xFF2E181C);
  static const Color darkSidebar = Color(0xFF200F12);
  static const Color darkTextPrimary = Color(0xFFF5EAEA);
  static const Color darkTextSecondary = Color(0xFFB79196);
  static const Color darkTextMuted = Color(0xFF7C5C60);
  static const Color darkBorder = Color(0xFF3A2226);
  static const Color darkDivider = Color(0xFF32191D);

  // ─── Light palette ────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF7F4F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0EBEB);
  static const Color lightSidebar = Color(0xFF1F1215);
  static const Color lightTextPrimary = Color(0xFF1A0E10);
  static const Color lightTextSecondary = Color(0xFF6B4E52);
  static const Color lightTextMuted = Color(0xFF9A7A7E);
  static const Color lightBorder = Color(0xFFE5D8DA);
  static const Color lightDivider = Color(0xFFEDE4E5);

  // ─── Legacy static accessors (dark defaults for non-context use) ──
  static const Color background = darkBackground;
  static const Color surface = darkSurface;
  static const Color surfaceVariant = darkSurfaceVariant;
  static const Color sidebar = darkSidebar;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textMuted = darkTextMuted;
  static const Color border = darkBorder;
  static const Color divider = darkDivider;

  /// Resolve palette from the nearest [ThemeData].
  static AppColorScheme of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? AppColorScheme.dark()
        : AppColorScheme.light();
  }
}

class AppColorScheme {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color sidebar;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color divider;
  final Color primary;

  const AppColorScheme({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.sidebar,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.divider,
    required this.primary,
  });

  factory AppColorScheme.dark() => const AppColorScheme(
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        surfaceVariant: AppColors.darkSurfaceVariant,
        sidebar: AppColors.darkSidebar,
        textPrimary: AppColors.darkTextPrimary,
        textSecondary: AppColors.darkTextSecondary,
        textMuted: AppColors.darkTextMuted,
        border: AppColors.darkBorder,
        divider: AppColors.darkDivider,
        primary: AppColors.primary,
      );

  factory AppColorScheme.light() => const AppColorScheme(
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        surfaceVariant: AppColors.lightSurfaceVariant,
        sidebar: AppColors.lightSidebar,
        textPrimary: AppColors.lightTextPrimary,
        textSecondary: AppColors.lightTextSecondary,
        textMuted: AppColors.lightTextMuted,
        border: AppColors.lightBorder,
        divider: AppColors.lightDivider,
        primary: AppColors.primary,
      );
}
