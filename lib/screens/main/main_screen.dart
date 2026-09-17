import 'package:flutter/material.dart';
import 'package:rdx_admin/screens/order/live_orders_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../widgets/reusable_widgets/main_side_nav.dart';
import '../../core/router/app_router.dart';
import '../dashboard/dashboard_screen.dart';
import '../menu/menu_screen.dart';
import '../coupons/coupons_screen.dart';
import '../notifications/notifications_screen.dart';
import '../inventory/inventory_screen.dart';
import '../settings/settings_screen.dart';
import '../support/support_screen.dart';

/// Persistent app shell: collapsible sidebar + IndexedStack content.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _currentRoute = '/dashboard';
  bool _sidebarExpanded = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<NavigatorState> _contentNavigatorKey =
      GlobalKey<NavigatorState>();
  final ValueNotifier<String> _currentRouteNotifier =
      ValueNotifier<String>('/dashboard');

  late final Map<String, Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = {
      '/dashboard': DashboardScreen(onNavigate: _navigate),
      '/live-orders': LiveOrdersScreen(),
      '/menu': const MenuScreen(),
      '/coupons': const CouponsScreen(),
      '/notifications': const NotificationsScreen(),
      '/inventory': const InventoryScreen(),
      '/settings': const SettingsScreen(),
      '/support': const SupportScreen(),
    };
  }

  void _navigate(String route) {
    _contentNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    _currentRouteNotifier.value = route;
    setState(() => _currentRoute = route);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _toggleSidebar() => setState(() => _sidebarExpanded = !_sidebarExpanded);

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
                  index:
                      routes.indexOf(currentRoute).clamp(0, routes.length - 1),
                  children:
                      routes.map<Widget>((route) => _screens[route]!).toList(),
                );
              },
            ),
          );
        }

        return AppRoutes.generateRoute(settings);
      },
    );
  }

  @override
  void dispose() {
    _currentRouteNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isMobile = Responsive.isMobile(context);

    final sideNav = MainSideNav(
      currentRoute: _currentRoute,
      onNavigate: _navigate,
      expanded: isMobile ? true : _sidebarExpanded,
      onToggleExpand: _toggleSidebar,
      onLogout: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out')),
        );
      },
      onAddOrder: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add Order coming soon')),
        );
      },
    );

    if (isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: colors.background,
        drawer: Drawer(
          backgroundColor: AppColors.lightSidebar,
          // Scale drawer width with screen; keep a sensible min/max.
          width: context.w(MainSideNav.expandedWidth).clamp(260.0, 320.0),
          child: sideNav,
        ),
        body: Column(
          children: [
            _MobileTopBar(
              title: _titleForRoute(_currentRoute),
              onMenu: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            Expanded(child: _content()),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          sideNav,
          Expanded(child: _content()),
        ],
      ),
    );
  }

  String _titleForRoute(String route) {
    switch (route) {
      case '/dashboard':
        return 'Dashboard';
      case '/live-orders':
        return 'Live Orders';
      case '/menu':
        return 'Menu';
      case '/coupons':
        return 'Coupons';
      case '/notifications':
        return 'Notifications';
      case '/inventory':
        return 'Inventory';
      case '/settings':
        return 'Settings';
      case '/support':
        return 'Support';
      default:
        return 'RDX Admin';
    }
  }
}

class _MobileTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onMenu;

  const _MobileTopBar({required this.title, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      height: context.h(56),
      padding: EdgeInsets.symmetric(horizontal: context.w(8)),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.menu,
              color: colors.textPrimary,
              size: context.h(24),
            ),
            onPressed: onMenu,
            padding: EdgeInsets.all(context.w(8)),
            constraints: BoxConstraints(
              minWidth: context.w(40),
              minHeight: context.h(40),
            ),
          ),
          SizedBox(width: context.w(4)),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
