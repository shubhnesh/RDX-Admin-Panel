import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/router/app_router.dart';
import 'core/theme/text_styles.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/live_orders_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/coupon_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/settings_provider.dart';
import 'services/dashboard_service.dart';
import 'services/order_service.dart';
import 'services/menu_service.dart';
import 'services/coupon_service.dart';
import 'services/notification_service.dart';
import 'services/inventory_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase isn't wired up to a real project yet (firebase_options.dart is
  // still a placeholder — see the comment there). The Dashboard runs on
  // mock data regardless (see DashboardService.useMockData), so we swallow
  // init failure here rather than block the whole app from launching.
  // Once you run `flutterfire configure`, this will succeed normally and
  // every other screen's live Firestore calls will start working too.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init skipped (not configured yet): $e');
  }
  runApp(const RdxAdminApp());
}

class RdxAdminApp extends StatelessWidget {
  const RdxAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider(DashboardService())),
        ChangeNotifierProvider(create: (_) => LiveOrdersProvider(OrderService())),
        ChangeNotifierProvider(create: (_) => MenuProvider(MenuService())),
        ChangeNotifierProvider(create: (_) => CouponProvider(CouponService())),
        ChangeNotifierProvider(create: (_) => NotificationProvider(NotificationService())),
        ChangeNotifierProvider(create: (_) => InventoryProvider(InventoryService())),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, theme, auth, _) {
          return MaterialApp(
            title: 'RDX Admin',
            debugShowCheckedModeBanner: false,
            theme: AppTextStyles.themeData(isDark: false),
            darkTheme: AppTextStyles.themeData(isDark: true),
            themeMode: theme.themeMode,
            home: auth.isLoggedIn ? const MainScreen() : const LoginScreen(),
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}
