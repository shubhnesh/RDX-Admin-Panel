import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/formatters.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/coupon_model.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_table.dart';

class CouponCard extends StatelessWidget {
  final CouponModel coupon;
  // final VoidCallback onDelete;
  final ValueChanged<BuildContext>? onActions;

  const CouponCard({super.key, 
    required this.coupon,
    // required this.onDelete,
    this.onActions,
  });

  Color _statusColor(BuildContext context) {
    switch (coupon.status) {
      case CouponStatus.active:
        return AppColors.success;
      case CouponStatus.scheduled:
        return AppColors.info;
      case CouponStatus.expired:
        return AppColors.of(context).textMuted;
    }
  }

  double get _usageProgress {
    if (coupon.usageLimit == null || coupon.usageLimit == 0) return 0;
    return (coupon.usageCount / coupon.usageLimit!).clamp(0, 1).toDouble();
  }


  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final statusColor = _statusColor(context);
    final isExpired = coupon.status == CouponStatus.expired;

    final discount = coupon.discountType == DiscountType.percentage
        ? '${coupon.discountValue.toStringAsFixed(0)}% OFF'
        : '${Formatters.currency(coupon.discountValue)} OFF';

    final usageLabel = coupon.usageLimit == null
        ? '${coupon.usageCount} used · No limit'
        : '${coupon.usageCount} of ${coupon.usageLimit} used';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.h(14)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: context.h(10),
            offset: Offset(0, context.h(3)),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status + menu ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(5),
                    vertical: context.h(2),
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(context.h(5)),
                  ),
                  child: Text(
                    coupon.status.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context)
                        .copyWith(color: statusColor),
                  ),
                ),
              ),
              const Spacer(),
              Builder(
                builder: (buttonContext) {
                  return RdxTableMoreButton(
                    tooltip: 'More actions',
                    onPressed: () {
                      onActions!(buttonContext);
                    },
                  );
                },
              ),
            ],
          ),

          SizedBox(height: context.h(8)),

          // ── Coupon code + copy ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  coupon.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading(context),
                ),
              ),
              SizedBox(width: context.w(4)),
              IconButton(
                tooltip: 'Copy coupon code',
                onPressed: () {},
                icon: Icon(
                  Icons.copy_outlined,
                  size: context.h(15),
                  color: colors.textMuted,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: context.w(32),
                  minHeight: context.h(32),
                ),
              ),
            ],
          ),

          // ── Description ─────────────────────────────────────────
          Text(
            coupon.description.isEmpty
                ? 'Description will be shown here.'
                : coupon.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySecondary(context),
          ),

          SizedBox(height: context.h(10)),

          // ── Discount ────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: context.w(10),
              vertical: context.h(9),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EC),
              borderRadius: BorderRadius.circular(context.h(7)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: context.h(17),
                  color: AppColors.primary,
                ),
                SizedBox(width: context.w(8)),
                Flexible(
                  child: Text(
                    discount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.section(context)
                        .copyWith(color: AppColors.primary),
                  ),
                ),
                if (coupon.minOrderValue != null) ...[
                  SizedBox(width: context.w(8)),
                  Flexible(
                    child: Text(
                      'Min. ${Formatters.currency(coupon.minOrderValue!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AppTextStyles.label(context),
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: context.h(11)),

          // ── Usage progress ──────────────────────────────────────
          if (coupon.usageLimit != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(context.h(4)),
              child: LinearProgressIndicator(
                value: _usageProgress,
                minHeight: context.h(6),
                backgroundColor: colors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(
                  isExpired ? colors.textMuted : AppColors.primary,
                ),
              ),
            ),

          SizedBox(height: context.h(5)),

          // ── Usage information ──────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: context.h(14),
                color: colors.textMuted,
              ),
              SizedBox(width: context.w(5)),
              Expanded(
                child: Text(
                  usageLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label(context),
                ),
              ),
            ],
          ),

          SizedBox(height: context.h(8)),

          Divider(color: colors.divider, height: context.h(1)),

          SizedBox(height: context.h(8)),

          // ── Date + current status ───────────────────────────────
          Row(
            children: [
              Icon(
                Icons.event_outlined,
                size: context.h(14),
                color: colors.textMuted,
              ),
              SizedBox(width: context.w(5)),
              Expanded(
                child: Text(
                  '${Formatters.date(coupon.startDate)} - ${Formatters.date(coupon.endDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label(context)
                      .copyWith(color: colors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
