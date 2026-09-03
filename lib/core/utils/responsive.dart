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
  static EdgeInsets pagePadding(
    BuildContext context, {
    double top = 16,
    double bottom = 32,
  }) {
    final horizontal = pageHorizontal(context);
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
  }

  /// Shared spacing for full-width screen toolbars.
  static EdgeInsets toolbarPadding(BuildContext context) {
    final horizontal = pageHorizontal(context);
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: 10);
  }

  /// Grid columns for cards/menu grids based on available width.
  static int gridColumns(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }
}
