import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdx_admin/widgets/rdx_header.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../models/coupon_model.dart';
import '../../providers/coupon_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';


class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CouponProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CouponProvider>();

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: RdxHeader(
        title: 'Offers & Coupons',
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.of(context).pushNamed(AppRoutes.createCoupon);
              if (context.mounted) context.read<CouponProvider>().load();
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create New Coupon'),
          ),
        ],
      ),
      body: provider.isLoading
          ? const LoadingIndicator()
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _filterChip(provider, 'All', null),
                      const SizedBox(width: 8),
                      _filterChip(provider, 'Active', CouponStatus.active),
                      const SizedBox(width: 8),
                      _filterChip(provider, 'Scheduled', CouponStatus.scheduled),
                      const SizedBox(width: 8),
                      _filterChip(provider, 'Expired', CouponStatus.expired),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: provider.filteredCoupons.isEmpty
                        ? const EmptyState(message: 'No coupons found', icon: Icons.local_offer_outlined)
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.6,
                            ),
                            itemCount: provider.filteredCoupons.length,
                            itemBuilder: (context, index) {
                              final c = provider.filteredCoupons[index];
                              return _CouponCard(coupon: c, onDelete: () => provider.deleteCoupon(c.id));
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _filterChip(CouponProvider provider, String label, CouponStatus? status) {
    return ChoiceChip(
      label: Text(label),
      selected: provider.statusFilter == status,
      onSelected: (_) => provider.setStatusFilter(status),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
      side: const BorderSide(color: AppColors.border),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final VoidCallback onDelete;

  const _CouponCard({required this.coupon, required this.onDelete});

  Color get _statusColor {
    switch (coupon.status) {
      case CouponStatus.active:
        return AppColors.success;
      case CouponStatus.scheduled:
        return AppColors.info;
      case CouponStatus.expired:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(coupon.code,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(coupon.status.name,
                    style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(coupon.description,
              maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyMuted),
          const Spacer(),
          Text(
            coupon.discountType == DiscountType.percentage
                ? '${coupon.discountValue.toStringAsFixed(0)}% OFF'
                : '₹${coupon.discountValue.toStringAsFixed(0)} FLAT',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Expires ${coupon.endDate.day}/${coupon.endDate.month}/${coupon.endDate.year}',
                  style: AppTextStyles.caption),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16),
                color: AppColors.danger,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
