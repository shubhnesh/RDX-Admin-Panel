import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/formatters.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/coupon_model.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_table.dart';

class CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final ValueChanged<BuildContext>? onActions;

  /// When true (create/edit preview only), an empty description shows the
  /// placeholder "Description will be shown here." Real list cards never
  /// show that dummy text.
  final bool isPreview;

  const CouponCard({
    super.key,
    required this.coupon,
    this.onActions,
    this.isPreview = false,
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

    final hasImage =
        coupon.imageUrl != null && coupon.imageUrl!.trim().isNotEmpty;

    // Description text:
    // - Preview + empty → show placeholder
    // - Real card + empty → hide the line entirely
    // - Has text → show it
    final descriptionText = coupon.description.trim().isEmpty
        ? (isPreview ? 'Description will be shown here.' : null)
        : coupon.description;

    return Container(
      width: double.infinity,
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ─────────────────────────────────────────────
          AspectRatio(
            aspectRatio: 2.2,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(8),
                context.w(8),
                context.w(8),
                context.w(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(context.h(8)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasImage
                        ? Image.network(
                            coupon.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: colors.surfaceVariant,
                              child: Icon(
                                Icons.local_offer_outlined,
                                color: colors.textMuted,
                                size: context.h(28),
                              ),
                            ),
                          )
                        : Container(
                            color: colors.surfaceVariant,
                            child: Icon(
                              Icons.local_offer_outlined,
                              color: colors.textMuted,
                              size: context.h(28),
                            ),
                          ),
                    // Subtle bottom gradient so overlaid badges stay
                    // readable over bright photos.
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.0),
                              Colors.black.withValues(alpha: 0.18),
                            ],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Status pill, top-left over the image.
                    Positioned(
                      left: context.w(6),
                      top: context.h(6),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.w(5),
                          vertical: context.h(2),
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(context.h(5)),
                        ),
                        child: Text(
                          coupon.status.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(context)
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(14),
              0,
              context.w(14),
              context.h(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: context.h(2)),
                // ── Discount ──────────────────────────────────────────────
                Text(
                  discount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(context).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: context.h(2)),
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
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: coupon.code),
                        );
                      },
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

                // ── Description (only when there is text, or preview placeholder)
                if (descriptionText != null) ...[
                  Text(
                    descriptionText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySecondary(context),
                  ),
                ],

                if (coupon.minOrderValue != null) ...[
                  SizedBox(height: context.h(8)),
                  Text(
                    'On orders above ${Formatters.currency(coupon.minOrderValue!)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label(context)
                        .copyWith(color: colors.textMuted),
                  ),
                ],

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

                Divider(color: colors.divider, height: context.h(1)),

                SizedBox(height: context.h(8)),

                // ── Date + more actions ──────────────────────────────────
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
                    if (onActions != null)
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
