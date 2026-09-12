import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import '../../core/theme/app_colors.dart';

class SidebarItem {
  final String label;
  final IconData icon;
  final String route;
  const SidebarItem(
      {required this.label, required this.icon, required this.route});
}

const List<SidebarItem> kPrimaryNavItems = [
  SidebarItem(
      label: 'Dashboard', icon: Icons.dashboard_outlined, route: '/dashboard'),
  SidebarItem(
      label: 'Live Orders',
      icon: Icons.receipt_long_outlined,
      route: '/live-orders'),
  SidebarItem(
      label: 'Menu', icon: Icons.restaurant_menu_outlined, route: '/menu'),
  SidebarItem(
      label: 'Coupons', icon: Icons.local_offer_outlined, route: '/coupons'),
  SidebarItem(
      label: 'Inventory',
      icon: Icons.inventory_2_outlined,
      route: '/inventory'),
];

/// Professional collapsible side navigation rail.
/// Expanded width ~240, collapsed ~72. Smooth width + fade animation.
class MainSideNav extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback? onLogout;
  final VoidCallback? onAddOrder;

  static const double expandedWidth = 240;
  static const double collapsedWidth = 72;
  static const Duration _animDuration = Duration(milliseconds: 280);
  static const Curve _animCurve = Curves.easeInOutCubic;

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
    const sidebarBg = AppColors.lightSidebar;
    const textPrimary = AppColors.lightTextPrimary;
    const textSecondary = AppColors.lightTextSecondary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: _animDuration,
          curve: _animCurve,
          width: expanded ? expandedWidth : collapsedWidth,
          decoration: const BoxDecoration(
            color: sidebarBg,
            border: Border(
                right: BorderSide(color: AppColors.lightBorder, width: 1)),
          ),
          // Clip everything so nothing paints outside during the width animation.
          child: ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header / brand ────────────────────────────────────
                _buildHeader(context, textPrimary, textSecondary),
                const SizedBox(height: 8),
                // ── Primary nav ───────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                // ── Footer actions ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Divider(
                    color: AppColors.lightDivider.withOpacity(0.8),
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      _FooterTile(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        expanded: expanded,
                        selected: currentRoute == '/settings',
                        onTap: () => onNavigate('/settings'),
                      ),
                      _FooterTile(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        expanded: expanded,
                        selected: currentRoute == '/notifications',
                        onTap: () => onNavigate('/notifications'),
                      ),
                      _FooterTile(
                        icon: Icons.support_agent_outlined,
                        label: 'Support',
                        expanded: expanded,
                        selected: currentRoute == '/support',
                        onTap: () => onNavigate('/support'),
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
          ),
        ),
        // ── Floating edge toggle ────────────────────────────────────
        AnimatedPositioned(
          duration: _animDuration,
          curve: _animCurve,
          top: 28,
          left: (expanded ? expandedWidth : collapsedWidth) - 14,
          child: _EdgeToggleButton(
            expanded: expanded,
            onTap: onToggleExpand,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
      BuildContext context, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        expanded ? 16 : 12,
        20,
        expanded ? 16 : 12,
        12,
      ),
      child: Row(
        children: [
          // Logo stays fixed size so it never causes overflow.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.restaurant,
                color: AppColors.primary, size: 20),
          ),
          // Text fades + size-animates instead of being crushed.
          AnimatedSize(
            duration: _animDuration,
            curve: _animCurve,
            alignment: Alignment.centerLeft,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: expanded ? 1.0 : 0.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Admin',
                            // style: TextStyle(
                            //   color: textPrimary,
                            //   fontSize: 17,
                            //   fontWeight: FontWeight.bold,
                            //   letterSpacing: 0.2,
                            //   height: 1.1,
                            // ),
                            style: AppTextStyles.heading(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'RDX Restaurant',
                            // style: TextStyle(
                            //   color: textSecondary,
                            //   fontSize: 9.5,
                            //   fontWeight: FontWeight.w600,
                            //   letterSpacing: 1.0,
                            //   height: 1.4,
                            // ),
                            style: AppTextStyles.body(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Floating circular toggle that sits on the right edge of the rail.
class _EdgeToggleButton extends StatefulWidget {
  final bool expanded;
  final VoidCallback onTap;
  const _EdgeToggleButton({required this.expanded, required this.onTap});

  @override
  State<_EdgeToggleButton> createState() => _EdgeToggleButtonState();
}

class _EdgeToggleButtonState extends State<_EdgeToggleButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Tooltip(
        message: widget.expanded ? 'Collapse sidebar' : 'Expand sidebar',
        waitDuration: const Duration(milliseconds: 400),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 160),
            scale: _hovering ? 1.1 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _hovering ? AppColors.primary : AppColors.lightSurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _hovering ? AppColors.primary : AppColors.lightBorder,
                  width: 1.5,
                ),
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.black.withOpacity(0.4),
                //     blurRadius: 8,
                //     offset: const Offset(0, 2),
                //   ),
                // ],
              ),
              // Clear directional icons instead of a rotating chevron.
              child: Icon(
                widget.expanded
                    ? Icons.keyboard_double_arrow_left_rounded
                    : Icons.keyboard_double_arrow_right_rounded,
                size: 18,
                color: _hovering ? Colors.white : AppColors.lightTextSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sectional widgets ────────────────────────────────────────────────

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

  static const Duration _d = Duration(milliseconds: 280);
  static const Curve _c = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    final bg =
        selected ? AppColors.primary.withOpacity(0.15) : Colors.transparent;
    final color = selected ? AppColors.primary : AppColors.lightTextSecondary;

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
            child: Row(
              mainAxisAlignment:
                  expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: expanded ? 12 : 0),
                  child: Icon(item.icon, size: 20, color: color),
                ),
                AnimatedSize(
                  duration: _d,
                  curve: _c,
                  alignment: Alignment.centerLeft,
                  child: expanded
                      ? Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: expanded ? 1.0 : 0.0,
                            child: Text(
                              item.label,
                              // style: TextStyle(
                              //   color: selected
                              //       ? AppColors.lightTextPrimary
                              //       : AppColors.lightTextSecondary,
                              //   fontSize: 13,
                              //   fontWeight: FontWeight.w500,
                              // ),
                              style: AppTextStyles.section(context).copyWith(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.lightTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
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

  static const Duration _d = Duration(milliseconds: 280);
  static const Curve _c = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppColors.danger.withOpacity(0.9)
        : selected
            ? AppColors.primary
            : AppColors.lightTextSecondary;
    final bg =
        selected ? AppColors.primary.withOpacity(0.15) : Colors.transparent;

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
            child: Row(
              mainAxisAlignment:
                  expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: expanded ? 12 : 0),
                  child: Icon(icon, size: 20, color: color),
                ),
                AnimatedSize(
                  duration: _d,
                  curve: _c,
                  alignment: Alignment.centerLeft,
                  child: expanded
                      ? Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: expanded ? 1.0 : 0.0,
                            child: Text(
                              label,
                              style: AppTextStyles.section(context)
                                  .copyWith(color: color),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
