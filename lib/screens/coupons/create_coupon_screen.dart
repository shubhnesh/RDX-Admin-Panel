import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rdx_admin/screens/coupons/widgets/coupon_card.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/coupon_model.dart';
import '../../providers/coupon_provider.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/resuable_options/rdx_dropdown.dart';
import '../../widgets/resuable_options/rdx_text_field.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';

class CreateCouponScreen extends StatefulWidget {
  final CouponModel? existing;
  const CreateCouponScreen({
    super.key,
    this.existing,
  });

  @override
  State<CreateCouponScreen> createState() => _CreateCouponScreenState();
}

class _CreateCouponScreenState extends State<CreateCouponScreen> {
  final codeController = TextEditingController();
  final descriptionController = TextEditingController();
  final discountValueController = TextEditingController();
  final minOrderController = TextEditingController();
  final usageLimitController = TextEditingController();

  bool get isEdit => widget.existing != null && widget.existing!.id.isNotEmpty;

  // Percentage is the default selection
  DiscountType discountType = DiscountType.percentage;
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;

    if (existing != null) {
      codeController.text = existing.code;
      descriptionController.text = existing.description;
      discountValueController.text = existing.discountValue.toString();
      minOrderController.text = existing.minOrderValue?.toString() ?? '';
      usageLimitController.text = existing.usageLimit?.toString() ?? '';

      discountType = existing.discountType;
      startDate = existing.startDate;
      endDate = existing.endDate;
    }

    for (final c in [
      codeController,
      descriptionController,
      discountValueController,
      minOrderController,
      usageLimitController,
    ]) {
      c.addListener(() => setState(() {}));
    }

    // Clamp percentage value to max 100 while typing
    discountValueController.addListener(_clampPercentage);
  }

  void _clampPercentage() {
    if (discountType != DiscountType.percentage) return;
    final text = discountValueController.text.trim();
    if (text.isEmpty) return;
    final value = double.tryParse(text);
    if (value != null && value > 100) {
      discountValueController.text = '100';
      discountValueController.selection = TextSelection.fromPosition(
        const TextPosition(offset: 3),
      );
    }
  }

  // Future<void> _save() async {
  //   final code = codeController.text.trim();
  //   final description = descriptionController.text.trim();
  //   final discountText = discountValueController.text.trim();
  //   final minOrderText = minOrderController.text.trim();
  //   final usageLimitText = usageLimitController.text.trim();

  //   final discountValue = double.tryParse(discountText);
  //   final minOrderValue = double.tryParse(minOrderText);
  //   final usageLimit = int.tryParse(usageLimitText);

  //   // Every field is mandatory
  //   if (code.isEmpty ||
  //       description.isEmpty ||
  //       discountValue == null ||
  //       minOrderValue == null ||
  //       usageLimit == null ||
  //       startDate == null ||
  //       endDate == null) {
  //     setState(() => errorMessage =
  //         'All fields are mandatory. Please fill coupon code, description, discount value, minimum order value, usage limit, start date and expiry date.');
  //     return;
  //   }

  //   // Coupon code length restriction
  //   if (code.length > 15) {
  //     setState(() =>
  //         errorMessage = 'Coupon code cannot be longer than 15 characters.');
  //     return;
  //   }

  //   // Percentage max value = 100
  //   if (discountType == DiscountType.percentage && discountValue > 100) {
  //     setState(
  //         () => errorMessage = 'Discount percentage cannot be more than 100.');
  //     return;
  //   }

  //   if (discountValue <= 0) {
  //     setState(() => errorMessage = 'Discount value must be greater than 0.');
  //     return;
  //   }

  //   if (minOrderValue < 0) {
  //     setState(() => errorMessage = 'Minimum order value cannot be negative.');
  //     return;
  //   }

  //   if (usageLimit <= 0) {
  //     setState(() => errorMessage = 'Usage limit must be greater than 0.');
  //     return;
  //   }

  //   if (endDate!.isBefore(startDate!)) {
  //     setState(
  //         () => errorMessage = 'Expiry date cannot be before the start date.');
  //     return;
  //   }

  //   final coupon = CouponModel(
  //     id: 'c${DateTime.now().millisecondsSinceEpoch}',
  //     code: code.toUpperCase(),
  //     description: description,
  //     discountType: discountType,
  //     discountValue: discountValue,
  //     minOrderValue: minOrderValue,
  //     usageLimit: usageLimit,
  //     startDate: startDate!,
  //     endDate: endDate!,
  //     status: startDate!.isAfter(DateTime.now())
  //         ? CouponStatus.scheduled
  //         : CouponStatus.active,
  //   );

  //   setState(() {
  //     isLoading = true;
  //     errorMessage = null;
  //   });
  //   final success = await context.read<CouponProvider>().createCoupon(coupon);
  //   if (!mounted) return;
  //   setState(() => isLoading = false);
  //   if (success) {
  //     Navigator.of(context).pop();
  //   } else {
  //     setState(() => errorMessage = 'Failed to create coupon.');
  //   }
  // }

  Future<void> _save() async {
    final code = codeController.text.trim();
    final description = descriptionController.text.trim();
    final discountText = discountValueController.text.trim();
    final minOrderText = minOrderController.text.trim();
    final usageLimitText = usageLimitController.text.trim();

    final discountValue = double.tryParse(discountText);
    final minOrderValue = double.tryParse(minOrderText);
    final usageLimit = int.tryParse(usageLimitText);

    // Every field is mandatory.
    if (code.isEmpty ||
        description.isEmpty ||
        discountValue == null ||
        minOrderValue == null ||
        usageLimit == null ||
        startDate == null ||
        endDate == null) {
      setState(() {
        errorMessage =
            'All fields are mandatory. Please fill coupon code, description, '
            'discount value, minimum order value, usage limit, start date and expiry date.';
      });
      return;
    }

    if (code.length > 15) {
      setState(() {
        errorMessage = 'Coupon code cannot be longer than 15 characters.';
      });
      return;
    }

    if (discountType == DiscountType.percentage && discountValue > 100) {
      setState(() {
        errorMessage = 'Discount percentage cannot be more than 100.';
      });
      return;
    }

    if (discountValue <= 0) {
      setState(() {
        errorMessage = 'Discount value must be greater than 0.';
      });
      return;
    }

    if (minOrderValue < 0) {
      setState(() {
        errorMessage = 'Minimum order value cannot be negative.';
      });
      return;
    }

    if (usageLimit <= 0) {
      setState(() {
        errorMessage = 'Usage limit must be greater than 0.';
      });
      return;
    }

    if (endDate!.isBefore(startDate!)) {
      setState(() {
        errorMessage = 'Expiry date cannot be before the start date.';
      });
      return;
    }

    final coupon = CouponModel(
      // Keep existing ID while editing.
      id: isEdit
          ? widget.existing!.id
          : 'c${DateTime.now().millisecondsSinceEpoch}',

      code: code.toUpperCase(),
      description: description,
      discountType: discountType,
      discountValue: discountValue,
      minOrderValue: minOrderValue,
      usageLimit: usageLimit,
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

    try {
      final provider = context.read<CouponProvider>();

      final success = isEdit
          ? await provider.updateCoupon(coupon)
          : await provider.createCoupon(coupon);

      if (!mounted) return;

      setState(() => isLoading = false);

      if (success) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          errorMessage =
              isEdit ? 'Failed to update coupon.' : 'Failed to create coupon.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            isEdit ? 'Failed to update coupon.' : 'Failed to create coupon.';
      });
    }
  }

  @override
  void dispose() {
    discountValueController.removeListener(_clampPercentage);
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

    final parsedDiscount = double.tryParse(discountValueController.text.trim());

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          RdxHeader(
              title: isEdit ? 'Edit Coupon' : 'Create New Coupon',
              showBackButton: true),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final form = _formContent(context, colors);
                final previewCoupon = CouponModel(
                  id: 'draft',
                  code: codeController.text.trim().isEmpty
                      ? 'ABCD123'
                      : codeController.text.trim().toUpperCase(),
                  description: descriptionController.text.trim(),
                  discountType: discountType,
                  discountValue: parsedDiscount ?? 0,
                  minOrderValue:
                      double.tryParse(minOrderController.text.trim()),
                  usageLimit: int.tryParse(usageLimitController.text.trim()),
                  startDate: startDate ?? DateTime.now(),
                  endDate: endDate ?? DateTime.now(),
                  status:
                      startDate != null && !startDate!.isAfter(DateTime.now())
                          ? CouponStatus.active
                          : CouponStatus.scheduled,
                );
                final preview = CouponCard(
                  coupon: previewCoupon,
                  onActions: (_) {},
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
                        Text(
                          'Preview',
                          style: AppTextStyles.section(context)
                              .copyWith(color: colors.textPrimary),
                        ),
                        SizedBox(height: context.h(10)),
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
                              Text(
                                'Preview',
                                style: AppTextStyles.section(context)
                                    .copyWith(color: colors.textPrimary),
                              ),
                              SizedBox(height: context.h(10)),
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
          ),
        ],
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
              maxLength: 15,
              inputFormatters: [
                LengthLimitingTextInputFormatter(15),
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              ],
            ),
            SizedBox(height: context.h(16)),
            RdxTextField(
              controller: descriptionController,
              label: 'Description',
              maxLines: 3,
              hint: 'Enter coupon description',
            ),
            SizedBox(height: context.h(16)),
            LayoutBuilder(builder: (context, c) {
              final stack = c.maxWidth < 420;
              final typeField = _discountTypeDropdown(context, colors);
              final valueField = RdxTextField(
                controller: discountValueController,
                label: 'Discount Value',
                hint: discountType == DiscountType.percentage
                    ? 'Enter Discount Percentage'
                    : 'Enter Discount Amount',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
              );
              if (stack) {
                return Column(
                  children: [
                    typeField,
                    SizedBox(height: context.h(16)),
                    valueField,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: typeField),
                  SizedBox(width: context.w(16)),
                  Expanded(child: valueField),
                ],
              );
            }),
          ],
        ),
        SizedBox(height: context.h(20)),
        _sectionCard(
          context,
          icon: Icons.rule_folder_outlined,
          title: 'Usage Rules',
          children: [
            LayoutBuilder(builder: (context, c) {
              final stack = c.maxWidth < 420;
              final minField = RdxTextField(
                controller: minOrderController,
                label: 'Minimum Order Value (₹)',
                hint: 'Enter Amount',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
              );
              final limitField = RdxTextField(
                controller: usageLimitController,
                label: 'Usage Limit',
                hint: 'Enter usage limit of coupon',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              );
              if (stack) {
                return Column(
                  children: [
                    minField,
                    SizedBox(height: context.h(16)),
                    limitField,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: minField),
                  SizedBox(width: context.w(16)),
                  Expanded(child: limitField),
                ],
              );
            }),
            SizedBox(height: context.h(16)),
            LayoutBuilder(builder: (context, c) {
              final stack = c.maxWidth < 420;
              final startCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start Date',
                    style: AppTextStyles.bodySecondary(context)
                        .copyWith(color: colors.textSecondary),
                  ),
                  SizedBox(height: context.h(6)),
                  _datePickerField(
                    startDate,
                    (d) => setState(() {
                      startDate = d;
                      if (endDate != null && endDate!.isBefore(d)) {
                        endDate = null;
                      }
                    }),
                  ),
                ],
              );
              final endCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expiry Date',
                    style: AppTextStyles.bodySecondary(context)
                        .copyWith(color: colors.textSecondary),
                  ),
                  SizedBox(height: context.h(6)),
                  _datePickerField(
                    endDate,
                    (d) => setState(() => endDate = d),
                    firstDate: startDate ?? DateTime(2024),
                  ),
                ],
              );
              if (stack) {
                return Column(
                  children: [
                    startCol,
                    SizedBox(height: context.h(16)),
                    endCol,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: startCol),
                  SizedBox(width: context.w(16)),
                  Expanded(child: endCol),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _actionButtons(BuildContext context) => Row(
        children: [
          Expanded(
            child: RdxActionButton.save(
              label: isEdit ? 'Update' : 'Save',
              isLoading: isLoading,
              onPressed: _save,
            ),
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: RdxActionButton.discard(
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
        if (v != null) {
          setState(() {
            discountType = v;
            // Re-clamp if switching back to percentage
            if (v == DiscountType.percentage) {
              _clampPercentage();
            }
          });
        }
      },
    );
  }

  Widget _datePickerField(
    DateTime? date,
    ValueChanged<DateTime> onPick, {
    DateTime? firstDate,
  }) {
    return Builder(builder: (context) {
      final colors = AppColors.of(context);
      final minimumDate = firstDate ?? DateTime(2024);
      final lastDate = DateTime(2030);
      final today = DateTime.now();
      final initialDate = today.isBefore(minimumDate)
          ? minimumDate
          : today.isAfter(lastDate)
              ? lastDate
              : today;
      return InkWell(
        borderRadius: BorderRadius.circular(context.h(8)),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: minimumDate,
            lastDate: lastDate,
            builder: (context, child) {
              final theme = Theme.of(context);
              return Theme(
                data: theme.copyWith(
                  colorScheme: theme.colorScheme.copyWith(
                    primary: colors.primary,
                    onPrimary: Colors.white,
                    surface: colors.surface,
                    onSurface: colors.textPrimary,
                  ),
                  datePickerTheme: DatePickerThemeData(
                    backgroundColor: colors.surface,
                    surfaceTintColor: Colors.transparent,
                    headerBackgroundColor: colors.primary,
                    headerForegroundColor: Colors.white,
                    todayBackgroundColor: WidgetStatePropertyAll(
                      colors.primary.withValues(alpha: 0.12),
                    ),
                    todayForegroundColor: WidgetStatePropertyAll(
                      colors.primary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.h(16)),
                    ),
                  ),
                  dialogTheme: DialogThemeData(
                    backgroundColor: colors.surface,
                    surfaceTintColor: Colors.transparent,
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.h(16)),
                    ),
                  ),
                ),
                child: child!,
              );
            },
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
