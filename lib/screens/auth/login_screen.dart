// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:rdx_admin/core/theme/text_styles.dart';
// import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
// import 'package:rdx_admin/widgets/resuable_options/rdx_text_field.dart';
// import '../../providers/auth_provider.dart';
// import '../../core/theme/app_colors.dart';

// class LoginScreen extends ConsumerStatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   ConsumerState<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends ConsumerState<LoginScreen> {
//   final _emailCtrl = TextEditingController();
//   final _passCtrl = TextEditingController();
//   bool _obscure = true;
//   bool _isRegister = false;

//   @override
//   void dispose() {
//     _emailCtrl.dispose();
//     _passCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _submit() async {
//     final auth = ref.read(authProvider);
//     final ok = _isRegister
//         ? await auth.register(_emailCtrl.text, _passCtrl.text)
//         : await auth.signIn(_emailCtrl.text, _passCtrl.text);
//     if (!ok && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(auth.errorMessage ?? 'Error')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final auth = ref.watch(authProvider);
//     return Scaffold(
//       body: Center(
//         child: ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 400),
//           child: Card(
//             margin: const EdgeInsets.all(24),
//             child: Padding(
//               padding: const EdgeInsets.all(32),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     'RDX Admin',
//                     // style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                     //       fontWeight: FontWeight.bold,
//                     //       color: AppColors.primary,
//                     //     ),
//                     style: AppTextStyles.heading(context)
//                         .copyWith(color: AppColors.primary),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     _isRegister
//                         ? 'Create admin account'
//                         : 'Sign in to continue',
//                     // style: Theme.of(context).textTheme.bodyMedium,
//                     style: AppTextStyles.bodySecondary(context),
//                   ),
//                   const SizedBox(height: 32),
//                   // TextField(
//                   //   controller: _emailCtrl,
//                   //   keyboardType: TextInputType.emailAddress,
//                   //   decoration: const InputDecoration(
//                   //     labelText: 'Email',
//                   //     border: OutlineInputBorder(),
//                   //     prefixIcon: Icon(Icons.email_outlined),
//                   //   ),
//                   // ),
//                   RdxTextField(
//                     controller: _emailCtrl,
//                     maxLength: 25,
//                     keyboardType: TextInputType.emailAddress,
//                     hint: 'Email',
//                     prefixIcon: const Icon(Icons.email_outlined),
//                   ),
//                   const SizedBox(height: 16),
//                   // TextField(
//                   //   controller: _passCtrl,
//                   //   obscureText: _obscure,
//                   //   decoration: InputDecoration(
//                   //     labelText: 'Password',
//                   //     border: const OutlineInputBorder(),
//                   //     prefixIcon: const Icon(Icons.lock_outline),
//                   //     suffixIcon: IconButton(
//                   //       icon: Icon(
//                   //           _obscure ? Icons.visibility : Icons.visibility_off),
//                   //       onPressed: () => setState(() => _obscure = !_obscure),
//                   //     ),
//                   //   ),
//                   // ),
//                   RdxTextField(
//                     controller: _passCtrl,
//                     maxLength: 8,
//                     obscureText: _obscure,
//                     hint: 'Password',
//                     prefixIcon: const Icon(Icons.lock_outline),
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                           _obscure ? Icons.visibility : Icons.visibility_off),
//                       onPressed: () => setState(() => _obscure = !_obscure),
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//                   SizedBox(
//                     width: double.infinity,
//                     height: 48,
//                     child: RdxActionButton(
//                       label: _isRegister ? 'Create Account' : 'Sign In',
//                       onPressed: auth.isLoading ? null : _submit,
//                       isPrimary: true,
//                       isLoading: auth.isLoading,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   TextButton(
//                     onPressed: () => setState(() => _isRegister = !_isRegister),
//                     child: Text(
//                       _isRegister
//                           ? 'Already have an account? Sign in'
//                           : 'First time? Create admin account',
//                       style: AppTextStyles.label(context),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/resuable_options/rdx_text_field.dart';

import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _loaderController;

  bool _obscurePassword = true;
  bool _isRegister = false;

  @override
  void initState() {
    super.initState();

    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final auth = ref.read(authProvider);

    _loaderController.repeat();

    final success = _isRegister
        ? await auth.register(
            _emailController.text.trim(),
            _passwordController.text,
          )
        : await auth.signIn(
            _emailController.text.trim(),
            _passwordController.text,
          );

    _loaderController.stop();
    _loaderController.reset();

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ?? 'Unable to continue.',
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          elevation: 0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Stack(
        children: [
          const _LoginBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 35,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 480,
                  ),
                  child: _buildLoginContainer(
                    context,
                    auth,
                  ),
                ),
              ),
            ),
          ),
          if (auth.isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN LOGIN CONTAINER
  // ---------------------------------------------------------------------------

  Widget _buildLoginContainer(
    BuildContext context,
    AuthProvider auth,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 60,
            offset: const Offset(0, 25),
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.045),
            blurRadius: 80,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          42,
          38,
          42,
          30,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBrand(),
            const SizedBox(height: 38),
            Text(
              _isRegister ? 'Create your account' : 'Welcome back',
              style: AppTextStyles.heading(context).copyWith(
                color: const Color(0xFF182033),
                fontSize: 30,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isRegister
                  ? 'Enter your details to continue.'
                  : 'Sign in to continue.',
              style: AppTextStyles.bodySecondary(context).copyWith(
                color: const Color(0xFF7B8494),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 34),
            _buildLabel(
              context,
              'Email',
            ),
            const SizedBox(height: 8),
            RdxTextField(
              controller: _emailController,
              maxLength: 50,
              keyboardType: TextInputType.emailAddress,
              hint: 'Enter your email',
              prefixIcon: const Icon(
                Icons.mail_outline_rounded,
                size: 20,
              ),
            ),
            const SizedBox(height: 21),
            _buildLabel(
              context,
              'Password',
            ),
            const SizedBox(height: 8),
            RdxTextField(
              controller: _passwordController,
              maxLength: 50,
              obscureText: _obscurePassword,
              hint: 'Enter your password',
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                size: 20,
              ),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (!_isRegister)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: auth.isLoading ? null : _showForgotPassword,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 5,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot password?',
                    style: AppTextStyles.label(context).copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 22),
            _buildSignInButton(
              context,
              auth,
            ),
            const SizedBox(height: 27),
            _buildDivider(context),
            const SizedBox(height: 21),
            Center(
              child: TextButton(
                onPressed: auth.isLoading
                    ? null
                    : () {
                        setState(() {
                          _isRegister = !_isRegister;
                        });
                      },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.label(context).copyWith(
                      color: const Color(0xFF7B8494),
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: _isRegister
                            ? 'Already have an account? '
                            : 'Don\'t have an account? ',
                      ),
                      TextSpan(
                        text: _isRegister ? 'Sign in' : 'Create one',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BRAND
  // ---------------------------------------------------------------------------

  Widget _buildBrand() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 47,
          height: 47,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.78),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(
            Icons.restaurant_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
        const SizedBox(width: 13),
        Text(
          'RDX',
          style: const TextStyle(
            color: Color(0xFF182033),
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BUTTON
  // ---------------------------------------------------------------------------

  Widget _buildSignInButton(
    BuildContext context,
    AuthProvider auth,
  ) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: RdxActionButton(
          label: _isRegister ? 'Create Account' : 'Sign In',
          onPressed: auth.isLoading ? null : _submit,
          isPrimary: true,
          isLoading: false,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DIVIDER
  // ---------------------------------------------------------------------------

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE8EBF0),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          child: Text(
            'OR',
            style: AppTextStyles.caption(context).copyWith(
              color: const Color(0xFFA1A8B4),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE8EBF0),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(
    BuildContext context,
    String text,
  ) {
    return Text(
      text,
      style: AppTextStyles.label(context).copyWith(
        color: const Color(0xFF30394A),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LOADING
  // ---------------------------------------------------------------------------

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.white.withOpacity(0.62),
        child: Center(
          child: AnimatedBuilder(
            animation: _loaderController,
            builder: (context, child) {
              return _RdxLoginLoader(
                progress: _loaderController.value,
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FORGOT PASSWORD
  // ---------------------------------------------------------------------------

  Future<void> _showForgotPassword() async {
    final emailController = TextEditingController(
      text: _emailController.text,
    );

    bool sending = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              elevation: 0,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reset password',
                        style: AppTextStyles.heading(context).copyWith(
                          color: const Color(0xFF182033),
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Enter your email address.',
                        style: AppTextStyles.bodySecondary(context).copyWith(
                          color: const Color(0xFF7B8494),
                        ),
                      ),
                      const SizedBox(height: 22),
                      RdxTextField(
                        controller: emailController,
                        maxLength: 50,
                        keyboardType: TextInputType.emailAddress,
                        hint: 'Enter your email',
                        prefixIcon: const Icon(
                          Icons.mail_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: RdxActionButton(
                          label: 'Send reset link',
                          onPressed: sending
                              ? null
                              : () async {
                                  if (emailController.text.trim().isEmpty) {
                                    return;
                                  }

                                  setDialogState(() {
                                    sending = true;
                                  });

                                  final success = await ref
                                      .read(authProvider)
                                      .sendPasswordReset(
                                        emailController.text.trim(),
                                      );

                                  if (!dialogContext.mounted) {
                                    return;
                                  }

                                  if (success) {
                                    Navigator.of(
                                      dialogContext,
                                    ).pop();

                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Password reset link sent.',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } else {
                                    setDialogState(() {
                                      sending = false;
                                    });

                                    ScaffoldMessenger.of(
                                      dialogContext,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ref
                                                  .read(
                                                    authProvider,
                                                  )
                                                  .errorMessage ??
                                              'Unable to send reset link.',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                          isPrimary: true,
                          isLoading: sending,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    emailController.dispose();
  }
}

// =============================================================================
// BACKGROUND
// =============================================================================

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPainter(),
            ),
          ),
          Positioned(
            top: -170,
            right: -120,
            child: _glow(
              430,
              AppColors.primary.withOpacity(0.075),
            ),
          ),
          Positioned(
            bottom: -220,
            left: -160,
            child: _glow(
              500,
              AppColors.primary.withOpacity(0.035),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(
    double size,
    Color color,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0),
          ],
        ),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = const Color(0xFF172033).withOpacity(0.018)
      ..strokeWidth = 1;

    const gap = 32.0;

    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// =============================================================================
// PREMIUM LOGIN LOADER
// =============================================================================

class _RdxLoginLoader extends StatelessWidget {
  final double progress;

  const _RdxLoginLoader({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final rotation = progress * math.pi * 2;

    return SizedBox(
      width: 125,
      height: 125,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft ambient glow
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(
                    0.13 +
                        math.sin(
                              progress * math.pi * 2,
                            ) *
                            0.04,
                  ),
                  blurRadius: 35,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),

          // Rotating ring
          Transform.rotate(
            angle: rotation,
            child: CustomPaint(
              size: const Size(104, 104),
              painter: _LoaderRingPainter(
                color: AppColors.primary,
              ),
            ),
          ),

          // Second subtle ring
          Transform.rotate(
            angle: -rotation * 0.65,
            child: CustomPaint(
              size: const Size(86, 86),
              painter: _LoaderSecondRingPainter(
                color: AppColors.primary,
              ),
            ),
          ),

          // Center
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.10),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Center(
              child: Transform.scale(
                scale: 0.94 +
                    math.sin(
                          progress * math.pi * 2,
                        ) *
                        0.06,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.78),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.restaurant_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          // Moving dot
          Transform.rotate(
            angle: rotation,
            child: Transform.translate(
              offset: const Offset(0, -52),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoaderRingPainter extends CustomPainter {
  final Color color;

  _LoaderRingPainter({
    required this.color,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2 - 7;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          color.withOpacity(0.03),
          color.withOpacity(0.12),
          color.withOpacity(0.45),
          color,
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
      );

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      -math.pi / 2,
      math.pi * 1.55,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _LoaderRingPainter oldDelegate,
  ) {
    return oldDelegate.color != color;
  }
}

class _LoaderSecondRingPainter extends CustomPainter {
  final Color color;

  _LoaderSecondRingPainter({
    required this.color,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withOpacity(0.08);

    canvas.drawCircle(
      center,
      size.width / 2 - 5,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _LoaderSecondRingPainter oldDelegate,
  ) {
    return oldDelegate.color != color;
  }
}
