import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import '../../core/theme/app_colors.dart';

class SidebarItem {
  final String label;
  final IconData icon;
  final String route;

  const SidebarItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

/// Professional collapsible side navigation rail.
/// Expanded width ~240, collapsed ~78. Smooth width + fade animation.
class MainSideNav extends StatelessWidget {
  final List<SidebarItem> items;
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback? onLogout;
  final VoidCallback? onAddOrder;
  final bool showNotifications;
  final int notificationUnreadCount;

  /// Design-time widths (scaled at runtime via [context.w]).
  static const double expandedWidth = 240;
  static const double collapsedWidth = 78;

  static const Duration _animDuration = Duration(milliseconds: 280);
  static const Curve _animCurve = Curves.easeInOutCubic;

  const MainSideNav({
    super.key,
    required this.items,
    required this.currentRoute,
    required this.onNavigate,
    required this.expanded,
    required this.onToggleExpand,
    this.onLogout,
    this.onAddOrder,
    this.showNotifications = false,
    this.notificationUnreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final expandedW = context.w(expandedWidth);
    final collapsedW = context.w(collapsedWidth);
    final currentW = expanded ? expandedW : collapsedW;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: _animDuration,
          curve: _animCurve,
          width: currentW,
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              right: BorderSide(color: colors.border, width: 1),
            ),
          ),
          // ClipRect prevents any mid-animation overflow from ever
          // painting outside the rail's current (animating) width.
          child: ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header / brand ────────────────────────────────────
                _buildHeader(context, colors),
                SizedBox(height: context.h(8)),
                // ── Primary nav ───────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(expanded ? 10 : 8),
                      vertical: context.h(10),
                    ),
                    children: [
                      for (final item in items)
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
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(expanded ? 10 : 8),
                  ),
                  child: Divider(
                    color: colors.divider.withValues(alpha: 0.8),
                    height: 1,
                  ),
                ),
                SizedBox(height: context.h(8)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(expanded ? 10 : 8),
                  ),
                  child: Column(
                    children: [
                      if (showNotifications)
                        _FooterTile(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          expanded: expanded,
                          selected: currentRoute == '/notifications',
                          onTap: () => onNavigate('/notifications'),
                          unreadCount: notificationUnreadCount,
                        ),
                      _FooterTile(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        expanded: expanded,
                        selected: currentRoute == '/settings' ||
                            currentRoute == '/support',
                        onTap: () => onNavigate('/settings'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.h(16)),
              ],
            ),
          ),
        ),
        // ── Floating edge toggle ────────────────────────────────────
        AnimatedPositioned(
          duration: _animDuration,
          curve: _animCurve,
          top: context.h(28),
          left: currentW - context.w(14),
          child: _EdgeToggleButton(
            expanded: expanded,
            onTap: onToggleExpand,
          ),
        ),
      ],
    );
  }

  /// Brand block: text-only "RDX" wordmark with a small "Ops Center" tag.
  /// When collapsed, only the "RDX" wordmark remains, centered in the rail.
  Widget _buildHeader(BuildContext context, AppColorScheme colors) {
    final inset = context.w(expanded ? 10 : 8);
    final tile = context.h(42);

    return Padding(
      padding: EdgeInsets.fromLTRB(inset, context.h(20), inset, context.h(12)),
      child: SizedBox(
        height: tile,
        child: Row(
          mainAxisAlignment:
              expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Flexible(
              child: AnimatedSize(
                duration: _animDuration,
                curve: _animCurve,
                alignment: Alignment.centerLeft,
                child: ClipRect(
                  child: Padding(
                    padding: EdgeInsets.only(left: context.w(expanded ? 6 : 0)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: expanded
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'RDX',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: AppTextStyles.bodyLargeSemi(context).copyWith(
                            color: colors.textPrimary,
                            fontSize: expanded ? 19 : 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                            height: 1.1,
                          ),
                        ),
                        if (expanded) ...[
                          SizedBox(height: context.h(2)),
                          Text(
                            'Ops Center',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                            style: AppTextStyles.caption(context).copyWith(
                              color: colors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.6,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
    final colors = AppColors.of(context);
    // Single scale factor for both dimensions so the button stays a true circle.
    final size = context.h(28);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Tooltip(
        message: widget.expanded ? 'Collapse sidebar' : 'Expand sidebar',
        waitDuration: const Duration(milliseconds: 400),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _hovering ? AppColors.primary : colors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: _hovering ? AppColors.primary : colors.border,
                width: 1.5,
              ),
            ),
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 280),
              turns: widget.expanded ? 0 : 0.5,
              child: Icon(
                Icons.keyboard_double_arrow_left_rounded,
                size: size * (18 / 28),
                color: _hovering ? AppColors.white : colors.textSecondary,
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
    final colors = AppColors.of(context);
    final bg = selected
        ? AppColors.primary.withValues(alpha: 0.15)
        : Colors.transparent;
    final color = selected ? AppColors.primary : colors.textSecondary;

    final tileHeight = context.h(42);
    final squareSide = tileHeight;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(6)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // constraints.maxWidth is the real, concrete width available
          // (the ListView's content width), so we can animate to it
          // instead of jumping to double.infinity.
          final fullWidth = constraints.maxWidth;
          final targetWidth = expanded ? fullWidth : squareSide;

          return Center(
            child: AnimatedContainer(
              duration: _d,
              curve: _c,
              width: targetWidth,
              height: tileHeight,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(context.h(10)),
              ),
              // Clip so children never paint/measure outside the
              // currently-animating width — this is what kills the
              // overflow exception during the collapse transition.
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Icon: pinned at a fixed left inset when expanded,
                      // dead-centered in the square when collapsed.
                      Positioned(
                        left: expanded ? context.w(12) : null,
                        child: expanded
                            ? Icon(item.icon, size: context.h(20), color: color)
                            : SizedBox(
                                width: squareSide,
                                child: Icon(
                                  item.icon,
                                  size: context.h(20),
                                  color: color,
                                ),
                              ),
                      ),
                      Positioned(
                        left: context.w(44),
                        right: context.w(8),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: expanded ? 1.0 : 0.0,
                          child: Text(
                            item.label,
                            style: AppTextStyles.bodyLargeSemi(context)
                                .copyWith(color: color),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
  final int unreadCount;

  const _FooterTile({
    required this.icon,
    required this.label,
    required this.expanded,
    required this.onTap,
    this.selected = false,
    this.unreadCount = 0,
  });

  static const Duration _d = Duration(milliseconds: 280);
  static const Curve _c = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = selected ? AppColors.primary : colors.textSecondary;
    final bg = selected
        ? AppColors.primary.withValues(alpha: 0.15)
        : Colors.transparent;

    final tileHeight = context.h(42);
    final squareSide = tileHeight;
    final icon = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(this.icon, size: context.h(20), color: color),
        if (unreadCount > 0)
          Positioned(
            top: -context.h(2),
            right: -context.w(3),
            child: Container(
              width: context.h(8),
              height: context.h(8),
              decoration: BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
                border: Border.all(color: colors.surface, width: 1.2),
              ),
            ),
          ),
      ],
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(6)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fullWidth = constraints.maxWidth;
          final targetWidth = expanded ? fullWidth : squareSide;

          return Center(
            child: AnimatedContainer(
              duration: _d,
              curve: _c,
              width: targetWidth,
              height: tileHeight,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(context.h(10)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Positioned(
                        left: expanded ? context.w(12) : null,
                        child: expanded
                            ? icon
                            : SizedBox(
                                width: squareSide,
                                child: Center(child: icon),
                              ),
                      ),
                      Positioned(
                        left: context.w(44),
                        right: context.w(8),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: expanded ? 1.0 : 0.0,
                          child: Text(
                            label,
                            style: AppTextStyles.bodyLargeSemi(context)
                                .copyWith(color: color),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
