import 'package:flutter/material.dart';

/// Responsive sizing utilities replacing the old `responsive.dart`.
///
/// Provides:
/// - [Responsive] static helpers (breakpoints, padding, grid columns)
/// - BuildContext extensions: [w], [h], [defaultScreenPadding]
class Responsive {
  Responsive._();

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1100;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  /// Grid column count for card grids (menu, coupons, etc.).
  static int gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    return 4;
  }

  /// Horizontal page inset that scales with width.
  static double pageHorizontal(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return 16;
    if (width < 1100) return 24;
    return 32;
  }

  /// Standard page padding. Optional [top] / [bottom] overrides.
  static EdgeInsets pagePadding(
    BuildContext context, {
    double? top,
    double? bottom,
  }) {
    final horizontal = pageHorizontal(context);
    return EdgeInsets.fromLTRB(
      horizontal,
      top ?? 16,
      horizontal,
      bottom ?? 16,
    );
  }

  /// Padding used by search toolbars.
  static EdgeInsets toolbarPadding(BuildContext context) {
    final horizontal = pageHorizontal(context);
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: 10);
  }
}

extension ResponsiveContext on BuildContext {
  /// Scale a design-width value to the current screen width.
  /// Design reference width = 1440.
  double w(double size) {
    final screenWidth = MediaQuery.sizeOf(this).width;
    final scale = (screenWidth / 1440).clamp(0.65, 1.25);
    return size * scale;
  }

  /// Scale a design-height value to the current screen height.
  /// Design reference height = 900.
  double h(double size) {
    final screenHeight = MediaQuery.sizeOf(this).height;
    final scale = (screenHeight / 900).clamp(0.65, 1.25);
    return size * scale;
  }

  /// Convenience alias for [Responsive.pagePadding].
  EdgeInsets defaultScreenPadding() => Responsive.pagePadding(this);
}
