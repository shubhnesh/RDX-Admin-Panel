import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/screens/order_details/order_details_screen.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/order_model.dart';
import '../../providers/order_providers.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/empty_state.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';
import '../../widgets/reusable_widgets/stat_card.dart';

import 'place_order_screen.dart';
import 'widgets/live_order_card.dart';

class LiveOrdersScreen extends ConsumerStatefulWidget {
  const LiveOrdersScreen({super.key});

  @override
  ConsumerState<LiveOrdersScreen> createState() => _LiveOrdersScreenState();
}

class _LiveOrdersScreenState extends ConsumerState<LiveOrdersScreen> {
  OrderType? _typeFilter;

  /// null = All, pending = New, preparing = Preparing, ready = Ready
  OrderStatus? _statusFilter;

  Future<void> _openPlaceOrder() async {
    final placed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PlaceOrderScreen()),
    );

    if (!mounted) return;

    // Firestore stream is already reactive; invalidate to guarantee
    // a fresh read when returning from the order flow.
    ref.invalidate(liveOrdersStreamProvider);

    if (placed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New order added to the queue.')),
      );
    }
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    return orders.where((order) {
      final matchesType = _typeFilter == null || order.orderType == _typeFilter;
      final matchesStatus =
          _statusFilter == null || order.status == _statusFilter;
      return matchesType && matchesStatus;
    }).toList();
  }

  Future<void> _openOrderDetails(String orderId) async {
    if (orderId.trim().isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(orderId: orderId),
      ),
    );

    if (!mounted) return;
    ref.invalidate(liveOrdersStreamProvider);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final ordersAsync = ref.watch(liveOrdersStreamProvider);

    final allOrders = ordersAsync.value ?? <OrderModel>[];

    if (ordersAsync.hasError) {
      debugPrint('Live orders stream error: ${ordersAsync.error}');
    }

    final visibleOrders = _filterOrders(allOrders);

    final newOrders =
        allOrders.where((o) => o.status == OrderStatus.pending).toList();
    final preparingOrders =
        allOrders.where((o) => o.status == OrderStatus.preparing).toList();
    final readyOrders =
        allOrders.where((o) => o.status == OrderStatus.ready).toList();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: Responsive.pagePadding(
            context,
            top: context.h(0),
            bottom: context.h(0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RdxHeader(title: 'Live Orders', showBackButton: false),
              SizedBox(height: context.h(8)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _buildStatusTabs(context, colors)),
                  SizedBox(width: context.w(16)),
                  RdxActionButton(
                    label: 'New Order',
                    leadingIcon: Icons.add,
                    onPressed: _openPlaceOrder,
                  ),
                ],
              ),
              SizedBox(height: context.h(18)),
              Text('Live Orders', style: AppTextStyles.heading(context)),
              SizedBox(height: context.h(4)),
              Text(
                'Manage incoming orders and track their current status.',
                style: AppTextStyles.bodySecondary(context)
                    .copyWith(color: colors.textSecondary),
              ),
              SizedBox(height: context.h(18)),
              _buildSummaryCards(
                context,
                colors,
                newCount: newOrders.length,
                preparingCount: preparingOrders.length,
                readyCount: readyOrders.length,
              ),
              SizedBox(height: context.h(18)),
              Expanded(
                child: ordersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) =>
                      _buildErrorState(context, colors),
                  data: (_) {
                    if (visibleOrders.isEmpty) {
                      return const EmptyState(
                        message: 'No orders found',
                        icon: Icons.receipt_long_outlined,
                      );
                    }
                    return _buildOrderGrid(context, colors, visibleOrders);
                  },
                ),
              ),
              SizedBox(height: context.h(4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTabs(BuildContext context, AppColorScheme colors) {
    final tabs = [
      const _OrderFilterTab(label: 'All', status: null),
      const _OrderFilterTab(label: 'New', status: OrderStatus.pending),
      const _OrderFilterTab(label: 'Preparing', status: OrderStatus.preparing),
      const _OrderFilterTab(label: 'Ready', status: OrderStatus.ready),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in tabs) ...[
            _buildFilterChip(
              context,
              colors,
              label: tab.label,
              selected: _statusFilter == tab.status,
              onTap: () => setState(() => _statusFilter = tab.status),
            ),
            SizedBox(width: context.w(8)),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    AppColorScheme colors, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.h(20)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: EdgeInsets.symmetric(
            horizontal: context.w(15),
            vertical: context.h(8),
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : colors.surface,
            borderRadius: BorderRadius.circular(context.h(20)),
            border: Border.all(
              color: selected ? AppColors.primary : colors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.label(context).copyWith(
              color: selected ? Colors.white : colors.textPrimary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    AppColorScheme colors, {
    required int newCount,
    required int preparingCount,
    required int readyCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 700;

        final cards = [
          _summaryCard(
            context,
            label: 'New Orders',
            value: '$newCount orders',
            icon: Icons.access_time_rounded,
            accentColor: AppColors.primary,
          ),
          _summaryCard(
            context,
            label: 'Preparing',
            value: '$preparingCount orders',
            icon: Icons.restaurant_rounded,
            accentColor: AppColors.success,
          ),
          _summaryCard(
            context,
            label: 'Ready',
            value: '$readyCount orders',
            icon: Icons.check_circle_outline_rounded,
            accentColor: AppColors.primary,
          ),
        ];

        if (narrow) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i != cards.length - 1) SizedBox(height: context.h(10)),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) SizedBox(width: context.w(16)),
            ],
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return StatCard(
      label: label,
      value: value,
      icon: icon,
      accentColor: accentColor,
      horizontal: true,
    );
  }

  Widget _buildOrderGrid(
    BuildContext context,
    AppColorScheme colors,
    List<OrderModel> orders,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns;
        if (width >= 1050) {
          columns = 4;
        } else if (width >= 760) {
          columns = 3;
        } else if (width >= 500) {
          columns = 2;
        } else {
          columns = 1;
        }

        const spacing = 16.0;
        final cardWidth =
            columns == 1 ? width : (width - ((columns - 1) * spacing)) / columns;

        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: context.h(24)),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final order in orders)
                SizedBox(
                  width: cardWidth,
                  child: LiveOrderCard(
                    order: order,
                    onTap: () => _openOrderDetails(order.id),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, AppColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: context.w(48),
            height: context.w(48),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(context.h(12)),
            ),
            child: Icon(
              Icons.cloud_off_outlined,
              color: AppColors.danger,
              size: context.w(24),
            ),
          ),
          SizedBox(height: context.h(12)),
          Text(
            'Unable to load orders',
            style: AppTextStyles.section(context).copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: context.h(5)),
          Text(
            'Please check your connection and try again.',
            style: AppTextStyles.bodySecondary(context)
                .copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: context.h(14)),
          RdxActionButton(
            label: 'Refresh',
            leadingIcon: Icons.refresh_rounded,
            onPressed: () => ref.invalidate(liveOrdersStreamProvider),
          ),
        ],
      ),
    );
  }
}

class _OrderFilterTab {
  final String label;
  final OrderStatus? status;

  const _OrderFilterTab({required this.label, required this.status});
}
