import 'package:flutter/material.dart';

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
  }

  @override
  void dispose() {
    _controller.removeListener(_controllerListener);

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

  void _clear() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final bool hasText = _controller.text.isNotEmpty;

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      padding: widget.padding ??
          const EdgeInsets.symmetric(
            horizontal: 13,
          ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          widget.borderRadius,
        ),
        border: Border.all(
          color: widget.borderColor ?? const Color(0xFF302B2B),
          width: widget.borderWidth,
        ),
      ),
      child: Row(
        children: [
          widget.leading ??
              const Icon(
                Icons.search_rounded,
                size: 19,
                color: Color(0xFFE5BDBB),
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
                  const TextStyle(
                    color: Color(0xFFE5BDBB),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: widget.hintStyle ??
                    TextStyle(
                      color: widget.hintColor ?? const Color(0xFFE5BDBB),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
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
              child: const Padding(
                padding: EdgeInsets.only(
                  left: 8,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Color(0xFF777070),
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
