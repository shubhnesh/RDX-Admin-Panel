import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/text_styles.dart';
import '../core/utils/formatters.dart';
import '../core/utils/responsive_size.dart';
import '../models/coupon_model.dart';

class CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final DateTime? previewStartDate;
  final DateTime? previewEndDate;
  final bool isDraft;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CouponCard({
    super.key,
    required this.coupon,
    this.previewStartDate,
    this.previewEndDate,
    this.isDraft = false,
    this.onEdit,
    this.onDelete,
  });

  String _statusLabel() =>
      isDraft ? 'DRAFT PREVIEW' : coupon.status.name.toUpperCase();

  String _discountLabel() => coupon.discountType == DiscountType.percentage
      ? '${coupon.discountValue.toStringAsFixed(0)}% OFF'
      : '${Formatters.currency(coupon.discountValue)} OFF';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.h(16)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: context.h(18),
            offset: Offset(0, context.h(6)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.h(16)),
        child: _hero(context),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.h(14)),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,            // theme orange (left)
            Color(0xFFFFE0C2),            // soft peach
            Colors.white,                 // white (right)
          ],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: context.w(8), vertical: context.h(4)),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(context.h(20)),
                ),
                child: Text(
                  _statusLabel(),
                  style: AppTextStyles.label(context).copyWith(
                    color: Colors.white,
                    fontSize: context.h(10),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (onDelete != null)
                PopupMenuButton<String>(
                  tooltip: 'Coupon actions',
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'delete') {
                      onDelete?.call();
                    }
                  },
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.more_vert,
                    size: context.h(20),
                    color: AppColors.primaryDark,
                  ),
                  color: Colors.white,
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                )
              else
                Icon(
                  Icons.local_offer_rounded,
                  color: AppColors.primaryDark.withValues(alpha: 0.8),
                  size: context.h(22),
                ),
            ],
          ),
          SizedBox(height: context.h(12)),

          // Discount
          Text(
            _discountLabel(),
            style: AppTextStyles.heading(context).copyWith(
              color: Colors.white,
              fontSize: context.h(24),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: context.h(12)),

          // Code + copy
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: context.h(8)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(context.h(10)),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      coupon.code.isEmpty ? 'COUPON CODE' : coupon.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.section(context).copyWith(
                        color: AppColors.primaryDark,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.w(10)),
              IconButton(
                tooltip: 'Copy coupon code',
                onPressed: coupon.code.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(
                          ClipboardData(text: coupon.code),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coupon code copied')),
                        );
                      },
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(context.h(8)),
                ),
                icon: Icon(
                  Icons.copy_rounded,
                  size: context.h(18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}