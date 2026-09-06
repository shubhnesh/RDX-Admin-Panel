import 'package:flutter/material.dart';
import 'rdx_text_field.dart';

/// Deprecated alias — prefer [RdxTextField].
/// Kept so older imports keep compiling.
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;

  const CustomTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return RdxTextField(
      controller: controller,
      label: label,
      hint: hint,
      maxLines: maxLines,
      keyboardType: keyboardType,
      obscureText: obscureText,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
    );
  }
}
