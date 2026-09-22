import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/screens/order/checkout_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_size.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/empty_state.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';
import '../../widgets/resuable_options/rdx_category_tabs.dart';
import '../../widgets/resuable_options/rdx_search_bar.dart';
import 'widgets/cart_panel.dart';
import 'widgets/live_order_menu_card.dart';

class PlaceOrderScreen extends ConsumerStatefulWidget {
  const PlaceOrderScreen({super.key});

  @override
  ConsumerState<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends ConsumerState<PlaceOrderScreen> {
  // ── Manage-categories filter panel state ──────────────────────
  // Mirrors MenuScreen exactly so the tabs row, fade, filter button
  // and popover panel look and behave identically on both screens.
  final Set<String> _appliedCategories = {};
  Set<String>? _stagedCategories;
  bool _hasAppliedCategories = false;
  bool _categoryPickerOpen = false;
  final GlobalKey _categoryButtonKey = GlobalKey();
  OverlayEntry? _categoryOverlay;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref.read(menuProvider).load();
    });
  }

  @override
  void dispose() {
    _categoryOverlay?.remove();
    _categoryOverlay = null;
    super.dispose();
  }

  /// Moves from the active order/cart screen to checkout.
  ///
  /// IMPORTANT:
  /// This does NOT create the Firestore order.
  /// CheckoutScreen is responsible for final submission.
  void _goToCheckout() {
    final cart = ref.read(cartProvider);

    if (cart.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CheckoutScreen(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MANAGE CATEGORIES (ported from MenuScreen, unchanged behaviour)
  // ═══════════════════════════════════════════════════════════════

  void _openCategoryPicker(MenuProvider provider) {
    if (_categoryPickerOpen) {
      _closeCategoryPicker();
      return;
    }

    _stagedCategories = !_hasAppliedCategories
        ? provider.categoryList.map((category) => category.name).toSet()
        : Set<String>.from(_appliedCategories);

    final buttonContext = _categoryButtonKey.currentContext;
    if (buttonContext == null) return;

    final renderBox = buttonContext.findRenderObject();
    if (renderBox is! RenderBox) return;

    final buttonOffset = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;

    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    final panelWidth = context.w(330);
    final horizontalMargin = context.w(16);
    final verticalGap = context.h(8);

    final availableBelow = screenSize.height -
        (buttonOffset.dy + buttonSize.height) -
        mediaQuery.padding.bottom -
        horizontalMargin;

    final availableAbove =
        buttonOffset.dy - mediaQuery.padding.top - horizontalMargin;

    final estimatedPanelHeight = context.h(430);

    final showBelow = availableBelow >= estimatedPanelHeight ||
        availableBelow >= availableAbove;

    double top;
    if (showBelow) {
      top = buttonOffset.dy + buttonSize.height + verticalGap;
    } else {
      top = buttonOffset.dy - estimatedPanelHeight - verticalGap;
    }

    final maxTop = screenSize.height - estimatedPanelHeight - horizontalMargin;

    top = top.clamp(
      mediaQuery.padding.top + horizontalMargin,
      maxTop > mediaQuery.padding.top
          ? maxTop
          : mediaQuery.padding.top + horizontalMargin,
    );

    double left = buttonOffset.dx + buttonSize.width - panelWidth;
    left = left.clamp(
      horizontalMargin,
      screenSize.width - panelWidth - horizontalMargin,
    );

    _categoryOverlay = OverlayEntry(
      builder: (_) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeCategoryPicker,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: panelWidth,
              child: Material(
                color: Colors.transparent,
                child: _categoryPickerPanel(
                  AppColors.of(context),
                  provider,
                  panelWidth: panelWidth,
                  maxHeight: showBelow ? availableBelow : availableAbove,
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_categoryOverlay!);

    setState(() {
      _categoryPickerOpen = true;
    });
  }

  void _closeCategoryPicker() {
    final overlay = _categoryOverlay;
    _categoryOverlay = null;

    if (overlay != null) {
      overlay.remove();
    }

    if (!mounted) return;

    setState(() {
      _categoryPickerOpen = false;
      _stagedCategories = null;
    });
  }

  void _toggleStagedCategory(String name, bool selected) {
    final staged = _stagedCategories ?? <String>{};
    if (selected) {
      staged.add(name);
    } else {
      staged.remove(name);
    }
    _stagedCategories = staged;
    _categoryOverlay?.markNeedsBuild();
  }

  void _applyCategories(MenuProvider provider) {
    final next = Set<String>.from(_stagedCategories ?? {});
    _appliedCategories
      ..clear()
      ..addAll(next);
    _hasAppliedCategories = true;

    final selectedIsVisible = provider.selectedCategory == 'All' ||
        _appliedCategories.contains(provider.selectedCategory);

    _closeCategoryPicker();

    if (!selectedIsVisible) provider.setCategory('All');
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuProvider);
    final colors = AppColors.of(context);

    final width = MediaQuery.sizeOf(context).width;

    // Keep the two-column POS layout on desktop/tablet.
    final isCompact = width < 900;

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
                    child: isCompact
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

  // ===========================================================================
  // DESKTOP / TABLET
  // ===========================================================================

  Widget _buildDesktopLayout(
    BuildContext context,
    MenuProvider menuState,
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
        // DIVIDER
        // ---------------------------------------------------------------------

        VerticalDivider(
          width: context.w(1),
          thickness: 1,
          color: colors.border,
        ),

        // ---------------------------------------------------------------------
        // RIGHT - ACTIVE ORDER / CART
        // ---------------------------------------------------------------------

        SizedBox(
          width: context.w(350),
          child: Padding(
            padding: EdgeInsets.only(
              left: context.w(14),
            ),
            child: CartPanel(
              onProceed: _goToCheckout,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // COMPACT
  // ===========================================================================

  Widget _buildCompactLayout(
    BuildContext context,
    MenuProvider menuState,
    AppColorScheme colors,
  ) {
    return Column(
      children: [
        // Menu section.
        Expanded(
          child: _buildMenuArea(
            context,
            menuState,
            colors,
          ),
        ),

        SizedBox(height: context.h(12)),

        // Cart remains on the same screen.
        //
        // No bottom sheet is used.
        SizedBox(
          height: context.h(360),
          child: CartPanel(
            onProceed: _goToCheckout,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // MENU AREA
  //
  // Top bar, category-tabs row (fade + manage-categories filter button) and
  // all spacing/padding here match MenuScreen's own _buildTopBar /
  // _buildCategoryTabs exactly. Only the grid's card (LiveOrderMenuCard) and
  // this section's own heading stay specific to the order screen.
  // ===========================================================================

  Widget _buildMenuArea(
    BuildContext context,
    MenuProvider menuState,
    AppColorScheme colors,
  ) {
    final notifier = ref.read(menuProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------------------------------------------------------------------
        // SEARCH
        // ---------------------------------------------------------------------

        RdxSearchToolbar(
          hintText: 'Search menu items',
          onChanged: notifier.setSearchQuery,
          actions: const [],
        ),

        SizedBox(height: context.h(16)),

        // ---------------------------------------------------------------------
        // CATEGORY TABS
        // ---------------------------------------------------------------------

        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: context.h(10)),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colors.divider),
              bottom: BorderSide(color: colors.divider),
            ),
          ),
          child: _buildCategoryTabs(menuState, colors),
        ),

        SizedBox(height: context.h(18)),

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
                    maxCrossAxisExtent: context.w(225),
                    mainAxisExtent: context.h(320),
                    mainAxisSpacing: context.h(14),
                    crossAxisSpacing: context.w(14),
                  ),
                  itemCount: menuState.filteredItems.length,
                  itemBuilder: (context, index) {
                    return LiveOrderMenuCard(
                      item: menuState.filteredItems[index],
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CATEGORY TABS (same shader-fade + manage-categories button as
  // MenuScreen._buildCategoryTabs)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCategoryTabs(MenuProvider provider, AppColorScheme colors) {
    final categories = !_hasAppliedCategories
        ? provider.categoryList.map((c) => c.name).toList()
        : _appliedCategories.toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [Colors.black, Colors.black, Colors.transparent],
              stops: const [0.0, 0.9, 1.0],
            ).createShader(bounds),
            blendMode: BlendMode.dstIn,
            child: RdxCategoryTabs(
              labels: categories,
              allLabel: 'All',
              selectedLabel: provider.selectedCategory,
              onSelected: provider.setCategory,
              expand: false,
            ),
          ),
        ),
        SizedBox(width: context.w(8)),
        _manageCategoriesButton(colors, provider),
      ],
    );
  }

  Widget _manageCategoriesButton(AppColorScheme colors, MenuProvider provider) {
    return InkWell(
      key: _categoryButtonKey,
      onTap: () => _openCategoryPicker(provider),
      borderRadius: BorderRadius.circular(context.h(8)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(11),
          vertical: context.h(9),
        ),
        decoration: BoxDecoration(
          color: _categoryPickerOpen
              ? AppColors.primary.withValues(alpha: 0.08)
              : colors.surface,
          borderRadius: BorderRadius.circular(context.h(8)),
          border: Border.all(
            color: _categoryPickerOpen ? AppColors.primary : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune, size: context.h(19), color: AppColors.primary),
            SizedBox(width: context.w(4)),
            Icon(
              _categoryPickerOpen
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: context.h(20),
              color: colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryPickerPanel(
    AppColorScheme colors,
    MenuProvider provider, {
    required double panelWidth,
    required double maxHeight,
  }) {
    final staged = _stagedCategories ?? <String>{};
    final categoryOptions = provider.categoryList;

    final listHeight =
        (maxHeight - context.h(170)).clamp(context.h(140), context.h(270));

    return Container(
      width: panelWidth,
      padding: EdgeInsets.fromLTRB(
        context.w(14),
        context.h(13),
        context.w(14),
        context.h(12),
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(10)),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: context.h(18),
            offset: Offset(0, context.h(7)),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filter categories',
                  style: AppTextStyles.section(context)
                      .copyWith(color: colors.textPrimary),
                ),
              ),
              Text(
                '${staged.length} selected',
                style: AppTextStyles.bodySecondary(context)
                    .copyWith(color: colors.textMuted),
              ),
            ],
          ),
          SizedBox(height: context.h(4)),
          Text(
            'Choose which categories appear in the filter row.',
            style: AppTextStyles.caption(context)
                .copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: context.h(10)),
          Container(
            height: listHeight,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(context.h(7)),
              border: Border.all(color: colors.border),
            ),
            child: categoryOptions.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(context.h(14)),
                      child: Text(
                        'No categories yet. Create one from the menu item form.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySecondary(context)
                            .copyWith(color: colors.textMuted),
                      ),
                    ),
                  )
                : Scrollbar(
                    thumbVisibility: true,
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(vertical: context.h(5)),
                      itemCount: categoryOptions.length,
                      separatorBuilder: (_, __) => Divider(
                        height: context.h(1),
                        thickness: 1,
                        indent: 0,
                        endIndent: 0,
                        color: colors.divider,
                      ),
                      itemBuilder: (context, index) {
                        final category = categoryOptions[index];
                        final selected = staged.contains(category.name);

                        return InkWell(
                          onTap: () => _toggleStagedCategory(
                            category.name,
                            !selected,
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              context.w(10),
                              context.h(2),
                              context.w(8),
                              context.h(2),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: selected,
                                  onChanged: (value) {
                                    _toggleStagedCategory(
                                      category.name,
                                      value == true,
                                    );
                                  },
                                  activeColor: AppColors.primary,
                                  checkColor: colors.surface,
                                  fillColor:
                                      WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return AppColors.primary;
                                    }
                                    return Colors.transparent;
                                  }),
                                  side: BorderSide(
                                    width: 1.2,
                                    color: selected
                                        ? AppColors.primary
                                        : colors.border,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(3.5),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                Expanded(
                                  child: Text(
                                    category.name,
                                    style: AppTextStyles.label(context)
                                        .copyWith(color: colors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          SizedBox(height: context.h(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              RdxActionButton(
                label: 'Cancel',
                isPrimary: false,
                onPressed: _closeCategoryPicker,
              ),
              SizedBox(width: context.w(6)),
              RdxActionButton(
                label: 'Apply',
                onPressed: () => _applyCategories(provider),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
