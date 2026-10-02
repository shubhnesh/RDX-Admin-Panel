import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/screens/coupons/create_coupon_screen.dart';
import 'package:rdx_admin/screens/coupons/create_offer_screen.dart';
import 'package:rdx_admin/screens/coupons/widgets/coupon_card.dart';
import 'package:rdx_admin/screens/coupons/widgets/offer_card.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_action_menu_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_delete_dialog.dart';
import 'package:rdx_admin/widgets/buttons/stats_collapse_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/coupon_model.dart';
import '../../models/offer_model.dart';
import '../../providers/coupon_provider.dart';
import '../../providers/offer_provider.dart';
import '../../widgets/reusable_widgets/empty_state.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/resuable_options/rdx_search_bar.dart';
import '../../widgets/resuable_options/rdx_category_tabs.dart';
import '../../widgets/reusable_widgets/stat_card.dart';

enum PromotionTypeFilter { all, coupons, offers }

class CouponsScreen extends ConsumerStatefulWidget {
  const CouponsScreen({super.key});

  @override
  ConsumerState<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends ConsumerState<CouponsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _statsCollapsed = false;
  PromotionTypeFilter _typeFilter = PromotionTypeFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(couponProvider).load();
      ref.read(offerProvider).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _selectedStatusLabel(CouponStatus? status) => switch (status) {
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

  String _selectedTypeLabel() => switch (_typeFilter) {
        PromotionTypeFilter.all => 'All',
        PromotionTypeFilter.coupons => 'Coupons',
        PromotionTypeFilter.offers => 'Offers',
      };

  PromotionTypeFilter _typeForLabel(String label) => switch (label) {
        'Coupons' => PromotionTypeFilter.coupons,
        'Offers' => PromotionTypeFilter.offers,
        _ => PromotionTypeFilter.all,
      };

  void _showCouponActions(BuildContext buttonContext, CouponModel coupon) {
    final renderObject = buttonContext.findRenderObject();
    if (renderObject is! RenderBox) return;
    final buttonPosition = renderObject.localToGlobal(Offset.zero);

    showGeneralDialog<void>(
      context: buttonContext,
      barrierDismissible: true,
      barrierLabel: 'Coupon actions',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (_, __, ___) {
        return RdxActionMenuDialog(
          position: buttonPosition,
          gap: 6,
          items: [
            RdxActionMenuItem(
              title: 'Edit',
              onTap: () => _openCreateCoupon(context, coupon: coupon),
            ),
            RdxActionMenuItem(
              title: 'Delete',
              textColor: AppColors.danger,
              onTap: () => _confirmDeleteCoupon(context, coupon),
            ),
          ],
        );
      },
    );
  }

  void _showOfferActions(BuildContext buttonContext, OfferModel offer) {
    final renderObject = buttonContext.findRenderObject();
    if (renderObject is! RenderBox) return;
    final buttonPosition = renderObject.localToGlobal(Offset.zero);

    showGeneralDialog<void>(
      context: buttonContext,
      barrierDismissible: true,
      barrierLabel: 'Offer actions',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (_, __, ___) {
        return RdxActionMenuDialog(
          position: buttonPosition,
          gap: 6,
          items: [
            RdxActionMenuItem(
              title: 'Edit',
              onTap: () => _openCreateOffer(context, offer: offer),
            ),
            RdxActionMenuItem(
              title: 'Delete',
              textColor: AppColors.danger,
              onTap: () => _confirmDeleteOffer(context, offer),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteCoupon(
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

  Future<void> _confirmDeleteOffer(
    BuildContext context,
    OfferModel offer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Offer',
        itemName: offer.title,
        itemDetails: [
          if (offer.description.isNotEmpty)
            Text(
              offer.description,
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
                  value: offer.discountType == DiscountType.percentage
                      ? '${offer.discountValue.toStringAsFixed(0)}% OFF'
                      : '${Formatters.currency(offer.discountValue)} OFF',
                ),
              ),
              SizedBox(width: context.w(16)),
              Expanded(
                child: RdxDeleteMetric(
                  label: 'Usage',
                  value: offer.usageLimit == null
                      ? '${offer.usageCount} used'
                      : '${offer.usageCount} / ${offer.usageLimit}',
                ),
              ),
            ],
          ),
          RdxDeleteMetric(
            label: 'Validity',
            value: '${Formatters.date(offer.startDate)} - '
                '${Formatters.date(offer.endDate)}',
          ),
        ],
        deleteButtonLabel: 'Delete Offer',
        warningMessage: 'Deleting this offer will permanently remove it from '
            'your promotions. This action cannot be undone.',
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(offerProvider).deleteOffer(offer.id);
    }
  }

  Future<void> _openCreateCoupon(
    BuildContext context, {
    CouponModel? coupon,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateCouponScreen(existing: coupon),
      ),
    );
  }

  Future<void> _openCreateOffer(
    BuildContext context, {
    OfferModel? offer,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateOfferScreen(existing: offer),
      ),
    );
  }

  void _showCreatePromotionMenu(BuildContext buttonContext) {
    final renderObject = buttonContext.findRenderObject();
    if (renderObject is! RenderBox) return;
    final buttonPosition = renderObject.localToGlobal(Offset.zero);

    showGeneralDialog<void>(
      context: buttonContext,
      barrierDismissible: true,
      barrierLabel: 'Create promotion',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (_, __, ___) {
        return RdxActionMenuDialog(
          position: buttonPosition,
          gap: 6,
          items: [
            RdxActionMenuItem(
              title: 'Create Coupon',
              onTap: () async {
                await _openCreateCoupon(context);
                if (context.mounted) {
                  ref.read(couponProvider).load();
                }
              },
            ),
            RdxActionMenuItem(
              title: 'Create Offer',
              onTap: () async {
                await _openCreateOffer(context);
                if (context.mounted) {
                  ref.read(offerProvider).load();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final couponState = ref.watch(couponProvider);
    final offerState = ref.watch(offerProvider);

    final visibleCoupons = _query.isEmpty
        ? couponState.filteredCoupons
        : couponState.filteredCoupons
            .where(
              (coupon) =>
                  coupon.code.toLowerCase().contains(_query.toLowerCase()) ||
                  coupon.description
                      .toLowerCase()
                      .contains(_query.toLowerCase()),
            )
            .toList();

    final visibleOffers = _query.isEmpty
        ? offerState.filteredOffers
        : offerState.filteredOffers
            .where(
              (offer) =>
                  offer.title.toLowerCase().contains(_query.toLowerCase()) ||
                  offer.description
                      .toLowerCase()
                      .contains(_query.toLowerCase()),
            )
            .toList();

    final filteredCoupons = switch (_typeFilter) {
      PromotionTypeFilter.all || PromotionTypeFilter.coupons => visibleCoupons,
      PromotionTypeFilter.offers => const <CouponModel>[],
    };

    final filteredOffers = switch (_typeFilter) {
      PromotionTypeFilter.all || PromotionTypeFilter.offers => visibleOffers,
      PromotionTypeFilter.coupons => const <OfferModel>[],
    };

    final totalUsageToday = couponState.filteredCoupons.fold<int>(
      0,
      (sum, coupon) => sum + coupon.usageCount,
    );

    final hasVisibleResults =
        filteredCoupons.isNotEmpty || filteredOffers.isNotEmpty;
    final emptyMessage = switch (_typeFilter) {
      PromotionTypeFilter.coupons => 'No coupons found',
      PromotionTypeFilter.offers => 'No offers found',
      PromotionTypeFilter.all => 'No coupons or offers found',
    };

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
              RdxSearchToolbar(
                hintText: 'Search coupons & offers',
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                actions: [
                  Builder(
                    builder: (buttonContext) => RdxActionButton(
                      label: 'Create Coupon',
                      leadingIcon: Icons.add,
                      onPressed: () => _showCreatePromotionMenu(buttonContext),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.h(16)),
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

                final typeTabs = RdxCategoryTabs(
                  expand: false,
                  labels: const ['Coupons', 'Offers'],
                  allLabel: 'All',
                  selectedLabel: _selectedTypeLabel(),
                  onSelected: (label) {
                    setState(() => _typeFilter = _typeForLabel(label));
                  },
                );

                final statusTabs = RdxCategoryTabs(
                  expand: false,
                  labels: const ['Active', 'Scheduled', 'Expired'],
                  allLabel: 'All',
                  selectedLabel: _selectedStatusLabel(
                    couponState.statusFilter ?? offerState.statusFilter,
                  ),
                  onSelected: (label) {
                    final status = _statusForLabel(label);
                    ref.read(couponProvider).setStatusFilter(status);
                    ref.read(offerProvider).setStatusFilter(status);
                  },
                );

                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      titleBlock,
                      SizedBox(height: context.h(12)),
                      typeTabs,
                      SizedBox(height: context.h(8)),
                      statusTabs,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: titleBlock),
                    Column(
                      children: [
                        typeTabs,
                        SizedBox(height: context.h(8)),
                        statusTabs,
                      ],
                    ),
                  ],
                );
              }),
              SizedBox(height: context.h(20)),
              Align(
                alignment: Alignment.centerLeft,
                child: StatsCollapseButton(
                  collapsed: _statsCollapsed,
                  onPressed: () => setState(
                    () => _statsCollapsed = !_statsCollapsed,
                  ),
                ),
              ),
              SizedBox(height: context.h(8)),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _statsCollapsed
                    ? const SizedBox(width: double.infinity)
                    : IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: StatCard(
                                label: 'Total Active',
                                value: '${couponState.activeCount} coupons',
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
              ),
              SizedBox(height: context.h(20)),
              Expanded(
                child: couponState.isLoading || offerState.isLoading
                    ? const LoadingIndicator()
                    : !hasVisibleResults
                        ? EmptyState(
                            message: emptyMessage,
                            icon: Icons.local_offer_outlined,
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = Responsive.gridColumns(context);
                              final spacing = context.w(16);
                              final cardWidth = (constraints.maxWidth -
                                      ((columns - 1) * spacing)) /
                                  columns;

                              final cards = <Widget>[];
                              for (final coupon in filteredCoupons) {
                                cards.add(
                                  SizedBox(
                                    width: cardWidth,
                                    child: CouponCard(
                                      coupon: coupon,
                                      onActions: (buttonContext) {
                                        _showCouponActions(
                                            buttonContext, coupon);
                                      },
                                    ),
                                  ),
                                );
                              }
                              for (final offer in filteredOffers) {
                                cards.add(
                                  SizedBox(
                                    width: cardWidth,
                                    child: OfferCard(
                                      offer: offer,
                                      onActions: (buttonContext) {
                                        _showOfferActions(buttonContext, offer);
                                      },
                                    ),
                                  ),
                                );
                              }

                              return SingleChildScrollView(
                                child: Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: cards,
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
