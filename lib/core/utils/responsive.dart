import 'package:flutter/material.dart';

/// Simple responsive helpers for the admin panel (primarily desktop/tablet,
/// but should degrade sensibly on smaller screens).
class Responsive {
  Responsive._();

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 700;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 700 && width < 1100;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  /// Shared horizontal rhythm for screen content.
  static double pageHorizontal(BuildContext context) {
    if (isMobile(context)) return 16;
    if (isTablet(context)) return 20;
    return 24;
  }

  /// Shared outer spacing for screen content.
  /// Uses context.h() for vertical and context.w() for horizontal.
  static EdgeInsets pagePadding(
    BuildContext context, {
    double? top,
    double? bottom,
  }) {
    final horizontal = context.w(40); // standard side padding
    return EdgeInsets.fromLTRB(
      horizontal,
      top ?? context.h(10), // standard top gap under app bar
      horizontal,
      bottom ?? context.h(32),
    );
  }

  /// Shared spacing for full-width screen toolbars.
  static EdgeInsets toolbarPadding(BuildContext context) {
    final horizontal = context.w(40);
    return EdgeInsets.symmetric(
      horizontal: horizontal,
      vertical: context.h(10),
    );
  }

  /// Grid columns for cards/menu grids based on available width.
  static int gridColumns(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }
}

/// Extension so you can write:
///   context.h(10)  → responsive vertical value
///   context.w(40)  → responsive horizontal value
extension ResponsiveContext on BuildContext {
  /// Vertical scale based on design height (812).
  /// Example: context.h(10) ≈ 10 logical pixels on a 812-tall design.
  double h(double value) {
    final height = MediaQuery.sizeOf(this).height;
    return value * (height / 812);
  }

  /// Horizontal scale based on design width (375 for mobile baseline).
  /// Example: context.w(40) ≈ 40 logical pixels on a 375-wide design.
  double w(double value) {
    final width = MediaQuery.sizeOf(this).width;
    // Clamp so desktop doesn't get huge side padding
    final scaled = value * (width / 375);
    if (width >= 1100) return value.clamp(16, 40); // keep desktop sides reasonable
    if (width >= 700) return scaled.clamp(16, 32);
    return scaled.clamp(12, 24);
  }
}