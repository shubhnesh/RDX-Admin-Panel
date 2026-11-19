import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/responsive_size.dart';
import 'app_colors.dart';

/// Limited, intentional text styles for the whole Ops Center.
///
/// Uses **Inter** — the standard for professional SaaS / admin UIs.
/// Neutral, highly legible, restrained hierarchy. No decorative geometry.
///
/// Rules:
/// - Do NOT change fontSize or fontWeight with copyWith.
/// - Color (and letterSpacing / height when needed) may be overridden with
///   copyWith.
/// - Default colours are theme-aware, so they work in light and dark mode.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base(
    BuildContext context, {
    required double fontSize,
    required FontWeight weight,
    required Color Function(AppColorScheme c) color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: weight,
      color: color(AppColors.of(context)),
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ── Headings ────────────────────────────────────────────────────────────
  /// Hero / large screen titles (e.g. “Welcome”, “Ops Center”)
  static TextStyle h1(BuildContext context) => _base(
        context,
        fontSize: context.h(28),
        weight: FontWeight.w600,
        color: (c) => c.textPrimary,
        height: 1.2,
        letterSpacing: -0.4,
      );

  /// Page titles / brand text (e.g. “Coupons & Offers”, “RDX”)
  static TextStyle h2(BuildContext context) => _base(
        context,
        fontSize: context.h(20),
        weight: FontWeight.w600,
        color: (c) => c.textPrimary,
        height: 1.25,
        letterSpacing: -0.3,
      );

  /// Prominent values (e.g. discount amount on a promotion card)
  static TextStyle h3(BuildContext context) => _base(
        context,
        fontSize: context.h(16),
        weight: FontWeight.w600,
        color: (c) => c.textPrimary,
        height: 1.3,
        letterSpacing: -0.15,
      );

  // ── Body ────────────────────────────────────────────────────────────────
  /// Emphasized body: card / section titles, item titles, empty-state titles
  static TextStyle bodyLargeSemi(BuildContext context) => _base(
        context,
        fontSize: context.h(15),
        weight: FontWeight.w500,
        color: (c) => c.textPrimary,
        height: 1.4,
        letterSpacing: -0.1,
      );

  /// Large readable body (e.g. brand tagline)
  static TextStyle bodyLarge(BuildContext context) => _base(
        context,
        fontSize: context.h(15),
        weight: FontWeight.w400,
        color: (c) => c.textPrimary,
        height: 1.5,
      );

  /// Default secondary body text, descriptions, helper text
  static TextStyle body(BuildContext context) => _base(
        context,
        fontSize: context.h(13.5),
        weight: FontWeight.w400,
        color: (c) => c.textSecondary,
        height: 1.5,
      );

  /// Emphasized body (form labels, links, key labels)
  static TextStyle bodySemi(BuildContext context) => _base(
        context,
        fontSize: context.h(13.5),
        weight: FontWeight.w500,
        color: (c) => c.textPrimary,
        height: 1.4,
      );

  /// Captions, meta lines (e.g. min. order, date ranges)
  static TextStyle bodySmall(BuildContext context) => _base(
        context,
        fontSize: context.h(12),
        weight: FontWeight.w400,
        color: (c) => c.textSecondary,
        height: 1.4,
      );

  /// Emphasized small text (“Copy”, small values)
  static TextStyle bodySmallSemi(BuildContext context) => _base(
        context,
        fontSize: context.h(12),
        weight: FontWeight.w500,
        color: (c) => c.textPrimary,
        height: 1.35,
      );

  /// Chip / pill / status text
  static TextStyle caption(BuildContext context) => _base(
        context,
        fontSize: context.h(11),
        weight: FontWeight.w500,
        color: (c) => c.textMuted,
        height: 1.3,
        letterSpacing: 0.2,
      );

  /// Tiny badge / overline text (urgency pills, footers)
  static TextStyle overline(BuildContext context) => _base(
        context,
        fontSize: context.h(10),
        weight: FontWeight.w500,
        color: (c) => c.textMuted,
        height: 1.2,
        letterSpacing: 0.5,
      );

  // ── Legacy aliases ──────────────────────────────────────────────────────
  @Deprecated('Use h2')
  static TextStyle heading(BuildContext context) => h2(context);

  @Deprecated('Use bodyLargeSemi')
  static TextStyle section(BuildContext context) => bodyLargeSemi(context);

  @Deprecated('Use body')
  static TextStyle bodySecondary(BuildContext context) => body(context);

  @Deprecated('Use bodySmall')
  static TextStyle bodyTertiary(BuildContext context) => bodySmall(context);

  @Deprecated('Use bodySemi')
  static TextStyle label(BuildContext context) => bodySemi(context);
}
