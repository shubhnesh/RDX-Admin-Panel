import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/text_styles.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(
    const ProviderScope(
      child: RdxAdminApp(),
    ),
  );
}

class RdxAdminApp extends ConsumerWidget {
  const RdxAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return MaterialApp(
      title: 'RDX Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTextStyles.themeData(context),
      home: auth.isLoggedIn ? const MainScreen() : const LoginScreen(),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
