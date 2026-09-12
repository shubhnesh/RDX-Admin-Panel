import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/screens/menu/widgets/menu_item_card.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_action_menu_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_delete_dialog.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/menu_item_model.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/reusable_widgets/empty_state.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/resuable_options/rdx_category_tabs.dart';
import '../../widgets/resuable_options/rdx_search_bar.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
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
      context.read<MenuProvider>().load();
    });
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
    _categoryOverlay?.remove();
    _categoryOverlay = null;
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // MENU ITEM ACTIONS (edit / delete)
  // ═══════════════════════════════════════════════════════════════

  void _showMenuItemActions(
    BuildContext buttonContext,
    MenuItemModel item,
  ) {
    final renderObject = buttonContext.findRenderObject();
    if (renderObject is! RenderBox) return;

    final buttonPosition = renderObject.localToGlobal(Offset.zero);

    showGeneralDialog<void>(
      context: buttonContext,
      barrierDismissible: true,
      barrierLabel: 'Menu item actions',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return RdxActionMenuDialog(
          position: buttonPosition,
          gap: 6,
          items: [
            RdxActionMenuItem(
              title: 'Edit',
              onTap: () async {
                await Navigator.of(context).pushNamed(
                  AppRoutes.editMenuItem,
                  arguments: item.id,
                );
                if (context.mounted) {
                  context.read<MenuProvider>().load();
                }
              },
            ),
            RdxActionMenuItem(
              title: 'Delete',
              textColor: AppColors.danger,
              onTap: () {
                _confirmDeleteMenuItem(context, item);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteMenuItem(
    BuildContext context,
    MenuItemModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Menu Item',
        itemName: item.name,
        itemDetails: [
          Text(
            item.category,
            style: AppTextStyles.body(context).copyWith(
              color: AppColors.of(context).textSecondary,
            ),
          ),
        ],
        deleteButtonLabel: 'Delete Item',
        warningMessage:
            'Deleting this menu item will permanently remove it from your '
            'menu. This action cannot be undone.',
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await context.read<MenuProvider>().deleteItem(item.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Menu item deleted.' : 'Failed to delete menu item.',
          ),
        ),
      );
    }
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

  // ═══════════════════════════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTopBar(BuildContext context, AppColorScheme colors) {
    return RdxSearchToolbar(
      hintText: 'Search menu items',
      onChanged: (value) => context.read<MenuProvider>().setSearchQuery(value),
      actions: [
        RdxActionButton(
          label: 'Add Item',
          leadingIcon: Icons.add,
          onPressed: () async {
            await Navigator.of(context).pushNamed(AppRoutes.editMenuItem);
            if (context.mounted) context.read<MenuProvider>().load();
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CATEGORY TABS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCategoryTabs(MenuProvider provider, AppColorScheme colors) {
    final categories = !_hasAppliedCategories
        ? MenuTaxonomy.mainCategories.map((c) => c.name).toList()
        : _appliedCategories.toList();

    // Always keep tabs + manage button on ONE row.
    // Tabs scroll horizontally so they never wrap under the filter button.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: RdxCategoryTabs(
            labels: categories,
            allLabel: 'All',
            selectedLabel: provider.selectedCategory,
            onSelected: provider.setCategory,
            expand: false,
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

  // ═══════════════════════════════════════════════════════════════
  // GRID
  // ═══════════════════════════════════════════════════════════════

  Widget _buildGrid(
    BuildContext context,
    MenuProvider provider,
    AppColorScheme colors,
  ) {
    final items = provider.filteredItems;
    final showAddItemTile = provider.selectedCategory == 'All';

    // Desktop/tablet: original-style card size (~240 x 400).
    // Narrow screens: one card per row so content is easy to read/tap.
    final screenW = MediaQuery.sizeOf(context).width;
    final isNarrow = screenW < 700;

     final SliverGridDelegate gridDelegate = isNarrow
        ? const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            mainAxisExtent: 360,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          )
        : const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            mainAxisExtent: 350,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
          );

    return GridView.builder(
      padding: EdgeInsets.only(bottom: context.h(24)),
      gridDelegate: gridDelegate,
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

        return MenuItemCard(
          item: item,
          onToggleAvailability: () => provider.toggleAvailability(item),
          onActions: (buttonContext) {
            _showMenuItemActions(buttonContext, item);
          },
        );
      },
    );
  }
}

// ─── Add Item Tile ────────────────────────────────────────────────────

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
        color: colors.border,
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
                child: Icon(
                  Icons.add,
                  color: colors.textMuted.withValues(alpha: 0.5),
                  size: context.h(30),
                ),
              ),
              SizedBox(height: context.h(10)),
              Text(
                'Add Item',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyTertiary(context)
                    .copyWith(color: colors.textMuted.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dotted Border helpers ────────────────────────────────────────────

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
