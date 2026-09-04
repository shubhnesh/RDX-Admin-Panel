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
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.gridColumns(context),
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 0.78,
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
          // onDelete: () => provider.deleteItem(item.id),
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
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
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
    final preparation = item.preparationStyle.name.replaceAll('_', ' ');
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.45,
            child: Stack(children: [
              Positioned.fill(
                child: item.imageUrl.trim().isEmpty
                    ? Container(
                        color: colors.surfaceVariant,
                        child: Icon(Icons.restaurant_outlined,
                            color: colors.textMuted, size: 34),
                      )
                    : Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: colors.surfaceVariant,
                          child: Icon(Icons.restaurant_outlined,
                              color: colors.textMuted, size: 34),
                        ),
                      ),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: _cardBadge(
                    item.category, colors.surface, colors.textPrimary),
              ),
              if (item.featuredItem)
                Positioned(
                  right: 10,
                  top: 10,
                  child:
                      _cardBadge('Featured', AppColors.primary, Colors.white),
                ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: _dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description.isEmpty
                      ? 'No description added'
                      : item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: colors.textSecondary, fontSize: 11, height: 1.35),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    _detailChip(_dietaryLabel(item.dietaryType),
                        item.isVeg ? AppColors.success : AppColors.primary),
                    _detailChip(_titleCase(preparation), colors.textSecondary),
                    for (final tag in item.tags.take(2))
                      _detailChip(_titleCase(tag), colors.textMuted),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '₹${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text(
                      item.available ? 'Available' : 'Unavailable',
                      style: TextStyle(
                          color: item.available
                              ? AppColors.success
                              : colors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      onPressed: onToggleAvailability,
                      tooltip: item.available
                          ? 'Mark unavailable'
                          : 'Mark available',
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.only(left: 4),
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        item.available
                            ? Icons.toggle_on_outlined
                            : Icons.toggle_off_outlined,
                        size: 22,
                        color: item.available
                            ? AppColors.success
                            : colors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: colors.divider),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Icon(Icons.edit_outlined,
                            size: 16, color: colors.textSecondary),
                      ),
                    ),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(Icons.delete_outline,
                            size: 16, color: AppColors.danger),
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

  Widget _cardBadge(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background.withValues(
            alpha: background == AppColors.primary ? 1 : 0.92),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label,
          style: TextStyle(
              color: foreground, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }

  Widget _detailChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4)),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 9, fontWeight: FontWeight.w600)),
      );

  String _dietaryLabel(DietaryType type) => type == DietaryType.nonVeg
      ? 'Non-Veg'
      : type == DietaryType.egg
          ? 'Egg'
          : 'Veg';

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
