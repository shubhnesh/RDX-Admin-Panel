import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/widgets/rdx_header.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../models/inventory_item_model.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/form_action_button.dart';
import '../../widgets/rdx_text_field.dart';
import '../../widgets/rdx_dropdown.dart';
import '../../widgets/app_back_button.dart';

class AddMaterialScreen extends StatefulWidget {
  final InventoryItemModel? existing;

  const AddMaterialScreen({super.key, this.existing});

  @override
  State<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late final TextEditingController _costCtrl;

  String _category = 'Dry Pantry';
  String _unit = 'Cans / Tins';
  bool _saving = false;

  static const _categories = [
    'Proteins & Meats',
    'Fresh Produce',
    'Dairy & Cold',
    'Dry Pantry',
    'Packaging',
    'Seafood',
    'Other',
  ];

  static const _units = [
    'kg',
    'g',
    'pcs',
    'Cans / Tins',
    'L',
    'ml',
    'box',
    'bag',
  ];

  bool get isEdit => widget.existing != null && widget.existing!.id.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _qtyCtrl =
        TextEditingController(text: e != null ? e.quantity.toString() : '');
    _minCtrl =
        TextEditingController(text: e != null ? e.minRequired.toString() : '');
    _maxCtrl =
        TextEditingController(text: e != null ? e.maxCapacity.toString() : '');
    _costCtrl =
        TextEditingController(text: e != null ? e.unitCost.toString() : '');
    if (e != null) {
      _category = e.category;
      _unit = e.unit;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  double get _previewQty => double.tryParse(_qtyCtrl.text) ?? 0;
  double get _previewMax => double.tryParse(_maxCtrl.text) ?? 0;
  double get _previewMin => double.tryParse(_minCtrl.text) ?? 0;

  StockStatus get _previewStatus {
    if (_previewQty <= 0) return StockStatus.outOfStock;
    if (_previewQty < _previewMin * 0.25) return StockStatus.critical;
    if (_previewQty < _previewMin) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final item = InventoryItemModel(
      id: widget.existing?.id ?? '',
      name: _nameCtrl.text.trim(),
      category: _category,
      quantity: double.tryParse(_qtyCtrl.text) ?? 0,
      minRequired: double.tryParse(_minCtrl.text) ?? 0,
      maxCapacity: double.tryParse(_maxCtrl.text) ?? 0,
      unit: _unit,
      unitCost: double.tryParse(_costCtrl.text) ?? 0,
    );

    try {
      await context.read<InventoryProvider>().saveItem(item);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Material updated' : 'Material added'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save material')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RdxHeader(
            title: isEdit ? 'Edit Material' : 'Add New Material',
            subtitle:
                'Create a new raw ingredient or packaging item in your inventory catalog.',
            showBackButton: true,
            actions: [
              FormActionButton.discard(
                onPressed: () => Navigator.of(context).pop(),
              ),
              SizedBox(width: context.w(10)),
              FormActionButton.save(
                label: 'Save',
                onPressed: _save,
                isLoading: _saving,
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: Responsive.pagePadding(context, top: 16, bottom: 32),
              child: Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1 – Basic info
                    Expanded(
                      child: _SectionCard(
                        title: 'Basic Information & Category',
                        sectionLabel: 'SECTION 1',
                        icon: Icons.badge_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            RdxTextField(
                              controller: _nameCtrl,
                              label: 'MATERIAL NAME *',
                              hint: 'e.g., San Marzano Whole Peeled Tomatoes',
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            // SizedBox(height: context.h(0.5)),
                            Text(
                              'Enter descriptive name recognized by kitchen & receiving staff',
                              style: AppTextStyles.body(context)
                                  .copyWith(color: colors.textMuted),
                            ),
                            SizedBox(height: context.h(16)),
                            Row(
                              children: [
                                Expanded(
                                  child: RdxDropdown<String>(
                                    label: 'CATEGORY *',
                                    value: _category,
                                    items: _categories,
                                    labelBuilder: (s) => s,
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() => _category = v);
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(width: context.w(12)),
                                Expanded(
                                  child: RdxDropdown<String>(
                                    label: 'UNIT OF MEASUREMENT *',
                                    value: _unit,
                                    items: _units,
                                    labelBuilder: (s) => s,
                                    onChanged: (v) {
                                      if (v != null) setState(() => _unit = v);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: context.h(16)),
                            RdxTextField(
                              controller: _costCtrl,
                              label: 'UNIT COST (\$) *',
                              hint: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d.]')),
                              ],
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (double.tryParse(v) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                            // SizedBox(height: context.h(6)),
                            Text(
                              'Direct cost per unit',
                              style: AppTextStyles.body(context)
                                  .copyWith(color: colors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: context.w(20)),
                    // Section 2 – Stock tracking
                    Expanded(
                      child: _SectionCard(
                        title: 'Stock Tracking & Thresholds',
                        sectionLabel: 'SECTION 2',
                        icon: Icons.bar_chart_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: RdxTextField(
                                    controller: _qtyCtrl,
                                    label: 'CURRENT IN-STOCK QUANTITY',
                                    hint: 'e.g., 25.0',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'[\d.]')),
                                    ],
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                SizedBox(width: context.w(12)),
                                Expanded(
                                  child: RdxTextField(
                                    controller: _maxCtrl,
                                    label: 'TOTAL STORAGE CAPACITY',
                                    hint: 'e.g., 50.0',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'[\d.]')),
                                    ],
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: context.h(16)),
                            RdxTextField(
                              controller: _minCtrl,
                              label: 'MIN. REQUIRED LEVEL',
                              hint: 'e.g., 10.0',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d.]')),
                              ],
                              onChanged: (_) => setState(() {}),
                            ),
                            SizedBox(height: context.h(6)),
                            Text(
                              'Restock alert triggers when stock falls below this amount — no confusing PAR terminology',
                              style: AppTextStyles.body(context)
                                  .copyWith(color: colors.textMuted),
                            ),
                            SizedBox(height: context.h(20)),
                            // Live preview
                            Container(
                              padding: EdgeInsets.all(context.h(14)),
                              decoration: BoxDecoration(
                                color: colors.surfaceVariant,
                                borderRadius:
                                    BorderRadius.circular(context.h(10)),
                                border: Border.all(color: colors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'LIVE STOCK PREVIEW',
                                        style:
                                            AppTextStyles.bodySecondary(context)
                                                .copyWith(
                                          color: colors.textMuted,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: context.w(8),
                                            vertical: context.h(3)),
                                        decoration: BoxDecoration(
                                          color: _statusColor(_previewStatus)
                                              .withValues(alpha: 0.14),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _StatusDot(status: _previewStatus),
                                            SizedBox(width: context.w(5)),
                                            Text(
                                              _statusLabel(_previewStatus),
                                              // style: TextStyle(
                                              //   color: _statusColor(
                                              //       _previewStatus),
                                              //   fontSize: context.h(10),
                                              //   fontWeight: FontWeight.w700,
                                              // ),
                                              style:
                                                  AppTextStyles.label(context)
                                                      .copyWith(
                                                color: _statusColor(
                                                    _previewStatus),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: context.h(10)),
                                  Row(
                                    children: [
                                      Text(
                                        'Initial Stock: ${_previewMax > 0 ? ((_previewQty / _previewMax) * 100).toStringAsFixed(0) : 0}%',
                                        style: AppTextStyles.body(context)
                                            .copyWith(
                                                fontWeight: FontWeight.w600),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${_previewQty.toStringAsFixed(1)} / ${_previewMax.toStringAsFixed(1)} $_unit',
                                        style: AppTextStyles.body(context)
                                            .copyWith(color: colors.textMuted),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: context.h(8)),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _previewMax > 0
                                          ? (_previewQty / _previewMax)
                                              .clamp(0.0, 1.0)
                                          : 0,
                                      minHeight: 8,
                                      backgroundColor: colors.border,
                                      valueColor: AlwaysStoppedAnimation(
                                          _statusColor(_previewStatus)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: context.h(12)),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline,
                                    size: 14, color: colors.textMuted),
                                SizedBox(width: context.w(8)),
                                Expanded(
                                  child: Text(
                                    'Status badges (In Stock / Low Stock / Critical) are calculated automatically based on your minimum required level.',
                                    style: AppTextStyles.body(context)
                                        .copyWith(color: colors.textMuted),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(StockStatus s) {
    switch (s) {
      case StockStatus.inStock:
        return AppColors.success;
      case StockStatus.lowStock:
        return AppColors.warning;
      case StockStatus.critical:
      case StockStatus.outOfStock:
        return AppColors.danger;
    }
  }

  String _statusLabel(StockStatus s) {
    switch (s) {
      case StockStatus.inStock:
        return 'In Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.critical:
        return 'Critical';
      case StockStatus.outOfStock:
        return 'Out of Stock';
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String sectionLabel;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.sectionLabel,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: EdgeInsets.all(context.h(20)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(12)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(context.h(6)),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(context.h(6)),
                ),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              SizedBox(width: context.w(10)),
              Expanded(
                child: Text(title, style: AppTextStyles.section(context)),
              ),
              Text(sectionLabel,
                  style: AppTextStyles.label(context)
                      .copyWith(color: colors.textMuted, letterSpacing: 0.8)),
            ],
          ),
          SizedBox(height: context.h(16)),
          child,
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final StockStatus status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (status) {
      case StockStatus.inStock:
        c = AppColors.success;
        break;
      case StockStatus.lowStock:
        c = AppColors.warning;
        break;
      default:
        c = AppColors.danger;
    }
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }
}
