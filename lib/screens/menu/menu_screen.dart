import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/menu_item_model.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rdx_search_bar.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  /// Tabs shown even before any items exist for that category, so the
  /// filter row matches the reference design from the first load.
  static const List<String> _pinnedCategories = [
    'Starters',
    'Grills',
    'Mains',
    'Biryani',
    'Seafood',
    'Desserts',
    'Drinks',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<MenuProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MenuProvider>();
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: Responsive.pagePadding(context, top: 14, bottom: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context, colors),
              const SizedBox(height: 16),
              _buildCategoryTabs(provider, colors),
              const SizedBox(height: 18),
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
      hintText: 'Search menu items...',
      onChanged: (value) => context.read<MenuProvider>().setSearchQuery(value),
      actions: [
        ElevatedButton.icon(
          onPressed: () async {
            await Navigator.of(context).pushNamed(AppRoutes.editMenuItem);
            if (context.mounted) context.read<MenuProvider>().load();
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add New Item'),
        ),
        _iconBtn(colors,
            icon: Icons.notifications_outlined, badge: true, onTap: () {}),
        CircleAvatar(
          radius: 18,
          backgroundColor: colors.surfaceVariant,
          child: Icon(Icons.person, size: 18, color: colors.textSecondary),
        ),
      ],
    );
  }

  Widget _iconBtn(
    AppColorScheme colors, {
    required IconData icon,
    bool badge = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 21, color: colors.textSecondary),
            if (badge)
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // CATEGORY TABS
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildCategoryTabs(MenuProvider provider, AppColorScheme colors) {
    final categories = <String>{
      ..._pinnedCategories,
      ...provider.categories.where((c) => c != 'All'),
    }.toList();

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _categoryChip(colors,
                    label: 'All',
                    selected: provider.selectedCategory == 'All',
                    onTap: () => provider.setCategory('All')),
                for (final c in categories) ...[
                  const SizedBox(width: 8),
                  _categoryChip(colors,
                      label: c,
                      selected: provider.selectedCategory == c,
                      onTap: () => provider.setCategory(c)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        TextButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Manage Categories coming soon')),
            );
          },
          icon: const Icon(Icons.tune, size: 16),
          label: const Text('Manage Categories'),
          style: TextButton.styleFrom(
            foregroundColor: colors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ],
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
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: selected ? AppColors.primary : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : colors.textSecondary,
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // GRID — item cards + trailing "Add New Menu Item" tile
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildGrid(
      BuildContext context, MenuProvider provider, AppColorScheme colors) {
    final items = provider.filteredItems;

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == items.length) {
          return _AddItemTile(
              colors: colors,
              onTap: () async {
                await Navigator.of(context).pushNamed(AppRoutes.editMenuItem);
                if (context.mounted) context.read<MenuProvider>().load();
              });
        }
        final item = items[index];
        return _MenuItemCard(
          item: item,
          colors: colors,
          onToggleAvailability: () => provider.toggleAvailability(item),
          onEdit: () async {
            await Navigator.of(context)
                .pushNamed(AppRoutes.editMenuItem, arguments: item.id);
            if (context.mounted) context.read<MenuProvider>().load();
          },
          onDelete: () => provider.deleteItem(item.id),
        );
      },
    );
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

  /// Dot logic: grey when unavailable, otherwise green for veg / red (brand)
  /// for non-veg — matches the reference card design.
  Color get _dotColor {
    if (!item.available) return colors.textMuted;
    return item.isVeg ? AppColors.success : AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: colors.surfaceVariant,
                  child: Icon(Icons.fastfood_outlined,
                      color: colors.textMuted, size: 30),
                ),
                if (item.category.isNotEmpty)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3),
                      ),
                    ),
                  ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.8), width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5),
                ),
                const SizedBox(height: 3),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: item.available,
                            onChanged: (_) => onToggleAvailability(),
                            activeColor: AppColors.primary,
                          ),
                        ),
                        Text(
                          item.available ? 'Available' : 'Out of Stock',
                          style: TextStyle(
                            color: item.available
                                ? colors.textSecondary
                                : colors.textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: onEdit,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.edit_outlined,
                                size: 15, color: colors.textSecondary),
                          ),
                        ),
                        InkWell(
                          onTap: onDelete,
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.delete_outline,
                                size: 15, color: AppColors.danger),
                          ),
                        ),
                      ],
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
      borderRadius: BorderRadius.circular(14),
      child: DottedBorderContainer(
        color: colors.border,
        radius: 14,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: colors.textSecondary, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                'Add New Menu Item',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
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
  final Widget child;

  const DottedBorderContainer({
    super.key,
    required this.color,
    required this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(color: color, radius: radius),
      child: child,
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedRRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.6, 0.6, size.width - 1.2, size.height - 1.2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dashLength = 6.0;
    const gapLength = 5.0;
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
      oldDelegate.color != color || oldDelegate.radius != radius;
}
