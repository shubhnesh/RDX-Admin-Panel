import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/theme_provider.dart';

class SidebarItem {
  final String label;
  final IconData icon;
  final String route;
  const SidebarItem({required this.label, required this.icon, required this.route});
}

const List<SidebarItem> kPrimaryNavItems = [
  SidebarItem(label: 'Dashboard', icon: Icons.dashboard_outlined, route: '/dashboard'),
  SidebarItem(label: 'Live Orders', icon: Icons.receipt_long_outlined, route: '/live-orders'),
  SidebarItem(label: 'Menu', icon: Icons.restaurant_menu_outlined, route: '/menu'),
  SidebarItem(label: 'Coupons', icon: Icons.local_offer_outlined, route: '/coupons'),
  SidebarItem(label: 'Notifications', icon: Icons.campaign_outlined, route: '/notifications'),
  SidebarItem(label: 'Inventory', icon: Icons.inventory_2_outlined, route: '/inventory'),
];

/// Professional collapsible side navigation rail.
/// Expanded width ~240, collapsed ~72. Animates smoothly.
class MainSideNav extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback? onLogout;
  final VoidCallback? onAddOrder;

  static const double expandedWidth = 240;
  static const double collapsedWidth = 72;

  const MainSideNav({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.expanded,
    required this.onToggleExpand,
    this.onLogout,
    this.onAddOrder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    // Sidebar stays dark for brand consistency even in light mode.
    const sidebarBg = AppColors.darkSidebar;
    const textPrimary = AppColors.darkTextPrimary;
    const textSecondary = AppColors.darkTextSecondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: expanded ? expandedWidth : collapsedWidth,
      decoration: const BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: AppColors.darkBorder, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header / brand ────────────────────────────────────────
          _buildHeader(textPrimary, textSecondary),
          const SizedBox(height: 8),
          // ── Primary nav ───────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              children: [
                for (final item in kPrimaryNavItems)
                  _NavTile(
                    item: item,
                    selected: currentRoute == item.route,
                    expanded: expanded,
                    onTap: () => onNavigate(item.route),
                  ),
              ],
            ),
          ),
          // ── Add Order CTA ─────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 10, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onAddOrder ?? () => onNavigate('/live-orders'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: expanded
                    ? const Text('Add Order', style: TextStyle(fontWeight: FontWeight.w600))
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // ── Footer actions ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Divider(color: AppColors.darkDivider.withOpacity(0.8), height: 1),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                // Theme toggle
                _FooterTile(
                  icon: theme.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  label: theme.isDark ? 'Light Mode' : 'Dark Mode',
                  expanded: expanded,
                  onTap: () => theme.toggle(),
                ),
                _FooterTile(
                  icon: Icons.support_agent_outlined,
                  label: 'Support',
                  expanded: expanded,
                  selected: currentRoute == '/support',
                  onTap: () => onNavigate('/support'),
                ),
                _FooterTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  expanded: expanded,
                  selected: currentRoute == '/settings',
                  onTap: () => onNavigate('/settings'),
                ),
                _FooterTile(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  expanded: expanded,
                  onTap: onLogout ?? () {},
                  danger: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary) {
    return Padding(
      padding: EdgeInsets.fromLTRB(expanded ? 16 : 12, 20, expanded ? 8 : 12, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.restaurant, color: AppColors.primary, size: 20),
          ),
          if (expanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'RDX Admin',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                      height: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'MANAGEMENT HUB',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      height: 1.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Collapse sidebar',
              onPressed: onToggleExpand,
              icon: Icon(Icons.menu_open, size: 20, color: textSecondary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ] else
            Expanded(
              child: IconButton(
                tooltip: 'Expand sidebar',
                onPressed: onToggleExpand,
                icon: Icon(Icons.menu, size: 20, color: textSecondary),
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Sectional widgets (same file, private) ─────────────────────────

class _NavTile extends StatelessWidget {
  final SidebarItem item;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primary.withOpacity(0.18) : Colors.transparent;
    final iconColor = selected ? AppColors.primary : AppColors.darkTextSecondary;
    final textColor = selected ? AppColors.darkTextPrimary : AppColors.darkTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: selected
                  ? Border.all(color: AppColors.primary.withOpacity(0.45))
                  : null,
            ),
            child: expanded
                ? Row(
                    children: [
                      Icon(item.icon, size: 20, color: iconColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Center(child: Icon(item.icon, size: 22, color: iconColor)),
          ),
        ),
      ),
    );
  }
}

class _FooterTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool expanded;
  final VoidCallback onTap;
  final bool selected;
  final bool danger;

  const _FooterTile({
    required this.icon,
    required this.label,
    required this.expanded,
    required this.onTap,
    this.selected = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppColors.danger.withOpacity(0.9)
        : selected
            ? AppColors.primary
            : AppColors.darkTextSecondary;
    final bg = selected ? AppColors.primary.withOpacity(0.15) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 42,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(icon, size: 20, color: color),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: color,
                              fontSize: 13.5,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(child: Icon(icon, size: 20, color: color)),
          ),
        ),
      ),
    );
  }
}
