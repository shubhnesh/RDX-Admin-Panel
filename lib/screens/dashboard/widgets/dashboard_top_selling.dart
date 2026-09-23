import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/formatters.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';

class DashboardTopSelling extends StatelessWidget {
  final List<TopSellingItem> items;

  const DashboardTopSelling({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(20),
        context.h(18),
        context.w(20),
        context.h(12),
      ),
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
              Expanded(
                child: Text(
                  'Top Selling Items',
                  style: AppTextStyles.heading(context),
                ),
              ),
              Text(
                'Today',
                style: AppTextStyles.label(context).copyWith(color: AppColors.primary),
              ),
            ],
          ),
          SizedBox(height: context.h(6)),
          Text(
            'By order count',
            style: AppTextStyles.bodySecondary(context),
          ),
          SizedBox(height: context.h(14)),
          if (items.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: context.h(12)),
              child: Text(
                'No sales data yet',
                style: AppTextStyles.bodySecondary(context),
              ),
            )
          else
            for (final item in items) ...[
              _row(context, colors, item),
              if (item != items.last)
                Divider(height: context.h(20), color: colors.divider),
            ],
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    AppColorScheme colors,
    TopSellingItem item,
  ) {
    return Row(
      children: [
        Container(
          width: context.w(28),
          height: context.h(28),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: item.rank == 1
                ? AppColors.primary.withValues(alpha: 0.15)
                : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${item.rank}',
            style: AppTextStyles.label(context).copyWith(
              color:
                  item.rank == 1 ? AppColors.primary : colors.textSecondary,
            ),
          ),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: AppTextStyles.label(context)
                    .copyWith(color: colors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${item.orders} Orders',
                style: AppTextStyles.caption(context),
              ),
            ],
          ),
        ),
        Text(
          Formatters.currency(item.revenue, symbol: '₹'),
          style: AppTextStyles.label(context)
              .copyWith(color: colors.textPrimary),
        ),
      ],
    );
  }
}
