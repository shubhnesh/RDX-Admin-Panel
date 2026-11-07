import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import 'rdx_text_field.dart';

/// Shared search field used across Inventory, Menu, Coupons, and elsewhere.
///
/// Visually identical to [RdxTextField]: same height, same padding, same
/// radius, same border, same fill behaviour (grey when idle, white when
/// focused / has text), same font size and same text/hint placement.
/// The only differences are the leading search icon and the clear button.
class RdxSearchBar extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  final VoidCallback? onClear;

  final double? width;

  /// Optional override. Defaults to [RdxTextField.singleLineHeight].
  final double? height;

  final EdgeInsetsGeometry? margin;

  /// Optional override of the inner content padding. Defaults to the same
  /// padding [RdxTextField] uses.
  final EdgeInsetsGeometry? padding;

  final Widget? leading;
  final Widget? trailing;

  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLength;

  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;

  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? hintColor;

  /// Null = same radius as [RdxTextField].
  final double? borderRadius;
  final double borderWidth;

  final TextStyle? textStyle;
  final TextStyle? hintStyle;

  final bool showClearButton;

  /// Canonical height — exactly the same as a single-line [RdxTextField].
  static double standardHeight(BuildContext context) =>
      RdxTextField.singleLineHeight(context);

  const RdxSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.leading,
    this.trailing,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLength,
    this.focusNode,
    this.textInputAction = TextInputAction.search,
    this.keyboardType,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.hintColor,
    this.borderRadius,
    this.borderWidth = 1,
    this.textStyle,
    this.hintStyle,
    this.showClearButton = true,
  });

  @override
  State<RdxSearchBar> createState() => _RdxSearchBarState();
}

/// Shared page toolbar: search + optional trailing actions.
/// Always uses [RdxSearchBar.standardHeight] so Menu/Coupons match Inventory.
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
    this.padding,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 480;
    final searchHeight = RdxSearchBar.standardHeight(context);
    final search = RdxSearchBar(
      height: searchHeight,
      hintText: hintText,
      controller: controller,
      onChanged: onChanged,
    );

    if (narrow && actions.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          search,
          SizedBox(height: context.h(10)),
          Wrap(
            spacing: context.w(10),
            runSpacing: context.h(8),
            alignment: WrapAlignment.end,
            children: [
              for (final action in actions)
                SizedBox(height: searchHeight, child: action),
            ],
          ),
        ],
      );
    }

    return SizedBox(
      height: searchHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: search),
          for (final action in actions) ...[
            SizedBox(width: context.w(14)),
            SizedBox(height: searchHeight, child: action),
          ],
        ],
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

    if (_ownsController) _internalController.dispose();
    if (_ownsFocusNode) _internalFocusNode.dispose();

    super.dispose();
  }

  void _controllerListener() {
    if (mounted) setState(() {});
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
    final colors = AppColors.of(context);
    final hasText = _controller.text.isNotEmpty;

    // ---- Same sizing tokens as RdxTextField -------------------------------
    final hPad = RdxTextField.horizontalPad(context);
    final vPad = RdxTextField.verticalPad(context);
    final textFontSize = RdxTextField.textFontSize(context);
    final radius = BorderRadius.circular(
      widget.borderRadius ?? context.h(8).clamp(6.0, 8.0),
    );
    final fieldHeight = widget.height ?? RdxTextField.singleLineHeight(context);

    // ---- Same text styles as RdxTextField ---------------------------------
    final textStyle = widget.textStyle ??
        AppTextStyles.bodySecondary(context).copyWith(
          fontSize: textFontSize,
          color: widget.textColor,
        );
    final hintStyle = widget.hintStyle ??
        AppTextStyles.bodySecondary(context).copyWith(
          color: widget.hintColor ?? colors.textMuted,
          fontSize: textFontSize,
        );

    // ---- Same border / fill behaviour as RdxTextField ---------------------
    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: widget.borderColor ?? colors.border,
        width: widget.borderWidth,
      ),
    );

    final fillColor = widget.backgroundColor ??
        (_focusNode.hasFocus || hasText ? Colors.white : colors.surfaceVariant);

    final iconColor = widget.hintColor ?? colors.textMuted;

    // ---- Prefix (search icon) --------------------------------------------
    final prefix = Padding(
      padding: EdgeInsets.only(left: hPad, right: context.w(8)),
      child: widget.leading ??
          Icon(
            Icons.search_rounded,
            size: context.h(20).clamp(14.0, 20.0),
            color: iconColor,
          ),
    );

    // ---- Suffix (clear button + optional trailing) ------------------------
    final showClear = widget.showClearButton && hasText;
    final hasSuffix = showClear || widget.trailing != null;

    final Widget? suffix = hasSuffix
        ? Padding(
            padding: EdgeInsets.only(right: hPad),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showClear)
                  GestureDetector(
                    onTap: _clear,
                    behavior: HitTestBehavior.opaque,
                    child: Icon(
                      Icons.close_rounded,
                      size: context.h(18).clamp(14.0, 18.0),
                      color: iconColor,
                    ),
                  ),
                if (showClear && widget.trailing != null)
                  SizedBox(width: context.w(6)),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          )
        : null;

    return Container(
      margin: widget.margin,
      width: widget.width,
      height: fieldHeight,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autofocus: widget.autofocus,
        maxLength: widget.maxLength,
        textInputAction: widget.textInputAction,
        keyboardType: widget.keyboardType,
        maxLines: 1,
        textAlignVertical: TextAlignVertical.center,
        style: textStyle,
        cursorColor: AppColors.primary,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: hintStyle,
          prefixIcon: prefix,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          suffixIcon: suffix,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          counterText: '',
          filled: true,
          fillColor: fillColor,
          hoverColor: Colors.transparent,
          isDense: true,
          // Left/right padding is handled by the prefix/suffix widgets, so
          // only keep horizontal padding when there is no icon on that side.
          contentPadding: widget.padding ??
              EdgeInsets.symmetric(
                horizontal: 0,
                vertical: vPad,
              ),
          border: border,
          enabledBorder: border,
          disabledBorder: border,
          focusedBorder: border,
          errorBorder: border,
          focusedErrorBorder: border,
        ),
      ),
    );
  }
}
