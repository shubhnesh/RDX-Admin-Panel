import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';

class AppBackButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const AppBackButton({super.key, this.onPressed});

  @override
  State<AppBackButton> createState() => _AppBackButtonState();
}

class _AppBackButtonState extends State<AppBackButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed ?? () => Navigator.of(context).maybePop(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: context.h(36),
          height: context.h(36),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hovering ? AppColors.primary : colors.surface,
            border: Border.all(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.arrow_back,
            size: 18,
            color: _hovering ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}