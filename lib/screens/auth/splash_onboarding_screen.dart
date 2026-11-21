import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/providers/auth_provider.dart';
import 'package:rdx_admin/screens/auth/login_screen.dart';
import 'package:rdx_admin/screens/main/main_screen.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/reusable_widgets/loading_indicator.dart';

class SplashOnboardingScreen extends ConsumerStatefulWidget {
  const SplashOnboardingScreen({super.key});

  @override
  ConsumerState<SplashOnboardingScreen> createState() =>
      _SplashOnboardingScreenState();
}

class _SplashOnboardingScreenState extends ConsumerState<SplashOnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _navigating = false;

  late final AnimationController _entranceController;
  late final AnimationController _floatController;
  late final AnimationController _glowController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _featuresFade;
  late final Animation<Offset> _featuresSlide;
  late final Animation<double> _ctaFade;
  late final Animation<double> _floatY;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat(reverse: true);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.22, 0.62, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.22, 0.62, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.72, curve: Curves.easeOut),
    );
    _featuresFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.48, 0.88, curve: Curves.easeOut),
    );
    _featuresSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.48, 0.88, curve: Curves.easeOutCubic),
      ),
    );
    _ctaFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );
    _floatY = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _glowPulse = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    if (_navigating) return;
    setState(() => _navigating = true);

    final auth = ref.read(authProvider);

    // Give a tiny moment so the button loading state feels intentional
    await Future.delayed(const Duration(milliseconds: 180));

    if (!mounted) return;

    Widget next;
    if (auth.isResolvingAccess) {
      next = const Scaffold(body: LoadingIndicator());
    } else if (auth.canAccessApp) {
      next = const MainScreen();
    } else {
      next = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 520),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 900;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.network(
            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1920&q=80',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: const Color(0xFF0B0B0B)),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: const Color(0xFF0B0B0B),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
          ),

          // Overlays
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.82),
                  Colors.black.withOpacity(0.62),
                  Colors.black.withOpacity(0.88),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.45),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.55),
                ],
                stops: const [0.0, 0.22, 0.68, 1.0],
              ),
            ),
          ),

          // Ambient glow
          AnimatedBuilder(
            animation: _glowPulse,
            builder: (context, _) {
              return Positioned(
                top: -size.height * 0.18,
                right: -size.width * 0.15,
                child: Container(
                  width: size.width * 0.7,
                  height: size.width * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.09 * _glowPulse.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.w(24),
                    context.h(12),
                    context.w(24),
                    0,
                  ),
                  child: Row(
                    children: [
                      FadeTransition(
                        opacity: _logoFade,
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/images/logo/rdx_logo_picture.svg',
                              width: context.w(22),
                              height: context.h(22),
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                            SizedBox(width: context.w(8)),
                            Text(
                              'RDX',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: context.w(15),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (_currentPage < 2)
                        FadeTransition(
                          opacity: _ctaFade,
                          child: TextButton(
                            onPressed: _navigating ? null : _finishOnboarding,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withOpacity(0.75),
                              padding: EdgeInsets.symmetric(
                                horizontal: context.w(12),
                                vertical: context.h(6),
                              ),
                            ),
                            child: Text(
                              'Skip',
                              style: AppTextStyles.bodySemi(context).copyWith(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: context.w(14),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      _entranceController.forward(from: 0.35);
                    },
                    children: [
                      _buildPageOne(context, isWide),
                      _buildPageTwo(context, isWide),
                      _buildPageThree(context, isWide),
                    ],
                  ),
                ),

                // Bottom
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.w(28),
                    context.h(8),
                    context.w(28),
                    context.h(28),
                  ),
                  child: Column(
                    children: [
                      FadeTransition(
                        opacity: _ctaFade,
                        child: _PageIndicator(count: 3, current: _currentPage),
                      ),
                      SizedBox(height: context.h(28)),
                      FadeTransition(
                        opacity: _ctaFade,
                        child: SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(context.w(24)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.38),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(context.w(24)),
                              child: RdxActionButton(
                                label: _currentPage == 2
                                    ? 'Get Started'
                                    : 'Continue',
                                onPressed: _navigating ? null : _nextPage,
                                isPrimary: true,
                                isLoading: _navigating && _currentPage == 2,
                                height: context.h(52),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Pages (same as previous version) ────────────────────────────────────

  Widget _buildPageOne(BuildContext context, bool isWide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(isWide ? 64 : 28)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_floatY, _glowPulse]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatY.value * 0.6),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(context.w(28)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withOpacity(0.18 * _glowPulse.value),
                        blurRadius: 48 * _glowPulse.value,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: child,
                ),
              );
            },
            child: FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: SlideTransition(
                  position: _logoSlide,
                  child: Container(
                    width: context.w(isWide ? 120 : 100),
                    height: context.w(isWide ? 120 : 100),
                    padding: EdgeInsets.all(context.w(22)),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(context.w(28)),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                    ),
                    child: SvgPicture.asset(
                      'assets/images/logo/rdx_logo_picture.svg',
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: context.h(40)),
          FadeTransition(
            opacity: _titleFade,
            child: SlideTransition(
              position: _titleSlide,
              child: Text(
                'Welcome to\nRDX Admin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.w(isWide ? 46 : 36),
                  fontWeight: FontWeight.w700,
                  height: 1.12,
                  letterSpacing: -1.1,
                ),
              ),
            ),
          ),
          SizedBox(height: context.h(18)),
          FadeTransition(
            opacity: _subtitleFade,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.w(380)),
              child: Text(
                'Your complete command center for orders, menu, inventory, staff and rewards — designed for speed and clarity.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: context.w(15.5),
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTwo(BuildContext context, bool isWide) {
    final features = [
      _FeatureData(Icons.receipt_long_rounded, 'Live Orders',
          'Real-time board for walk-in & app orders with one-tap status updates.'),
      _FeatureData(Icons.restaurant_menu_rounded, 'Menu Control',
          'Manage categories, items, availability and featured dishes instantly.'),
      _FeatureData(Icons.inventory_2_outlined, 'Inventory',
          'Track stock, costs, restock alerts and portion-level accuracy.'),
      _FeatureData(Icons.people_alt_outlined, 'Staff & Access',
          'Role-based permissions so every team member sees only what they need.'),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(isWide ? 56 : 24)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: _titleFade,
            child: SlideTransition(
              position: _titleSlide,
              child: Text(
                'Everything you need\nin one place',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.w(isWide ? 40 : 32),
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  letterSpacing: -0.9,
                ),
              ),
            ),
          ),
          SizedBox(height: context.h(12)),
          FadeTransition(
            opacity: _subtitleFade,
            child: Text(
              'Built for restaurant operators who move fast.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.68),
                fontSize: context.w(15),
              ),
            ),
          ),
          SizedBox(height: context.h(36)),
          FadeTransition(
            opacity: _featuresFade,
            child: SlideTransition(
              position: _featuresSlide,
              child: isWide
                  ? Row(
                      children: [
                        for (int i = 0; i < features.length; i++) ...[
                          Expanded(child: _FeatureCard(data: features[i])),
                          if (i != features.length - 1)
                            SizedBox(width: context.w(14)),
                        ],
                      ],
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < features.length; i++) ...[
                          _FeatureCard(data: features[i]),
                          if (i != features.length - 1)
                            SizedBox(height: context.h(12)),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageThree(BuildContext context, bool isWide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.w(isWide ? 64 : 28)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: _logoFade,
            child: ScaleTransition(
              scale: _logoScale,
              child: Container(
                width: context.w(88),
                height: context.w(88),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.35),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: context.w(42),
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(height: context.h(36)),
          FadeTransition(
            opacity: _titleFade,
            child: SlideTransition(
              position: _titleSlide,
              child: Text(
                'You’re ready',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.w(isWide ? 44 : 34),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.0,
                ),
              ),
            ),
          ),
          SizedBox(height: context.h(16)),
          FadeTransition(
            opacity: _subtitleFade,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.w(360)),
              child: Text(
                'Sign in with the account your restaurant admin created for you and start managing operations with confidence.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: context.w(15.5),
                  height: 1.55,
                ),
              ),
            ),
          ),
          SizedBox(height: context.h(28)),
          FadeTransition(
            opacity: _featuresFade,
            child: Text(
              'Need access? Ask your restaurant admin\nto create a staff account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: context.w(13.5),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ──────────────────────────────────────────────────────

class _FeatureData {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FeatureData(this.icon, this.title, this.subtitle);
}

class _FeatureCard extends StatelessWidget {
  final _FeatureData data;
  const _FeatureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.w(18)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(context.w(18)),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.w(42),
            height: context.w(42),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.18),
              borderRadius: BorderRadius.circular(context.w(12)),
            ),
            child:
                Icon(data.icon, color: AppColors.primary, size: context.w(22)),
          ),
          SizedBox(height: context.h(14)),
          Text(
            data.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: context.w(15.5),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: context.h(6)),
          Text(
            data.subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.62),
              fontSize: context.w(13),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final int current;
  const _PageIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(horizontal: context.w(4)),
          width: isActive ? context.w(22) : context.w(7),
          height: context.h(7),
          decoration: BoxDecoration(
            color:
                isActive ? AppColors.primary : Colors.white.withOpacity(0.28),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}
