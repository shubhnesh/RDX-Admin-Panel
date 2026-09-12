import 'package:flutter/material.dart';

/// Responsive sizing utilities for the RDX Admin app.
///
/// Breakpoints:
/// - mobile:  < 600
/// - tablet:  600 – 1099
/// - desktop: ≥ 1100
///
/// Use [isNarrow] for "stack into a column" decisions (anything under 900).
class Responsive {
  Responsive._();

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1100;
  static const double narrowBreakpoint = 900;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  /// True when the layout should collapse into a single column (phone + small tablet).
  static bool isNarrow(BuildContext context) =>
      MediaQuery.sizeOf(context).width < narrowBreakpoint;

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
    if (width < 600) return 12;
    if (width < 1100) return 20;
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

  /// Builds a responsive row that becomes a column on narrow screens.
  /// Each child is expanded equally when in a row.
  static Widget adaptiveRow({
    required BuildContext context,
    required List<Widget> children,
    double spacing = 12,
    double runSpacing = 12,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    bool forceColumn = false,
  }) {
    final narrow = forceColumn || isNarrow(context);
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: mainAxisAlignment,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: runSpacing),
            children[i],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(child: children[i]),
        ],
      ],
    );
  }

  /// Same as [adaptiveRow] but children keep their intrinsic width (not Expanded).
  static Widget adaptiveRowIntrinsic({
    required BuildContext context,
    required List<Widget> children,
    double spacing = 12,
    double runSpacing = 12,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    bool forceColumn = false,
  }) {
    final narrow = forceColumn || isNarrow(context);
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: mainAxisAlignment,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: runSpacing),
            children[i],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          children[i],
        ],
      ],
    );
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

  bool get isNarrow => Responsive.isNarrow(this);
  bool get isMobile => Responsive.isMobile(this);
  bool get isDesktop => Responsive.isDesktop(this);
}
