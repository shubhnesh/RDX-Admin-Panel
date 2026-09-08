import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/menu_item_model.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/form_action_button.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rdx_toggle_button.dart';
import '../../widgets/rdx_search_bar.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final ScrollController _categoryScrollController = ScrollController();
  final Set<String> _appliedCategories = {};
  Set<String>? _stagedCategories;
  bool _hasAppliedCategories = false;
  bool _categoryPickerOpen = false;
  final GlobalKey _categoryButtonKey = GlobalKey();
  OverlayEntry? _categoryOverlay;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<MenuProvider>().load());
  }

  void _openCategoryPicker(MenuProvider provider) {
    if (_categoryPickerOpen) {
      _closeCategoryPicker();
      return;
    }

    _stagedCategories = !_hasAppliedCategories
        ? MenuTaxonomy.mainCategories.map((category) => category.name).toSet()
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
  void dispose() {
    _categoryScrollController.dispose();
    _categoryOverlay?.remove();
    _categoryOverlay = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MenuProvider>();
    final colors = AppColors.of(context);

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
              _buildTopBar(context, colors),
              SizedBox(height: context.h(16)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: context.h(10)),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: colors.divider),
                    bottom: BorderSide(color: colors.divider),
                  ),
                ),
                child: _buildCategoryTabs(provider, colors),
              ),
              SizedBox(height: context.h(18)),
              Expanded(
                child: provider.isLoading
                    ? const LoadingIndicator()
                    : provider.filteredItems.isEmpty
                        ? const EmptyState(message: 'No menu items found')
                        : _buildGrid(context, provider, colors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TOP BAR — search + Add New Item + notifications + avatar
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTopBar(BuildContext context, AppColorScheme colors) {
    return RdxSearchToolbar(
      hintText: 'Search menu items',
      onChanged: (value) => context.read<MenuProvider>().setSearchQuery(value),
      actions: [
        FormActionButton(
          label: 'Add Item',
          onPressed: () async {
            await Navigator.of(context).pushNamed(AppRoutes.editMenuItem);
            if (context.mounted) context.read<MenuProvider>().load();
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CATEGORY TABS (Horizontally Scrollable)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildCategoryTabs(
    MenuProvider provider,
    AppColorScheme colors,
  ) {
    final categories = !_hasAppliedCategories
        ? MenuTaxonomy.mainCategories.map((category) => category.name).toList()
        : _appliedCategories.toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent &&
                  _categoryScrollController.hasClients) {
                final position = _categoryScrollController.position;
                final offset = (position.pixels + event.scrollDelta.dy)
                    .clamp(0.0, position.maxScrollExtent);
                _categoryScrollController.jumpTo(offset);
              }
            },
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.touch,
                  PointerDeviceKind.stylus,
                },
              ),
              child: ClipRect(
                child: SingleChildScrollView(
                  controller: _categoryScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _categoryChip(
                        colors,
                        label: 'All',
                        selected: provider.selectedCategory == 'All',
                        onTap: () => provider.setCategory('All'),
                      ),
                      for (final category in categories) ...[
                        SizedBox(width: context.w(8)),
                        _categoryChip(
                          colors,
                          label: category,
                          selected: provider.selectedCategory == category,
                          onTap: () => provider.setCategory(category),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: context.w(12)),
        // This button stays fixed and never scrolls with the chips
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
              color: _categoryPickerOpen ? AppColors.primary : colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune, size: context.h(16), color: AppColors.primary),
            SizedBox(width: context.w(4)),
            Icon(
              _categoryPickerOpen
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: context.h(17),
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
                child: Text('Filter categories',
                    // style: TextStyle(
                    //   color: colors.textPrimary,
                    //   fontSize: context.h(13),
                    //   fontWeight: FontWeight.w700,
                    // ),
                    style: AppTextStyles.section(context)
                        .copyWith(color: colors.textPrimary)),
              ),
              Text('${staged.length} selected',
                  // style: TextStyle(
                  //   color: colors.textMuted,
                  //   fontSize: context.h(10.5),
                  //   fontWeight: FontWeight.w600,
                  // ),
                  style: AppTextStyles.bodySecondary(context)
                      .copyWith(color: colors.textMuted)),
            ],
          ),
          SizedBox(height: context.h(4)),
          Text('Choose which categories appear in the filter row.',
              // style: TextStyle(
              //   color: colors.textSecondary,
              //   fontSize: context.h(10.5),
              // ),
              style: AppTextStyles.caption(context)
                  .copyWith(color: colors.textSecondary)),
          SizedBox(height: context.h(10)),
          Container(
            height: listHeight,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(context.h(7)),
              border: Border.all(color: colors.border),
            ),
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: context.h(5)),
                itemCount: MenuTaxonomy.mainCategories.length,
                separatorBuilder: (_, __) => Divider(
                  height: context.h(1),
                  indent: context.w(48),
                  color: colors.divider,
                ),
                itemBuilder: (context, index) {
                  final category = MenuTaxonomy.mainCategories[index];
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
                            visualDensity: VisualDensity.compact,
                          ),
                          Expanded(
                            child: Text(category.name,
                                // style: TextStyle(
                                //   color: colors.textPrimary,
                                //   fontSize: context.h(11.5),
                                //   fontWeight: FontWeight.w600,
                                // ),
                                style: AppTextStyles.label(context)
                                    .copyWith(color: colors.textPrimary)),
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
              // TextButton(
              //   onPressed: _closeCategoryPicker,
              //   child: const Text('Cancel'),
              // ),
              FormActionButton(
                label: 'Cancel',
                isPrimary: false,
                onPressed: _closeCategoryPicker,
              ),
              SizedBox(width: context.w(6)),
              // ElevatedButton(
              //   onPressed: () => _applyCategories(provider),
              //   style: ElevatedButton.styleFrom(
              //     padding: EdgeInsets.symmetric(
              //       horizontal: context.w(14),
              //       vertical: context.h(9),
              //     ),
              //   ),
              //   child: const Text('Apply'),
              // ),
              FormActionButton(
                label: 'Apply',
                onPressed: () => _applyCategories(provider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(
    AppColorScheme colors, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.h(20)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(9),
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : colors.surface,
          borderRadius: BorderRadius.circular(context.h(20)),
          border:
              Border.all(color: selected ? AppColors.primary : colors.border),
        ),
        child: Text(
          label,
          // style: TextStyle(
          //   color: selected ? Colors.white : colors.textSecondary,
          //   fontSize: context.h(12.5),
          //   fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          // ),
          style: selected
              ? AppTextStyles.bodySecondary(context)
                  .copyWith(color: Colors.white)
              : AppTextStyles.bodySecondary(context)
                  .copyWith(color: colors.textSecondary),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // GRID — leading "Add New Menu Item" tile + item cards
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildGrid(
      BuildContext context, MenuProvider provider, AppColorScheme colors) {
    final items = provider.filteredItems;
    final showAddItemTile = provider.selectedCategory == 'All';

    return GridView.builder(
      padding: EdgeInsets.only(bottom: context.h(24)),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: context.w(225),
        mainAxisExtent: context.h(375),
        mainAxisSpacing: context.h(18),
        crossAxisSpacing: context.w(18),
      ),
      itemCount: items.length + (showAddItemTile ? 1 : 0),
      itemBuilder: (context, index) {
        if (showAddItemTile && index == 0) {
          return _AddItemTile(
            colors: colors,
            onTap: () async {
              await Navigator.of(context).pushNamed(AppRoutes.editMenuItem);
              if (context.mounted) {
                context.read<MenuProvider>().load();
              }
            },
          );
        }

        final item = items[showAddItemTile ? index - 1 : index];

        return _MenuItemCard(
          item: item,
          colors: colors,
          onToggleAvailability: () => provider.toggleAvailability(item),
          onEdit: () async {
            await Navigator.of(context).pushNamed(
              AppRoutes.editMenuItem,
              arguments: item.id,
            );
            if (context.mounted) {
              context.read<MenuProvider>().load();
            }
          },
          onDelete: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Delete menu item?'),
                  content: Text(
                    'Are you sure you want to delete "${item.name}"?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                );
              },
            );

            if (confirmed != true) return;

            final success = await provider.deleteItem(item.id);

            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Menu item deleted.'
                      : 'Failed to delete menu item.',
                ),
              ),
            );
          },
        );
      },
    );
    ;
  }
}

// ─── Menu item card ───────────────────────────────────────────────────

class _MenuItemCard extends StatelessWidget {
  final MenuItemModel item;
  final AppColorScheme colors;
  final VoidCallback onToggleAvailability;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MenuItemCard({
    required this.item,
    required this.colors,
    required this.onToggleAvailability,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final preparation = item.preparationStyle.name.replaceAll('_', ' ');
    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.45,
            child: Padding(
              padding: EdgeInsets.all(context.h(6)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(context.h(8)),
                child: Stack(children: [
                  Positioned.fill(
                    child: item.imageUrl.trim().isEmpty
                        ? Container(
                            color: colors.surfaceVariant,
                            child: Icon(Icons.restaurant_outlined,
                                color: colors.textMuted, size: context.h(34)),
                          )
                        : Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: colors.surfaceVariant,
                              child: Icon(Icons.restaurant_outlined,
                                  color: colors.textMuted, size: context.h(34)),
                            ),
                          ),
                  ),
                  if (item.featuredItem)
                    Positioned(
                      left: context.w(10),
                      top: context.h(10),
                      child: _cardBadge(
                          context, 'Featured', AppColors.primary, Colors.white),
                    ),
                  Positioned(
                    right: context.w(10),
                    bottom: context.h(10),
                    child: _dietaryBadge(context),
                  ),
                ]),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.w(12),
              context.h(6),
              context.w(12),
              context.h(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    // style: TextStyle(
                    //   color: AppColors.primary,
                    //   fontSize: context.h(9),
                    //   fontWeight: FontWeight.w700,
                    // ),
                    style: AppTextStyles.label(context)
                        .copyWith(color: AppColors.primary)),
                SizedBox(height: context.h(3)),
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    //   style: TextStyle(
                    //     color: colors.textPrimary,
                    //     fontWeight: FontWeight.w700,
                    //     fontSize: context.h(14),
                    //   ),
                    style: AppTextStyles.section(context)
                        .copyWith(color: colors.textPrimary)),
                SizedBox(height: context.h(4)),
                SizedBox(
                  height: context.h(14),
                  child: item.ingredients.isEmpty
                      ? null
                      : Text(
                          item.ingredients.join(', '),
                          // style: TextStyle(
                          //   color: colors.textSecondary,
                          //   fontSize: context.h(10),
                          // ),
                          style: AppTextStyles.body(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                SizedBox(height: context.h(8)),
                Wrap(
                  spacing: context.w(5),
                  runSpacing: context.h(5),
                  children: [
                    _detailChip(
                      context,
                      _titleCase(preparation),
                      colors.textSecondary,
                    ),
                    for (final tag in item.tags
                        .where((tag) => tag.toLowerCase() != 'featured')
                        .take(item.featuredItem ? 3 : 4))
                      _detailChip(
                          context, _titleCase(tag), colors.textSecondary),
                  ],
                ),
                SizedBox(height: context.h(10)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('₹${item.price.toStringAsFixed(2)}',
                        // style: TextStyle(
                        //   color: AppColors.primary,
                        //   fontSize: context.h(15),
                        //   fontWeight: FontWeight.w800,
                        // ),
                        style: AppTextStyles.label(context)
                            .copyWith(color: colors.primary)),
                  ],
                ),
                SizedBox(height: context.h(8)),
                Divider(height: context.h(1), color: colors.divider),
                SizedBox(height: context.h(6)),
                Row(
                  children: [
                    RdxToggleButton(
                      value: item.available,
                      activeColor: AppColors.primary,
                      onChanged: (_) => onToggleAvailability(),
                    ),
                    SizedBox(width: context.w(5)),
                    Text(
                      item.available ? 'Available' : 'Sold Out',
                      // style: AppTextStyles.label(context).copyWith(
                      //   color: item.available
                      //       ? AppColors.success
                      //       : colors.textMuted,
                      // )
                      style: AppTextStyles.bodySecondary(context).copyWith(
                        color: item.available
                            ? AppColors.success
                            : colors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(context.h(6)),
                      child: Padding(
                        padding: EdgeInsets.all(context.h(5)),
                        child: Icon(Icons.edit_outlined,
                            size: context.h(20), color: colors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardBadge(
      BuildContext context, String label, Color background, Color foreground) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(7),
        vertical: context.h(4),
      ),
      decoration: BoxDecoration(
        color: background.withValues(
            alpha: background == AppColors.primary ? 1 : 0.92),
        borderRadius: BorderRadius.circular(context.h(5)),
      ),
      child: Text(
        label,
        // style: TextStyle(
        //   color: foreground,
        //   fontSize: context.h(9),
        //   fontWeight: FontWeight.w700,
        // ),
        style: AppTextStyles.caption(context).copyWith(color: foreground),
      ),
    );
  }

  Widget _detailChip(BuildContext context, String label, Color color) =>
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.w(6),
          vertical: context.h(3),
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(context.h(4)),
        ),
        child: Text(label,
            // style: TextStyle(
            //   color: color,
            //   fontSize: context.h(9),
            //   fontWeight: FontWeight.w600,
            // ),
            style: AppTextStyles.caption(context).copyWith(color: color)),
      );

  Widget _dietaryBadge(BuildContext context) {
    final color = item.isVeg ? AppColors.success : AppColors.danger;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(7),
        vertical: context.h(4),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(context.h(5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: context.h(8), color: color),
          SizedBox(width: context.w(5)),
          Text(_dietaryLabel(item.dietaryType),
              // style: TextStyle(
              //   color: color,
              //   fontSize: context.h(9),
              //   fontWeight: FontWeight.w700,
              // ),
              style: AppTextStyles.label(context).copyWith(color: color)),
        ],
      ),
    );
  }

  String _dietaryLabel(DietaryType type) => type == DietaryType.veg
      ? 'Veg'
      : type == DietaryType.egg
          ? 'Contains Egg'
          : 'Non-Veg';

  String _titleCase(String value) => value
      .split(' ')
      .map((part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

// ─── Trailing "Add New Menu Item" tile ─────────────────────────────────

class _AddItemTile extends StatelessWidget {
  final AppColorScheme colors;
  final VoidCallback onTap;

  const _AddItemTile({required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.h(14)),
      child: DottedBorderContainer(
        color: colors.textMuted,
        radius: context.h(14),
        dashLength: context.h(6),
        gapLength: context.h(5),
        strokeWidth: context.h(1.2),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: context.w(36),
                height: context.h(36),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add,
                    color: colors.textSecondary, size: context.h(30)),
              ),
              SizedBox(height: context.h(10)),
              Text('Add Item',
                  textAlign: TextAlign.center,
                  // style: TextStyle(
                  //     color: colors.textSecondary,
                  //     fontSize: context.h(12),
                  //     fontWeight: FontWeight.w500),
                  style: AppTextStyles.section(context)
                      .copyWith(color: colors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lightweight dashed-border box (no external package dependency) used for
/// the trailing "Add New Menu Item" tile.
class DottedBorderContainer extends StatelessWidget {
  final Color color;
  final double radius;
  final double dashLength;
  final double gapLength;
  final double strokeWidth;
  final Widget child;

  const DottedBorderContainer({
    super.key,
    required this.color,
    required this.radius,
    required this.dashLength,
    required this.gapLength,
    required this.strokeWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: color,
        radius: radius,
        dashLength: dashLength,
        gapLength: gapLength,
        strokeWidth: strokeWidth,
      ),
      child: child,
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashLength;
  final double gapLength;
  final double strokeWidth;

  _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.dashLength,
    required this.gapLength,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.6, 0.6, size.width - 1.2, size.height - 1.2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dashLength).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next.toDouble()), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.gapLength != gapLength ||
      oldDelegate.strokeWidth != strokeWidth;
}
