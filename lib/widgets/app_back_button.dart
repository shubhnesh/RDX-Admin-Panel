import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }
}
