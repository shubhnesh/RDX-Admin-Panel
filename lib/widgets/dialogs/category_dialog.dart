// lib/widgets/dialogs/category_entry_dialog.dart
import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/resuable_options/rdx_text_field.dart';

/// One dialog mechanism for every "create/edit a category value" case in
/// the app: categories, subcategories, preparation styles, regionalities,
/// tags, inventory categories, units — anything that boils down to
/// "type a name (optionally with a list of sub-names), then either hand
/// it back locally or persist it".
///
/// Two usage shapes, both handled by the same class:
///
/// 1. **Local-only** (e.g. preparation/regionality typed inside the menu
///    item form): pass an [onSave] that does NOT call a service — just
///    returns the trimmed name(s) — and the caller decides when to
///    actually persist it.
///
/// 2. **Save-now** (e.g. category, tag, inventory category, unit): pass
///    an [onSave] that calls the relevant `*Service` and returns the
///    created/updated model. The dialog shows its own loading state and
///    surfaces a generic error if [onSave] throws.
///
/// [T] is whatever [onSave] returns — `String`, `CategoryModel`,
/// `UnitModel`, etc. It's popped via `Navigator.pop` as-is.
class CategoryEntryDialog<T> extends StatefulWidget {
  const CategoryEntryDialog({
    super.key,
    required this.title,
    required this.onSave,
    this.editTitle,
    this.nameLabel = 'Name',
    this.nameHint,
    this.description,
    this.initialName,
    this.subItemsLabel,
    this.subItemHintBuilder,
    this.initialSubItems,
    this.maxSubItems = 0,
    this.dialogWidth = 380,
    this.saveButtonLabel,
  });

  /// Heading shown when creating.
  final String title;

  /// Heading shown when editing (i.e. [initialName] was non-null).
  /// Defaults to [title] if omitted.
  final String? editTitle;

  final String nameLabel;
  final String? nameHint;

  /// Optional helper copy shown under the title (create mode only).
  final String? description;

  /// Pre-filled name — presence of this flips the dialog into "edit" mode.
  final String? initialName;

  /// If non-null, a repeatable "sub item" section is shown (used for
  /// category → subcategories). Leave null to get a plain name dialog.
  final List<String>? initialSubItems;
  final int maxSubItems;
  final String? subItemsLabel;
  final String Function(int index)? subItemHintBuilder;

  /// Does the actual work (Firestore call or none) and returns the value
  /// to pop with. Receives the trimmed name and trimmed/non-empty sub
  /// item names (empty list if sub items aren't enabled).
  final Future<T> Function(String name, List<String> subItems) onSave;

  final String? saveButtonLabel;

  final double dialogWidth;

  bool get _hasSubItems => initialSubItems != null;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Future<T> Function(String name, List<String> subItems) onSave,
    String? editTitle,
    String nameLabel = 'Name',
    String? nameHint,
    String? description,
    String? initialName,
    List<String>? initialSubItems,
    int maxSubItems = 0,
    String? subItemsLabel,
    String Function(int index)? subItemHintBuilder,
    String? saveButtonLabel,
    double dialogWidth = 380,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CategoryEntryDialog<T>(
        title: title,
        editTitle: editTitle,
        nameLabel: nameLabel,
        nameHint: nameHint,
        description: description,
        initialName: initialName,
        initialSubItems: initialSubItems,
        maxSubItems: maxSubItems,
        subItemsLabel: subItemsLabel,
        subItemHintBuilder: subItemHintBuilder,
        onSave: onSave,
        saveButtonLabel: saveButtonLabel,
        dialogWidth: dialogWidth,
      ),
    );
  }

  @override
  State<CategoryEntryDialog<T>> createState() => _CategoryEntryDialogState<T>();
}

class _CategoryEntryDialogState<T> extends State<CategoryEntryDialog<T>> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName ?? '');
  late final List<TextEditingController> _subControllers = widget._hasSubItems
      ? (widget.initialSubItems!.isNotEmpty
          ? widget.initialSubItems!
              .map((s) => TextEditingController(text: s))
              .toList()
          : [TextEditingController()])
      : const [];

  bool get _editing => widget.initialName != null;

  bool _saving = false;
  String? _error;

  void _addSubField() {
    if (_subControllers.length >= widget.maxSubItems) return;
    setState(() => _subControllers.add(TextEditingController()));
  }

  void _removeSubField(int index) {
    setState(() {
      _subControllers.removeAt(index).dispose();
      if (_subControllers.isEmpty) _subControllers.add(TextEditingController());
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final subItems = _subControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    try {
      final result = await widget.onSave(_name.text.trim(), subItems);
      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Failed to save. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    for (final c in _subControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.h(12)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.w(widget.dialogWidth)),
        child: Padding(
          padding: EdgeInsets.all(context.h(20)),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editing
                        ? (widget.editTitle ?? widget.title)
                        : widget.title,
                    style: AppTextStyles.section(context)
                        .copyWith(color: colors.textPrimary),
                  ),
                  if (!_editing && widget.description != null) ...[
                    SizedBox(height: context.h(6)),
                    Text(
                      widget.description!,
                      style: AppTextStyles.bodyTertiary(context)
                          .copyWith(color: colors.textMuted),
                    ),
                  ],
                  SizedBox(height: context.h(16)),
                  RdxTextField(
                    controller: _name,
                    label: widget.nameLabel,
                    hint: widget.nameHint ?? 'e.g. ${widget.nameLabel}',
                    onSubmitted: widget._hasSubItems ? null : (_) => _save(),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                  if (widget._hasSubItems) ...[
                    SizedBox(height: context.h(16)),
                    Text(
                      widget.subItemsLabel ??
                          'Sub items (optional, up to ${widget.maxSubItems})',
                      style: AppTextStyles.bodySecondary(context)
                          .copyWith(color: colors.textMuted),
                    ),
                    SizedBox(height: context.h(8)),
                    for (int i = 0; i < _subControllers.length; i++)
                      Padding(
                        padding: EdgeInsets.only(bottom: context.h(10)),
                        child: Row(
                          children: [
                            Expanded(
                              child: RdxTextField(
                                controller: _subControllers[i],
                                hint: widget.subItemHintBuilder?.call(i) ??
                                    'Item ${i + 1}',
                              ),
                            ),
                            SizedBox(width: context.w(8)),
                            InkWell(
                              onTap: () => _removeSubField(i),
                              borderRadius: BorderRadius.circular(context.h(6)),
                              child: Padding(
                                padding: EdgeInsets.all(context.w(4)),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: context.h(18),
                                  color: colors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_subControllers.length < widget.maxSubItems)
                      TextButton.icon(
                        onPressed: _addSubField,
                        icon: Icon(
                          Icons.add_rounded,
                          size: context.h(18),
                          color: AppColors.primary,
                        ),
                        label: Text(
                          'Add item',
                          style: AppTextStyles.label(context)
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                  ],
                  if (_error != null) ...[
                    SizedBox(height: context.h(8)),
                    Text(_error!, style: TextStyle(color: AppColors.danger)),
                  ],
                  SizedBox(height: context.h(18)),
                  Row(
                    children: [
                      Expanded(
                        child: RdxActionButton.save(
                          label: widget.saveButtonLabel ?? 'Save',
                          isLoading: _saving,
                          onPressed: _save,
                        ),
                      ),
                      SizedBox(width: context.w(10)),
                      Expanded(
                        child: RdxActionButton.discard(
                          onPressed:
                              _saving ? null : () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
