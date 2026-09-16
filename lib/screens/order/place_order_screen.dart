// // // // import 'package:flutter/material.dart';
// // // // import 'package:flutter_riverpod/flutter_riverpod.dart';

// // // // import '../../core/theme/app_colors.dart';
// // // // import '../../core/theme/text_styles.dart';
// // // // import '../../core/utils/responsive_size.dart';
// // // // import '../../providers/menu_provider.dart';
// // // // import '../../providers/cart_provider.dart';
// // // // import '../../widgets/reusable_widgets/empty_state.dart';
// // // // import '../../widgets/reusable_widgets/loading_indicator.dart';
// // // // import '../../widgets/reusable_widgets/rdx_header.dart';
// // // // import '../../widgets/resuable_options/rdx_category_tabs.dart';
// // // // import '../../widgets/resuable_options/rdx_search_bar.dart';
// // // // import '../../widgets/resuable_options/rdx_text_field.dart';
// // // // import 'widgets/cart_panel.dart';
// // // // import 'widgets/order_menu_item_card.dart';

// // // // /// Lets front-of-house staff build an order for a walk-in/phone/table
// // // // /// customer: browse the same menu (via [menuNotifierProvider]), tap
// // // // /// items to customize + add to cart, then check out. Both the menu and
// // // // /// the cart are Riverpod state, so the cart persists cleanly across the
// // // // /// Checkout screen without constructor plumbing.
// // // // class PlaceOrderScreen extends ConsumerStatefulWidget {
// // // //   const PlaceOrderScreen({super.key});

// // // //   @override
// // // //   ConsumerState<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
// // // // }

// // // // class _PlaceOrderScreenState extends ConsumerState<PlaceOrderScreen> {
// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // // //       if (mounted) ref.read(menuNotifierProvider.notifier).load();
// // // //     });
// // // //   }

// // // //   void _openCartSheet() {
// // // //     showModalBottomSheet(
// // // //       context: context,
// // // //       isScrollControlled: true,
// // // //       backgroundColor: Colors.transparent,
// // // //       builder: (_) => DraggableScrollableSheet(
// // // //         initialChildSize: 0.75,
// // // //         minChildSize: 0.4,
// // // //         maxChildSize: 0.95,
// // // //         expand: false,
// // // //         builder: (context, scrollController) => Container(
// // // //           padding: EdgeInsets.fromLTRB(
// // // //             context.w(18),
// // // //             context.h(14),
// // // //             context.w(18),
// // // //             context.h(16),
// // // //           ),
// // // //           decoration: BoxDecoration(
// // // //             color: AppColors.of(context).surface,
// // // //             borderRadius:
// // // //                 BorderRadius.vertical(top: Radius.circular(context.h(18))),
// // // //           ),
// // // //           child: SafeArea(
// // // //             top: false,
// // // //             child: const CartPanel(),
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final menuState = ref.watch(menuNotifierProvider);
// // // // //     final colors = AppColors.of(context);
// // // // //     final narrow = MediaQuery.sizeOf(context).width < 900;
// // // // //     final cartCount = ref.watch(cartCountProvider);

// // // // //     return Scaffold(
// // // // //       backgroundColor: colors.background,
// // // // //       body: Column(
// // // // //         children: [
// // // // //           const RdxHeader(title: 'Place Order', showBackButton: true),
// // // // //           Expanded(
// // // // //             child: menuState.isLoading
// // // // //                 ? const LoadingIndicator()
// // // // //                 : Padding(
// // // // //                     padding: Responsive.pagePadding(context,
// // // // //                         top: context.h(14), bottom: context.h(0)),
// // // // //                     child: narrow
// // // // //                         ? _menuColumn(context, menuState, colors)
// // // // //                         : Row(
// // // // //                             crossAxisAlignment: CrossAxisAlignment.stretch,
// // // // //                             children: [
// // // // //                               Expanded(
// // // // //                                 child: Padding(
// // // // //                                   padding:
// // // // //                                       EdgeInsets.only(right: context.w(20)),
// // // // //                                   child:
// // // // //                                       _menuColumn(context, menuState, colors),
// // // // //                                 ),
// // // // //                               ),
// // // // //                               VerticalDivider(
// // // // //                                 width: context.w(1),
// // // // //                                 thickness: context.w(1),
// // // // //                                 color: colors.border,
// // // // //                               ),
// // // // //                               SizedBox(
// // // // //                                 width: context.w(340),
// // // // //                                 child: Padding(
// // // // //                                   padding: EdgeInsets.only(
// // // // //                                     left: context.w(20),
// // // // //                                     top: context.h(4),
// // // // //                                   ),
// // // // //                                   child: const CartPanel(),
// // // // //                                 ),
// // // // //                               ),
// // // // //                             ],
// // // // //                           ),
// // // // //                   ),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //       floatingActionButton: narrow && cartCount > 0
// // // // //           ? FloatingActionButton.extended(
// // // // //               onPressed: _openCartSheet,
// // // // //               backgroundColor: AppColors.primary,
// // // // //               icon: Badge(
// // // // //                 label: Text('$cartCount'),
// // // // //                 child: const Icon(Icons.shopping_cart_outlined,
// // // // //                     color: Colors.white),
// // // // //               ),
// // // // //               label: Text(
// // // // //                 'View Cart',
// // // // //                 style:
// // // // //                     AppTextStyles.label(context).copyWith(color: Colors.white),
// // // // //               ),
// // // // //             )
// // // // //           : null,
// // // // //     );
// // // // //   }

// // // // //   Widget _menuColumn(
// // // // //       BuildContext context, MenuState menuState, AppColorScheme colors) {
// // // // //     final notifier = ref.read(menuNotifierProvider.notifier);

// // // // //     return Column(
// // // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // // //       children: [
// // // // //         RdxSearchBar(
// // // // //           height: RdxTextField.singleLineHeight(context),
// // // // //           hintText: 'Search menu items',
// // // // //           onChanged: notifier.setSearchQuery,
// // // // //         ),
// // // // //         SizedBox(height: context.h(14)),
// // // // //         Container(
// // // // //           width: double.infinity,
// // // // //           padding: EdgeInsets.symmetric(vertical: context.h(10)),
// // // // //           decoration: BoxDecoration(
// // // // //             border: Border(
// // // // //               top: BorderSide(color: colors.divider),
// // // // //               bottom: BorderSide(color: colors.divider),
// // // // //             ),
// // // // //           ),
// // // // //           child: RdxCategoryTabs(
// // // // //             labels: menuState.categories.where((c) => c != 'All').toList(),
// // // // //             allLabel: 'All',
// // // // //             selectedLabel: menuState.selectedCategory,
// // // // //             onSelected: notifier.setCategory,
// // // // //             expand: false,
// // // // //           ),
// // // // //         ),
// // // // //         SizedBox(height: context.h(16)),
// // // // //         Expanded(
// // // // //           child: menuState.filteredItems.isEmpty
// // // // //               ? const EmptyState(message: 'No menu items found')
// // // // //               : GridView.builder(
// // // // //                   padding: EdgeInsets.only(bottom: context.h(90)),
// // // // //                   gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
// // // // //                     maxCrossAxisExtent: context.w(240),
// // // // //                     mainAxisExtent: context.h(260),
// // // // //                     mainAxisSpacing: context.h(14),
// // // // //                     crossAxisSpacing: context.w(14),
// // // // //                   ),
// // // // //                   itemCount: menuState.filteredItems.length,
// // // // //                   itemBuilder: (context, index) =>
// // // // //                       OrderMenuItemCard(item: menuState.filteredItems[index]),
// // // // //                 ),
// // // // //         ),
// // // // //       ],
// // // // //     );
// // // // //   }

// // // // // place_order_screen.dart – only the parts that need layout tweaks

// // // // // Inside _PlaceOrderScreenState.build, replace the narrow / wide body
// // // // // with the version below (keep the rest of the class the same).

// // // // // … existing imports & class …

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final menuState = ref.watch(menuNotifierProvider);
// // // //     final colors = AppColors.of(context);
// // // //     final narrow = MediaQuery.sizeOf(context).width < 900;
// // // //     final cartCount = ref.watch(cartCountProvider);

// // // //     return Scaffold(
// // // //       backgroundColor: colors.background,
// // // //       body: Column(
// // // //         children: [
// // // //           const RdxHeader(title: 'Create New Order', showBackButton: true),
// // // //           Expanded(
// // // //             child: menuState.isLoading
// // // //                 ? const LoadingIndicator()
// // // //                 : Padding(
// // // //                     padding: Responsive.pagePadding(context,
// // // //                         top: context.h(10), bottom: context.h(0)),
// // // //                     child: narrow
// // // //                         ? _menuColumn(context, menuState, colors)
// // // //                         : Row(
// // // //                             crossAxisAlignment: CrossAxisAlignment.stretch,
// // // //                             children: [
// // // //                               Expanded(
// // // //                                 flex: 3,
// // // //                                 child: Padding(
// // // //                                   padding:
// // // //                                       EdgeInsets.only(right: context.w(16)),
// // // //                                   child:
// // // //                                       _menuColumn(context, menuState, colors),
// // // //                                 ),
// // // //                               ),
// // // //                               VerticalDivider(
// // // //                                 width: 1,
// // // //                                 thickness: 1,
// // // //                                 color: colors.border,
// // // //                               ),
// // // //                               SizedBox(
// // // //                                 width: context.w(360),
// // // //                                 child: Padding(
// // // //                                   padding: EdgeInsets.only(
// // // //                                     left: context.w(16),
// // // //                                     top: context.h(4),
// // // //                                   ),
// // // //                                   child: const CartPanel(),
// // // //                                 ),
// // // //                               ),
// // // //                             ],
// // // //                           ),
// // // //                   ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       floatingActionButton: narrow && cartCount > 0
// // // //           ? FloatingActionButton.extended(
// // // //               onPressed: _openCartSheet,
// // // //               backgroundColor: AppColors.primary,
// // // //               icon: Badge(
// // // //                 label: Text('$cartCount'),
// // // //                 child: const Icon(Icons.shopping_cart_outlined,
// // // //                     color: Colors.white),
// // // //               ),
// // // //               label: Text(
// // // //                 'View Cart',
// // // //                 style:
// // // //                     AppTextStyles.label(context).copyWith(color: Colors.white),
// // // //               ),
// // // //             )
// // // //           : null,
// // // //     );
// // // //   }

// // // //   Widget _menuColumn(
// // // //       BuildContext context, MenuState menuState, AppColorScheme colors) {
// // // //     final notifier = ref.read(menuNotifierProvider.notifier);

// // // //     return Column(
// // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // //       children: [
// // // //         // ── order type + table row (matches Figma top bar) ────────────
// // // //         Container(
// // // //           padding: EdgeInsets.symmetric(
// // // //               horizontal: context.w(12), vertical: context.h(10)),
// // // //           decoration: BoxDecoration(
// // // //             color: colors.surface,
// // // //             borderRadius: BorderRadius.circular(context.h(10)),
// // // //             border: Border.all(color: colors.border),
// // // //           ),
// // // //           child: Row(
// // // //             children: [
// // // //               _orderTypeChip(context, colors, 'Eat In', true),
// // // //               SizedBox(width: context.w(8)),
// // // //               _orderTypeChip(context, colors, 'To Go', false),
// // // //               SizedBox(width: context.w(8)),
// // // //               _orderTypeChip(context, colors, 'Delivery', false),
// // // //               const Spacer(),
// // // //               Text(
// // // //                 'Table  ·  No Table (Counter)',
// // // //                 style: AppTextStyles.caption(context)
// // // //                     .copyWith(color: colors.textMuted),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //         SizedBox(height: context.h(12)),

// // // //         // search
// // // //         RdxSearchBar(
// // // //           height: RdxTextField.singleLineHeight(context),
// // // //           hintText: 'Search menu items…',
// // // //           onChanged: notifier.setSearchQuery,
// // // //         ),
// // // //         SizedBox(height: context.h(12)),

// // // //         // category tabs
// // // //         Container(
// // // //           width: double.infinity,
// // // //           padding: EdgeInsets.symmetric(vertical: context.h(8)),
// // // //           child: RdxCategoryTabs(
// // // //             labels: menuState.categories.where((c) => c != 'All').toList(),
// // // //             allLabel: 'All',
// // // //             selectedLabel: menuState.selectedCategory,
// // // //             onSelected: notifier.setCategory,
// // // //             expand: false,
// // // //           ),
// // // //         ),
// // // //         SizedBox(height: context.h(12)),

// // // //         // menu grid
// // // //         Expanded(
// // // //           child: menuState.filteredItems.isEmpty
// // // //               ? const EmptyState(message: 'No menu items found')
// // // //               : GridView.builder(
// // // //                   padding: EdgeInsets.only(bottom: context.h(90)),
// // // //                   gridDelegate: fromLTRB(
// // // //                     maxCrossAxisExtent: context.w(220),
// // // //                     mainAxisExtent: context.h(210),
// // // //                     mainAxisSpacing: context.h(12),
// // // //                     crossAxisSpacing: context.w(12),
// // // //                   ),
// // // //                   itemCount: menuState.filteredItems.length,
// // // //                   itemBuilder: (context, index) =>
// // // //                       OrderMenuItemCard(item: menuState.filteredItems[index]),
// // // //                 ),
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }

// // // //   Widget _orderTypeChip(BuildContext context, AppColorScheme colors,
// // // //       String label, bool selected) {
// // // //     return Container(
// // // //       padding: EdgeInsets.symmetric(
// // // //           horizontal: context.w(12), vertical: context.h(6)),
// // // //       decoration: BoxDecoration(
// // // //         color: selected ? AppColors.primary : colors.surfaceVariant,
// // // //         borderRadius: BorderRadius.circular(context.h(8)),
// // // //         border: Border.all(
// // // //           color: selected ? AppColors.primary : colors.border,
// // // //         ),
// // // //       ),
// // // //       child: Text(
// // // //         label,
// // // //         style: AppTextStyles.label(context).copyWith(
// // // //           color: selected ? Colors.white : colors.textPrimary,
// // // //           fontWeight: FontWeight.w600,
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_riverpod/flutter_riverpod.dart';

// // // import '../../core/theme/app_colors.dart';
// // // import '../../core/theme/text_styles.dart';
// // // import '../../core/utils/responsive_size.dart';
// // // import '../../providers/menu_provider.dart';
// // // import '../../providers/cart_provider.dart';
// // // import '../../widgets/reusable_widgets/empty_state.dart';
// // // import '../../widgets/reusable_widgets/loading_indicator.dart';
// // // import '../../widgets/reusable_widgets/rdx_header.dart';
// // // import '../../widgets/resuable_options/rdx_category_tabs.dart';
// // // import '../../widgets/resuable_options/rdx_search_bar.dart';
// // // import '../../widgets/resuable_options/rdx_text_field.dart';
// // // import 'widgets/cart_panel.dart';
// // // import 'widgets/order_menu_item_card.dart';

// // // class PlaceOrderScreen extends ConsumerStatefulWidget {
// // //   const PlaceOrderScreen({super.key});

// // //   @override
// // //   ConsumerState<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
// // // }

// // // class _PlaceOrderScreenState extends ConsumerState<PlaceOrderScreen> {
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // //       if (mounted) ref.read(menuNotifierProvider.notifier).load();
// // //     });
// // //   }

// // //   void _openCartSheet() {
// // //     showModalBottomSheet(
// // //       context: context,
// // //       isScrollControlled: true,
// // //       backgroundColor: Colors.transparent,
// // //       builder: (_) => DraggableScrollableSheet(
// // //         initialChildSize: 0.75,
// // //         minChildSize: 0.4,
// // //         maxChildSize: 0.95,
// // //         expand: false,
// // //         builder: (context, scrollController) => Container(
// // //           padding: EdgeInsets.fromLTRB(
// // //             context.w(18),
// // //             context.h(14),
// // //             context.w(18),
// // //             context.h(16),
// // //           ),
// // //           decoration: BoxDecoration(
// // //             color: AppColors.of(context).surface,
// // //             borderRadius:
// // //                 BorderRadius.vertical(top: Radius.circular(context.h(18))),
// // //           ),
// // //           child: const SafeArea(
// // //             top: false,
// // //             child: CartPanel(),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final menuState = ref.watch(menuNotifierProvider);
// // //     final colors = AppColors.of(context);
// // //     final narrow = MediaQuery.sizeOf(context).width < 900;
// // //     final cartCount = ref.watch(cartCountProvider);

// // //     return Scaffold(
// // //       backgroundColor: colors.background,
// // //       body: Column(
// // //         children: [
// // //           const RdxHeader(title: 'Create New Order', showBackButton: true),
// // //           Expanded(
// // //             child: menuState.isLoading
// // //                 ? const LoadingIndicator()
// // //                 : Padding(
// // //                     padding: Responsive.pagePadding(context,
// // //                         top: context.h(10), bottom: context.h(0)),
// // //                     child: narrow
// // //                         ? _menuColumn(context, menuState, colors)
// // //                         : Row(
// // //                             crossAxisAlignment: CrossAxisAlignment.stretch,
// // //                             children: [
// // //                               Expanded(
// // //                                 flex: 3,
// // //                                 child: Padding(
// // //                                   padding:
// // //                                       EdgeInsets.only(right: context.w(16)),
// // //                                   child:
// // //                                       _menuColumn(context, menuState, colors),
// // //                                 ),
// // //                               ),
// // //                               VerticalDivider(
// // //                                 width: 1,
// // //                                 thickness: 1,
// // //                                 color: colors.border,
// // //                               ),
// // //                               SizedBox(
// // //                                 width: context.w(360),
// // //                                 child: Padding(
// // //                                   padding: EdgeInsets.only(
// // //                                     left: context.w(16),
// // //                                     top: context.h(4),
// // //                                   ),
// // //                                   child: const CartPanel(),
// // //                                 ),
// // //                               ),
// // //                             ],
// // //                           ),
// // //                   ),
// // //           ),
// // //         ],
// // //       ),
// // //       floatingActionButton: narrow && cartCount > 0
// // //           ? FloatingActionButton.extended(
// // //               onPressed: _openCartSheet,
// // //               backgroundColor: AppColors.primary,
// // //               icon: Badge(
// // //                 label: Text('$cartCount'),
// // //                 child: const Icon(Icons.shopping_cart_outlined,
// // //                     color: Colors.white),
// // //               ),
// // //               label: Text(
// // //                 'View Cart',
// // //                 style:
// // //                     AppTextStyles.label(context).copyWith(color: Colors.white),
// // //               ),
// // //             )
// // //           : null,
// // //     );
// // //   }

// // //   Widget _menuColumn(
// // //       BuildContext context, MenuState menuState, AppColorScheme colors) {
// // //     final notifier = ref.read(menuNotifierProvider.notifier);

// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         // ── order type + table row (matches Figma top bar) ────────────
// // //         Container(
// // //           padding: EdgeInsets.symmetric(
// // //               horizontal: context.w(12), vertical: context.h(10)),
// // //           decoration: BoxDecoration(
// // //             color: colors.surface,
// // //             borderRadius: BorderRadius.circular(context.h(10)),
// // //             border: Border.all(color: colors.border),
// // //           ),
// // //           child: Row(
// // //             children: [
// // //               _orderTypeChip(context, colors, 'Eat In', true),
// // //               SizedBox(width: context.w(8)),
// // //               _orderTypeChip(context, colors, 'To Go', false),
// // //               SizedBox(width: context.w(8)),
// // //               _orderTypeChip(context, colors, 'Delivery', false),
// // //               const Spacer(),
// // //               Text(
// // //                 'Table  ·  No Table (Counter)',
// // //                 style: AppTextStyles.caption(context)
// // //                     .copyWith(color: colors.textMuted),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //         SizedBox(height: context.h(12)),

// // //         // search
// // //         RdxSearchBar(
// // //           height: RdxTextField.singleLineHeight(context),
// // //           hintText: 'Search menu items…',
// // //           onChanged: notifier.setSearchQuery,
// // //         ),
// // //         SizedBox(height: context.h(12)),

// // //         // category tabs
// // //         Container(
// // //           width: double.infinity,
// // //           padding: EdgeInsets.symmetric(vertical: context.h(8)),
// // //           child: RdxCategoryTabs(
// // //             labels: menuState.categories.where((c) => c != 'All').toList(),
// // //             allLabel: 'All',
// // //             selectedLabel: menuState.selectedCategory,
// // //             onSelected: notifier.setCategory,
// // //             expand: false,
// // //           ),
// // //         ),
// // //         SizedBox(height: context.h(12)),

// // //         // menu grid – FIXED: correct SliverGridDelegate
// // //         Expanded(
// // //           child: menuState.filteredItems.isEmpty
// // //               ? const EmptyState(message: 'No menu items found')
// // //               : GridView.builder(
// // //                   padding: EdgeInsets.only(bottom: context.h(90)),
// // //                   gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
// // //                     maxCrossAxisExtent: context.w(220),
// // //                     mainAxisExtent: context.h(210),
// // //                     mainAxisSpacing: context.h(12),
// // //                     crossAxisSpacing: context.w(12),
// // //                   ),
// // //                   itemCount: menuState.filteredItems.length,
// // //                   itemBuilder: (context, index) =>
// // //                       OrderMenuItemCard(item: menuState.filteredItems[index]),
// // //                 ),
// // //         ),
// // //       ],
// // //     );
// // //   }

// // //   Widget _orderTypeChip(BuildContext context, AppColorScheme colors,
// // //       String label, bool selected) {
// // //     return Container(
// // //       padding: EdgeInsets.symmetric(
// // //           horizontal: context.w(12), vertical: context.h(6)),
// // //       decoration: BoxDecoration(
// // //         color: selected ? AppColors.primary : colors.surfaceVariant,
// // //         borderRadius: BorderRadius.circular(context.h(8)),
// // //         border: Border.all(
// // //           color: selected ? AppColors.primary : colors.border,
// // //         ),
// // //       ),
// // //       child: Text(
// // //         label,
// // //         style: AppTextStyles.label(context).copyWith(
// // //           color: selected ? Colors.white : colors.textPrimary,
// // //           fontWeight: FontWeight.w600,
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:flutter_riverpod/flutter_riverpod.dart';

// // import '../../core/utils/responsive_size.dart';
// // import '../../providers/menu_provider.dart';
// // import '../../providers/cart_provider.dart';
// // import '../../widgets/reusable_widgets/empty_state.dart';
// // import '../../widgets/reusable_widgets/loading_indicator.dart';
// // import 'widgets/cart_panel.dart';
// // import 'widgets/order_menu_item_card.dart';

// // class PlaceOrderScreen extends ConsumerStatefulWidget {
// //   const PlaceOrderScreen({super.key});

// //   @override
// //   ConsumerState<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
// // }

// // class _PlaceOrderScreenState extends ConsumerState<PlaceOrderScreen> {
// //   // ---------------------------------------------------------------------------
// //   // POS COLORS
// //   //
// //   // Kept local so this screen can match the Figma without changing the
// //   // application's global theme.
// //   // ---------------------------------------------------------------------------

// //   static const Color _pageBg = Color(0xFF1B0B0D);
// //   static const Color _headerBg = Color(0xFF16080A);
// //   static const Color _panelBg = Color(0xFF211012);
// //   static const Color _cardBg = Color(0xFF281417);
// //   static const Color _cardBorder = Color(0xFF3A2022);

// //   static const Color _text = Color(0xFFF4E8E8);
// //   static const Color _textSecondary = Color(0xFFB7A5A5);
// //   static const Color _textMuted = Color(0xFF806D6D);

// //   static const Color _accent = Color(0xFFE20D38);
// //   static const Color _accentDark = Color(0xFFB90A2D);

// //   static const Color _success = Color(0xFF55C98A);
// //   static const Color _warning = Color(0xFFE7A13D);

// //   // ---------------------------------------------------------------------------
// //   // STATE
// //   // ---------------------------------------------------------------------------

// //   String _orderType = 'Eat In';

// //   String _table = 'Table 4';

// //   @override
// //   void initState() {
// //     super.initState();

// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //       if (!mounted) return;

// //       ref.read(menuNotifierProvider.notifier).load();
// //     });
// //   }

// //   // ---------------------------------------------------------------------------
// //   // BUILD
// //   // ---------------------------------------------------------------------------

// //   @override
// //   Widget build(BuildContext context) {
// //     final menuState = ref.watch(menuNotifierProvider);

// //     final width = MediaQuery.sizeOf(context).width;

// //     final isMobile = width < 700;
// //     final isTablet = width >= 700 && width < 1100;

// //     return Scaffold(
// //       backgroundColor: _pageBg,
// //       body: SafeArea(
// //         child: menuState.isLoading
// //             ? const LoadingIndicator()
// //             : isMobile
// //                 ? _buildMobileLayout(context, menuState)
// //                 : _buildDesktopLayout(
// //                     context,
// //                     menuState,
// //                     isTablet: isTablet,
// //                   ),
// //       ),
// //     );
// //   }

// //   // ===========================================================================
// //   // DESKTOP / TABLET
// //   // ===========================================================================

// //   Widget _buildDesktopLayout(
// //     BuildContext context,
// //     MenuState menuState, {
// //     required bool isTablet,
// //   }) {
// //     return Column(
// //       children: [
// //         _buildTopHeader(context),
// //         Expanded(
// //           child: Padding(
// //             padding: EdgeInsets.fromLTRB(
// //               context.w(isTablet ? 14 : 18),
// //               context.h(10),
// //               context.w(isTablet ? 14 : 18),
// //               context.h(12),
// //             ),
// //             child: Row(
// //               crossAxisAlignment: CrossAxisAlignment.stretch,
// //               children: [
// //                 // -------------------------------------------------------------
// //                 // MAIN CREATE ORDER AREA
// //                 // -------------------------------------------------------------

// //                 Expanded(
// //                   child: _buildMainOrderArea(
// //                     context,
// //                     menuState,
// //                     isTablet: isTablet,
// //                   ),
// //                 ),

// //                 SizedBox(width: context.w(12)),

// //                 // -------------------------------------------------------------
// //                 // ACTIVE ORDER / CART
// //                 // -------------------------------------------------------------

// //                 SizedBox(
// //                   width: isTablet ? context.w(300) : context.w(350),
// //                   child: _buildActiveOrderPanel(context),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   // ===========================================================================
// //   // MOBILE
// //   // ===========================================================================

// //   Widget _buildMobileLayout(
// //     BuildContext context,
// //     MenuState menuState,
// //   ) {
// //     return Column(
// //       children: [
// //         _buildTopHeader(context),
// //         Expanded(
// //           child: ListView(
// //             padding: EdgeInsets.fromLTRB(
// //               context.w(12),
// //               context.h(10),
// //               context.w(12),
// //               context.h(20),
// //             ),
// //             children: [
// //               _buildOrderConfiguration(context),
// //               SizedBox(height: context.h(10)),
// //               _buildSearch(context, menuState),
// //               SizedBox(height: context.h(8)),
// //               _buildCategories(context, menuState),
// //               SizedBox(height: context.h(10)),
// //               _buildMenuGrid(
// //                 context,
// //                 menuState,
// //                 mobile: true,
// //               ),
// //               SizedBox(height: context.h(16)),
// //               SizedBox(
// //                 height: context.h(600),
// //                 child: _buildActiveOrderPanel(context),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   // ===========================================================================
// //   // TOP HEADER
// //   // ===========================================================================

// //   Widget _buildTopHeader(BuildContext context) {
// //     return Container(
// //       height: context.h(58),
// //       padding: EdgeInsets.symmetric(
// //         horizontal: context.w(16),
// //       ),
// //       decoration: const BoxDecoration(
// //         color: _headerBg,
// //         border: Border(
// //           bottom: BorderSide(
// //             color: _cardBorder,
// //             width: 1,
// //           ),
// //         ),
// //       ),
// //       child: Row(
// //         children: [
// //           // Back button
// //           _headerIconButton(
// //             context,
// //             icon: Icons.arrow_back_ios_new_rounded,
// //             onTap: () => Navigator.of(context).maybePop(),
// //           ),

// //           SizedBox(width: context.w(8)),

// //           Text(
// //             'Create New Order',
// //             style: TextStyle(
// //               color: _text,
// //               fontSize: context.h(16),
// //               fontWeight: FontWeight.w700,
// //             ),
// //           ),

// //           SizedBox(width: context.w(8)),

// //           Container(
// //             padding: EdgeInsets.symmetric(
// //               horizontal: context.w(7),
// //               vertical: context.h(3),
// //             ),
// //             decoration: BoxDecoration(
// //               color: const Color(0xFF392022),
// //               borderRadius: BorderRadius.circular(4),
// //             ),
// //             child: Text(
// //               'DRAFT #206',
// //               style: TextStyle(
// //                 color: _textMuted,
// //                 fontSize: context.h(8.5),
// //                 fontWeight: FontWeight.w700,
// //                 letterSpacing: .4,
// //               ),
// //             ),
// //           ),

// //           const Spacer(),

// //           // Queue indicator
// //           Container(
// //             padding: EdgeInsets.symmetric(
// //               horizontal: context.w(9),
// //               vertical: context.h(6),
// //             ),
// //             decoration: BoxDecoration(
// //               color: const Color(0xFF2C1517),
// //               borderRadius: BorderRadius.circular(6),
// //               border: Border.all(
// //                 color: _cardBorder,
// //               ),
// //             ),
// //             child: Row(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 Container(
// //                   width: context.h(6),
// //                   height: context.h(6),
// //                   decoration: const BoxDecoration(
// //                     color: _warning,
// //                     shape: BoxShape.circle,
// //                   ),
// //                 ),
// //                 SizedBox(width: context.w(5)),
// //                 Text(
// //                   '14 IN QUEUE',
// //                   style: TextStyle(
// //                     color: _textSecondary,
// //                     fontSize: context.h(8.5),
// //                     fontWeight: FontWeight.w700,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),

// //           SizedBox(width: context.w(12)),

// //           // Notification
// //           _headerIconButton(
// //             context,
// //             icon: Icons.notifications_none_rounded,
// //             onTap: () {},
// //           ),

// //           SizedBox(width: context.w(8)),

// //           // User
// //           Row(
// //             children: [
// //               Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 crossAxisAlignment: CrossAxisAlignment.end,
// //                 children: [
// //                   Text(
// //                     'Marcus Vane',
// //                     style: TextStyle(
// //                       color: _text,
// //                       fontSize: context.h(10),
// //                       fontWeight: FontWeight.w600,
// //                     ),
// //                   ),
// //                   Text(
// //                     'ADMIN',
// //                     style: TextStyle(
// //                       color: _textMuted,
// //                       fontSize: context.h(7),
// //                       fontWeight: FontWeight.w600,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //               SizedBox(width: context.w(7)),
// //               Container(
// //                 width: context.h(29),
// //                 height: context.h(29),
// //                 decoration: BoxDecoration(
// //                   color: const Color(0xFF3B2023),
// //                   shape: BoxShape.circle,
// //                   border: Border.all(
// //                     color: _cardBorder,
// //                   ),
// //                 ),
// //                 child: Icon(
// //                   Icons.person_outline_rounded,
// //                   size: context.h(15),
// //                   color: _textSecondary,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _headerIconButton(
// //     BuildContext context, {
// //     required IconData icon,
// //     required VoidCallback onTap,
// //   }) {
// //     return InkWell(
// //       onTap: onTap,
// //       borderRadius: BorderRadius.circular(6),
// //       child: SizedBox(
// //         width: context.h(30),
// //         height: context.h(30),
// //         child: Icon(
// //           icon,
// //           size: context.h(14),
// //           color: _textSecondary,
// //         ),
// //       ),
// //     );
// //   }

// //   // ===========================================================================
// //   // MAIN ORDER AREA
// //   // ===========================================================================

// //   Widget _buildMainOrderArea(
// //     BuildContext context,
// //     MenuState menuState, {
// //     required bool isTablet,
// //   }) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.stretch,
// //       children: [
// //         _buildOrderConfiguration(context),
// //         SizedBox(height: context.h(9)),
// //         _buildSearch(context, menuState),
// //         SizedBox(height: context.h(8)),
// //         _buildCategories(context, menuState),
// //         SizedBox(height: context.h(9)),
// //         Expanded(
// //           child: _buildMenuGrid(
// //             context,
// //             menuState,
// //             mobile: false,
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   // ===========================================================================
// //   // ORDER CONFIGURATION
// //   // ===========================================================================

// //   Widget _buildOrderConfiguration(BuildContext context) {
// //     return Container(
// //       padding: EdgeInsets.symmetric(
// //         horizontal: context.w(10),
// //         vertical: context.h(9),
// //       ),
// //       decoration: BoxDecoration(
// //         color: _panelBg,
// //         borderRadius: BorderRadius.circular(7),
// //         border: Border.all(
// //           color: _cardBorder,
// //         ),
// //       ),
// //       child: Row(
// //         children: [
// //           // Order type label
// //           Text(
// //             'ORDER TYPE',
// //             style: TextStyle(
// //               color: _textMuted,
// //               fontSize: context.h(8),
// //               fontWeight: FontWeight.w700,
// //               letterSpacing: .6,
// //             ),
// //           ),

// //           SizedBox(width: context.w(8)),

// //           _orderTypeButton(
// //             context,
// //             label: 'Eat In',
// //             selected: _orderType == 'Eat In',
// //             icon: Icons.restaurant_outlined,
// //           ),

// //           SizedBox(width: context.w(5)),

// //           _orderTypeButton(
// //             context,
// //             label: 'To Go',
// //             selected: _orderType == 'To Go',
// //             icon: Icons.shopping_bag_outlined,
// //           ),

// //           SizedBox(width: context.w(5)),

// //           _orderTypeButton(
// //             context,
// //             label: 'Delivery',
// //             selected: _orderType == 'Delivery',
// //             icon: Icons.delivery_dining_outlined,
// //           ),

// //           const Spacer(),

// //           // Table assignment
// //           Text(
// //             'TABLE ASSIGNMENT',
// //             style: TextStyle(
// //               color: _textMuted,
// //               fontSize: context.h(8),
// //               fontWeight: FontWeight.w700,
// //               letterSpacing: .5,
// //             ),
// //           ),

// //           SizedBox(width: context.w(6)),

// //           _tableButton(context),

// //           SizedBox(width: context.w(6)),

// //           _tableButton(
// //             context,
// //             label: 'No Table (Counter)',
// //             selected: _table == 'No Table (Counter)',
// //           ),

// //           SizedBox(width: context.w(10)),

// //           // Dispatch status
// //           Container(
// //             padding: EdgeInsets.symmetric(
// //               horizontal: context.w(9),
// //               vertical: context.h(7),
// //             ),
// //             decoration: BoxDecoration(
// //               color: const Color(0xFF25191A),
// //               borderRadius: BorderRadius.circular(6),
// //               border: Border.all(
// //                 color: _cardBorder,
// //               ),
// //             ),
// //             child: Row(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 Container(
// //                   width: context.h(6),
// //                   height: context.h(6),
// //                   decoration: const BoxDecoration(
// //                     color: _success,
// //                     shape: BoxShape.circle,
// //                   ),
// //                 ),
// //                 SizedBox(width: context.w(5)),
// //                 Text(
// //                   'RDX INSTANT-DISPATCH READY',
// //                   style: TextStyle(
// //                     color: _textSecondary,
// //                     fontSize: context.h(7.5),
// //                     fontWeight: FontWeight.w600,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _orderTypeButton(
// //     BuildContext context, {
// //     required String label,
// //     required bool selected,
// //     required IconData icon,
// //   }) {
// //     return InkWell(
// //       onTap: () {
// //         setState(() {
// //           _orderType = label;
// //         });
// //       },
// //       borderRadius: BorderRadius.circular(5),
// //       child: AnimatedContainer(
// //         duration: const Duration(milliseconds: 130),
// //         padding: EdgeInsets.symmetric(
// //           horizontal: context.w(9),
// //           vertical: context.h(6),
// //         ),
// //         decoration: BoxDecoration(
// //           color: selected ? _accent : const Color(0xFF2A1719),
// //           borderRadius: BorderRadius.circular(5),
// //           border: Border.all(
// //             color: selected ? _accent : _cardBorder,
// //           ),
// //         ),
// //         child: Row(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Icon(
// //               icon,
// //               size: context.h(10),
// //               color: selected ? Colors.white : _textSecondary,
// //             ),
// //             SizedBox(width: context.w(4)),
// //             Text(
// //               label,
// //               style: TextStyle(
// //                 color: selected ? Colors.white : _textSecondary,
// //                 fontSize: context.h(8.5),
// //                 fontWeight: FontWeight.w600,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _tableButton(
// //     BuildContext context, {
// //     String? label,
// //     bool? selected,
// //   }) {
// //     final actualLabel = label ?? _table;
// //     final isSelected = selected ?? (_table == actualLabel);

// //     return InkWell(
// //       onTap: () {
// //         setState(() {
// //           _table = actualLabel;
// //         });
// //       },
// //       borderRadius: BorderRadius.circular(5),
// //       child: Container(
// //         padding: EdgeInsets.symmetric(
// //           horizontal: context.w(9),
// //           vertical: context.h(6),
// //         ),
// //         decoration: BoxDecoration(
// //           color: isSelected ? const Color(0xFF3A1A1F) : const Color(0xFF241315),
// //           borderRadius: BorderRadius.circular(5),
// //           border: Border.all(
// //             color: isSelected ? _accent : _cardBorder,
// //           ),
// //         ),
// //         child: Row(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Icon(
// //               Icons.table_restaurant_outlined,
// //               size: context.h(9),
// //               color: isSelected ? _accent : _textMuted,
// //             ),
// //             SizedBox(width: context.w(4)),
// //             Text(
// //               actualLabel,
// //               style: TextStyle(
// //                 color: isSelected ? _text : _textSecondary,
// //                 fontSize: context.h(8),
// //                 fontWeight: FontWeight.w600,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   // ===========================================================================
// //   // SEARCH
// //   // ===========================================================================

// //   Widget _buildSearch(
// //     BuildContext context,
// //     MenuState menuState,
// //   ) {
// //     final notifier = ref.read(menuNotifierProvider.notifier);

// //     return Container(
// //       height: context.h(34),
// //       decoration: BoxDecoration(
// //         color: _panelBg,
// //         borderRadius: BorderRadius.circular(6),
// //         border: Border.all(
// //           color: _cardBorder,
// //         ),
// //       ),
// //       child: TextField(
// //         onChanged: notifier.setSearchQuery,
// //         style: TextStyle(
// //           color: _text,
// //           fontSize: context.h(9.5),
// //         ),
// //         cursorColor: _accent,
// //         decoration: InputDecoration(
// //           border: InputBorder.none,
// //           prefixIcon: Icon(
// //             Icons.search_rounded,
// //             color: _textMuted,
// //             size: context.h(14),
// //           ),
// //           hintText: 'Search menu items, dishes, tickets...',
// //           hintStyle: TextStyle(
// //             color: _textMuted,
// //             fontSize: context.h(9),
// //           ),
// //           contentPadding: EdgeInsets.symmetric(
// //             horizontal: context.w(8),
// //             vertical: context.h(8),
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   // ===========================================================================
// //   // CATEGORIES
// //   // ===========================================================================

// //   Widget _buildCategories(
// //     BuildContext context,
// //     MenuState menuState,
// //   ) {
// //     final notifier = ref.read(menuNotifierProvider.notifier);

// //     final categories = [
// //       'All',
// //       ...menuState.categories.where((category) => category != 'All'),
// //     ];

// //     return SizedBox(
// //       height: context.h(29),
// //       child: ListView.separated(
// //         scrollDirection: Axis.horizontal,
// //         itemCount: categories.length,
// //         separatorBuilder: (_, __) => SizedBox(
// //           width: context.w(5),
// //         ),
// //         itemBuilder: (context, index) {
// //           final category = categories[index];

// //           final selected = menuState.selectedCategory == category;

// //           return InkWell(
// //             onTap: () => notifier.setCategory(category),
// //             borderRadius: BorderRadius.circular(5),
// //             child: AnimatedContainer(
// //               duration: const Duration(milliseconds: 130),
// //               padding: EdgeInsets.symmetric(
// //                 horizontal: context.w(11),
// //               ),
// //               alignment: Alignment.center,
// //               decoration: BoxDecoration(
// //                 color: selected ? _accent : const Color(0xFF281517),
// //                 borderRadius: BorderRadius.circular(5),
// //                 border: Border.all(
// //                   color: selected ? _accent : _cardBorder,
// //                 ),
// //               ),
// //               child: Text(
// //                 category,
// //                 style: TextStyle(
// //                   color: selected ? Colors.white : _textSecondary,
// //                   fontSize: context.h(8.5),
// //                   fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
// //                 ),
// //               ),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }

// //   // ===========================================================================
// //   // MENU GRID
// //   // ===========================================================================

// //   Widget _buildMenuGrid(
// //     BuildContext context,
// //     MenuState menuState, {
// //     required bool mobile,
// //   }) {
// //     final items = menuState.filteredItems;

// //     if (items.isEmpty) {
// //       return const EmptyState(
// //         message: 'No menu items found',
// //       );
// //     }

// //     if (mobile) {
// //       return GridView.builder(
// //         shrinkWrap: true,
// //         physics: const NeverScrollableScrollPhysics(),
// //         itemCount: items.length,
// //         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// //           crossAxisCount: 2,
// //           mainAxisExtent: context.h(165),
// //           mainAxisSpacing: context.h(8),
// //           crossAxisSpacing: context.w(8),
// //         ),
// //         itemBuilder: (context, index) {
// //           return OrderMenuItemCard(
// //             item: items[index],
// //           );
// //         },
// //       );
// //     }

// //     return LayoutBuilder(
// //       builder: (context, constraints) {
// //         final width = constraints.maxWidth;

// //         int columns;

// //         if (width >= 1050) {
// //           columns = 4;
// //         } else if (width >= 760) {
// //           columns = 3;
// //         } else {
// //           columns = 2;
// //         }

// //         return GridView.builder(
// //           padding: EdgeInsets.only(
// //             bottom: context.h(12),
// //           ),
// //           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// //             crossAxisCount: columns,
// //             mainAxisExtent: context.h(174),
// //             mainAxisSpacing: context.h(8),
// //             crossAxisSpacing: context.w(8),
// //           ),
// //           itemCount: items.length,
// //           itemBuilder: (context, index) {
// //             return OrderMenuItemCard(
// //               item: items[index],
// //             );
// //           },
// //         );
// //       },
// //     );
// //   }

// //   // ===========================================================================
// //   // ACTIVE ORDER
// //   // ===========================================================================

// //   Widget _buildActiveOrderPanel(BuildContext context) {
// //     return Container(
// //       decoration: BoxDecoration(
// //         color: _panelBg,
// //         borderRadius: BorderRadius.circular(8),
// //         border: Border.all(
// //           color: _cardBorder,
// //         ),
// //       ),
// //       clipBehavior: Clip.antiAlias,
// //       child: Column(
// //         children: [
// //           // ---------------------------------------------------------------
// //           // Panel header
// //           // ---------------------------------------------------------------

// //           Padding(
// //             padding: EdgeInsets.fromLTRB(
// //               context.w(12),
// //               context.h(10),
// //               context.w(9),
// //               context.h(9),
// //             ),
// //             child: Row(
// //               children: [
// //                 Text(
// //                   'ACTIVE ORDER',
// //                   style: TextStyle(
// //                     color: _text,
// //                     fontSize: context.h(10),
// //                     fontWeight: FontWeight.w700,
// //                     letterSpacing: .4,
// //                   ),
// //                 ),
// //                 SizedBox(width: context.w(5)),
// //                 Text(
// //                   '#206',
// //                   style: TextStyle(
// //                     color: _textMuted,
// //                     fontSize: context.h(9),
// //                     fontWeight: FontWeight.w500,
// //                   ),
// //                 ),
// //                 const Spacer(),
// //                 Container(
// //                   padding: EdgeInsets.symmetric(
// //                     horizontal: context.w(6),
// //                     vertical: context.h(3),
// //                   ),
// //                   decoration: BoxDecoration(
// //                     color: const Color(0xFF522021),
// //                     borderRadius: BorderRadius.circular(4),
// //                   ),
// //                   child: Text(
// //                     'NEW',
// //                     style: TextStyle(
// //                       color: const Color(0xFFFF8B8B),
// //                       fontSize: context.h(7),
// //                       fontWeight: FontWeight.w800,
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),

// //           const Divider(
// //             height: 1,
// //             color: _cardBorder,
// //           ),

// //           // ---------------------------------------------------------------
// //           // Existing cart panel
// //           //
// //           // CartPanel remains responsible for your actual cart state,
// //           // quantities, notes, totals and checkout functionality.
// //           // ---------------------------------------------------------------

// //           Expanded(
// //             child: Theme(
// //               data: Theme.of(context).copyWith(
// //                 scaffoldBackgroundColor: _panelBg,
// //                 cardColor: _cardBg,
// //                 dividerColor: _cardBorder,
// //               ),
// //               child: const CartPanel(),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../core/theme/app_colors.dart';
// import '../../core/theme/text_styles.dart';
// import '../../core/utils/responsive_size.dart';
// import '../../providers/menu_provider.dart';
// import '../../widgets/reusable_widgets/empty_state.dart';
// import '../../widgets/reusable_widgets/loading_indicator.dart';
// import '../../widgets/reusable_widgets/rdx_header.dart';
// import '../../widgets/resuable_options/rdx_category_tabs.dart';
// import '../../widgets/resuable_options/rdx_search_bar.dart';
// import '../../widgets/resuable_options/rdx_text_field.dart';
// import 'widgets/order_menu_item_card.dart';

// class PlaceOrderScreen extends ConsumerStatefulWidget {
//   const PlaceOrderScreen({super.key});

//   @override
//   ConsumerState<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
// }

// class _PlaceOrderScreenState extends ConsumerState<PlaceOrderScreen> {
//   @override
//   void initState() {
//     super.initState();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         ref.read(menuNotifierProvider.notifier).load();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final menuState = ref.watch(menuNotifierProvider);
//     final colors = AppColors.of(context);

//     return Scaffold(
//       backgroundColor: colors.background,
//       body: Column(
//         children: [
//           const RdxHeader(
//             title: 'Create New Order',
//             showBackButton: true,
//           ),
//           Expanded(
//             child: menuState.isLoading
//                 ? const LoadingIndicator()
//                 : Padding(
//                     padding: Responsive.pagePadding(
//                       context,
//                       top: context.h(10),
//                       bottom: context.h(10),
//                     ),
//                     child: _buildCreateOrderContent(
//                       context,
//                       menuState,
//                       colors,
//                     ),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCreateOrderContent(
//     BuildContext context,
//     MenuState menuState,
//     AppColorScheme colors,
//   ) {
//     final notifier = ref.read(menuNotifierProvider.notifier);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // ---------------------------------------------------------------
//         // ORDER TYPE / TABLE ASSIGNMENT
//         // ---------------------------------------------------------------
//         _buildOrderConfiguration(
//           context,
//           colors,
//         ),

//         SizedBox(height: context.h(12)),

//         // ---------------------------------------------------------------
//         // SEARCH
//         // ---------------------------------------------------------------
//         RdxSearchBar(
//           height: RdxTextField.singleLineHeight(context),
//           hintText: 'Search menu items…',
//           onChanged: notifier.setSearchQuery,
//         ),

//         SizedBox(height: context.h(12)),

//         // ---------------------------------------------------------------
//         // CATEGORY TABS
//         // ---------------------------------------------------------------
//         Container(
//           width: double.infinity,
//           padding: EdgeInsets.symmetric(
//             vertical: context.h(4),
//           ),
//           child: RdxCategoryTabs(
//             labels: menuState.categories
//                 .where((category) => category != 'All')
//                 .toList(),
//             allLabel: 'All',
//             selectedLabel: menuState.selectedCategory,
//             onSelected: notifier.setCategory,
//             expand: false,
//           ),
//         ),

//         SizedBox(height: context.h(12)),

//         // ---------------------------------------------------------------
//         // MENU
//         // ---------------------------------------------------------------
//         Expanded(
//           child: menuState.filteredItems.isEmpty
//               ? const EmptyState(
//                   message: 'No menu items found',
//                 )
//               : GridView.builder(
//                   padding: EdgeInsets.only(
//                     bottom: context.h(10),
//                   ),
//                   gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
//                     maxCrossAxisExtent: context.w(220),
//                     mainAxisExtent: context.h(210),
//                     mainAxisSpacing: context.h(12),
//                     crossAxisSpacing: context.w(12),
//                   ),
//                   itemCount: menuState.filteredItems.length,
//                   itemBuilder: (context, index) {
//                     return OrderMenuItemCard(
//                       item: menuState.filteredItems[index],
//                     );
//                   },
//                 ),
//         ),
//       ],
//     );
//   }

//   Widget _buildOrderConfiguration(
//     BuildContext context,
//     AppColorScheme colors,
//   ) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.symmetric(
//         horizontal: context.w(12),
//         vertical: context.h(10),
//       ),
//       decoration: BoxDecoration(
//         color: colors.surface,
//         borderRadius: BorderRadius.circular(
//           context.h(10),
//         ),
//         border: Border.all(
//           color: colors.border,
//         ),
//       ),
//       child: Row(
//         children: [
//           _orderTypeChip(
//             context,
//             colors,
//             'Eat In',
//             true,
//           ),

//           SizedBox(width: context.w(8)),

//           _orderTypeChip(
//             context,
//             colors,
//             'To Go',
//             false,
//           ),

//           SizedBox(width: context.w(8)),

//           _orderTypeChip(
//             context,
//             colors,
//             'Delivery',
//             false,
//           ),

//           const Spacer(),

//           // Table assignment information.
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 Icons.table_restaurant_outlined,
//                 size: context.h(15),
//                 color: colors.textMuted,
//               ),
//               SizedBox(width: context.w(5)),
//               Text(
//                 'Table',
//                 style: AppTextStyles.caption(context).copyWith(
//                   color: colors.textSecondary,
//                 ),
//               ),
//               SizedBox(width: context.w(6)),
//               Text(
//                 'No Table (Counter)',
//                 style: AppTextStyles.caption(context).copyWith(
//                   color: colors.textMuted,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _orderTypeChip(
//     BuildContext context,
//     AppColorScheme colors,
//     String label,
//     bool selected,
//   ) {
//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: context.w(12),
//         vertical: context.h(6),
//       ),
//       decoration: BoxDecoration(
//         color: selected ? AppColors.primary : colors.surfaceVariant,
//         borderRadius: BorderRadius.circular(
//           context.h(8),
//         ),
//         border: Border.all(
//           color: selected ? AppColors.primary : colors.border,
//         ),
//       ),
//       child: Text(
//         label,
//         style: AppTextStyles.label(context).copyWith(
//           color: selected ? Colors.white : colors.textPrimary,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
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
      if (mounted) {
        ref.read(menuNotifierProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuNotifierProvider);
    final colors = AppColors.of(context);

    final width = MediaQuery.sizeOf(context).width;

    // Keep the right order panel on normal desktop/tablet layouts.
    final compact = width < 900;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const RdxHeader(
            title: 'Create New Order',
            showBackButton: true,
          ),
          Expanded(
            child: menuState.isLoading
                ? const LoadingIndicator()
                : Padding(
                    padding: Responsive.pagePadding(
                      context,
                      top: context.h(10),
                      bottom: context.h(10),
                    ),
                    child: compact
                        ? _buildCompactLayout(
                            context,
                            menuState,
                            colors,
                          )
                        : _buildDesktopLayout(
                            context,
                            menuState,
                            colors,
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DESKTOP / TABLET
  // ---------------------------------------------------------------------------

  Widget _buildDesktopLayout(
    BuildContext context,
    MenuState menuState,
    AppColorScheme colors,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---------------------------------------------------------------------
        // LEFT - MENU
        // ---------------------------------------------------------------------
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: context.w(14),
            ),
            child: _buildMenuArea(
              context,
              menuState,
              colors,
            ),
          ),
        ),

        // ---------------------------------------------------------------------
        // RIGHT - ACTIVE ORDER / CART
        // ---------------------------------------------------------------------
        SizedBox(
          width: context.w(350),
          child: CartPanel(
            onClose: null,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // COMPACT
  // ---------------------------------------------------------------------------

  Widget _buildCompactLayout(
    BuildContext context,
    MenuState menuState,
    AppColorScheme colors,
  ) {
    return _buildMenuArea(
      context,
      menuState,
      colors,
    );
  }

  // ---------------------------------------------------------------------------
  // MENU AREA
  // ---------------------------------------------------------------------------

  Widget _buildMenuArea(
    BuildContext context,
    MenuState menuState,
    AppColorScheme colors,
  ) {
    final notifier = ref.read(menuNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------------------------------------------------------------------
        // ORDER TYPE + TABLE
        // ---------------------------------------------------------------------
        _buildOrderConfiguration(
          context,
          colors,
        ),

        SizedBox(height: context.h(10)),

        // ---------------------------------------------------------------------
        // SEARCH
        // ---------------------------------------------------------------------
        RdxSearchBar(
          height: RdxTextField.singleLineHeight(context),
          hintText: 'Search menu items...',
          onChanged: notifier.setSearchQuery,
        ),

        SizedBox(height: context.h(10)),

        // ---------------------------------------------------------------------
        // CATEGORY TABS
        // ---------------------------------------------------------------------
        SizedBox(
          height: context.h(38),
          child: RdxCategoryTabs(
            labels: menuState.categories
                .where((category) => category != 'All')
                .toList(),
            allLabel: 'All',
            selectedLabel: menuState.selectedCategory,
            onSelected: notifier.setCategory,
            expand: false,
          ),
        ),

        SizedBox(height: context.h(8)),

        // ---------------------------------------------------------------------
        // MENU GRID
        // ---------------------------------------------------------------------
        Expanded(
          child: menuState.filteredItems.isEmpty
              ? const EmptyState(
                  message: 'No menu items found',
                )
              : GridView.builder(
                  padding: EdgeInsets.only(
                    bottom: context.h(4),
                  ),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    // Three compact cards on the normal desktop width.
                    maxCrossAxisExtent: context.w(220),

                    // IMPORTANT:
                    // The old 210 height made the cards huge.
                    // The Figma card is compact.
                    mainAxisExtent: context.h(116),

                    mainAxisSpacing: context.h(10),
                    crossAxisSpacing: context.w(10),
                  ),
                  itemCount: menuState.filteredItems.length,
                  itemBuilder: (context, index) {
                    return OrderMenuItemCard(
                      item: menuState.filteredItems[index],
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ORDER CONFIGURATION
  // ---------------------------------------------------------------------------

  Widget _buildOrderConfiguration(
    BuildContext context,
    AppColorScheme colors,
  ) {
    return Container(
      width: double.infinity,
      height: context.h(48),
      padding: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(7),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(
          context.h(8),
        ),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Row(
        children: [
          Text(
            'ORDER TYPE',
            style: AppTextStyles.caption(context).copyWith(
              fontSize: context.h(9),
              color: colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: context.w(7)),
          _orderTypeChip(
            context,
            colors,
            'Eat In',
            true,
          ),
          SizedBox(width: context.w(5)),
          _orderTypeChip(
            context,
            colors,
            'To Go',
            false,
          ),
          SizedBox(width: context.w(5)),
          _orderTypeChip(
            context,
            colors,
            'Delivery',
            false,
          ),
          const Spacer(),
          Icon(
            Icons.table_restaurant_outlined,
            size: context.h(13),
            color: colors.textMuted,
          ),
          SizedBox(width: context.w(4)),
          Text(
            'Table',
            style: AppTextStyles.caption(context).copyWith(
              fontSize: context.h(10),
              color: colors.textMuted,
            ),
          ),
          SizedBox(width: context.w(5)),
          Text(
            'No Table (Counter)',
            style: AppTextStyles.caption(context).copyWith(
              fontSize: context.h(10),
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderTypeChip(
    BuildContext context,
    AppColorScheme colors,
    String label,
    bool selected,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(5),
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : colors.surfaceVariant,
        borderRadius: BorderRadius.circular(
          context.h(6),
        ),
        border: Border.all(
          color: selected ? AppColors.primary : colors.border,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(context).copyWith(
          fontSize: context.h(10),
          color: selected ? Colors.white : colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
