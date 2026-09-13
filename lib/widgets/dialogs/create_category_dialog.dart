import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/category_model.dart';
import 'package:rdx_admin/services/category_service.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/resuable_options/rdx_text_field.dart';

/// Dialog matching the app's theme for creating or editing a category,
/// with an optional set of up to [CategoryService.maxSubcategories]
/// subcategories.
///
/// Returns the created/updated [CategoryModel] via `Navigator.pop`, or
/// null if the user cancels. Pass [existing] to edit that category in
/// place (same ID, name/subcategories updated immediately).
class CreateCategoryDialog extends StatefulWidget {
  const CreateCategoryDialog({super.key, this.existing});

  final CategoryModel? existing;

  static Future<CategoryModel?> show(
    BuildContext context, {
    CategoryModel? existing,
  }) {
    return showDialog<CategoryModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateCategoryDialog(existing: existing),
    );
  }

  @override
  State<CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<CreateCategoryDialog> {
  static const _maxSubcategories = CategoryService.maxSubcategories;

  final _formKey = GlobalKey<FormState>();
  late final _categoryName =
      TextEditingController(text: widget.existing?.name ?? '');
  late final List<TextEditingController> _subcategoryControllers = widget
              .existing?.subcategories.isNotEmpty ==
          true
      ? widget.existing!.subcategories
          .map((sub) => TextEditingController(text: sub.name))
          .toList()
      : [TextEditingController()];
  final _service = CategoryService();

  bool get _editing => widget.existing != null;

  bool _saving = false;
  String? _error;

  void _addSubcategoryField() {
    if (_subcategoryControllers.length >= _maxSubcategories) return;
    setState(() => _subcategoryControllers.add(TextEditingController()));
  }

  void _removeSubcategoryField(int index) {
    setState(() {
      _subcategoryControllers.removeAt(index).dispose();
      if (_subcategoryControllers.isEmpty) {
        _subcategoryControllers.add(TextEditingController());
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final subcategoryNames = _subcategoryControllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    try {
      if (_editing) {
        final existing = widget.existing!;
        final updated = CategoryModel(
          id: existing.id,
          name: _categoryName.text.trim(),
          subcategories: [
            for (final subName in subcategoryNames)
              SubcategoryModel(
                id: '${existing.id}-${subName.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}',
                name: subName,
              ),
          ],
        );
        await _service.updateCategory(updated);

        if (!mounted) return;
        Navigator.pop(context, updated);
        return;
      }

      final id = await _service.createCategory(
        name: _categoryName.text.trim(),
        subcategoryNames: subcategoryNames,
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        CategoryModel(
          id: id,
          name: _categoryName.text.trim(),
          subcategories: [
            for (final subName in subcategoryNames)
              SubcategoryModel(id: subName, name: subName),
          ],
        ),
      );
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'Failed to save category. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _categoryName.dispose();
    for (final controller in _subcategoryControllers) {
      controller.dispose();
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
        constraints: BoxConstraints(maxWidth: context.w(420)),
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
                    _editing ? 'Edit Category' : 'Create Category',
                    style: AppTextStyles.section(context)
                        .copyWith(color: colors.textPrimary),
                  ),
                  SizedBox(height: context.h(16)),
                  RdxTextField(
                    controller: _categoryName,
                    label: 'Category Name *',
                    hint: 'e.g. Beverages',
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                  SizedBox(height: context.h(16)),
                  Text(
                    'Subcategories (optional, up to $_maxSubcategories)',
                    style: AppTextStyles.bodySecondary(context)
                        .copyWith(color: colors.textMuted),
                  ),
                  SizedBox(height: context.h(8)),
                  for (int i = 0; i < _subcategoryControllers.length; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: context.h(10)),
                      child: Row(
                        children: [
                          Expanded(
                            child: RdxTextField(
                              controller: _subcategoryControllers[i],
                              hint: 'Subcategory ${i + 1}',
                            ),
                          ),
                          SizedBox(width: context.w(8)),
                          InkWell(
                            onTap: () => _removeSubcategoryField(i),
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
                  if (_subcategoryControllers.length < _maxSubcategories)
                    TextButton.icon(
                      onPressed: _addSubcategoryField,
                      icon: Icon(
                        Icons.add_rounded,
                        size: context.h(18),
                        color: AppColors.primary,
                      ),
                      label: Text(
                        'Add subcategory',
                        style: AppTextStyles.label(context)
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  if (_error != null) ...[
                    SizedBox(height: context.h(8)),
                    Text(_error!, style: TextStyle(color: AppColors.danger)),
                  ],
                  SizedBox(height: context.h(18)),
                  Row(
                    children: [
                      Expanded(
                        child: RdxActionButton.save(
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
