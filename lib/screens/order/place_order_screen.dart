import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/screens/order/checkout_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/reusable_widgets/empty_state.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';
import '../../widgets/resuable_options/rdx_category_tabs.dart';
import '../../widgets/resuable_options/rdx_search_bar.dart';
import '../../widgets/resuable_options/rdx_text_field.dart';
import 'widgets/cart_panel.dart';
import 'widgets/order_menu_item_card.dart';

class PlaceOrderScreen extends ConsumerStatefulWidget {
  const PlaceOrderScreen({super.key});

  @override
  ConsumerState<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends ConsumerState<PlaceOrderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(menuNotifierProvider.notifier).load();
    });
  }

  /// Moves from the active order/cart screen to checkout.
  /// This does NOT create the Firestore order — CheckoutScreen owns that.
  void _goToCheckout() {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuNotifierProvider);
    final colors = AppColors.of(context);

    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 900;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const RdxHeader(title: 'Create New Order', showBackButton: true),
          Expanded(
            child: menuState.isLoading
                ? const LoadingIndicator()
                : Padding(
                    padding: Responsive.pagePadding(
                      context,
                      top: context.h(10),
                      bottom: context.h(10),
                    ),
                    child: isCompact
                        ? _buildCompactLayout(context, menuState, colors)
                        : _buildDesktopLayout(context, menuState, colors),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    MenuState menuState,
    AppColorScheme colors,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: context.w(14)),
            child: _buildMenuArea(context, menuState, colors),
          ),
        ),
        VerticalDivider(width: context.w(1), thickness: 1, color: colors.border),
        SizedBox(
          width: context.w(350),
          child: Padding(
            padding: EdgeInsets.only(left: context.w(14)),
            child: CartPanel(onProceed: _goToCheckout),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout(
    BuildContext context,
    MenuState menuState,
    AppColorScheme colors,
  ) {
    return Column(
      children: [
        Expanded(child: _buildMenuArea(context, menuState, colors)),
        SizedBox(height: context.h(12)),
        SizedBox(
          height: context.h(360),
          child: CartPanel(onProceed: _goToCheckout),
        ),
      ],
    );
  }

  Widget _buildMenuArea(
    BuildContext context,
    MenuState menuState,
    AppColorScheme colors,
  ) {
    final notifier = ref.read(menuNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RdxSearchBar(
          height: RdxTextField.singleLineHeight(context),
          hintText: 'Search menu items...',
          onChanged: notifier.setSearchQuery,
        ),
        SizedBox(height: context.h(10)),
        SizedBox(
          height: context.h(38),
          child: RdxCategoryTabs(
            labels: menuState.categories.where((c) => c != 'All').toList(),
            allLabel: 'All',
            selectedLabel: menuState.selectedCategory,
            onSelected: notifier.setCategory,
            expand: false,
          ),
        ),
        SizedBox(height: context.h(8)),
        Expanded(
          child: menuState.filteredItems.isEmpty
              ? const EmptyState(message: 'No menu items found')
              : GridView.builder(
                  padding: EdgeInsets.only(bottom: context.h(4)),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: context.w(220),
                    mainAxisExtent: context.h(116),
                    mainAxisSpacing: context.h(10),
                    crossAxisSpacing: context.w(10),
                  ),
                  itemCount: menuState.filteredItems.length,
                  itemBuilder: (context, index) {
                    return OrderMenuItemCard(item: menuState.filteredItems[index]);
                  },
                ),
        ),
      ],
    );
  }
}
