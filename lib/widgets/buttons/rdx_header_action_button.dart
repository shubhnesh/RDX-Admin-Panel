import 'package:flutter/material.dart';

import '../../core/utils/responsive_size.dart';
import 'rdx_action_button.dart';

class RdxHeaderActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  const RdxHeaderActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final width = isMobile
        ? context.w(104).clamp(100.0, 104.0)
        : context.w(130).clamp(112.0, 130.0);
    final height = context.h(isMobile ? 30 : 36).clamp(28.0, 36.0);

    return Tooltip(
      message: label,
      child: SizedBox(
        width: width,
        height: height,
        child: RdxActionButton(
          label: label,
          leadingIcon: icon,
          onPressed: onPressed,
          height: height,
          compact: true,
        ),
      ),
    );
  }
}
