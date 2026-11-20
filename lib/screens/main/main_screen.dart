import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/screens/coupons/coupons_screen.dart';
import 'package:rdx_admin/screens/dashboard/dashboard_screen.dart';
import 'package:rdx_admin/screens/inventory/inventory_screen.dart';
import 'package:rdx_admin/screens/menu/menu_screen.dart';
import 'package:rdx_admin/screens/notifications/notification_screen.dart';
import 'package:rdx_admin/screens/order/live_orders_screen.dart';
import 'package:rdx_admin/screens/rewards/rewards_management_screen.dart';
import 'package:rdx_admin/screens/settings/settings_screen.dart';
import 'package:rdx_admin/screens/settings/user_management_screen.dart';
import 'package:rdx_admin/screens/support/support_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/dialogs/rdx_notice_dialog.dart';
import '../../widgets/notification_toast_overlay.dart';
import 'main_side_nav.dart';
import '../../core/router/app_router.dart';

/// Persistent app shell: collapsible sidebar + IndexedStack content.
/// Nav items and default route depend on [AuthProvider.permissions].
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  String _currentRoute = '/dashboard';
  bool _sidebarExpanded = true;
  final GlobalKey<NavigatorState> _contentNavigatorKey =
      GlobalKey<NavigatorState>();
  final ValueNotifier<String> _currentRouteNotifier =
      ValueNotifier<String>('/dashboard');

  late final Map<String, Widget> _screens;
  bool _didApplyHomeRoute = false;
  bool _activityWatchConfigured = false;
  String? _activityWatchUid;

  void _syncActivityWatch(String? uid) {
    if (_activityWatchConfigured && _activityWatchUid == uid) return;
    final previousUid = _activityWatchUid;
    _activityWatchConfigured = true;
    _activityWatchUid = uid;
    if (uid == null && previousUid == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = ref.read(notificationProvider);
      if (uid == null) {
        provider.stopAdminActivityWatch();
      } else {
        provider.watchAdminActivity(uid);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _screens = {
      '/dashboard': DashboardScreen(onNavigate: _navigate),
      '/live-orders': LiveOrdersScreen(),
      '/menu': const MenuScreen(),
      '/coupons': const CouponsScreen(),
      '/notifications': const NotificationScreen(),
      '/inventory': const InventoryScreen(),
      '/rewards': RewardsManagementScreen(onBack: () => _navigate('/settings')),
      '/user-management':
          UserManagementScreen(onBack: () => _navigate('/settings')),
      '/settings': SettingsScreen(
          onRewards: () => _navigate('/rewards'),
          onUserManagement: () => _navigate('/user-management'),
          onSupport: () => _navigate('/support'),
          onLogout: _logout),
      '/support': SupportScreen(onBack: () => _navigate('/settings')),
    };
  }

  List<SidebarItem> _navItemsForRole() {
    final perms = ref.read(authProvider).permissions;
    final items = <SidebarItem>[];

    if (perms.canViewDashboard) {
      items.add(const SidebarItem(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          route: '/dashboard'));
    }
    if (perms.canViewOrders) {
      items.add(const SidebarItem(
          label: 'Orders',
          icon: Icons.receipt_long_outlined,
          route: '/live-orders'));
    }
    if (perms.canViewMenu) {
      items.add(const SidebarItem(
          label: 'Menu', icon: Icons.restaurant_menu_outlined, route: '/menu'));
    }
    if (perms.canViewCoupons) {
      items.add(const SidebarItem(
          label: 'Coupons',
          icon: Icons.local_offer_outlined,
          route: '/coupons'));
    }
    if (perms.canViewNotifications) {
      items.add(const SidebarItem(
          label: 'Notifications',
          icon: Icons.notifications_outlined,
          route: '/notifications'));
    }
    if (perms.canViewInventory) {
      items.add(const SidebarItem(
          label: 'Inventory',
          icon: Icons.inventory_2_outlined,
          route: '/inventory'));
    }
    if (perms.canViewSettings) {
      items.add(const SidebarItem(
          label: 'Settings',
          icon: Icons.settings_outlined,
          route: '/settings'));
    }
    return items;
  }

  void _ensureHomeRoute() {
    if (_didApplyHomeRoute) return;
    final perms = ref.read(authProvider).permissions;
    final home = perms.homeRoute;
    if (_screens.containsKey(home)) {
      _didApplyHomeRoute = true;
      _currentRoute = home;
      _currentRouteNotifier.value = home;
    }
  }

  void _navigate(String route) {
    final perms = ref.read(authProvider).permissions;
    if (!perms.allowedRoutes.contains(route) &&
        route != '/support' &&
        route != '/rewards' &&
        route != '/user-management') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You do not have access to this section.')));
      return;
    }
    if (route == '/rewards' && !perms.canViewRewards) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rewards are admin-only.')));
      return;
    }
    if (route == '/user-management' && !perms.canManageUsers) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User management is admin-only.')));
      return;
    }

    _contentNavigatorKey.currentState?.popUntil((r) => r.isFirst);
    _currentRouteNotifier.value = route;
    setState(() => _currentRoute = route);
  }

  void _toggleSidebar() => setState(() => _sidebarExpanded = !_sidebarExpanded);

  Future<void> _logout() async {
    final confirmed = await RdxNoticeDialog.showConfirmation(context,
        title: 'Log out?',
        message: 'Are you sure you want to log out?',
        cancelButtonLabel: 'Cancel',
        confirmButtonLabel: 'Log out');
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(authProvider).signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to log out. $e')));
    }
  }

  Widget _content() {
    final routes = _screens.keys.toList();

    return Navigator(
        key: _contentNavigatorKey,
        onGenerateRoute: (settings) {
          if (settings.name == '/') {
            return MaterialPageRoute(
                settings: settings,
                builder: (_) => ValueListenableBuilder<String>(
                    valueListenable: _currentRouteNotifier,
                    builder: (context, currentRoute, child) {
                      return IndexedStack(
                          index: routes
                              .indexOf(currentRoute)
                              .clamp(0, routes.length - 1),
                          children: routes
                              .map<Widget>((route) => _screens[route]!)
                              .toList());
                    }));
          }

          return AppRoutes.generateRoute(settings);
        });
  }

  @override
  void dispose() {
    _currentRouteNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final colors = AppColors.of(context);
    final useBottomNav = Responsive.useBottomNav(context);
    final navItems = _navItemsForRole();
    var notificationUnreadCount = 0;
    final notificationUid =
        auth.permissions.canViewNotifications ? auth.user?.uid : null;
    if (notificationUid != null) {
      final notifications = ref.watch(notificationProvider);
      _syncActivityWatch(notificationUid);
      notificationUnreadCount =
          notifications.unreadActivityCountFor(notificationUid);
    } else {
      _syncActivityWatch(null);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureHomeRoute();
    });

    if (useBottomNav) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Scaffold(
            backgroundColor: colors.background,
            body: SafeArea(bottom: false, child: _content()),
            bottomNavigationBar: _MainBottomNav(
              currentIndex: _bottomNavIndex(navItems),
              items: navItems,
              notificationUnreadCount: notificationUnreadCount,
              onTap: (index) => _navigate(navItems[index].route),
            ),
          ),
          if (notificationUid != null)
            NotificationToastOverlay(
              bottomInset: Responsive.bottomNavHeight(context) + context.h(16),
            ),
        ],
      );
    }

    final sideNav = MainSideNav(
        items: navItems
            .where((item) =>
                item.route != '/settings' && item.route != '/notifications')
            .toList(),
        currentRoute: _currentRoute,
        onNavigate: _navigate,
        expanded: _sidebarExpanded,
        onToggleExpand: _toggleSidebar,
        onAddOrder: auth.permissions.canCreateOrders ? () {} : null,
        showNotifications: auth.permissions.canViewNotifications,
        notificationUnreadCount: notificationUnreadCount);

    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
          backgroundColor: colors.background,
          body: Row(children: [
            sideNav,
            Expanded(child: _content()),
          ]),
        ),
        if (notificationUid != null)
          NotificationToastOverlay(bottomInset: context.h(24)),
      ],
    );
  }

  int _bottomNavIndex(List<SidebarItem> items) {
    if (_currentRoute == '/support' ||
        _currentRoute == '/rewards' ||
        _currentRoute == '/user-management') {
      final settingsIdx = items.indexWhere((item) => item.route == '/settings');
      return settingsIdx >= 0 ? settingsIdx : 0;
    }
    final index = items.indexWhere((item) => item.route == _currentRoute);
    return index >= 0 ? index : 0;
  }
}

class _MainBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<SidebarItem> items;
  final ValueChanged<int> onTap;
  final int notificationUnreadCount;

  const _MainBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    required this.notificationUnreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final barHeight = Responsive.bottomNavHeight(context);

    return Material(
        elevation: 8,
        color: colors.surface,
        child: Container(
            decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.border))),
            child: SafeArea(
                top: false,
                child: SizedBox(
                    height: barHeight,
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < items.length; i++)
                            Expanded(
                                child: _MainBottomNavTile(
                                    item: items[i],
                                    selected: i == currentIndex,
                                    showNotificationBadge:
                                        items[i].route == '/notifications' &&
                                            notificationUnreadCount > 0,
                                    onTap: () => onTap(i))),
                        ])))));
  }
}

class _MainBottomNavTile extends StatelessWidget {
  final SidebarItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool showNotificationBadge;

  const _MainBottomNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.showNotificationBadge,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = selected ? AppColors.primary : colors.textMuted;

    return InkWell(
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(selected ? _selectedIcon(item.icon) : item.icon,
                  size: context.h(20).clamp(18.0, 23.0), color: color),
              if (showNotificationBadge)
                Positioned(
                  top: -context.h(2),
                  right: -context.w(4),
                  child: Container(
                    width: context.h(8),
                    height: context.h(8),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: context.h(3)),
          Text(item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: context.sp(11).clamp(9.0, 12.5),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                  height: 1.1)),
        ]));
  }

  static IconData _selectedIcon(IconData icon) {
    if (icon == Icons.dashboard_outlined) return Icons.dashboard;
    if (icon == Icons.receipt_long_outlined) return Icons.receipt_long;
    if (icon == Icons.restaurant_menu_outlined) return Icons.restaurant_menu;
    if (icon == Icons.local_offer_outlined) return Icons.local_offer;
    if (icon == Icons.inventory_2_outlined) return Icons.inventory_2;
    if (icon == Icons.stars_outlined) return Icons.stars;
    if (icon == Icons.settings_outlined) return Icons.settings;
    return icon;
  }
}
