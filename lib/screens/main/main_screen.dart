import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/main_side_nav.dart';
import '../dashboard/dashboard_screen.dart';
import '../live_orders/live_orders_screen.dart';
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

  static const _screens = <String, Widget>{
    '/dashboard': DashboardScreen(),
    '/live-orders': LiveOrdersScreen(),
    '/menu': MenuScreen(),
    '/coupons': CouponsScreen(),
    '/notifications': NotificationsScreen(),
    '/inventory': InventoryScreen(),
    '/settings': SettingsScreen(),
    '/support': SupportScreen(),
  };

  void _navigate(String route) {
    setState(() => _currentRoute = route);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _toggleSidebar() => setState(() => _sidebarExpanded = !_sidebarExpanded);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isMobile = Responsive.isMobile(context);
    final routes = _screens.keys.toList();
    final currentIndex = routes.indexOf(_currentRoute).clamp(0, routes.length - 1);

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
          backgroundColor: AppColors.darkSidebar,
          width: MainSideNav.expandedWidth,
          child: sideNav,
        ),
        body: Column(
          children: [
            _MobileTopBar(
              title: _titleForRoute(_currentRoute),
              onMenu: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            Expanded(
              child: IndexedStack(
                index: currentIndex,
                children: routes.map<Widget>((r) => _screens[r]!).toList(),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          sideNav,
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: routes.map<Widget>((r) => _screens[r]!).toList(),
            ),
          ),
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
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.menu, color: colors.textPrimary),
            onPressed: onMenu,
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
