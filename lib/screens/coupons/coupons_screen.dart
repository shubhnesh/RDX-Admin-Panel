import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/coupon_model.dart';
import '../../providers/coupon_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rdx_search_bar.dart';
import '../../widgets/stat_card.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CouponProvider>().load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final provider = context.watch<CouponProvider>();

    final visibleCoupons = _query.isEmpty
        ? provider.filteredCoupons
        : provider.filteredCoupons
            .where((c) =>
                c.code.toLowerCase().contains(_query.toLowerCase()) ||
                c.description.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    final totalUsageToday =
        provider.filteredCoupons.fold<int>(0, (sum, c) => sum + c.usageCount);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: RdxSearchToolbar(
        hintText: 'Search coupons...',
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v),
        actions: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.surfaceVariant,
            child: Icon(Icons.person, size: 18, color: colors.textSecondary),
          ),
        ],
      ),
      body: provider.isLoading
          ? const LoadingIndicator()
          : Padding(
              padding: Responsive.pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title row with subtitle + create button ─────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Coupons & Offers',
                                style: AppTextStyles.h1
                                    .copyWith(color: colors.textPrimary)),
                            const SizedBox(height: 4),
                            Text(
                              'Manage active promotions and discount codes.',
                              style: AppTextStyles.bodyMuted
                                  .copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context)
                              .pushNamed(AppRoutes.createCoupon);
                          if (context.mounted)
                            context.read<CouponProvider>().load();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Create New Coupon'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Summary stat cards ───────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Total Active',
                          value: '${provider.activeCount} coupons',
                          icon: Icons.local_offer_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          label: 'Total Usages Today',
                          value: '$totalUsageToday',
                          icon: Icons.trending_up_rounded,
                          accentColor: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _StatusFilterCard(provider: provider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Coupon grid ───────────────────────────────────────
                  Expanded(
                    child: visibleCoupons.isEmpty
                        ? const EmptyState(
                            message: 'No coupons found',
                            icon: Icons.local_offer_outlined)
                        : GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: Responsive.gridColumns(context),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.18,
                            ),
                            itemCount: visibleCoupons.length,
                            itemBuilder: (context, index) {
                              final c = visibleCoupons[index];
                              return _CouponCard(
                                  coupon: c,
                                  onDelete: () => provider.deleteCoupon(c.id));
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Pill-style status filter row, styled like the reference design
/// ("All / Active / Scheduled / Expired") shown inside a bordered card.
class _StatusFilterCard extends StatelessWidget {
  final CouponProvider provider;
  const _StatusFilterCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Text('Filter by Status',
              style: AppTextStyles.label.copyWith(color: colors.textSecondary)),
          const Spacer(),
          _pill(context, 'All', null),
          const SizedBox(width: 6),
          _pill(context, 'Active', CouponStatus.active),
          const SizedBox(width: 6),
          _pill(context, 'Scheduled', CouponStatus.scheduled),
          const SizedBox(width: 6),
          _pill(context, 'Expired', CouponStatus.expired),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String label, CouponStatus? status) {
    final colors = AppColors.of(context);
    final selected = provider.statusFilter == status;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => provider.setStatusFilter(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: selected ? AppColors.primary : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final VoidCallback onDelete;

  const _CouponCard({required this.coupon, required this.onDelete});

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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  coupon.status.name.toUpperCase(),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4),
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: colors.textMuted),
                color: colors.surface,
                onSelected: (v) {
                  if (v == 'delete') onDelete();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(color: AppColors.danger)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(coupon.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        letterSpacing: 0.3)),
              ),
              IconButton(
                tooltip: 'Copy coupon code',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coupon code copied'))),
                icon: Icon(Icons.copy_outlined,
                    size: 15, color: colors.textMuted),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Text(
            coupon.description.isEmpty
                ? 'No description added'
                : coupon.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.bodyMuted.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF3EC),
                borderRadius: BorderRadius.circular(7)),
            child: Row(
              children: [
                const Icon(Icons.local_offer_outlined,
                    size: 17, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(discount,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                const Spacer(),
                if (coupon.minOrderValue != null)
                  Text('Min. ${Formatters.currency(coupon.minOrderValue!)}',
                      style: AppTextStyles.label
                          .copyWith(color: colors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 11),
          if (coupon.usageLimit != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _usageProgress,
                minHeight: 6,
                backgroundColor: colors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(
                    isExpired ? colors.textMuted : AppColors.primary),
              ),
            ),
          ],
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.bar_chart_outlined, size: 14, color: colors.textMuted),
              const SizedBox(width: 5),
              Text(usageLabel,
                  style: AppTextStyles.label
                      .copyWith(color: colors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: colors.divider, height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.event_outlined, size: 14, color: colors.textMuted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${Formatters.date(coupon.startDate)} - ${Formatters.date(coupon.endDate)}',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(color: colors.textMuted),
                ),
              ),
              Text(
                isExpired
                    ? 'Ended'
                    : coupon.status == CouponStatus.scheduled
                        ? 'Starts soon'
                        : 'Active now',
                style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
