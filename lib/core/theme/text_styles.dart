// import 'package:flutter/material.dart';
// import 'app_colors.dart';

// class AppFonts {
//   AppFonts._();

//   static const String display = 'Georgia';
//   static const String body = 'Segoe UI';
//   static const String label = 'Segoe UI';
// }

// class AppTextStyles {
//   AppTextStyles._();

//   // Keep all font choices here so screens only choose semantic styles.
//   static const String displayFont = AppFonts.display;
//   static const String bodyFont = AppFonts.body;
//   static const String labelFont = AppFonts.label;

//   static const TextStyle display = TextStyle(
//     fontFamily: displayFont,
//     color: AppColors.lightTextPrimary,
//     fontSize: 24,
//     fontWeight: FontWeight.w700,
//   );

//   static const TextStyle title = TextStyle(
//     fontFamily: bodyFont,
//     color: AppColors.lightTextPrimary,
//     fontSize: 18,
//     fontWeight: FontWeight.w700,
//   );

//   static const TextStyle body = TextStyle(
//     fontFamily: bodyFont,
//     color: AppColors.lightTextPrimary,
//     fontSize: 14,
//   );

//   static const TextStyle bodyMuted = TextStyle(
//     fontFamily: bodyFont,
//     color: AppColors.lightTextSecondary,
//     fontSize: 13,
//   );

//   static const TextStyle label = TextStyle(
//     fontFamily: labelFont,
//     color: AppColors.lightTextSecondary,
//     fontSize: 12,
//     fontWeight: FontWeight.w600,
//   );

//   static const TextStyle h1 = TextStyle(
//     fontFamily: bodyFont,
//     color: AppColors.lightTextPrimary,
//     fontSize: 22,
//     fontWeight: FontWeight.bold,
//   );

//   static const TextStyle h2 = TextStyle(
//     fontFamily: bodyFont,
//     color: AppColors.lightTextPrimary,
//     fontSize: 16,
//     fontWeight: FontWeight.w600,
//   );

//   static ThemeData themeData() {
//     final scheme = AppColorScheme.light();
//     const brightness = Brightness.light;

//     return ThemeData(
//       useMaterial3: true,
//       brightness: brightness,
//       fontFamily: bodyFont,
//       scaffoldBackgroundColor: scheme.background,
//       colorScheme: ColorScheme(
//         brightness: brightness,
//         primary: AppColors.primary,
//         onPrimary: Colors.white,
//         secondary: AppColors.primary,
//         onSecondary: Colors.white,
//         surface: scheme.surface,
//         onSurface: scheme.textPrimary,
//         error: AppColors.danger,
//         onError: Colors.white,
//       ),
//       cardTheme: CardThemeData(
//         color: scheme.surface,
//         elevation: 0,
//         shadowColor: AppColors.primary.withValues(alpha: 0.08),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//           side: BorderSide(color: scheme.border),
//         ),
//       ),
//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: scheme.surfaceVariant,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: scheme.border),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: BorderSide(color: scheme.border),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8),
//           borderSide: const BorderSide(color: AppColors.primary),
//         ),
//         hintStyle: TextStyle(color: scheme.textMuted),
//         labelStyle: TextStyle(color: scheme.textSecondary),
//         contentPadding:
//             const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//       ),
//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: AppColors.primary,
//           foregroundColor: Colors.white,
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           textStyle: const TextStyle(fontWeight: FontWeight.w600),
//         ),
//       ),
//       outlinedButtonTheme: OutlinedButtonThemeData(
//         style: OutlinedButton.styleFrom(
//           foregroundColor: scheme.textPrimary,
//           side: BorderSide(color: scheme.border),
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         ),
//       ),
//       dividerTheme: DividerThemeData(color: scheme.divider),
//       switchTheme: SwitchThemeData(
//         thumbColor: WidgetStateProperty.resolveWith((states) {
//           if (states.contains(WidgetState.selected)) return Colors.white;
//           return scheme.textMuted;
//         }),
//         trackColor: WidgetStateProperty.resolveWith((states) {
//           if (states.contains(WidgetState.selected)) {
//             return AppColors.primary.withValues(alpha: 0.6);
//           }
//           return scheme.border;
//         }),
//       ),
//       textTheme: TextTheme(
//         headlineLarge: TextStyle(
//           fontFamily: bodyFont,
//           color: scheme.textPrimary,
//           fontSize: 22,
//           fontWeight: FontWeight.bold,
//         ),
//         headlineMedium: TextStyle(
//           fontFamily: bodyFont,
//           color: scheme.textPrimary,
//           fontSize: 16,
//           fontWeight: FontWeight.w600,
//         ),
//         bodyLarge: TextStyle(
//             fontFamily: bodyFont, color: scheme.textPrimary, fontSize: 14),
//         bodyMedium: TextStyle(
//             fontFamily: bodyFont, color: scheme.textSecondary, fontSize: 13),
//         bodySmall: TextStyle(
//             fontFamily: labelFont, color: scheme.textMuted, fontSize: 12),
//         labelMedium: TextStyle(
//             fontFamily: labelFont, color: scheme.textSecondary, fontSize: 12),
//       ),
//       primaryTextTheme: TextTheme(
//         headlineLarge: display,
//         headlineMedium: h1,
//         titleLarge: title,
//         titleMedium: h2,
//         bodyLarge: body,
//         bodyMedium: bodyMuted,
//         bodySmall: label,
//         labelLarge: label,
//         labelMedium: label,
//         labelSmall: label,
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralized typography system for the application.
///
/// Usage:
///   Text('Menu', style: AppTextStyles.pageTitle)
///   Text('Description', style: AppTextStyles.body)
///   Text('Required', style: AppTextStyles.badge)
///
/// Keep screen-specific text styling out of widgets whenever possible.
class AppFonts {
  AppFonts._();

  /// Large/decorative headings.
  static const String display = 'Georgia';

  /// Main application font.
  static const String body = 'Segoe UI';

  /// Small labels and UI metadata.
  static const String label = 'Segoe UI';
}

class AppTextStyles {
  AppTextStyles._();

  // ---------------------------------------------------------------------------
  // FONT FAMILIES
  // ---------------------------------------------------------------------------

  static const String displayFont = AppFonts.display;
  static const String bodyFont = AppFonts.body;
  static const String labelFont = AppFonts.label;

  // ---------------------------------------------------------------------------
  // DISPLAY / BRAND
  // ---------------------------------------------------------------------------

  /// Large decorative heading.
  ///
  /// Example:
  /// "Welcome Back"
  /// "Restaurant Dashboard"
  static const TextStyle display = TextStyle(
    fontFamily: displayFont,
    color: AppColors.lightTextPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  // ---------------------------------------------------------------------------
  // PAGE HEADINGS
  // ---------------------------------------------------------------------------

  /// Main title of a screen/page.
  ///
  /// Example:
  /// "Menu Management"
  static const TextStyle pageTitle = TextStyle(
    fontFamily: bodyFont,
    color: AppColors.lightTextPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  /// Main heading inside a section.
  ///
  /// Example:
  /// "Basic Information"
  /// "Customization"
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: bodyFont,
    color: AppColors.lightTextPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  /// Smaller heading used for subsections.
  ///
  /// Example:
  /// "Display Settings"
  /// "Portion Sizes"
  static const TextStyle subsectionTitle = TextStyle(
    fontFamily: bodyFont,
    color: AppColors.lightTextPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // ---------------------------------------------------------------------------
  // CARD / COMPONENT TITLES
  // ---------------------------------------------------------------------------

  /// Title of a card, list item, menu item, etc.
  ///
  /// Example:
  /// "Paneer Butter Masala"
  static const TextStyle cardTitle = TextStyle(
    fontFamily: bodyFont,
    color: AppColors.lightTextPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  /// Smaller title for compact components.
  static const TextStyle componentTitle = TextStyle(
    fontFamily: bodyFont,
    color: AppColors.lightTextPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  // ---------------------------------------------------------------------------
  // BODY TEXT
  // ---------------------------------------------------------------------------

  /// Normal primary content.
  ///
  /// Example:
  /// Menu descriptions, general information, etc.
  static const TextStyle body = TextStyle(
    fontFamily: bodyFont,
    color: AppColors.lightTextPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// Secondary body content.
  ///
  /// Example:
  /// Additional information or less important text.
  static const TextStyle bodySecondary = TextStyle(
    fontFamily: bodyFont,
    color: AppColors.lightTextSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// Muted body content.
  ///
  /// Example:
  /// Placeholder-like supporting information.
  static const TextStyle bodyMuted = TextStyle(
    fontFamily: bodyFont,
    color: AppColors.lightTextSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  // ---------------------------------------------------------------------------
  // LABELS
  // ---------------------------------------------------------------------------

  /// Standard form/UI label.
  ///
  /// Example:
  /// "Item Name"
  /// "Category"
  /// "Price"
  static const TextStyle label = TextStyle(
    fontFamily: labelFont,
    color: AppColors.lightTextSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  /// Stronger label when the label needs more visual importance.
  static const TextStyle labelStrong = TextStyle(
    fontFamily: labelFont,
    color: AppColors.lightTextPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  /// Very small metadata text.
  ///
  /// Example:
  /// "Updated 2 mins ago"
  static const TextStyle metadata = TextStyle(
    fontFamily: labelFont,
    color: AppColors.lightTextSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  // ---------------------------------------------------------------------------
  // INPUTS / FORMS
  // ---------------------------------------------------------------------------

  /// Text entered inside a text field.
  static const TextStyle input = TextStyle(
    fontFamily: bodyFont,
    color: AppColors.lightTextPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// Placeholder text inside a text field.
  static const TextStyle inputHint = TextStyle(
    fontFamily: bodyFont,
    color: AppColors.lightTextSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// Helper text displayed below an input.
  static const TextStyle helper = TextStyle(
    fontFamily: bodyFont,
    color: AppColors.lightTextSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // ---------------------------------------------------------------------------
  // BUTTONS
  // ---------------------------------------------------------------------------

  /// Main button text.
  ///
  /// Example:
  /// "Save Item"
  /// "Create Menu"
  static const TextStyle button = TextStyle(
    fontFamily: labelFont,
    color: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  /// Text used by secondary/outlined buttons.
  static const TextStyle buttonSecondary = TextStyle(
    fontFamily: labelFont,
    color: AppColors.lightTextPrimary,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  /// Small button/action text.
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: labelFont,
    color: AppColors.lightTextPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  // ---------------------------------------------------------------------------
  // NAVIGATION
  // ---------------------------------------------------------------------------

  /// Main navigation item text.
  static const TextStyle navigation = TextStyle(
    fontFamily: labelFont,
    color: AppColors.lightTextSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  /// Active navigation item text.
  static const TextStyle navigationActive = TextStyle(
    fontFamily: labelFont,
    color: AppColors.primary,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  // ---------------------------------------------------------------------------
  // PRICE / NUMBERS
  // ---------------------------------------------------------------------------

  /// Standard price/value text.
  ///
  /// Example:
  /// "₹249"
  static const TextStyle price = TextStyle(
    fontFamily: bodyFont,
    color: AppColors.lightTextPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  /// Large/high-emphasis price.
  static const TextStyle priceLarge = TextStyle(
    fontFamily: bodyFont,
    color: AppColors.lightTextPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  /// Small numeric/stat value.
  static const TextStyle value = TextStyle(
    fontFamily: bodyFont,
    color: AppColors.lightTextPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  // ---------------------------------------------------------------------------
  // BADGES / STATUS
  // ---------------------------------------------------------------------------

  /// Small badge/status text.
  ///
  /// Example:
  /// "VEG"
  /// "FEATURED"
  /// "REQUIRED"
  static const TextStyle badge = TextStyle(
    fontFamily: labelFont,
    color: AppColors.lightTextPrimary,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  /// Status text.
  ///
  /// Example:
  /// "Available"
  /// "Preparing"
  /// "Completed"
  static const TextStyle status = TextStyle(
    fontFamily: labelFont,
    color: AppColors.lightTextPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  // ---------------------------------------------------------------------------
  // FEEDBACK
  // ---------------------------------------------------------------------------

  /// Error/validation message.
  static const TextStyle error = TextStyle(
    fontFamily: bodyFont,
    color: AppColors.danger,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /// Success message.
  static const TextStyle success = TextStyle(
    fontFamily: bodyFont,
    color: AppColors.success,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // ---------------------------------------------------------------------------
  // CAPTIONS
  // ---------------------------------------------------------------------------

  /// Small explanatory text.
  static const TextStyle caption = TextStyle(
    fontFamily: bodyFont,
    color: AppColors.lightTextSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  /// Very small muted caption.
  static const TextStyle captionMuted = TextStyle(
    fontFamily: bodyFont,
    color: AppColors.lightTextSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  // ---------------------------------------------------------------------------
  // THEME
  // ---------------------------------------------------------------------------

  static ThemeData themeData() {
    final scheme = AppColorScheme.light();

    const brightness = Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,

      fontFamily: bodyFont,

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

      // -----------------------------------------------------------------------
      // CARDS
      // -----------------------------------------------------------------------

      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shadowColor: AppColors.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.border),
        ),
      ),

      // -----------------------------------------------------------------------
      // INPUTS
      // -----------------------------------------------------------------------

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
          borderSide: const BorderSide(
            color: AppColors.primary,
          ),
        ),
        errorStyle: error,
        hintStyle: inputHint,
        labelStyle: label,
        helperStyle: helper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),

      // -----------------------------------------------------------------------
      // BUTTONS
      // -----------------------------------------------------------------------

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: button,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.textPrimary,
          side: BorderSide(color: scheme.border),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: buttonSecondary,
        ),
      ),

      // -----------------------------------------------------------------------
      // DIVIDERS
      // -----------------------------------------------------------------------

      dividerTheme: DividerThemeData(
        color: scheme.divider,
      ),

      // -----------------------------------------------------------------------
      // SWITCH
      // -----------------------------------------------------------------------

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }

          return scheme.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.6);
          }

          return scheme.border;
        }),
      ),

      // -----------------------------------------------------------------------
      // MATERIAL TEXT THEME
      // -----------------------------------------------------------------------

      textTheme: TextTheme(
        displayLarge: display,
        headlineLarge: pageTitle,
        headlineMedium: sectionTitle,
        headlineSmall: subsectionTitle,
        titleLarge: sectionTitle,
        titleMedium: cardTitle,
        titleSmall: componentTitle,
        bodyLarge: body,
        bodyMedium: bodySecondary,
        bodySmall: caption,
        labelLarge: button,
        labelMedium: label,
        labelSmall: metadata,
      ),
    );
  }
}
