import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive_size.dart';

class RdxSearchBar extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  final VoidCallback? onClear;

  final double? width;
  final double height;

  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  final Widget? leading;
  final Widget? trailing;

  final bool enabled;
  final bool readOnly;
  final bool autofocus;

  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;

  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? hintColor;

  final double borderRadius;
  final double borderWidth;

  final TextStyle? textStyle;
  final TextStyle? hintStyle;

  final bool showClearButton;

  const RdxSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.width,
    this.height = 42,
    this.margin,
    this.padding,
    this.leading,
    this.trailing,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction = TextInputAction.search,
    this.keyboardType,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.hintColor,
    this.borderRadius = 10,
    this.borderWidth = 1,
    this.textStyle,
    this.hintStyle,
    this.showClearButton = true,
  });

  @override
  State<RdxSearchBar> createState() => _RdxSearchBarState();
}

/// Shared page toolbar that keeps search and page actions in a stable layout.
class RdxSearchToolbar extends StatelessWidget implements PreferredSizeWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final List<Widget> actions;
  final EdgeInsetsGeometry? padding;

  const RdxSearchToolbar({
    super.key,
    this.hintText = 'Search...',
    this.controller,
    this.onChanged,
    this.actions = const [],
    EdgeInsetsGeometry? padding,
  }) : padding = padding;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: preferredSize.height,
      child: Padding(
        padding: padding ?? Responsive.toolbarPadding(context),
        child: Row(
          children: [
            Expanded(
              child: RdxSearchBar(
                height: 44,
                hintText: hintText,
                controller: controller,
                onChanged: onChanged,
              ),
            ),
            for (final action in actions) ...[
              const SizedBox(width: 14),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

class _RdxSearchBarState extends State<RdxSearchBar> {
  late final TextEditingController _internalController;
  late final FocusNode _internalFocusNode;

  bool _ownsController = false;
  bool _ownsFocusNode = false;

  TextEditingController get _controller =>
      widget.controller ?? _internalController;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();

    if (widget.controller == null) {
      _internalController = TextEditingController();
      _ownsController = true;
    } else {
      _internalController = widget.controller!;
    }

    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
      _ownsFocusNode = true;
    } else {
      _internalFocusNode = widget.focusNode!;
    }

    _controller.addListener(_controllerListener);
    _focusNode.addListener(_focusListener);
  }

  @override
  void dispose() {
    _controller.removeListener(_controllerListener);
    _focusNode.removeListener(_focusListener);

    if (_ownsController) {
      _internalController.dispose();
    }

    if (_ownsFocusNode) {
      _internalFocusNode.dispose();
    }

    super.dispose();
  }

  void _controllerListener() {
    if (mounted) {
      setState(() {});
    }
  }

  void _focusListener() {
    if (mounted) setState(() {});
  }

  void _clear() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final bool hasText = _controller.text.isNotEmpty;
    final colors = AppColors.of(context);
    final focused = _focusNode.hasFocus;

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      padding: widget.padding ??
          const EdgeInsets.symmetric(
            horizontal: 13,
          ),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? colors.surface,
        borderRadius: BorderRadius.circular(
          widget.borderRadius,
        ),
        border: Border.all(
          color: widget.borderColor ??
              (focused ? AppColors.primary : colors.border),
          width: focused ? 1.4 : widget.borderWidth,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          widget.leading ??
              Icon(
                Icons.search_rounded,
                size: 19,
                color: widget.hintColor ?? colors.textMuted,
              ),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              autofocus: widget.autofocus,
              textInputAction: widget.textInputAction,
              keyboardType: widget.keyboardType,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              style: widget.textStyle ??
                  AppTextStyles.bodySecondary(context).copyWith(
                    color: widget.textColor ?? colors.textPrimary,
                  ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: widget.hintStyle ??
                    AppTextStyles.bodySecondary(context).copyWith(
                      color: widget.hintColor ?? colors.textMuted,
                    ),

                // No background inside the TextField.
                filled: false,
                fillColor: Colors.transparent,

                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,

                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.showClearButton && hasText)
            GestureDetector(
              onTap: _clear,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 8,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: colors.textMuted,
                ),
              ),
            ),
          if (widget.trailing != null) ...[
            const SizedBox(width: 8),
            widget.trailing!,
          ],
        ],
      ),
    );
  }
}
