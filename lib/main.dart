import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';
import 'widgets/reusable_widgets/loading_indicator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hasDefaultApp = Firebase.apps.any((app) => app.name == '[DEFAULT]');
  if (!hasDefaultApp) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(
    const ProviderScope(
      child: RdxAdminApp(),
    ),
  );
}

/// App-wide light theme built from the [AppColors] tokens.
/// [AppColorScheme.light] is registered as a theme extension so that
/// `AppColors.of(context)` resolves to it everywhere.
ThemeData _buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
      outline: AppColors.border,
    ),
    dividerColor: AppColors.divider,
    extensions: const <ThemeExtension<dynamic>>[AppColorScheme.light],
  );

  return base.copyWith(
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
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
      theme: _buildTheme(),
      home: !auth.isLoggedIn
          ? const LoginScreen()
          : auth.isLoading
              ? const LoginScreen()
              : auth.isResolvingAccess
                  ? const Scaffold(body: LoadingIndicator())
                  : auth.canAccessApp
                      ? const MainScreen()
                      : const LoginScreen(),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}