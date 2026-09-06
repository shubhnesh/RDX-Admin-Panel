// import 'package:flutter/material.dart';
// import 'app_colors.dart';
// import '../utils/responsive_size.dart';

// /// Centralized typography system for the application.
// ///
// /// Usage:
// ///   Text('Menu', style: AppTextStyles.pageTitle(context))
// ///   Text('Description', style: AppTextStyles.body(context))
// ///
// /// Change color (or any property) with copyWith:
// ///   Text('Menu', style: AppTextStyles.pageTitle(context).copyWith(color: Colors.red))
// ///   Text('Price', style: AppTextStyles.price(context).copyWith(color: AppColors.primary))
// class AppFonts {
//   AppFonts._();

//   /// Large/decorative headings.
//   static const String display = 'Georgia';

//   /// Main application font.
//   static const String body = 'Segoe UI';

//   /// Small labels and UI metadata.
//   static const String label = 'Segoe UI';
// }

// class AppTextStyles {
//   AppTextStyles._();

//   // ---------------------------------------------------------------------------
//   // FONT FAMILIES
//   // ---------------------------------------------------------------------------

//   static const String displayFont = AppFonts.display;
//   static const String bodyFont = AppFonts.body;
//   static const String labelFont = AppFonts.label;

//   // ---------------------------------------------------------------------------
//   // DISPLAY / BRAND
//   // ---------------------------------------------------------------------------

//   static TextStyle display(BuildContext context) => TextStyle(
//         fontFamily: displayFont,
//         color: AppColors.lightTextPrimary,
//         fontSize: context.h(24),
//         fontWeight: FontWeight.w700,
//       );

//   // ---------------------------------------------------------------------------
//   // PAGE HEADINGS
//   // ---------------------------------------------------------------------------

//   static TextStyle pageTitle(BuildContext context) => TextStyle(
//         fontFamily: bodyFont,
//         color: AppColors.lightTextPrimary,
//         fontSize: context.h(22),
//         fontWeight: FontWeight.w700,
//       );

//   static TextStyle sectionTitle(BuildContext context) => TextStyle(
//         fontFamily: bodyFont,
//         color: AppColors.lightTextPrimary,
//         fontSize: context.h(18),
//         fontWeight: FontWeight.w700,
//       );

//   static TextStyle subsectionTitle(BuildContext context) => TextStyle(
//         fontFamily: bodyFont,
//         color: AppColors.lightTextPrimary,
//         fontSize: context.h(16),
//         fontWeight: FontWeight.w600,
//       );

//   // ---------------------------------------------------------------------------
//   // CARD / COMPONENT TITLES
//   // ---------------------------------------------------------------------------

//   static TextStyle cardTitle(BuildContext context) => TextStyle(
//         fontFamily: bodyFont,
//         color: AppColors.lightTextPrimary,
//         fontSize: context.h(15),
//         fontWeight: FontWeight.w600,
//       );

//   static TextStyle componentTitle(BuildContext context) => TextStyle(
//         fontFamily: bodyFont,
//         color: AppColors.lightTextPrimary,
//         fontSize: context.h(14),
//         fontWeight: FontWeight.w600,
//       );

//   // ---------------------------------------------------------------------------
//   // BODY TEXT
//   // ---------------------------------------------------------------------------

//   static TextStyle body(BuildContext context) => TextStyle(
//         fontFamily: bodyFont,
//         color: AppColors.lightTextPrimary,
//         fontSize: context.h(14),
//         fontWeight: FontWeight.w400,
//       );

//   static TextStyle bodySecondary(BuildContext context) => TextStyle(
//         fontFamily: bodyFont,
//         color: AppColors.lightTextSecondary,
//         fontSize: context.h(14),
//         fontWeight: FontWeight.w400,
//       );

//   static TextStyle bodyMuted(BuildContext context) => TextStyle(
//         fontFamily: bodyFont,
//         color: AppColors.lightTextSecondary,
//         fontSize: context.h(13),
//         fontWeight: FontWeight.w400,
//       );

//   // ---------------------------------------------------------------------------
//   // LABELS
//   // ---------------------------------------------------------------------------

//   static TextStyle label(BuildContext context) => TextStyle(
//         fontFamily: labelFont,
//         color: AppColors.lightTextSecondary,
//         fontSize: context.h(12),
//         fontWeight: FontWeight.w600,
//       );

//   static TextStyle labelStrong(BuildContext context) => TextStyle(
//         fontFamily: labelFont,
//         color: AppColors.lightTextPrimary,
//         fontSize: context.h(12),
//         fontWeight: FontWeight.w600,
//       );

//   static TextStyle metadata(BuildContext context) => TextStyle(
//         fontFamily: labelFont,
//         color: AppColors.lightTextSecondary,
//         fontSize: context.h(11),
//         fontWeight: FontWeight.w500,
//       );

//   // ---------------------------------------------------------------------------
//   // INPUTS / FORMS
//   // ---------------------------------------------------------------------------

//   static TextStyle input(BuildContext context) => TextStyle(
//         fontFamily: bodyFont,
//         color: AppColors.lightTextPrimary,
//         fontSize: context.h(14),
//         fontWeight: FontWeight.w400,
//       );

//   static TextStyle inputHint(BuildContext context) => TextStyle(
//         fontFamily: bodyFont,
//         color: AppColors.lightTextSecondary,
//         fontSize: context.h(14),
//         fontWeight: FontWeight.w400,
//       );

//   static TextStyle helper(BuildContext context) => TextStyle(
//         fontFamily: bodyFont,
//         color: AppColors.lightTextSecondary,
//         fontSize: context.h(12),
//         fontWeight: FontWeight.w400,
//       );

//   // ---------------------------------------------------------------------------
//   // BUTTONS
//   // ---------------------------------------------------------------------------

//   static TextStyle button(BuildContext context) => TextStyle(
//         fontFamily: labelFont,
//         color: Colors.white,
//         fontSize: context.h(13),
//         fontWeight: FontWeight.w600,
//       );

//   static TextStyle buttonSecondary(BuildContext context) => TextStyle(
//         fontFamily: labelFont,
//         color: AppColors.lightTextPrimary,
//         fontSize: context.h(13),
//         fontWeight: FontWeight.w600,
//       );

//   static TextStyle buttonSmall(BuildContext context) => TextStyle(
//         fontFamily: labelFont,
//         color: AppColors.lightTextPrimary,
//         fontSize: context.h(12),
//         fontWeight: FontWeight.w600,
//       );

//   // ---------------------------------------------------------------------------
//   // NAVIGATION
//   // ---------------------------------------------------------------------------

//   static TextStyle navigation(BuildContext context) => TextStyle(
//         fontFamily: labelFont,
//         color: AppColors.lightTextSecondary,
//         fontSize: context.h(13),
//         fontWeight: FontWeight.w600,
//       );

//   static TextStyle navigationActive(BuildContext context) => TextStyle(
//         fontFamily: labelFont,
//         color: AppColors.primary,
//         fontSize: context.h(13),
//         fontWeight: FontWeight.w700,
//       );

//   // ---------------------------------------------------------------------------
//   // PRICE / NUMBERS
//   // ---------------------------------------------------------------------------

//   static TextStyle price(BuildContext context) => TextStyle(
//         fontFamily: bodyFont,
//         color: AppColors.lightTextPrimary,
//         fontSize: context.h(16),
//         fontWeight: FontWeight.w700,
//       );

//   static TextStyle priceLarge(BuildContext context) => TextStyle(
//         fontFamily: bodyFont,
//         color: AppColors.lightTextPrimary,
//         fontSize: context.h(20),
//         fontWeight: FontWeight.w700,
//       );

//   static TextStyle value(BuildContext context) => TextStyle(
//         fontFamily: bodyFont,
//         color: AppColors.lightTextPrimary,
//         fontSize: context.h(14),
//         fontWeight: FontWeight.w600,
//       );

//   // ---------------------------------------------------------------------------
//   // BADGES / STATUS
//   // ---------------------------------------------------------------------------

//   static TextStyle badge(BuildContext context) => TextStyle(
//         fontFamily: labelFont,
//         color: AppColors.lightTextPrimary,
//         fontSize: context.h(10),
//         fontWeight: FontWeight.w700,
//         letterSpacing: 0.3,
//       );

//   static TextStyle status(BuildContext context) => TextStyle(
//         fontFamily: labelFont,
//         color: AppColors.lightTextPrimary,
//         fontSize: context.h(12),
//         fontWeight: FontWeight.w600,
//       );

//   // ---------------------------------------------------------------------------
//   // FEEDBACK
//   // ---------------------------------------------------------------------------

//   static TextStyle error(BuildContext context) => TextStyle(
//         fontFamily: bodyFont,
//         color: AppColors.danger,
//         fontSize: context.h(12),
//         fontWeight: FontWeight.w500,
//       );

//   static TextStyle success(BuildContext context) => TextStyle(
//         fontFamily: bodyFont,
//         color: AppColors.success,
//         fontSize: context.h(12),
//         fontWeight: FontWeight.w500,
//       );

//   // ---------------------------------------------------------------------------
//   // CAPTIONS
//   // ---------------------------------------------------------------------------

//   static TextStyle caption(BuildContext context) => TextStyle(
//         fontFamily: bodyFont,
//         color: AppColors.lightTextSecondary,
//         fontSize: context.h(12),
//         fontWeight: FontWeight.w400,
//       );

//   static TextStyle captionMuted(BuildContext context) => TextStyle(
//         fontFamily: bodyFont,
//         color: AppColors.lightTextSecondary,
//         fontSize: context.h(11),
//         fontWeight: FontWeight.w400,
//       );

//   // ---------------------------------------------------------------------------
//   // THEME
//   // ---------------------------------------------------------------------------

//   /// Build a ThemeData that uses responsive font sizes.
//   ///
//   /// Call it with a context, e.g. in MaterialApp:
//   ///   theme: AppTextStyles.themeData(context),
//   static ThemeData themeData(BuildContext context) {
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
//           borderRadius: BorderRadius.circular(context.h(12)),
//           side: BorderSide(color: scheme.border),
//         ),
//       ),

//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: scheme.surfaceVariant,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(context.h(8)),
//           borderSide: BorderSide(color: scheme.border),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(context.h(8)),
//           borderSide: BorderSide(color: scheme.border),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(context.h(8)),
//           borderSide: const BorderSide(color: AppColors.primary),
//         ),
//         errorStyle: error(context),
//         hintStyle: inputHint(context),
//         labelStyle: label(context),
//         helperStyle: helper(context),
//         contentPadding: EdgeInsets.symmetric(
//           horizontal: context.w(12),
//           vertical: context.h(12),
//         ),
//       ),

//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: AppColors.primary,
//           foregroundColor: Colors.white,
//           padding: EdgeInsets.symmetric(
//             horizontal: context.w(20),
//             vertical: context.h(14),
//           ),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(context.h(8)),
//           ),
//           textStyle: button(context),
//         ),
//       ),

//       outlinedButtonTheme: OutlinedButtonThemeData(
//         style: OutlinedButton.styleFrom(
//           foregroundColor: scheme.textPrimary,
//           side: BorderSide(color: scheme.border),
//           padding: EdgeInsets.symmetric(
//             horizontal: context.w(20),
//             vertical: context.h(14),
//           ),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(context.h(8)),
//           ),
//           textStyle: buttonSecondary(context),
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
//         displayLarge: display(context),
//         headlineLarge: pageTitle(context),
//         headlineMedium: sectionTitle(context),
//         headlineSmall: subsectionTitle(context),
//         titleLarge: sectionTitle(context),
//         titleMedium: cardTitle(context),
//         titleSmall: componentTitle(context),
//         bodyLarge: body(context),
//         bodyMedium: bodySecondary(context),
//         bodySmall: caption(context),
//         labelLarge: button(context),
//         labelMedium: label(context),
//         labelSmall: metadata(context),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../utils/responsive_size.dart';

class AppTextStyles {
  AppTextStyles._();

  // ---------------------------------------------------------------------------
  // HEADINGS
  // ---------------------------------------------------------------------------

  /// Main page heading.
  static TextStyle heading(BuildContext context) => TextStyle(
        color: AppColors.lightTextPrimary,
        fontSize: context.h(22),
        fontWeight: FontWeight.w700,
      );

  /// Section and card heading.
  static TextStyle section(BuildContext context) => TextStyle(
        color: AppColors.lightTextPrimary,
        fontSize: context.h(17),
        fontWeight: FontWeight.w600,
      );

  // ---------------------------------------------------------------------------
  // BODY
  // ---------------------------------------------------------------------------

  /// Main application text.
  static TextStyle body(BuildContext context) => TextStyle(
        color: AppColors.lightTextPrimary,
        fontSize: context.h(14),
        fontWeight: FontWeight.w400,
      );

  /// Secondary / muted application text.
  static TextStyle bodySecondary(BuildContext context) => TextStyle(
        color: AppColors.lightTextSecondary,
        fontSize: context.h(13),
        fontWeight: FontWeight.w400,
      );

  // ---------------------------------------------------------------------------
  // LABELS
  // ---------------------------------------------------------------------------

  /// Buttons, navigation items and important labels.
  static TextStyle label(BuildContext context) => TextStyle(
        color: AppColors.lightTextPrimary,
        fontSize: context.h(13),
        fontWeight: FontWeight.w600,
      );

  // ---------------------------------------------------------------------------
  // CAPTION
  // ---------------------------------------------------------------------------

  /// Small metadata, helper text and supporting information.
  static TextStyle caption(BuildContext context) => TextStyle(
        color: AppColors.lightTextSecondary,
        fontSize: context.h(11),
        fontWeight: FontWeight.w400,
      );

  // ---------------------------------------------------------------------------
  // THEME
  // ---------------------------------------------------------------------------

  static ThemeData themeData(BuildContext context) {
    final scheme = AppColorScheme.light();
    const brightness = Brightness.light;

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
        shadowColor: AppColors.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.h(12)),
          side: BorderSide(color: scheme.border),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceVariant,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.h(8)),
          borderSide: BorderSide(color: scheme.border),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.h(8)),
          borderSide: BorderSide(color: scheme.border),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.h(8)),
          borderSide: const BorderSide(color: AppColors.primary),
        ),

        errorStyle: caption(context).copyWith(
          color: AppColors.danger,
        ),

        hintStyle: bodySecondary(context),
        labelStyle: label(context),
        helperStyle: caption(context),

        contentPadding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.h(12),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: context.w(20),
            vertical: context.h(14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.h(8)),
          ),
          textStyle: label(context).copyWith(
            color: Colors.white,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.textPrimary,
          side: BorderSide(color: scheme.border),
          padding: EdgeInsets.symmetric(
            horizontal: context.w(20),
            vertical: context.h(14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.h(8)),
          ),
          textStyle: label(context),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.divider,
      ),

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

      textTheme: TextTheme(
        displayLarge: heading(context),
        headlineLarge: heading(context),
        headlineMedium: section(context),
        headlineSmall: section(context),

        titleLarge: section(context),
        titleMedium: section(context),
        titleSmall: label(context),

        bodyLarge: body(context),
        bodyMedium: body(context),
        bodySmall: bodySecondary(context),

        labelLarge: label(context),
        labelMedium: label(context),
        labelSmall: caption(context),
      ),
    );
  }
}