import 'package:flutter/material.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_table.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive_size.dart';
import '../../../models/coupon_model.dart';
import '../../../models/offer_model.dart';

class OfferCard extends StatelessWidget {
  final OfferModel offer;
  final ValueChanged<BuildContext>? onActions;
  final bool isPreview;

  const OfferCard({
    super.key,
    required this.offer,
    this.onActions,
    this.isPreview = false,
  });

  Color _statusColor(BuildContext context) {
    switch (offer.status) {
      case CouponStatus.active:
        return AppColors.success;
      case CouponStatus.scheduled:
        return AppColors.info;
      case CouponStatus.expired:
        return AppColors.of(context).textMuted;
    }
  }

  double get _usageProgress {
    if (offer.usageLimit == null || offer.usageLimit == 0) return 0;
    return (offer.usageCount / offer.usageLimit!).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final statusColor = _statusColor(context);
    final isExpired = offer.status == CouponStatus.expired;

    final discount = offer.discountType == DiscountType.percentage
        ? '${offer.discountValue.toStringAsFixed(0)}% OFF'
        : '${Formatters.currency(offer.discountValue)} OFF';

    final hasImage =
        offer.imageUrl != null && offer.imageUrl!.trim().isNotEmpty;

    final descriptionText = offer.description.trim().isEmpty
        ? (isPreview ? 'Description will be shown here.' : null)
        : offer.description;

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
                            offer.imageUrl!,
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
                          offer.status.name.toUpperCase(),
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
                Text(
                  offer.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading(context),
                ),
                if (descriptionText != null) ...[
                  Text(
                    descriptionText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySecondary(context),
                  ),
                ],
                if (offer.minOrderValue != null) ...[
                  SizedBox(height: context.h(8)),
                  Text(
                    'On orders above ${Formatters.currency(offer.minOrderValue!)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label(context)
                        .copyWith(color: colors.textMuted),
                  ),
                ],
                if (offer.autoApply || offer.showOnHome) ...[
                  SizedBox(height: context.h(8)),
                  Wrap(
                    spacing: context.w(6),
                    runSpacing: context.h(6),
                    children: [
                      if (offer.autoApply)
                        _infoChip(context, 'Auto Apply', colors),
                      if (offer.showOnHome) _infoChip(context, 'Home', colors),
                    ],
                  ),
                ],
                SizedBox(height: context.h(11)),
                if (offer.usageLimit != null)
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
                        '${Formatters.date(offer.startDate)} - ${Formatters.date(offer.endDate)}',
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
                            onPressed: () => onActions!(buttonContext),
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

  Widget _infoChip(BuildContext context, String label, AppColorScheme colors) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(8),
        vertical: context.h(3),
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(context.h(5)),
      ),
      child: Text(
        label,
        style: AppTextStyles.label(context).copyWith(
          color: colors.textSecondary,
        ),
      ),
    );
  }
}
