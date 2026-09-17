import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/screens/coupons/create_coupon_screen.dart';
import 'package:rdx_admin/screens/coupons/widgets/coupon_card.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_action_menu_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_delete_dialog.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/coupon_model.dart';
import '../../providers/coupon_provider.dart';
import '../../widgets/reusable_widgets/empty_state.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/resuable_options/rdx_search_bar.dart';
import '../../widgets/resuable_options/rdx_category_tabs.dart';
import '../../widgets/reusable_widgets/stat_card.dart';

class CouponsScreen extends ConsumerStatefulWidget {
  const CouponsScreen({super.key});

  @override
  ConsumerState<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends ConsumerState<CouponsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(couponProvider).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _selectedStatusLabel(CouponProvider provider) =>
      switch (provider.statusFilter) {
        CouponStatus.active => 'Active',
        CouponStatus.scheduled => 'Scheduled',
        CouponStatus.expired => 'Expired',
        null => 'All',
      };

  CouponStatus? _statusForLabel(String label) => switch (label) {
        'Active' => CouponStatus.active,
        'Scheduled' => CouponStatus.scheduled,
        'Expired' => CouponStatus.expired,
        _ => null,
      };

  void _showCouponActions(
    BuildContext buttonContext,
    CouponModel coupon,
  ) {
    final renderObject = buttonContext.findRenderObject();

    if (renderObject is! RenderBox) return;

    final buttonPosition = renderObject.localToGlobal(Offset.zero);

    showGeneralDialog<void>(
      context: buttonContext,
      barrierDismissible: true,
      barrierLabel: 'Coupon actions',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(
        milliseconds: 120,
      ),
      pageBuilder: (
        dialogContext,
        animation,
        secondaryAnimation,
      ) {
        return RdxActionMenuDialog(
          position: buttonPosition,
          gap: 6,
          items: [
            RdxActionMenuItem(
              title: 'Edit',
              onTap: () {
                _openCreateCoupon(
                  context,
                  coupon: coupon,
                );
              },
            ),
            RdxActionMenuItem(
              title: 'Delete',
              textColor: AppColors.danger,
              onTap: () {
                // ref.read(couponProvider).deleteCoupon(coupon.id);
                _confirmDelete(
                  context,
                  coupon,
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Future<void> _confirmDelete(BuildContext context, CouponModel coupon) async {
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (_) => DeleteMaterialDialog(item: coupon),
  //   );
  //   if (confirmed == true && context.mounted) {
  //     await ref.read(couponProvider).deleteCoupon(coupon.id);
  //   }
  // }

  Future<void> _confirmDelete(
    BuildContext context,
    CouponModel coupon,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Coupon',
        itemName: coupon.code,
        itemDetails: [
          if (coupon.description.isNotEmpty)
            Text(
              coupon.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(context).copyWith(
                color: AppColors.of(context).textSecondary,
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RdxDeleteMetric(
                  label: 'Discount',
                  value: coupon.discountType == DiscountType.percentage
                      ? '${coupon.discountValue.toStringAsFixed(0)}% OFF'
                      : '${Formatters.currency(coupon.discountValue)} OFF',
                ),
              ),
              SizedBox(width: context.w(16)),
              Expanded(
                child: RdxDeleteMetric(
                  label: 'Usage',
                  value: coupon.usageLimit == null
                      ? '${coupon.usageCount} used'
                      : '${coupon.usageCount} / ${coupon.usageLimit}',
                ),
              ),
            ],
          ),
          RdxDeleteMetric(
            label: 'Validity',
            value: '${Formatters.date(coupon.startDate)} - '
                '${Formatters.date(coupon.endDate)}',
          ),
        ],
        deleteButtonLabel: 'Delete Coupon',
        warningMessage: 'Deleting this coupon will permanently remove it from '
            'your promotions. This action cannot be undone.',
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(couponProvider).deleteCoupon(coupon.id);
    }
  }

  Future<void> _openCreateCoupon(
    BuildContext context, {
    CouponModel? coupon,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateCouponScreen(
          existing: coupon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final provider = ref.watch(couponProvider);

    final visibleCoupons = _query.isEmpty
        ? provider.filteredCoupons
        : provider.filteredCoupons
            .where(
              (c) =>
                  c.code.toLowerCase().contains(_query.toLowerCase()) ||
                  c.description.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();

    final totalUsageToday = provider.filteredCoupons.fold<int>(
      0,
      (sum, c) => sum + c.usageCount,
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: Responsive.pagePadding(
            context,
            top: context.h(14),
            bottom: context.h(0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search + Create button ──────────────────────────
              RdxSearchToolbar(
                hintText: 'Search coupons',
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                actions: [
                  RdxActionButton(
                    label: 'Create Coupon',
                    leadingIcon: Icons.add,
                    // onPressed: () async {
                    //   await Navigator.of(context).pushNamed(
                    //     AppRoutes.createCoupon,
                    //   );
                    //   if (context.mounted) {
                    //     ref.read(couponProvider).load();
                    //   }
                    onPressed: () async {
                      await _openCreateCoupon(context);

                      if (context.mounted) {
                        ref.read(couponProvider).load();
                      }
                    },
                  ),
                ],
              ),

              SizedBox(height: context.h(16)),

              // ── Title + status filter (stack on narrow) ─────────
              Builder(builder: (context) {
                final narrow = MediaQuery.sizeOf(context).width < 900;
                final titleBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coupons & Offers',
                      style: AppTextStyles.heading(context),
                    ),
                    SizedBox(height: context.h(4)),
                    Text(
                      'Manage active promotions and discount codes.',
                      style: AppTextStyles.bodySecondary(context).copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                );
                final tabs = RdxCategoryTabs(
                  expand: false,
                  labels: const ['Active', 'Scheduled', 'Expired'],
                  allLabel: 'All',
                  selectedLabel: _selectedStatusLabel(provider),
                  onSelected: (label) {
                    provider.setStatusFilter(_statusForLabel(label));
                  },
                );
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      titleBlock,
                      SizedBox(height: context.h(12)),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: tabs,
                      ),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: titleBlock),
                    tabs,
                  ],
                );
              }),

              SizedBox(height: context.h(20)),

              // ── Summary stat cards ──────────────────────────────
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Total Active',
                        value: '${provider.activeCount} coupons',
                        icon: Icons.local_offer_outlined,
                      ),
                    ),
                    SizedBox(width: context.w(16)),
                    Expanded(
                      child: StatCard(
                        label: 'Total Usages Today',
                        value: '$totalUsageToday',
                        icon: Icons.trending_up_rounded,
                        accentColor: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.h(20)),

              // ── Coupon grid ─────────────────────────────────────
              Expanded(
                child: provider.isLoading
                    ? const LoadingIndicator()
                    : visibleCoupons.isEmpty
                        ? const EmptyState(
                            message: 'No coupons found',
                            icon: Icons.local_offer_outlined,
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = Responsive.gridColumns(context);
                              final spacing = context.w(16);

                              final cardWidth = (constraints.maxWidth -
                                      ((columns - 1) * spacing)) /
                                  columns;

                              return SingleChildScrollView(
                                child: Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: visibleCoupons.map((coupon) {
                                    return SizedBox(
                                      width: cardWidth,
                                      child: CouponCard(
                                        coupon: coupon,
                                        onActions: (buttonContext) {
                                          _showCouponActions(
                                            buttonContext,
                                            coupon,
                                          );
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
