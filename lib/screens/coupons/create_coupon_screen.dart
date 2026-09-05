import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/coupon_model.dart';
import '../../providers/coupon_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/rdx_header.dart';

class CreateCouponScreen extends StatefulWidget {
  const CreateCouponScreen({super.key});

  @override
  State<CreateCouponScreen> createState() => _CreateCouponScreenState();
}

class _CreateCouponScreenState extends State<CreateCouponScreen> {
  final codeController = TextEditingController();
  final descriptionController = TextEditingController();
  final discountValueController = TextEditingController();
  final minOrderController = TextEditingController();
  final usageLimitController = TextEditingController();

  DiscountType discountType = DiscountType.percentage;
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 30));
  bool isLoading = false;
  String? errorMessage;

  static const _categories = ['All Menu', 'Main Courses', 'Beverages'];
  final Set<String> _selectedCategories = {'All Menu'};

  @override
  void initState() {
    super.initState();
    for (final c in [
      codeController,
      descriptionController,
      discountValueController,
      minOrderController,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  Future<void> _save() async {
    if (codeController.text.trim().isEmpty ||
        double.tryParse(discountValueController.text.trim()) == null) {
      setState(() => errorMessage =
          'Please enter a coupon code and a valid discount value.');
      return;
    }

    final coupon = CouponModel(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      code: codeController.text.trim().toUpperCase(),
      description: descriptionController.text.trim(),
      discountType: discountType,
      discountValue: double.parse(discountValueController.text.trim()),
      minOrderValue: double.tryParse(minOrderController.text.trim()),
      usageLimit: int.tryParse(usageLimitController.text.trim()),
      startDate: startDate,
      endDate: endDate,
      status: startDate.isAfter(DateTime.now())
          ? CouponStatus.scheduled
          : CouponStatus.active,
    );

    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    final success = await context.read<CouponProvider>().createCoupon(coupon);
    if (!mounted) return;
    setState(() => isLoading = false);
    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() => errorMessage = 'Failed to create coupon.');
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    descriptionController.dispose();
    discountValueController.dispose();
    minOrderController.dispose();
    usageLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: const RdxHeader(title: 'Create New Coupon'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final form = _formContent(context, colors);
          final preview = _LivePreviewCard(
            code: codeController.text.trim().isEmpty
                ? 'SUMMER50'
                : codeController.text.trim().toUpperCase(),
            discountType: discountType,
            discountValue:
                double.tryParse(discountValueController.text.trim()) ?? 50,
            minOrder: double.tryParse(minOrderController.text.trim()),
            isActive: !startDate.isAfter(DateTime.now()),
          );

          // ── Narrow (mobile / tablet) ───────────────────────────────
          if (narrow) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                Responsive.pageHorizontal(context),
                16,
                Responsive.pageHorizontal(context),
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  form,
                  const SizedBox(height: 20),
                  preview,
                  const SizedBox(height: 20),
                  _actionButtons(),
                ],
              ),
            );
          }

          // ── Wide (desktop) ─────────────────────────────────────────
          return Padding(
            padding: EdgeInsets.fromLTRB(
              Responsive.pageHorizontal(context),
              16,
              Responsive.pageHorizontal(context),
              24,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(right: 22),
                    child: form,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: colors.border,
                ),
                SizedBox(
                  width: 330,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        preview,
                        const Spacer(),
                        _actionButtons(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _formContent(BuildContext context, AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.danger.withOpacity(0.4)),
            ),
            child: Text(
              errorMessage!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
          const SizedBox(height: 16),
        ],
        _sectionCard(
          context,
          icon: Icons.local_offer_outlined,
          title: 'Coupon Basics',
          children: [
            CustomTextField(
              controller: codeController,
              label: 'Coupon Code',
              hint: 'e.g. SUMMER50',
            ),
            const SizedBox(height: 4),
            Text(
              'Customers will enter this code at checkout.',
              style: AppTextStyles.label.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: descriptionController,
              label: 'Description',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _discountTypeDropdown(colors)),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: discountValueController,
                    label: 'Discount Value',
                    hint: discountType == DiscountType.percentage
                        ? '0-100'
                        : '0.00',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionCard(
          context,
          icon: Icons.rule_folder_outlined,
          title: 'Usage Rules',
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: minOrderController,
                    label: 'Min. Order Value (₹)',
                    hint: '0.00',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: usageLimitController,
                    label: 'Usage Limit',
                    hint: 'Unlimited',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date',
                        style: AppTextStyles.label
                            .copyWith(color: colors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      _datePickerField(
                          startDate, (d) => setState(() => startDate = d)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expiry Date',
                        style: AppTextStyles.label
                            .copyWith(color: colors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      _datePickerField(
                          endDate, (d) => setState(() => endDate = d)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Applicable Categories',
              style:
                  AppTextStyles.label.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final selected = _selectedCategories.contains(cat);
                return FilterChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (v) => setState(() => v
                      ? _selectedCategories.add(cat)
                      : _selectedCategories.remove(cat)),
                  backgroundColor: colors.surfaceVariant,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color:
                        selected ? AppColors.primary : colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.primary : colors.border,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButtons() => Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Discard'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomButton(
              label: 'Save Coupon',
              icon: Icons.save_outlined,
              isLoading: isLoading,
              onPressed: _save,
            ),
          ),
        ],
      );

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.h2.copyWith(color: colors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _discountTypeDropdown(AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discount Type',
          style: AppTextStyles.label.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<DiscountType>(
          value: discountType,
          dropdownColor: colors.surface,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          items: const [
            DropdownMenuItem(
              value: DiscountType.percentage,
              child: Text('Percentage (%)'),
            ),
            DropdownMenuItem(
              value: DiscountType.flat,
              child: Text('Flat Amount (₹)'),
            ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => discountType = v);
          },
        ),
      ],
    );
  }

  Widget _datePickerField(DateTime date, ValueChanged<DateTime> onPick) {
    return Builder(builder: (context) {
      final colors = AppColors.of(context);
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2024),
            lastDate: DateTime(2030),
          );
          if (picked != null) onPick(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: colors.textMuted),
              const SizedBox(width: 8),
              Text(
                Formatters.date(date),
                style: TextStyle(color: colors.textPrimary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _LivePreviewCard extends StatelessWidget {
  final String code;
  final DiscountType discountType;
  final double discountValue;
  final double? minOrder;
  final bool isActive;

  const _LivePreviewCard({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrder,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_outlined,
                  size: 16, color: colors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Preview',
                style: AppTextStyles.h2
                    .copyWith(color: colors.textPrimary, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'ACTIVE' : 'SCHEDULED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  discountType == DiscountType.percentage
                      ? '${discountValue.toStringAsFixed(0)}%'
                      : Formatters.currency(discountValue),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Off your next order',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 15, color: colors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    minOrder != null && minOrder! > 0
                        ? 'This preview shows how the coupon will appear to end-users. Minimum order: ${Formatters.currency(minOrder!)}.'
                        : 'This preview shows how the coupon will appear to end-users in the RDX delivery app.',
                    style: AppTextStyles.label
                        .copyWith(color: colors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}