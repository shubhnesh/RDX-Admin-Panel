// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../core/router/app_router.dart';
// import '../../core/theme/app_colors.dart';
// import '../../core/theme/text_styles.dart';
// import '../../core/utils/responsive_size.dart';
// import '../../models/coupon_model.dart';
// import '../../providers/coupon_provider.dart';
// import '../../widgets/empty_state.dart';
// import '../../widgets/form_action_button.dart';
// import '../../widgets/loading_indicator.dart';
// import '../../widgets/rdx_search_bar.dart';
// import '../../widgets/rdx_category_tabs.dart';
// import '../../widgets/stat_card.dart';
// import '../../widgets/coupon_card.dart';

// class CouponsScreen extends StatefulWidget {
//   const CouponsScreen({super.key});

//   @override
//   State<CouponsScreen> createState() => _CouponsScreenState();
// }

// class _CouponsScreenState extends State<CouponsScreen> {
//   final _searchController = TextEditingController();
//   String _query = '';

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;
//       context.read<CouponProvider>().load();
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   String _selectedStatusLabel(CouponProvider provider) =>
//       switch (provider.statusFilter) {
//         CouponStatus.active => 'Active',
//         CouponStatus.scheduled => 'Scheduled',
//         CouponStatus.expired => 'Expired',
//         null => 'All',
//       };

//   CouponStatus? _statusForLabel(String label) => switch (label) {
//         'Active' => CouponStatus.active,
//         'Scheduled' => CouponStatus.scheduled,
//         'Expired' => CouponStatus.expired,
//         _ => null,
//       };

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);
//     final provider = context.watch<CouponProvider>();

//     final visibleCoupons = _query.isEmpty
//         ? provider.filteredCoupons
//         : provider.filteredCoupons
//             .where(
//               (c) =>
//                   c.code.toLowerCase().contains(_query.toLowerCase()) ||
//                   c.description.toLowerCase().contains(_query.toLowerCase()),
//             )
//             .toList();

//     final totalUsageToday = provider.filteredCoupons.fold<int>(
//       0,
//       (sum, c) => sum + c.usageCount,
//     );

//     return Scaffold(
//       backgroundColor: colors.background,
//       body: SafeArea(
//         child: Padding(
//           padding: Responsive.pagePadding(
//             context,
//             top: context.h(14),
//             bottom: context.h(0),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ── Search + Create button ──────────────────────────
//               RdxSearchToolbar(
//                 hintText: 'Search coupons',
//                 controller: _searchController,
//                 onChanged: (v) => setState(() => _query = v),
//                 actions: [
//                   FormActionButton(
//                     label: 'Create Coupon',
//                     onPressed: () async {
//                       await Navigator.of(context).pushNamed(
//                         AppRoutes.createCoupon,
//                       );
//                       if (context.mounted) {
//                         context.read<CouponProvider>().load();
//                       }
//                     },
//                   ),
//                 ],
//               ),

//               SizedBox(height: context.h(16)),

//               // ── Title + status filter on the same row ───────────
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Coupons & Offers',
//                           style: AppTextStyles.heading(context),
//                         ),
//                         SizedBox(height: context.h(4)),
//                         Text(
//                           'Manage active promotions and discount codes.',
//                           style: AppTextStyles.bodySecondary(context).copyWith(
//                             color: colors.textSecondary,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   RdxCategoryTabs(
//                     expand: false,
//                     labels: const ['Active', 'Scheduled', 'Expired'],
//                     allLabel: 'All',
//                     selectedLabel: _selectedStatusLabel(provider),
//                     onSelected: (label) {
//                       provider.setStatusFilter(_statusForLabel(label));
//                     },
//                   ),
//                 ],
//               ),

//               SizedBox(height: context.h(20)),

//               // ── Summary stat cards ──────────────────────────────
//               IntrinsicHeight(
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     Expanded(
//                       child: StatCard(
//                         label: 'Total Active',
//                         value: '${provider.activeCount} coupons',
//                         icon: Icons.local_offer_outlined,
//                       ),
//                     ),
//                     SizedBox(width: context.w(16)),
//                     Expanded(
//                       child: StatCard(
//                         label: 'Total Usages Today',
//                         value: '$totalUsageToday',
//                         icon: Icons.trending_up_rounded,
//                         accentColor: AppColors.success,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               SizedBox(height: context.h(20)),

//               // ── Coupon grid ─────────────────────────────────────
//               Expanded(
//                 child: provider.isLoading
//                     ? const LoadingIndicator()
//                     : visibleCoupons.isEmpty
//                         ? const EmptyState(
//                             message: 'No coupons found',
//                             icon: Icons.local_offer_outlined,
//                           )
//                         : LayoutBuilder(
//                             builder: (context, constraints) {
//                               final columns = Responsive.gridColumns(context);
//                               final spacing = context.w(16);

//                               final cardWidth = (constraints.maxWidth -
//                                       ((columns - 1) * spacing)) /
//                                   columns;

//                               return SingleChildScrollView(
//                                 child: Wrap(
//                                   spacing: spacing,
//                                   runSpacing: spacing,
//                                   children: visibleCoupons.map((coupon) {
//                                     return SizedBox(
//                                       width: cardWidth,
//                                       child: CouponCard(
//                                         coupon: coupon,
//                                         onDelete: () =>
//                                             provider.deleteCoupon(coupon.id),
//                                       ),
//                                     );
//                                   }).toList(),
//                                 ),
//                               );
//                             },
//                           ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// /* replaced by shared CouponCard */
// /*
// class _CouponCard extends StatelessWidget {
//   final CouponModel coupon;
//   final VoidCallback onDelete;

//   const _CouponCard({
//     required this.coupon,
//     required this.onDelete,
//   });

//   Color _statusColor(BuildContext context) {
//     switch (coupon.status) {
//       case CouponStatus.active:
//         return AppColors.success;
//       case CouponStatus.scheduled:
//         return AppColors.info;
//       case CouponStatus.expired:
//         return AppColors.of(context).textMuted;
//     }
//   }

//   double get _usageProgress {
//     if (coupon.usageLimit == null || coupon.usageLimit == 0) return 0;
//     return (coupon.usageCount / coupon.usageLimit!).clamp(0, 1).toDouble();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colors = AppColors.of(context);
//     final statusColor = _statusColor(context);
//     final isExpired = coupon.status == CouponStatus.expired;

//     final discount = coupon.discountType == DiscountType.percentage
//         ? '${coupon.discountValue.toStringAsFixed(0)}% OFF'
//         : '${Formatters.currency(coupon.discountValue)} OFF';

//     final usageLabel = coupon.usageLimit == null
//         ? '${coupon.usageCount} used · No limit'
//         : '${coupon.usageCount} of ${coupon.usageLimit} used';

//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(context.h(14)),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(context.h(10)),
//         border: Border.all(color: colors.border),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.04),
//             blurRadius: context.h(10),
//             offset: Offset(0, context.h(3)),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ── Status + menu ────────────────────────────────────────
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Flexible(
//                 child: Container(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: context.w(8),
//                     vertical: context.h(4),
//                   ),
//                   decoration: BoxDecoration(
//                     color: statusColor.withValues(alpha: 0.1),
//                     borderRadius: BorderRadius.circular(context.h(5)),
//                   ),
//                   child: Text(
//                     coupon.status.name.toUpperCase(),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: AppTextStyles.label(context)
//                         .copyWith(color: statusColor),
//                   ),
//                 ),
//               ),
//               const Spacer(),
//               PopupMenuButton<String>(
//                 icon: Icon(
//                   Icons.more_vert,
//                   size: context.h(18),
//                   color: colors.textMuted,
//                 ),
//                 color: colors.surface,
//                 onSelected: (v) {
//                   if (v == 'delete') onDelete();
//                 },
//                 padding: EdgeInsets.zero,
//                 constraints: BoxConstraints(
//                   minWidth: context.w(28),
//                   minHeight: context.h(28),
//                 ),
//                 itemBuilder: (context) => [
//                   const PopupMenuItem(value: 'edit', child: Text('Edit')),
//                   PopupMenuItem(
//                     value: 'delete',
//                     child: Text(
//                       'Delete',
//                       style: TextStyle(color: AppColors.danger),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),

//           SizedBox(height: context.h(8)),

//           // ── Coupon code + copy ──────────────────────────────────
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   coupon.code,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: AppTextStyles.heading(context),
//                 ),
//               ),
//               SizedBox(width: context.w(4)),
//               IconButton(
//                 tooltip: 'Copy coupon code',
//                 onPressed: () {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Coupon code copied')),
//                   );
//                 },
//                 icon: Icon(
//                   Icons.copy_outlined,
//                   size: context.h(15),
//                   color: colors.textMuted,
//                 ),
//                 visualDensity: VisualDensity.compact,
//                 padding: EdgeInsets.zero,
//                 constraints: BoxConstraints(
//                   minWidth: context.w(32),
//                   minHeight: context.h(32),
//                 ),
//               ),
//             ],
//           ),

//           // ── Description ─────────────────────────────────────────
//           Text(
//             coupon.description.isEmpty
//                 ? 'No description added'
//                 : coupon.description,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//             style: AppTextStyles.bodySecondary(context),
//           ),

//           SizedBox(height: context.h(10)),

//           // ── Discount ────────────────────────────────────────────
//           Container(
//             width: double.infinity,
//             padding: EdgeInsets.symmetric(
//               horizontal: context.w(10),
//               vertical: context.h(9),
//             ),
//             decoration: BoxDecoration(
//               color: const Color(0xFFFFF3EC),
//               borderRadius: BorderRadius.circular(context.h(7)),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.local_offer_outlined,
//                   size: context.h(17),
//                   color: AppColors.primary,
//                 ),
//                 SizedBox(width: context.w(8)),
//                 Flexible(
//                   child: Text(
//                     discount,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: AppTextStyles.section(context)
//                         .copyWith(color: AppColors.primary),
//                   ),
//                 ),
//                 if (coupon.minOrderValue != null) ...[
//                   SizedBox(width: context.w(8)),
//                   Flexible(
//                     child: Text(
//                       'Min. ${Formatters.currency(coupon.minOrderValue!)}',
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       textAlign: TextAlign.end,
//                       style: AppTextStyles.label(context),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),

//           SizedBox(height: context.h(11)),

//           // ── Usage progress ──────────────────────────────────────
//           if (coupon.usageLimit != null)
//             ClipRRect(
//               borderRadius: BorderRadius.circular(context.h(4)),
//               child: LinearProgressIndicator(
//                 value: _usageProgress,
//                 minHeight: context.h(6),
//                 backgroundColor: colors.surfaceVariant,
//                 valueColor: AlwaysStoppedAnimation(
//                   isExpired ? colors.textMuted : AppColors.primary,
//                 ),
//               ),
//             ),

//           SizedBox(height: context.h(5)),

//           // ── Usage information ──────────────────────────────────
//           Row(
//             children: [
//               Icon(
//                 Icons.bar_chart_outlined,
//                 size: context.h(14),
//                 color: colors.textMuted,
//               ),
//               SizedBox(width: context.w(5)),
//               Expanded(
//                 child: Text(
//                   usageLabel,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: AppTextStyles.label(context),
//                 ),
//               ),
//             ],
//           ),

//           SizedBox(height: context.h(8)),

//           Divider(color: colors.divider, height: context.h(1)),

//           SizedBox(height: context.h(8)),

//           // ── Date + current status ───────────────────────────────
//           Row(
//             children: [
//               Icon(
//                 Icons.event_outlined,
//                 size: context.h(14),
//                 color: colors.textMuted,
//               ),
//               SizedBox(width: context.w(5)),
//               Expanded(
//                 child: Text(
//                   '${Formatters.date(coupon.startDate)} - ${Formatters.date(coupon.endDate)}',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: AppTextStyles.label(context)
//                       .copyWith(color: colors.textMuted),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
// */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/coupon_model.dart';
import '../../providers/coupon_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/form_action_button.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rdx_search_bar.dart';
import '../../widgets/rdx_category_tabs.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CouponProvider>().load();
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final provider = context.watch<CouponProvider>();

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
                  FormActionButton(
                    label: 'Create Coupon',
                    onPressed: () async {
                      await Navigator.of(context).pushNamed(
                        AppRoutes.createCoupon,
                      );
                      if (context.mounted) {
                        context.read<CouponProvider>().load();
                      }
                    },
                  ),
                ],
              ),

              SizedBox(height: context.h(16)),

              // ── Title + status filter on the same row ───────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
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
                    ),
                  ),
                  RdxCategoryTabs(
                    expand: false,
                    labels: const ['Active', 'Scheduled', 'Expired'],
                    allLabel: 'All',
                    selectedLabel: _selectedStatusLabel(provider),
                    onSelected: (label) {
                      provider.setStatusFilter(_statusForLabel(label));
                    },
                  ),
                ],
              ),

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
                                      child: _CouponCard(
                                        coupon: coupon,
                                        onDelete: () =>
                                            provider.deleteCoupon(coupon.id),
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

class _CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final VoidCallback onDelete;

  const _CouponCard({
    required this.coupon,
    required this.onDelete,
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
                    horizontal: context.w(8),
                    vertical: context.h(4),
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(context.h(5)),
                  ),
                  child: Text(
                    coupon.status.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label(context)
                        .copyWith(color: statusColor),
                  ),
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: context.h(18),
                  color: colors.textMuted,
                ),
                color: colors.surface,
                onSelected: (v) {
                  if (v == 'delete') onDelete();
                },
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: context.w(28),
                  minHeight: context.h(28),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                ],
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coupon code copied')),
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

          // ── Description ─────────────────────────────────────────
          Text(
            coupon.description.isEmpty
                ? 'No description added'
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