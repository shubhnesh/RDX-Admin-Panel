import 'package:flutter/material.dart';

/// Single source of truth for every colour used in the Ops Center.
///
/// Two ways to use it:
///
/// 1. Theme-aware (preferred inside widgets):
///      final colors = AppColors.of(context);
///      colors.surface, colors.textMuted, colors.border ...
///
/// 2. Static constants (const contexts, fixed-look screens such as Login):
///      AppColors.primary, AppColors.white, AppColors.darkSurface ...
///    Static neutrals always hold the LIGHT palette.
///
/// Rules:
/// - Never write `Color(0x...)`, `AppColors.white` or `AppColors.black` in a screen.
/// - Closely related shades share ONE token (e.g. every muted grey-blue text
///   is [textMuted]). Opacity variations use `.withOpacity()` / `.withValues()`
///   on the token instead of a new colour.
class AppColors {
  AppColors._();

  // ── Brand ───────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFE8302B);
  static const Color primaryDark = Color(0xFFC0221E);

  /// Secondary brand colour (blue) – pairs with the red [primary].
  static const Color secondary = Color(0xFF2563EB);
  static const Color secondaryDark = Color(0xFF1D4ED8);

  // ── Semantic / status ───────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color danger = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFE8A72B);
  static const Color info = Color(0xFF1E88E5);

  /// Secondary highlight (e.g. “Active Offers” stat).
  static const Color accent = Color(0xFF7C5CFC);

  // ── Light neutrals (static = light palette) ─────────────────────────────
  static const Color background = Color(0xFFF5F6F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2F5);
  static const Color border = Color(0xFFE3E6EB);
  static const Color divider = Color(0xFFEBEEF2);

  // ── Text (light palette) ────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF182033);
  static const Color textSecondary = Color(0xFF4A5468);
  static const Color textMuted = Color(0xFF7B8494);

  // ── Fixed colours (identical in every theme) ────────────────────────────
  /// Text / icons that sit on [primary] or on dark panels.
  static const Color white = Color(0xFFFFFFFF);

  /// Shadows and image scrims.
  static const Color black = Color(0xFF000000);

  // ── Dark brand surfaces (login brand panel & dashboard preview) ─────────
  static const Color darkSurface = Color(0xFF171B22);
  static const Color darkSurfaceRaised = Color(0xFF222731);
  static const Color darkSurfaceElevated = Color(0xFF292E37);

  /// Theme-aware colours. Uses the registered [AppColorScheme] extension when
  /// present, otherwise picks light/dark from the current theme brightness.
  static AppColorScheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppColorScheme>() ??
        (theme.brightness == Brightness.dark
            ? AppColorScheme.dark
            : AppColorScheme.light);
  }
}

/// Theme-aware colour tokens. Register on [ThemeData.extensions] to override
/// the defaults; otherwise [AppColors.of] falls back to [light] / [dark].
@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.divider,
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.secondaryDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.danger,
    required this.warning,
    required this.info,
    required this.accent,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color border;
  final Color divider;
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color secondaryDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color danger;
  final Color warning;
  final Color info;
  final Color accent;

  static const light = AppColorScheme(
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceVariant: AppColors.surfaceVariant,
    border: AppColors.border,
    divider: AppColors.divider,
    primary: AppColors.primary,
    primaryDark: AppColors.primaryDark,
    secondary: AppColors.secondary,
    secondaryDark: AppColors.secondaryDark,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    success: AppColors.success,
    danger: AppColors.danger,
    warning: AppColors.warning,
    info: AppColors.info,
    accent: AppColors.accent,
  );

  static const dark = AppColorScheme(
    background: Color(0xFF0F1218),
    surface: AppColors.darkSurface,
    surfaceVariant: AppColors.darkSurfaceRaised,
    border: Color(0xFF2E3440),
    divider: Color(0xFF262B35),
    primary: AppColors.primary,
    primaryDark: AppColors.primaryDark,
    secondary: AppColors.secondary,
    secondaryDark: AppColors.secondaryDark,
    textPrimary: Color(0xFFF2F4F8),
    textSecondary: Color(0xFFB4BCCB),
    textMuted: Color(0xFF7B8494),
    success: Color(0xFF4CAF50),
    danger: Color(0xFFEF5350),
    warning: AppColors.warning,
    info: Color(0xFF42A5F5),
    accent: Color(0xFF9B83FF),
  );

  @override
  AppColorScheme copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? border,
    Color? divider,
    Color? primary,
    Color? primaryDark,
    Color? secondary,
    Color? secondaryDark,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? success,
    Color? danger,
    Color? warning,
    Color? info,
    Color? accent,
  }) {
    return AppColorScheme(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      secondary: secondary ?? this.secondary,
      secondaryDark: secondaryDark ?? this.secondaryDark,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      accent: accent ?? this.accent,
    );
  }

  @override
  AppColorScheme lerp(ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryDark: Color.lerp(secondaryDark, other.secondaryDark, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}
