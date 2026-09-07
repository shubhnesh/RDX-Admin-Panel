import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/coupon_model.dart';
import '../../providers/coupon_provider.dart';
import '../../widgets/form_action_button.dart';
import '../../widgets/rdx_dropdown.dart';
import '../../widgets/rdx_text_field.dart';
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
  DateTime? startDate;
  DateTime? endDate;
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
        double.tryParse(discountValueController.text.trim()) == null ||
        startDate == null ||
        endDate == null) {
      setState(() => errorMessage =
          'Please enter a coupon code, valid discount value, start date, and expiry date.');
      return;
    }
    if (endDate!.isBefore(startDate!)) {
      setState(
          () => errorMessage = 'Expiry date must be after the start date.');
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
      startDate: startDate!,
      endDate: endDate!,
      status: startDate!.isAfter(DateTime.now())
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
            isActive: startDate != null && !startDate!.isAfter(DateTime.now()),
          );

          // ── Narrow (mobile / tablet) ───────────────────────────────
          if (narrow) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                Responsive.pageHorizontal(context),
                context.h(16),
                Responsive.pageHorizontal(context),
                context.h(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  form,
                  SizedBox(height: context.h(20)),
                  preview,
                  SizedBox(height: context.h(20)),
                  _actionButtons(context),
                ],
              ),
            );
          }

          // ── Wide (desktop) ─────────────────────────────────────────
          return Padding(
            padding: EdgeInsets.fromLTRB(
              Responsive.pageHorizontal(context),
              context.h(16),
              Responsive.pageHorizontal(context),
              context.h(24),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(right: context.w(22)),
                    child: form,
                  ),
                ),
                VerticalDivider(
                  width: context.w(1),
                  thickness: context.h(1),
                  color: colors.border,
                ),
                SizedBox(
                  width: context.w(330),
                  child: Padding(
                    padding: EdgeInsets.only(left: context.w(22)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        preview,
                        const Spacer(),
                        _actionButtons(context),
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
            padding: EdgeInsets.symmetric(
              horizontal: context.w(12),
              vertical: context.h(10),
            ),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.h(8)),
              border: Border.all(color: AppColors.danger.withOpacity(0.4)),
            ),
            child: Text(
              errorMessage!,
              // style: TextStyle(
              //   color: AppColors.danger,
              //   fontSize: context.h(13),
              // ),
              style:
                  AppTextStyles.body(context).copyWith(color: AppColors.danger),
            ),
          ),
          SizedBox(height: context.h(16)),
        ],
        _sectionCard(
          context,
          icon: Icons.local_offer_outlined,
          title: 'Coupon Basics',
          children: [
            RdxTextField(
              controller: codeController,
              label: 'Coupon Code',
              hint: 'Create coupon code',
            ),
            SizedBox(height: context.h(4)),
            Text(
              'Customers will enter this code at checkout.',
              // style: AppTextStyles.label(context).copyWith(
              //   color: colors.textMuted,
              //   fontSize: context.h(11),
              // ),
              style: AppTextStyles.caption(context),
            ),
            SizedBox(height: context.h(16)),
            RdxTextField(
              controller: descriptionController,
              label: 'Description',
              maxLines: 3,
              hint: 'Enter coupon description',
            ),
            SizedBox(height: context.h(16)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _discountTypeDropdown(context, colors)),
                SizedBox(width: context.w(16)),
                Expanded(
                  child: RdxTextField(
                    controller: discountValueController,
                    label: 'Discount Value',
                    hint: discountType == DiscountType.percentage
                        ? 'Enter Discount Percentage'
                        : 'Enter Discount Amount',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: context.h(20)),
        _sectionCard(
          context,
          icon: Icons.rule_folder_outlined,
          title: 'Usage Rules',
          children: [
            Row(
              children: [
                Expanded(
                  child: RdxTextField(
                    controller: minOrderController,
                    label: 'Minimum Order Value (₹)',
                    hint: 'Enter Amount',
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: context.w(16)),
                Expanded(
                  child: RdxTextField(
                    controller: usageLimitController,
                    label: 'Usage Limit',
                    hint: 'Enter usage limit of coupon',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(16)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date',
                        // style: AppTextStyles.label(context).copyWith(
                        //   color: colors.textSecondary,
                        //   fontSize: context.h(12),
                        // ),
                        style: AppTextStyles.bodySecondary(context)
                            .copyWith(color: colors.textSecondary),
                      ),
                      SizedBox(height: context.h(6)),
                      _datePickerField(
                        startDate,
                        (d) => setState(() => startDate = d),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.w(16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expiry Date',
                        // style: AppTextStyles.label(context).copyWith(
                        //   color: colors.textSecondary,
                        //   fontSize: context.h(12),
                        // ),
                        style: AppTextStyles.bodySecondary(context)
                            .copyWith(color: colors.textSecondary),
                      ),
                      SizedBox(height: context.h(6)),
                      _datePickerField(
                        endDate,
                        (d) => setState(() => endDate = d),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(16)),
            Text(
              'Applicable Categories',
              style: AppTextStyles.bodySecondary(context).copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: context.h(8)),
            Wrap(
              spacing: context.w(8),
              runSpacing: context.h(8),
              children: _categories.map((cat) {
                final selected = _selectedCategories.contains(cat);
                return FilterChip(
                  label: Text(
                    cat,
                    // style: TextStyle(
                    //   color: selected ? AppColors.primary : colors.textPrimary,
                    //   fontSize: context.h(10),
                    //   fontWeight: FontWeight.w600,
                    // ),
                    style: AppTextStyles.body(context).copyWith(
                      color: selected ? AppColors.primary : colors.textPrimary,
                    ),
                  ),
                  selected: selected,
                  showCheckmark: true,
                  checkmarkColor: AppColors.primary,
                  onSelected: (v) => setState(() => v
                      ? _selectedCategories.add(cat)
                      : _selectedCategories.remove(cat)),
                  backgroundColor: colors.surfaceVariant,
                  selectedColor: Colors.white,
                  side: BorderSide(
                    color: selected ? AppColors.primary : colors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.h(8)),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(9),
                    vertical: context.h(5),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButtons(BuildContext context) => Row(
        children: [
          Expanded(
            child: FormActionButton.save(
              isLoading: isLoading,
              onPressed: _save,
            ),
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: FormActionButton.discard(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
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
      padding: EdgeInsets.all(context.h(20)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(14)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: context.h(18), color: AppColors.primary),
              SizedBox(width: context.w(8)),
              Text(
                title,
                // style: AppTextStyles.body(context).copyWith(
                //   color: colors.textPrimary,
                //   fontSize: context.h(14),
                //   fontWeight: FontWeight.w600,
                // ),
                style: AppTextStyles.section(context),
              ),
            ],
          ),
          SizedBox(height: context.h(16)),
          ...children,
        ],
      ),
    );
  }

  Widget _discountTypeDropdown(BuildContext context, AppColorScheme colors) {
    return RdxDropdown<DiscountType>(
      label: 'Discount Type',
      value: discountType,
      items: const [DiscountType.percentage, DiscountType.flat],
      labelBuilder: (v) =>
          v == DiscountType.percentage ? 'Percentage (%)' : 'Flat Amount (₹)',
      onChanged: (v) {
        if (v != null) setState(() => discountType = v);
      },
    );
  }

  Widget _datePickerField(DateTime? date, ValueChanged<DateTime> onPick) {
    return Builder(builder: (context) {
      final colors = AppColors.of(context);
      return InkWell(
        borderRadius: BorderRadius.circular(context.h(8)),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2024),
            lastDate: DateTime(2030),
          );
          if (picked != null) onPick(picked);
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(12),
            vertical: context.h(14),
          ),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(context.h(8)),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: context.h(14),
                color: colors.textMuted,
              ),
              SizedBox(width: context.w(8)),
              Text(
                date == null ? 'Select date' : Formatters.date(date),
                // style: TextStyle(
                //   color: date == null ? colors.textMuted : colors.textPrimary,
                //   fontSize: context.h(13),
                // ),
                style: AppTextStyles.body(context).copyWith(
                  color: date == null ? colors.textMuted : colors.textPrimary,
                ),
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
      padding: EdgeInsets.all(context.h(20)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(14)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: context.h(16),
                color: colors.textSecondary,
              ),
              SizedBox(width: context.w(6)),
              Text(
                'Preview',
                // style: AppTextStyles.body(context).copyWith(
                //   color: colors.textPrimary,
                //   fontSize: context.h(15),
                // ),
                style: AppTextStyles.section(context),
              ),
            ],
          ),
          SizedBox(height: context.h(16)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.h(18)),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(context.h(14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(8),
                        vertical: context.h(3),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(context.h(20)),
                      ),
                      child: Text(
                        isActive ? 'ACTIVE' : 'SCHEDULED',
                        // style: TextStyle(
                        //   color: Colors.white,
                        //   fontSize: context.h(9.5),
                        //   fontWeight: FontWeight.w700,
                        // ),
                        style: AppTextStyles.label(context)
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(14)),
                Text(
                  discountType == DiscountType.percentage
                      ? '${discountValue.toStringAsFixed(0)}%'
                      : Formatters.currency(discountValue),
                  // style: TextStyle(
                  //   color: Colors.white,
                  //   fontSize: context.h(34),
                  //   fontWeight: FontWeight.bold,
                  //   height: 1,
                  // ),
                  style: AppTextStyles.heading(context)
                      .copyWith(color: Colors.white),
                ),
                SizedBox(height: context.h(4)),
                Text(
                  'Off your next order',
                  // style: TextStyle(
                  //   color: Colors.white70,
                  //   fontSize: context.h(13),
                  // ),
                  style: AppTextStyles.bodySecondary(context)
                      .copyWith(color: Colors.white70),
                ),
                SizedBox(height: context.h(16)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: context.h(10)),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(context.h(8)),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      code,
                      // style: TextStyle(
                      //   color: Colors.white,
                      //   fontSize: context.h(15),
                      //   fontWeight: FontWeight.bold,
                      //   letterSpacing: 1.5,
                      // ),
                      style: AppTextStyles.section(context)
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.h(16)),
          Container(
            padding: EdgeInsets.all(context.h(12)),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(context.h(10)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: context.h(15),
                  color: colors.textMuted,
                ),
                SizedBox(width: context.w(8)),
                Expanded(
                  child: Text(
                    minOrder != null && minOrder! > 0
                        ? 'This preview shows how the coupon will appear to end-users. Minimum order: ${Formatters.currency(minOrder!)}.'
                        : 'This preview shows how the coupon will appear to end-users in the RDX delivery app.',
                    // style: AppTextStyles.label(context).copyWith(
                    //   color: colors.textSecondary,
                    //   height: 1.4,
                    //   fontSize: context.h(11),
                    // ),
                    style: AppTextStyles.label(context),
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
