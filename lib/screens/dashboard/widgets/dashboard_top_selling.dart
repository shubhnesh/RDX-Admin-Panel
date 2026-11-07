import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_empty.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_card_style.dart';

class DashboardTopSelling extends StatelessWidget {
  final List<TopSellingItem> items;

  const DashboardTopSelling({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.w(22),
        context.h(16),
        context.w(22),
        context.h(14),
      ),
      decoration: DashboardCardStyle.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Popular menu items', style: DashboardCardStyle.title(context)),
          if (items.isNotEmpty) ...[
            SizedBox(height: context.h(4)),
            Text('Sales and order count for this period',
                style: DashboardCardStyle.description(context)),
          ],
          if (items.isEmpty)
            SizedBox(
              height: context.h(300),
              child: const Center(
                child: DashboardEmpty(
                  icon: Icons.restaurant_menu_rounded,
                  title: 'No item data available',
                  subtitle:
                      'Top sellers will appear after orders are recorded.',
                ),
              ),
            )
          else ...[
            SizedBox(height: context.h(12)),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(height: context.h(10)),
              _row(context, colors, items[i]),
            ],
          ],
        ],
      ),
    );
  }

  Widget _row(
      BuildContext context, AppColorScheme colors, TopSellingItem item) {
    return Row(
      children: [
        SizedBox(
          width: context.w(28),
          child: Text(
            '#${item.rank}',
            textAlign: TextAlign.center,
            style: AppTextStyles.label(context).copyWith(
              color: colors.textMuted,
              fontSize: context.h(18),
              fontWeight: FontWeight.w700,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(context)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Text(
          '${item.orders} sold',
          style: AppTextStyles.body(context).copyWith(
            fontSize: context.h(18),
            fontWeight: FontWeight.w800,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
