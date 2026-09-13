import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
import '../../providers/menu_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/reusable_widgets/empty_state.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';
import '../../widgets/resuable_options/rdx_category_tabs.dart';
import '../../widgets/resuable_options/rdx_search_bar.dart';
import '../../widgets/resuable_options/rdx_text_field.dart';
import 'widgets/cart_panel.dart';
import 'widgets/order_menu_item_card.dart';

/// Lets front-of-house staff build an order for a walk-in/phone/table
/// customer: browse the same menu (via [menuNotifierProvider]), tap
/// items to customize + add to cart, then check out. Both the menu and
/// the cart are Riverpod state, so the cart persists cleanly across the
/// Checkout screen without constructor plumbing.
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
      if (mounted) ref.read(menuNotifierProvider.notifier).load();
    });
  }

  void _openCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.fromLTRB(
            context.w(18),
            context.h(14),
            context.w(18),
            context.h(16),
          ),
          decoration: BoxDecoration(
            color: AppColors.of(context).surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(context.h(18))),
          ),
          child: SafeArea(
            top: false,
            child: const CartPanel(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuNotifierProvider);
    final colors = AppColors.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 900;
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const RdxHeader(title: 'Place Order', showBackButton: true),
          Expanded(
            child: menuState.isLoading
                ? const LoadingIndicator()
                : Padding(
                    padding: Responsive.pagePadding(context,
                        top: context.h(14), bottom: context.h(0)),
                    child: narrow
                        ? _menuColumn(context, menuState, colors)
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding:
                                      EdgeInsets.only(right: context.w(20)),
                                  child:
                                      _menuColumn(context, menuState, colors),
                                ),
                              ),
                              VerticalDivider(
                                width: context.w(1),
                                thickness: context.w(1),
                                color: colors.border,
                              ),
                              SizedBox(
                                width: context.w(340),
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: context.w(20),
                                    top: context.h(4),
                                  ),
                                  child: const CartPanel(),
                                ),
                              ),
                            ],
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: narrow && cartCount > 0
          ? FloatingActionButton.extended(
              onPressed: _openCartSheet,
              backgroundColor: AppColors.primary,
              icon: Badge(
                label: Text('$cartCount'),
                child: const Icon(Icons.shopping_cart_outlined,
                    color: Colors.white),
              ),
              label: Text(
                'View Cart',
                style:
                    AppTextStyles.label(context).copyWith(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _menuColumn(
      BuildContext context, MenuState menuState, AppColorScheme colors) {
    final notifier = ref.read(menuNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RdxSearchBar(
          height: RdxTextField.singleLineHeight(context),
          hintText: 'Search menu items',
          onChanged: notifier.setSearchQuery,
        ),
        SizedBox(height: context.h(14)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: context.h(10)),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colors.divider),
              bottom: BorderSide(color: colors.divider),
            ),
          ),
          child: RdxCategoryTabs(
            labels: menuState.categories.where((c) => c != 'All').toList(),
            allLabel: 'All',
            selectedLabel: menuState.selectedCategory,
            onSelected: notifier.setCategory,
            expand: false,
          ),
        ),
        SizedBox(height: context.h(16)),
        Expanded(
          child: menuState.filteredItems.isEmpty
              ? const EmptyState(message: 'No menu items found')
              : GridView.builder(
                  padding: EdgeInsets.only(bottom: context.h(90)),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: context.w(240),
                    mainAxisExtent: context.h(260),
                    mainAxisSpacing: context.h(14),
                    crossAxisSpacing: context.w(14),
                  ),
                  itemCount: menuState.filteredItems.length,
                  itemBuilder: (context, index) =>
                      OrderMenuItemCard(item: menuState.filteredItems[index]),
                ),
        ),
      ],
    );
  }
}
