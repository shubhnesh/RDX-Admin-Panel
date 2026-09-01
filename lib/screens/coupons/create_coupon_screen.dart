import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
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

  Future<void> _save() async {
    if (codeController.text.trim().isEmpty || double.tryParse(discountValueController.text.trim()) == null) {
      setState(() => errorMessage = 'Please enter a coupon code and a valid discount value.');
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
      status: startDate.isAfter(DateTime.now()) ? CouponStatus.scheduled : CouponStatus.active,
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
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: RdxHeader(
        title: 'Create New Coupon',
        showBack: true,
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CustomButton(label: 'Save Coupon', isLoading: isLoading, onPressed: _save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (errorMessage != null) ...[
                Text(errorMessage!, style: const TextStyle(color: AppColors.danger)),
                const SizedBox(height: 12),
              ],
              const Text('Coupon Basics', style: AppTextStyles.h2),
              const SizedBox(height: 12),
              CustomTextField(controller: codeController, label: 'Coupon Code'),
              const SizedBox(height: 16),
              CustomTextField(controller: descriptionController, label: 'Description', maxLines: 2),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Discount Type', style: AppTextStyles.label),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<DiscountType>(
                          value: discountType,
                          dropdownColor: AppColors.surface,
                          items: const [
                            DropdownMenuItem(value: DiscountType.percentage, child: Text('Percentage (%)')),
                            DropdownMenuItem(value: DiscountType.flat, child: Text('Flat Amount (₹)')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => discountType = v);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: discountValueController,
                      label: 'Discount Value',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Usage Rules', style: AppTextStyles.h2),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: minOrderController,
                      label: 'Min Order Value (₹)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: usageLimitController,
                      label: 'Usage Limit',
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
                        const Text('Start Date', style: AppTextStyles.label),
                        const SizedBox(height: 6),
                        _datePickerField(startDate, (d) => setState(() => startDate = d)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Date', style: AppTextStyles.label),
                        const SizedBox(height: 6),
                        _datePickerField(endDate, (d) => setState(() => endDate = d)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _datePickerField(DateTime date, ValueChanged<DateTime> onPick) {
    return InkWell(
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
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Text('${date.day}/${date.month}/${date.year}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
