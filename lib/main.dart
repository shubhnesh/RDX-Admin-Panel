import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/text_styles.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase isn't wired up to a real project yet (firebase_options.dart is
  // still a placeholder). The Dashboard runs on mock data regardless, so we
  // swallow init failure here rather than block the whole app from launching.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init skipped (not configured yet): $e');
  }
  runApp(const ProviderScope(child: RdxAdminApp()));
}

class RdxAdminApp extends ConsumerWidget {
  const RdxAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // authProvider must expose an `isLoggedIn` bool on its state — see
    // providers/auth_provider.dart. All the other former ChangeNotifier
    // providers (Dashboard/Coupon/Notification/Inventory/Settings) no
    // longer need app-wide registration: with Riverpod each screen reads
    // its own provider directly via ref.watch(...) instead of pulling it
    // from a MultiProvider tree.
    final isLoggedIn = ref.watch(authProvider).isLoggedIn;

    return MaterialApp(
      title: 'RDX Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTextStyles.themeData(context),
      home: isLoggedIn ? const MainScreen() : const LoginScreen(),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
