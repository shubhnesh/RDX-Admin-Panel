import 'package:flutter/material.dart';

/// Responsive sizing extensions based on the app's mobile design dimensions.
extension ResponsiveSize on BuildContext {
  /// Returns a value scaled against the design height of 812 logical pixels.
  double h(double value) {
    final height = MediaQuery.sizeOf(this).height;
    return value * (height / 812);
  }

  /// Returns a value scaled against the design width of 375 logical pixels.
  double w(double value) {
    final width = MediaQuery.sizeOf(this).width;
    final scale = (width / 375).clamp(0.8, 1.0);
    return value * scale;
  }

  /// Standard screen padding: 10 responsive vertical and 20 horizontal.
  EdgeInsets defaultScreenPadding() {
    return EdgeInsets.symmetric(
      vertical: h(10),
      horizontal: w(20),
    );
  }
}
