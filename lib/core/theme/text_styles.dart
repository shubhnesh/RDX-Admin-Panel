import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle h1 = TextStyle(
    color: AppColors.darkTextPrimary,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle h2 = TextStyle(
    color: AppColors.darkTextPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.darkTextPrimary,
    fontSize: 14,
  );

  static const TextStyle bodyMuted = TextStyle(
    color: AppColors.darkTextSecondary,
    fontSize: 13,
  );

  static const TextStyle caption = TextStyle(
    color: AppColors.darkTextMuted,
    fontSize: 11,
  );

  static const TextStyle label = TextStyle(
    color: AppColors.darkTextSecondary,
    fontSize: 12,
  );

  /// Build full ThemeData for the given brightness.
  static ThemeData themeData({required bool isDark}) {
    final scheme = isDark ? AppColorScheme.dark() : AppColorScheme.light();
    final brightness = isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scheme.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primary,
        onSecondary: Colors.white,
        surface: scheme.surface,
        onSurface: scheme.textPrimary,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        hintStyle: TextStyle(color: scheme.textMuted),
        labelStyle: TextStyle(color: scheme.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.textPrimary,
          side: BorderSide(color: scheme.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.divider),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return scheme.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withOpacity(0.6);
          }
          return scheme.border;
        }),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: scheme.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: scheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: scheme.textPrimary, fontSize: 14),
        bodyMedium: TextStyle(color: scheme.textSecondary, fontSize: 13),
        bodySmall: TextStyle(color: scheme.textMuted, fontSize: 11),
        labelMedium: TextStyle(color: scheme.textSecondary, fontSize: 12),
      ),
    );
  }
}
