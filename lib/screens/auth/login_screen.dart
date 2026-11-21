// // import 'package:flutter/material.dart';
// // import 'package:flutter/foundation.dart';
// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'package:flutter_svg/flutter_svg.dart';
// // import 'package:rdx_admin/core/theme/app_colors.dart';
// // import 'package:rdx_admin/core/theme/text_styles.dart';
// // import 'package:rdx_admin/core/utils/responsive_size.dart';
// // import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
// // import 'package:rdx_admin/widgets/dialogs/category_dialog.dart';
// // import 'package:rdx_admin/widgets/reusable_widgets/rdx_text_field.dart';

// // import '../../providers/auth_provider.dart';

// // class LoginScreen extends ConsumerStatefulWidget {
// //   const LoginScreen({super.key});

// //   @override
// //   ConsumerState<LoginScreen> createState() => _LoginScreenState();
// // }

// // class _LoginScreenState extends ConsumerState<LoginScreen> {
// //   final _emailController = TextEditingController();
// //   final _passwordController = TextEditingController();

// //   bool _obscurePassword = true;

// //   void _log(String message) {
// //     if (kDebugMode) debugPrint('[LoginScreen] $message');
// //   }

// //   @override
// //   void initState() {
// //     super.initState();
// //   }

// //   @override
// //   void dispose() {
// //     _emailController.dispose();
// //     _passwordController.dispose();
// //     super.dispose();
// //   }

// //   Future<void> _submit() async {
// //     _log('Step 1: login form submitted.');
// //     FocusScope.of(context).unfocus();

// //     final auth = ref.read(authProvider);

// //     // Accounts are provisioned by an admin; sign-in also verifies the role claim.
// //     _log('Step 2: forwarding sign-in to AuthProvider.');
// //     final success = await auth.signIn(
// //       _emailController.text.trim(),
// //       _passwordController.text,
// //     );
// //     _log('Step 3: sign-in flow returned success=$success.');

// //     if (!success && mounted) {
// //       _log('Step 4: displaying login failure message.');
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text(
// //             auth.errorMessage ?? 'Unable to continue.',
// //           ),
// //           behavior: SnackBarBehavior.floating,
// //           margin: EdgeInsets.all(context.w(20)),
// //           elevation: 0,
// //         ),
// //       );
// //     } else if (success) {
// //       _log('Step 4: login accepted; app navigation is handled by auth state.');
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final auth = ref.watch(authProvider);

// //     return Scaffold(
// //       backgroundColor: AppColors.background,
// //       body: Stack(
// //         children: [
// //           const _PageBackground(),
// //           SafeArea(
// //             child: Center(
// //               child: SingleChildScrollView(
// //                 padding: EdgeInsets.symmetric(
// //                   horizontal: context.w(28),
// //                   vertical: context.h(28),
// //                 ),
// //                 child: LayoutBuilder(
// //                   builder: (context, constraints) {
// //                     final isDesktop = constraints.maxWidth >= 900;

// //                     return ConstrainedBox(
// //                       constraints: BoxConstraints(
// //                         maxWidth: context.w(960),
// //                       ),
// //                       child: isDesktop
// //                           ? _buildDesktopLayout(context, auth)
// //                           : _buildMobileLayout(context, auth),
// //                     );
// //                   },
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // ===========================================================================
// //   // DESKTOP
// //   // ===========================================================================

// //   Widget _buildDesktopLayout(
// //     BuildContext context,
// //     AuthProvider auth,
// //   ) {
// //     return Container(
// //       clipBehavior: Clip.antiAlias,
// //       decoration: BoxDecoration(
// //         color: AppColors.surface,
// //         borderRadius: BorderRadius.circular(context.w(28)),
// //         boxShadow: [
// //           BoxShadow(
// //             color: AppColors.black.withOpacity(0.07),
// //             blurRadius: context.w(60),
// //             offset: Offset(0, context.h(24)),
// //           ),
// //           BoxShadow(
// //             color: AppColors.primary.withOpacity(0.035),
// //             blurRadius: context.w(90),
// //             spreadRadius: -context.w(10),
// //           ),
// //         ],
// //       ),
// //       child: IntrinsicHeight(
// //         child: Row(
// //           crossAxisAlignment: CrossAxisAlignment.stretch,
// //           children: [
// //             Expanded(
// //               flex: 45,
// //               child: _buildBrandPanel(context),
// //             ),
// //             Expanded(
// //               flex: 55,
// //               child: _buildLoginPanel(context, auth),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   // ===========================================================================
// //   // MOBILE
// //   // ===========================================================================

// //   Widget _buildMobileLayout(
// //     BuildContext context,
// //     AuthProvider auth,
// //   ) {
// //     return Container(
// //       constraints: BoxConstraints(
// //         maxWidth: context.w(520),
// //       ),
// //       padding: EdgeInsets.fromLTRB(
// //         context.w(30),
// //         context.h(30),
// //         context.w(30),
// //         context.h(26),
// //       ),
// //       decoration: BoxDecoration(
// //         color: AppColors.surface.withOpacity(0.97),
// //         borderRadius: BorderRadius.circular(context.w(26)),
// //         boxShadow: [
// //           BoxShadow(
// //             color: AppColors.black.withOpacity(0.06),
// //             blurRadius: context.w(45),
// //             offset: Offset(0, context.h(20)),
// //           ),
// //         ],
// //       ),
// //       child: _buildLoginContent(context, auth),
// //     );
// //   }

// //   // ===========================================================================
// //   // LEFT BRAND PANEL
// //   // ===========================================================================

// //   Widget _buildBrandPanel(BuildContext context) {
// //     return Container(
// //       constraints: BoxConstraints(
// //         minHeight: context.h(690),
// //       ),
// //       padding: EdgeInsets.fromLTRB(
// //         context.w(52),
// //         context.h(50),
// //         context.w(45),
// //         context.h(35),
// //       ),
// //       decoration: const BoxDecoration(
// //         color: AppColors.darkSurface,
// //       ),
// //       child: Stack(
// //         children: [
// //           Positioned(
// //             top: -context.w(150),
// //             right: -context.w(140),
// //             child: _darkGlow(
// //               context,
// //               context.w(390),
// //             ),
// //           ),
// //           Positioned(
// //             bottom: -context.w(170),
// //             left: -context.w(170),
// //             child: _darkGlow(
// //               context,
// //               context.w(430),
// //             ),
// //           ),
// //           Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               _buildDarkBrand(context),
// //               SizedBox(height: context.h(65)),
// //               Container(
// //                 width: context.w(38),
// //                 height: context.h(3),
// //                 decoration: BoxDecoration(
// //                   color: AppColors.primary,
// //                   borderRadius: BorderRadius.circular(20),
// //                 ),
// //               ),
// //               SizedBox(height: context.h(22)),
// //               RichText(
// //                 text: TextSpan(
// //                   style: AppTextStyles.h1(context).copyWith(height: 1.08,
// //                     letterSpacing: -1),
// //                   children: const [
// //                     TextSpan(
// //                       text: 'Admin ',
// //                       style: TextStyle(
// //                         color: AppColors.white,
// //                       ),
// //                     ),
// //                     TextSpan(
// //                       text: 'Panel',
// //                       style: TextStyle(
// //                         color: AppColors.primary,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //               SizedBox(height: context.h(16)),
// //               Text(
// //                 'Manage your restaurant,\n'
// //                 'orders, customers and more —\n'
// //                 'all in one place.',
// //                 style: AppTextStyles.bodyLarge(context).copyWith(color: AppColors.white.withOpacity(0.58),
// //                   height: 1.55,
// //                 ),
// //               ),
// //               const Spacer(),
// //               _buildDashboardPreview(context),
// //               SizedBox(height: context.h(20)),
// //               Text(
// //                 'RDX ADMIN • RESTAURANT MANAGEMENT',
// //                 style: AppTextStyles.overline(context).copyWith(color: AppColors.white.withOpacity(0.25),
// //                   letterSpacing: 1.2,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildDarkBrand(BuildContext context) {
// //     return Row(
// //       mainAxisSize: MainAxisSize.min,
// //       children: [
// //         SvgPicture.asset(
// //           'assets/images/logo/rdx_logo_picture.svg',
// //           width: context.w(48),
// //           height: context.h(48),
// //           fit: BoxFit.contain,
// //           colorFilter: const ColorFilter.mode(
// //             AppColors.white,
// //             BlendMode.srcIn,
// //           ),
// //         ),
// //         SizedBox(width: context.w(13)),
// //         Text(
// //           'RDX',
// //           style: AppTextStyles.h2(context).copyWith(color: AppColors.white,
// //             letterSpacing: 1.5),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _darkGlow(
// //     BuildContext context,
// //     double size,
// //   ) {
// //     return Container(
// //       width: size,
// //       height: size,
// //       decoration: BoxDecoration(
// //         shape: BoxShape.circle,
// //         gradient: RadialGradient(
// //           colors: [
// //             AppColors.primary.withOpacity(0.08),
// //             Colors.transparent,
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   // ===========================================================================
// //   // DASHBOARD PREVIEW
// //   // ===========================================================================

// //   Widget _buildDashboardPreview(BuildContext context) {
// //     return Transform.rotate(
// //       angle: -0.035,
// //       child: Container(
// //         height: context.h(245),
// //         width: double.infinity,
// //         padding: EdgeInsets.all(context.w(13)),
// //         decoration: BoxDecoration(
// //           color: AppColors.darkSurfaceRaised,
// //           borderRadius: BorderRadius.circular(context.w(17)),
// //           border: Border.all(
// //             color: AppColors.white.withOpacity(0.07),
// //           ),
// //           boxShadow: [
// //             BoxShadow(
// //               color: AppColors.black.withOpacity(0.28),
// //               blurRadius: context.w(30),
// //               offset: Offset(0, context.h(15)),
// //             ),
// //           ],
// //         ),
// //         child: Row(
// //           children: [
// //             Container(
// //               width: context.w(43),
// //               padding: EdgeInsets.symmetric(
// //                 vertical: context.h(8),
// //               ),
// //               decoration: BoxDecoration(
// //                 color: AppColors.darkSurface,
// //                 borderRadius: BorderRadius.circular(context.w(10)),
// //               ),
// //               child: Column(
// //                 children: [
// //                   _dashboardSideIcon(
// //                     context,
// //                     Icons.home_rounded,
// //                     true,
// //                   ),
// //                   _dashboardSideIcon(
// //                     context,
// //                     Icons.receipt_long_rounded,
// //                     false,
// //                   ),
// //                   _dashboardSideIcon(
// //                     context,
// //                     Icons.restaurant_menu_rounded,
// //                     false,
// //                   ),
// //                   _dashboardSideIcon(
// //                     context,
// //                     Icons.people_alt_outlined,
// //                     false,
// //                   ),
// //                   const Spacer(),
// //                   _dashboardSideIcon(
// //                     context,
// //                     Icons.settings_outlined,
// //                     false,
// //                     isLast: true,
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             SizedBox(width: context.w(12)),
// //             Expanded(
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Row(
// //                     children: [
// //                       _smallDashText(
// //                         context,
// //                         'Overview',
// //                         14,
// //                         true,
// //                       ),
// //                       const Spacer(),
// //                       Container(
// //                         width: context.w(32),
// //                         height: context.h(8),
// //                         decoration: BoxDecoration(
// //                           color: AppColors.white.withOpacity(0.07),
// //                           borderRadius: BorderRadius.circular(20),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                   SizedBox(height: context.h(14)),
// //                   Row(
// //                     children: [
// //                       Expanded(
// //                         child: _statCard(
// //                           context,
// //                           'Orders',
// //                           '248',
// //                           Icons.shopping_bag_outlined,
// //                         ),
// //                       ),
// //                       SizedBox(width: context.w(8)),
// //                       Expanded(
// //                         child: _statCard(
// //                           context,
// //                           'Revenue',
// //                           '₹42.8K',
// //                           Icons.trending_up_rounded,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                   SizedBox(height: context.h(10)),
// //                   Expanded(
// //                     child: Container(
// //                       padding: EdgeInsets.all(context.w(12)),
// //                       decoration: BoxDecoration(
// //                         color: AppColors.darkSurfaceElevated,
// //                         borderRadius: BorderRadius.circular(context.w(10)),
// //                       ),
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           _smallDashText(
// //                             context,
// //                             'Weekly sales',
// //                             9,
// //                             false,
// //                           ),
// //                           SizedBox(height: context.h(8)),
// //                           Expanded(
// //                             child: LayoutBuilder(
// //                               builder: (context, constraints) {
// //                                 return CustomPaint(
// //                                   size: Size(constraints.maxWidth,
// //                                       constraints.maxHeight),
// //                                   painter: _DashboardChartPainter(
// //                                     color: AppColors.primary,
// //                                   ),
// //                                 );
// //                               },
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _dashboardSideIcon(
// //     BuildContext context,
// //     IconData icon,
// //     bool active, {
// //     bool isLast = false,
// //   }) {
// //     return Container(
// //       margin: EdgeInsets.only(
// //         bottom: isLast ? 0 : context.h(6),
// //       ),
// //       width: context.w(29),
// //       height: context.h(29),
// //       decoration: BoxDecoration(
// //         color:
// //             active ? AppColors.primary.withOpacity(0.14) : Colors.transparent,
// //         borderRadius: BorderRadius.circular(context.w(8)),
// //       ),
// //       child: Icon(
// //         icon,
// //         size: context.w(15),
// //         color: active ? AppColors.primary : AppColors.white.withOpacity(0.3),
// //       ),
// //     );
// //   }

// //   Widget _statCard(
// //     BuildContext context,
// //     String title,
// //     String value,
// //     IconData icon,
// //   ) {
// //     return Container(
// //       padding: EdgeInsets.all(context.w(10)),
// //       decoration: BoxDecoration(
// //         color: AppColors.darkSurfaceElevated,
// //         borderRadius: BorderRadius.circular(context.w(10)),
// //       ),
// //       child: Row(
// //         children: [
// //           Container(
// //             width: context.w(27),
// //             height: context.h(27),
// //             decoration: BoxDecoration(
// //               color: AppColors.primary.withOpacity(0.11),
// //               borderRadius: BorderRadius.circular(context.w(7)),
// //             ),
// //             child: Icon(
// //               icon,
// //               color: AppColors.primary,
// //               size: context.w(13),
// //             ),
// //           ),
// //           SizedBox(width: context.w(8)),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   title,
// //                   style: AppTextStyles.overline(context).copyWith(color: AppColors.white.withOpacity(0.38),
// //                   ),
// //                 ),
// //                 SizedBox(height: context.h(2)),
// //                 Text(
// //                   value,
// //                   style: AppTextStyles.bodySmallSemi(context).copyWith(color: AppColors.white),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _smallDashText(
// //     BuildContext context,
// //     String text,
// //     double size,
// //     bool bold,
// //   ) {
// //     return Text(
// //       text,
// //       style: (bold
// //               ? AppTextStyles.bodySemi(context)
// //               : AppTextStyles.overline(context))
// //           .copyWith(
// //         color: AppColors.white.withOpacity(
// //           bold ? 0.82 : 0.48,
// //         ),
// //       ),
// //     );
// //   }

// //   // ===========================================================================
// //   // RIGHT LOGIN PANEL
// //   // ===========================================================================

// //   Widget _buildLoginPanel(
// //     BuildContext context,
// //     AuthProvider auth,
// //   ) {
// //     return Container(
// //       color: AppColors.surface,
// //       padding: EdgeInsets.fromLTRB(
// //         context.w(65),
// //         context.h(50),
// //         context.w(65),
// //         context.h(38),
// //       ),
// //       child: _buildLoginContent(context, auth),
// //     );
// //   }

// //   Widget _buildLoginContent(
// //     BuildContext context,
// //     AuthProvider auth,
// //   ) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Align(
// //           alignment: Alignment.topRight,
// //           child: Text(
// //             'We. Serve. Passion',
// //             style: AppTextStyles.bodySmallSemi(context).copyWith(color: AppColors.textMuted,
// //               letterSpacing: 1.1),
// //           ),
// //         ),
// //         SizedBox(height: context.h(58)),
// //         Text(
// //           'Welcome',
// //           style: AppTextStyles.h1(context).copyWith(color: AppColors.textPrimary),
// //         ),
// //         SizedBox(height: context.h(9)),
// //         Text(
// //           'Sign in with your RDX admin or staff account to continue.',
// //           style: AppTextStyles.body(context).copyWith(color: AppColors.textMuted,
// //             height: 1.45),
// //         ),
// //         SizedBox(height: context.h(35)),
// //         _buildLabel(
// //           context,
// //           'Email Address',
// //         ),
// //         SizedBox(height: context.h(8)),
// //         RdxTextField(
// //           controller: _emailController,
// //           maxLength: 50,
// //           keyboardType: TextInputType.emailAddress,
// //           hint: 'Enter your email address',
// //           prefixIcon: Icon(
// //             Icons.mail_outline_rounded,
// //             size: context.w(18),
// //           ),
// //         ),
// //         SizedBox(height: context.h(21)),
// //         _buildLabel(
// //           context,
// //           'Password',
// //         ),
// //         SizedBox(height: context.h(8)),
// //         RdxTextField(
// //           controller: _passwordController,
// //           maxLength: 50,
// //           obscureText: _obscurePassword,
// //           hint: 'Enter your password',
// //           prefixIcon: Icon(
// //             Icons.lock_outline_rounded,
// //             size: context.w(18),
// //           ),
// //           suffixIcon: IconButton(
// //             tooltip: _obscurePassword ? 'Show password' : 'Hide password',
// //             onPressed: () {
// //               setState(() {
// //                 _obscurePassword = !_obscurePassword;
// //               });
// //             },
// //             icon: Icon(
// //               _obscurePassword
// //                   ? Icons.visibility_outlined
// //                   : Icons.visibility_off_outlined,
// //               size: context.w(18),
// //             ),
// //           ),
// //         ),
// //         SizedBox(height: context.h(9)),
// //         Align(
// //           alignment: Alignment.centerRight,
// //           child: TextButton(
// //             onPressed: auth.isLoading ? null : _showForgotPassword,
// //             style: TextButton.styleFrom(
// //               padding: EdgeInsets.symmetric(
// //                 horizontal: context.w(2),
// //                 vertical: context.h(5),
// //               ),
// //               minimumSize: Size.zero,
// //               tapTargetSize: MaterialTapTargetSize.shrinkWrap,
// //             ),
// //             child: Text(
// //               'Forgot password?',
// //               style: AppTextStyles.bodySemi(context).copyWith(color: AppColors.primary),
// //             ),
// //           ),
// //         ),
// //         SizedBox(height: context.h(22)),
// //         _buildSignInButton(
// //           context,
// //           auth,
// //         ),
// //         SizedBox(height: context.h(24)),
// //         Center(
// //           child: Text(
// //             'Need access? Ask your restaurant admin to create an account.',
// //             textAlign: TextAlign.center,
// //             style: AppTextStyles.body(context).copyWith(color: AppColors.textMuted),
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   // ===========================================================================
// //   // LABEL
// //   // ===========================================================================

// //   Widget _buildLabel(
// //     BuildContext context,
// //     String text,
// //   ) {
// //     return Text(
// //       text,
// //       style: AppTextStyles.bodySemi(context).copyWith(color: AppColors.textSecondary),
// //     );
// //   }

// //   // ===========================================================================
// //   // SIGN IN BUTTON
// //   // ===========================================================================

// //   Widget _buildSignInButton(
// //     BuildContext context,
// //     AuthProvider auth,
// //   ) {
// //     return Container(
// //       width: double.infinity,
// //       decoration: BoxDecoration(
// //         borderRadius: BorderRadius.circular(context.w(24)),
// //         boxShadow: [
// //           BoxShadow(
// //             color: AppColors.primary.withOpacity(0.22),
// //             blurRadius: context.w(18),
// //             offset: Offset(0, context.h(8)),
// //           ),
// //         ],
// //       ),
// //       child: ClipRRect(
// //         borderRadius: BorderRadius.circular(context.w(24)),
// //         child: RdxActionButton(
// //           label: 'Sign In',
// //           onPressed: _submit,
// //           isPrimary: true,
// //           isLoading: auth.isLoading,
// //         ),
// //       ),
// //     );
// //   }

// //   // ===========================================================================
// //   // FORGOT PASSWORD
// //   // ===========================================================================

// //   Future<void> _showForgotPassword() async {
// //     _log('Password reset flow opened.');
// //     final sent = await CategoryEntryDialog.show<bool>(
// //       context,
// //       title: 'Reset password',
// //       nameLabel: 'Email Address',
// //       nameHint: 'Enter your email address',
// //       nameMaxLength: 50,
// //       description: 'Enter your email address to receive a reset link.',
// //       initialName: _emailController.text,
// //       saveButtonLabel: 'Send reset link',
// //       onSave: (email, _) async {
// //         _log('Password reset request submitted to AuthProvider.');
// //         final success = await ref.read(authProvider).sendPasswordReset(email);
// //         if (!success) {
// //           _log('Password reset request failed.');
// //           throw StateError(
// //             ref.read(authProvider).errorMessage ?? 'Unable to send reset link.',
// //           );
// //         }
// //         _log('Password reset request accepted.');
// //         return true;
// //       },
// //     );

// //     _log('Password reset dialog completed (sent: ${sent == true}).');
// //     if (sent == true && mounted) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(
// //           content: Text('Password reset link sent.'),
// //           behavior: SnackBarBehavior.floating,
// //         ),
// //       );
// //     }
// //   }
// // }

// // // =============================================================================
// // // PAGE BACKGROUND
// // // =============================================================================

// // class _PageBackground extends StatelessWidget {
// //   const _PageBackground();

// //   @override
// //   Widget build(BuildContext context) {
// //     return IgnorePointer(
// //       child: Stack(
// //         children: [
// //           Positioned.fill(
// //             child: CustomPaint(
// //               painter: _BackgroundPainter(),
// //             ),
// //           ),
// //           Positioned(
// //             top: -context.w(180),
// //             right: -context.w(130),
// //             child: _backgroundGlow(
// //               context,
// //               context.w(420),
// //               AppColors.primary.withOpacity(0.06),
// //             ),
// //           ),
// //           Positioned(
// //             bottom: -context.w(220),
// //             left: -context.w(170),
// //             child: _backgroundGlow(
// //               context,
// //               context.w(500),
// //               AppColors.primary.withOpacity(0.025),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _backgroundGlow(
// //     BuildContext context,
// //     double size,
// //     Color color,
// //   ) {
// //     return Container(
// //       width: size,
// //       height: size,
// //       decoration: BoxDecoration(
// //         shape: BoxShape.circle,
// //         gradient: RadialGradient(
// //           colors: [
// //             color,
// //             color.withOpacity(0),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // =============================================================================
// // // BACKGROUND GRID
// // // =============================================================================

// // class _BackgroundPainter extends CustomPainter {
// //   @override
// //   void paint(
// //     Canvas canvas,
// //     Size size,
// //   ) {
// //     final paint = Paint()
// //       ..color = AppColors.textPrimary.withOpacity(0.018)
// //       ..strokeWidth = 1;

// //     const gap = 32.0;

// //     for (double x = 0; x < size.width; x += gap) {
// //       canvas.drawLine(
// //         Offset(x, 0),
// //         Offset(x, size.height),
// //         paint,
// //       );
// //     }

// //     for (double y = 0; y < size.height; y += gap) {
// //       canvas.drawLine(
// //         Offset(0, y),
// //         Offset(size.width, y),
// //         paint,
// //       );
// //     }
// //   }

// //   @override
// //   bool shouldRepaint(
// //     covariant _BackgroundPainter oldDelegate,
// //   ) {
// //     return false;
// //   }
// // }

// // // =============================================================================
// // // DASHBOARD CHART
// // // =============================================================================

// // class _DashboardChartPainter extends CustomPainter {
// //   final Color color;

// //   const _DashboardChartPainter({
// //     required this.color,
// //   });

// //   @override
// //   void paint(Canvas canvas, Size size) {
// //     if (size.width <= 0 || size.height <= 0) return;
// //     if (!size.width.isFinite || !size.height.isFinite) return;

// //     final points = <Offset>[
// //       Offset(0, size.height * 0.72),
// //       Offset(size.width * 0.14, size.height * 0.58),
// //       Offset(size.width * 0.27, size.height * 0.64),
// //       Offset(size.width * 0.40, size.height * 0.43),
// //       Offset(size.width * 0.53, size.height * 0.51),
// //       Offset(size.width * 0.67, size.height * 0.28),
// //       Offset(size.width * 0.81, size.height * 0.36),
// //       Offset(size.width, size.height * 0.12),
// //     ];

// //     final path = Path()..moveTo(points.first.dx, points.first.dy);
// //     for (var i = 1; i < points.length; i++) {
// //       path.lineTo(points[i].dx, points[i].dy);
// //     }

// //     final linePaint = Paint()
// //       ..color = color
// //       ..style = PaintingStyle.stroke
// //       ..strokeWidth = 2.5
// //       ..strokeCap = StrokeCap.round
// //       ..strokeJoin = StrokeJoin.round;

// //     canvas.drawPath(path, linePaint);

// //     final dotPaint = Paint()
// //       ..color = color
// //       ..style = PaintingStyle.fill;

// //     for (final point in points) {
// //       canvas.drawCircle(point, 2.7, dotPaint);
// //     }
// //   }

// //   @override
// //   bool shouldRepaint(covariant _DashboardChartPainter oldDelegate) {
// //     return oldDelegate.color != color;
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:rdx_admin/core/theme/app_colors.dart';
// import 'package:rdx_admin/core/theme/text_styles.dart';
// import 'package:rdx_admin/core/utils/responsive_size.dart';
// import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
// import 'package:rdx_admin/widgets/dialogs/category_dialog.dart';
// import 'package:rdx_admin/widgets/reusable_widgets/rdx_text_field.dart';

// import '../../providers/auth_provider.dart';

// class LoginScreen extends ConsumerStatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   ConsumerState<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends ConsumerState<LoginScreen>
//     with SingleTickerProviderStateMixin {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();

//   bool _obscurePassword = true;

//   late final AnimationController _entranceController;
//   late final Animation<double> _fadeIn;
//   late final Animation<Offset> _slideUp;

//   void _log(String message) {
//     if (kDebugMode) debugPrint('[LoginScreen] $message');
//   }

//   @override
//   void initState() {
//     super.initState();

//     _entranceController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     );

//     _fadeIn = CurvedAnimation(
//       parent: _entranceController,
//       curve: Curves.easeOutCubic,
//     );

//     _slideUp = Tween<Offset>(
//       begin: const Offset(0, 0.04),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _entranceController,
//       curve: Curves.easeOutCubic,
//     ));

//     _entranceController.forward();
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _entranceController.dispose();
//     super.dispose();
//   }

//   Future<void> _submit() async {
//     _log('Step 1: login form submitted.');
//     FocusScope.of(context).unfocus();

//     final auth = ref.read(authProvider);

//     _log('Step 2: forwarding sign-in to AuthProvider.');
//     final success = await auth.signIn(
//       _emailController.text.trim(),
//       _passwordController.text,
//     );
//     _log('Step 3: sign-in flow returned success=$success.');

//     if (!success && mounted) {
//       _log('Step 4: displaying login failure message.');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(auth.errorMessage ?? 'Unable to continue.'),
//           behavior: SnackBarBehavior.floating,
//           margin: EdgeInsets.all(context.w(20)),
//           elevation: 0,
//         ),
//       );
//     } else if (success) {
//       _log('Step 4: login accepted; app navigation is handled by auth state.');
//     }
//   }

//   Future<void> _showForgotPassword() async {
//     _log('Password reset flow opened.');
//     final sent = await CategoryEntryDialog.show<bool>(
//       context,
//       title: 'Reset password',
//       nameLabel: 'Email Address',
//       nameHint: 'Enter your email address',
//       nameMaxLength: 50,
//       description: 'Enter your email address to receive a reset link.',
//       initialName: _emailController.text,
//       saveButtonLabel: 'Send reset link',
//       onSave: (email, _) async {
//         _log('Password reset request submitted to AuthProvider.');
//         final success = await ref.read(authProvider).sendPasswordReset(email);
//         if (!success) {
//           _log('Password reset request failed.');
//           throw StateError(
//             ref.read(authProvider).errorMessage ?? 'Unable to send reset link.',
//           );
//         }
//         _log('Password reset request accepted.');
//         return true;
//       },
//     );

//     _log('Password reset dialog completed (sent: ${sent == true}).');
//     if (sent == true && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Password reset link sent.'),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final auth = ref.watch(authProvider);
//     final size = MediaQuery.sizeOf(context);
//     final isWide = size.width >= 900;

//     return Scaffold(
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           // ── Full-screen professional restaurant image ──────────────────
//           Image.network(
//             'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1920&q=80',
//             fit: BoxFit.cover,
//             width: double.infinity,
//             height: double.infinity,
//             errorBuilder: (_, __, ___) =>
//                 Container(color: const Color(0xFF0F0F0F)),
//             loadingBuilder: (context, child, loadingProgress) {
//               if (loadingProgress == null) return child;
//               return Container(
//                 color: const Color(0xFF0F0F0F),
//                 child: const Center(
//                   child: CircularProgressIndicator(
//                     color: AppColors.primary,
//                     strokeWidth: 2,
//                   ),
//                 ),
//               );
//             },
//           ),

//           // ── Dark elegant overlay ───────────────────────────────────────
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.centerLeft,
//                 end: Alignment.centerRight,
//                 colors: [
//                   Colors.black.withOpacity(0.78),
//                   Colors.black.withOpacity(0.55),
//                   Colors.black.withOpacity(0.72),
//                 ],
//               ),
//             ),
//           ),

//           // ── Soft top & bottom vignette ─────────────────────────────────
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Colors.black.withOpacity(0.35),
//                   Colors.transparent,
//                   Colors.transparent,
//                   Colors.black.withOpacity(0.45),
//                 ],
//                 stops: const [0.0, 0.18, 0.75, 1.0],
//               ),
//             ),
//           ),

//           // ── Main content ───────────────────────────────────────────────
//           SafeArea(
//             child: FadeTransition(
//               opacity: _fadeIn,
//               child: SlideTransition(
//                 position: _slideUp,
//                 child: isWide
//                     ? _buildDesktopLayout(context, auth)
//                     : _buildMobileLayout(context, auth),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ===========================================================================
//   // DESKTOP — full coverage split
//   // ===========================================================================

//   Widget _buildDesktopLayout(BuildContext context, AuthProvider auth) {
//     return Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: context.w(56),
//         vertical: context.h(40),
//       ),
//       child: Row(
//         children: [
//           // Left branding
//           Expanded(
//             flex: 5,
//             child: _buildBrandContent(context),
//           ),
//           SizedBox(width: context.w(48)),
//           // Right form card
//           Expanded(
//             flex: 4,
//             child: Align(
//               alignment: Alignment.centerRight,
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(maxWidth: context.w(440)),
//                 child: _buildFormCard(context, auth),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ===========================================================================
//   // MOBILE
//   // ===========================================================================

//   Widget _buildMobileLayout(BuildContext context, AuthProvider auth) {
//     return SingleChildScrollView(
//       padding: EdgeInsets.symmetric(
//         horizontal: context.w(24),
//         vertical: context.h(32),
//       ),
//       child: Column(
//         children: [
//           _buildBrandContent(context, isMobile: true),
//           SizedBox(height: context.h(36)),
//           _buildFormCard(context, auth),
//         ],
//       ),
//     );
//   }

//   // ===========================================================================
//   // BRANDING (left side)
//   // ===========================================================================

//   Widget _buildBrandContent(BuildContext context, {bool isMobile = false}) {
//     return Column(
//       crossAxisAlignment:
//           isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         // Logo + name
//         Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: EdgeInsets.all(context.w(10)),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.12),
//                 borderRadius: BorderRadius.circular(context.w(14)),
//                 border: Border.all(color: Colors.white.withOpacity(0.15)),
//               ),
//               child: SvgPicture.asset(
//                 'assets/images/logo/rdx_logo_picture.svg',
//                 width: context.w(28),
//                 height: context.h(28),
//                 colorFilter: const ColorFilter.mode(
//                   Colors.white,
//                   BlendMode.srcIn,
//                 ),
//               ),
//             ),
//             SizedBox(width: context.w(14)),
//             Text(
//               'RDX',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: context.w(26),
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: 1.8,
//               ),
//             ),
//           ],
//         ),

//         SizedBox(height: context.h(isMobile ? 28 : 48)),

//         // Main headline
//         Text(
//           isMobile ? 'Restaurant\nAdmin Panel' : 'Restaurant\nAdmin Panel',
//           textAlign: isMobile ? TextAlign.center : TextAlign.left,
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: context.w(isMobile ? 34 : 48),
//             fontWeight: FontWeight.w700,
//             height: 1.12,
//             letterSpacing: -1.2,
//           ),
//         ),

//         SizedBox(height: context.h(18)),

//         // Subtitle
//         ConstrainedBox(
//           constraints: BoxConstraints(maxWidth: context.w(420)),
//           child: Text(
//             'Manage orders, menu, inventory, staff and rewards from one powerful, modern workspace.',
//             textAlign: isMobile ? TextAlign.center : TextAlign.left,
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.72),
//               fontSize: context.w(16),
//               height: 1.55,
//               fontWeight: FontWeight.w400,
//             ),
//           ),
//         ),

//         if (!isMobile) ...[
//           SizedBox(height: context.h(42)),
//           // Subtle feature row
//           Wrap(
//             spacing: context.w(28),
//             runSpacing: context.h(14),
//             children: [
//               _featureItem(Icons.receipt_long_rounded, 'Live Orders'),
//               _featureItem(Icons.restaurant_menu_rounded, 'Menu Control'),
//               _featureItem(Icons.inventory_2_outlined, 'Inventory'),
//               _featureItem(Icons.people_alt_outlined, 'Staff Access'),
//             ],
//           ),
//         ],
//       ],
//     );
//   }

//   Widget _featureItem(IconData icon, String label) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, size: 16, color: AppColors.primary),
//         const SizedBox(width: 8),
//         Text(
//           label,
//           style: TextStyle(
//             color: Colors.white.withOpacity(0.78),
//             fontSize: 13.5,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }

//   // ===========================================================================
//   // FORM CARD
//   // ===========================================================================

//   Widget _buildFormCard(BuildContext context, AuthProvider auth) {
//     return Container(
//       padding: EdgeInsets.fromLTRB(
//         context.w(36),
//         context.h(40),
//         context.w(36),
//         context.h(36),
//       ),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.97),
//         borderRadius: BorderRadius.circular(context.w(24)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.25),
//             blurRadius: 40,
//             offset: const Offset(0, 20),
//           ),
//         ],
//         border: Border.all(
//           color: Colors.white.withOpacity(0.2),
//           width: 1,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             'Welcome back',
//             style: AppTextStyles.h1(context).copyWith(
//               color: AppColors.textPrimary,
//               fontSize: context.w(28),
//               letterSpacing: -0.6,
//             ),
//           ),
//           SizedBox(height: context.h(8)),
//           Text(
//             'Sign in with your admin or staff account',
//             style: AppTextStyles.body(context).copyWith(
//               color: AppColors.textMuted,
//               height: 1.4,
//             ),
//           ),
//           SizedBox(height: context.h(32)),

//           // Email
//           Text(
//             'Email Address',
//             style: AppTextStyles.bodySemi(context).copyWith(
//               color: AppColors.textSecondary,
//             ),
//           ),
//           SizedBox(height: context.h(8)),
//           RdxTextField(
//             controller: _emailController,
//             maxLength: 50,
//             keyboardType: TextInputType.emailAddress,
//             hint: 'Enter your email address',
//             prefixIcon: Icon(
//               Icons.mail_outline_rounded,
//               size: context.w(18),
//             ),
//           ),

//           SizedBox(height: context.h(20)),

//           // Password
//           Text(
//             'Password',
//             style: AppTextStyles.bodySemi(context).copyWith(
//               color: AppColors.textSecondary,
//             ),
//           ),
//           SizedBox(height: context.h(8)),
//           RdxTextField(
//             controller: _passwordController,
//             maxLength: 50,
//             obscureText: _obscurePassword,
//             hint: 'Enter your password',
//             prefixIcon: Icon(
//               Icons.lock_outline_rounded,
//               size: context.w(18),
//             ),
//             suffixIcon: IconButton(
//               tooltip: _obscurePassword ? 'Show password' : 'Hide password',
//               onPressed: () {
//                 setState(() => _obscurePassword = !_obscurePassword);
//               },
//               icon: Icon(
//                 _obscurePassword
//                     ? Icons.visibility_outlined
//                     : Icons.visibility_off_outlined,
//                 size: context.w(18),
//               ),
//             ),
//           ),

//           SizedBox(height: context.h(10)),

//           Align(
//             alignment: Alignment.centerRight,
//             child: TextButton(
//               onPressed: auth.isLoading ? null : _showForgotPassword,
//               style: TextButton.styleFrom(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: context.w(2),
//                   vertical: context.h(4),
//                 ),
//                 minimumSize: Size.zero,
//                 tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//               ),
//               child: Text(
//                 'Forgot password?',
//                 style: AppTextStyles.bodySemi(context).copyWith(
//                   color: AppColors.primary,
//                 ),
//               ),
//             ),
//           ),

//           SizedBox(height: context.h(24)),

//           // Sign In button
//           SizedBox(
//             width: double.infinity,
//             child: Container(
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(context.w(24)),
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppColors.primary.withOpacity(0.35),
//                     blurRadius: 18,
//                     offset: const Offset(0, 8),
//                   ),
//                 ],
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(context.w(24)),
//                 child: RdxActionButton(
//                   label: 'Sign In',
//                   onPressed: _submit,
//                   isPrimary: true,
//                   isLoading: auth.isLoading,
//                 ),
//               ),
//             ),
//           ),

//           SizedBox(height: context.h(22)),

//           Center(
//             child: Text(
//               'Need access? Ask your restaurant admin\nto create an account.',
//               textAlign: TextAlign.center,
//               style: AppTextStyles.body(context).copyWith(
//                 color: AppColors.textMuted,
//                 fontSize: context.w(13),
//                 height: 1.45,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/screens/main/main_screen.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/dialogs/category_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_text_field.dart';

import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  // ── Animation Controllers ─────────────────────────────────────────────
  late final AnimationController _mainController;
  late final AnimationController _floatController;
  late final AnimationController _glowController;

  // Branding staggered animations
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _featuresFade;
  late final Animation<Offset> _featuresSlide;

  // Form card
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardScale;

  // Continuous
  late final Animation<double> _floatY;
  late final Animation<double> _glowPulse;

  void _log(String message) {
    if (kDebugMode) debugPrint('[LoginScreen] $message');
  }

  @override
  void initState() {
    super.initState();

    // Main entrance (1.1s)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // Continuous float
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);

    // Continuous soft glow
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    // ── Staggered branding ─────────────────────────────────────────────
    _logoFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    ));

    _titleFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
    ));

    _subtitleFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.28, 0.65, curve: Curves.easeOutCubic),
    );

    _featuresFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
    );
    _featuresSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
    ));

    // ── Form card ──────────────────────────────────────────────────────
    _cardFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.25, 0.85, curve: Curves.easeOutCubic),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.25, 0.85, curve: Curves.easeOutCubic),
    ));
    _cardScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.25, 0.9, curve: Curves.easeOutBack),
      ),
    );

    // Continuous effects
    _floatY = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _glowPulse = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _mainController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // Future<void> _submit() async {
  //   _log('Step 1: login form submitted.');
  //   FocusScope.of(context).unfocus();

  //   final auth = ref.read(authProvider);

  //   _log('Step 2: forwarding sign-in to AuthProvider.');
  //   final success = await auth.signIn(
  //     _emailController.text.trim(),
  //     _passwordController.text,
  //   );
  //   _log('Step 3: sign-in flow returned success=$success.');

  //   if (!success && mounted) {
  //     _log('Step 4: displaying login failure message.');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(auth.errorMessage ?? 'Unable to continue.'),
  //         behavior: SnackBarBehavior.floating,
  //         margin: EdgeInsets.all(context.w(20)),
  //         elevation: 0,
  //       ),
  //     );
  //   } else if (success) {
  //     _log('Step 4: login accepted; app navigation is handled by auth state.');
  //   }
  // }

  Future<void> _submit() async {
    _log('Step 1: login form submitted.');
    FocusScope.of(context).unfocus();

    final auth = ref.read(authProvider);

    _log('Step 2: forwarding sign-in to AuthProvider.');
    final success = await auth.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );
    _log('Step 3: sign-in flow returned success=$success.');

    if (!mounted) return;

    if (!success) {
      _log('Step 4: displaying login failure message.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Unable to continue.'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(context.w(20)),
          elevation: 0,
        ),
      );
      return;
    }

    // Success → go to MainScreen
    _log('Step 4: login accepted; navigating to MainScreen.');
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 480),
      ),
    );
  }

  Future<void> _showForgotPassword() async {
    _log('Password reset flow opened.');
    final sent = await CategoryEntryDialog.show<bool>(
      context,
      title: 'Reset password',
      nameLabel: 'Email Address',
      nameHint: 'Enter your email address',
      nameMaxLength: 50,
      description: 'Enter your email address to receive a reset link.',
      initialName: _emailController.text,
      saveButtonLabel: 'Send reset link',
      onSave: (email, _) async {
        _log('Password reset request submitted to AuthProvider.');
        final success = await ref.read(authProvider).sendPasswordReset(email);
        if (!success) {
          _log('Password reset request failed.');
          throw StateError(
            ref.read(authProvider).errorMessage ?? 'Unable to send reset link.',
          );
        }
        _log('Password reset request accepted.');
        return true;
      },
    );

    _log('Password reset dialog completed (sent: ${sent == true}).');
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 900;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-screen professional image ───────────────────────────
          Image.network(
            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1920&q=80',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) =>
                Container(color: const Color(0xFF0F0F0F)),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: const Color(0xFF0F0F0F),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
          ),

          // ── Dark elegant overlay ─────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withOpacity(0.80),
                  Colors.black.withOpacity(0.58),
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
          ),

          // ── Soft vignette ────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.40),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.50),
                ],
                stops: const [0.0, 0.18, 0.72, 1.0],
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────────────
          SafeArea(
            child: isWide
                ? _buildDesktopLayout(context, auth)
                : _buildMobileLayout(context, auth),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DESKTOP
  // ===========================================================================

  Widget _buildDesktopLayout(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(56),
        vertical: context.h(40),
      ),
      child: Row(
        children: [
          // Left branding
          Expanded(
            flex: 5,
            child: _buildBrandContent(context),
          ),
          SizedBox(width: context.w(48)),
          // Right form card with continuous float + glow
          Expanded(
            flex: 4,
            child: Align(
              alignment: Alignment.centerRight,
              child: AnimatedBuilder(
                animation: Listenable.merge([_floatY, _glowPulse]),
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatY.value),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(context.w(24)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary
                                .withOpacity(0.12 * _glowPulse.value),
                            blurRadius: 50 * _glowPulse.value,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.28),
                            blurRadius: 40,
                            offset: const Offset(0, 22),
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  );
                },
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: context.w(440)),
                  child: FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: ScaleTransition(
                        scale: _cardScale,
                        child: _buildFormCard(context, auth),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MOBILE
  // ===========================================================================

  Widget _buildMobileLayout(BuildContext context, AuthProvider auth) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(24),
        vertical: context.h(32),
      ),
      child: Column(
        children: [
          _buildBrandContent(context, isMobile: true),
          SizedBox(height: context.h(36)),
          FadeTransition(
            opacity: _cardFade,
            child: SlideTransition(
              position: _cardSlide,
              child: ScaleTransition(
                scale: _cardScale,
                child: _buildFormCard(context, auth),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BRANDING (staggered)
  // ===========================================================================

  Widget _buildBrandContent(BuildContext context, {bool isMobile = false}) {
    return Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo
        FadeTransition(
          opacity: _logoFade,
          child: SlideTransition(
            position: _logoSlide,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(context.w(10)),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(context.w(14)),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: SvgPicture.asset(
                    'assets/images/logo/rdx_logo_picture.svg',
                    width: context.w(28),
                    height: context.h(28),
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                SizedBox(width: context.w(14)),
                Text(
                  'RDX',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.w(26),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: context.h(isMobile ? 28 : 48)),

        // Title
        FadeTransition(
          opacity: _titleFade,
          child: SlideTransition(
            position: _titleSlide,
            child: Text(
              'Restaurant\nAdmin Panel',
              textAlign: isMobile ? TextAlign.center : TextAlign.left,
              style: TextStyle(
                color: Colors.white,
                fontSize: context.w(isMobile ? 34 : 48),
                fontWeight: FontWeight.w700,
                height: 1.12,
                letterSpacing: -1.2,
              ),
            ),
          ),
        ),

        SizedBox(height: context.h(18)),

        // Subtitle
        FadeTransition(
          opacity: _subtitleFade,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.w(420)),
            child: Text(
              'Manage orders, menu, inventory, staff and rewards from one powerful, modern workspace.',
              textAlign: isMobile ? TextAlign.center : TextAlign.left,
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: context.w(16),
                height: 1.55,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),

        if (!isMobile) ...[
          SizedBox(height: context.h(42)),
          FadeTransition(
            opacity: _featuresFade,
            child: SlideTransition(
              position: _featuresSlide,
              child: Wrap(
                spacing: context.w(28),
                runSpacing: context.h(14),
                children: [
                  _featureItem(Icons.receipt_long_rounded, 'Live Orders'),
                  _featureItem(Icons.restaurant_menu_rounded, 'Menu Control'),
                  _featureItem(Icons.inventory_2_outlined, 'Inventory'),
                  _featureItem(Icons.people_alt_outlined, 'Staff Access'),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _featureItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.78),
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // FORM CARD
  // ===========================================================================

  Widget _buildFormCard(BuildContext context, AuthProvider auth) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(36),
        context.h(40),
        context.w(36),
        context.h(36),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(context.w(24)),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Welcome back',
            style: AppTextStyles.h1(context).copyWith(
              color: AppColors.textPrimary,
              fontSize: context.w(28),
              letterSpacing: -0.6,
            ),
          ),
          SizedBox(height: context.h(8)),
          Text(
            'Sign in with your admin or staff account',
            style: AppTextStyles.body(context).copyWith(
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          SizedBox(height: context.h(32)),

          // Email
          Text(
            'Email Address',
            style: AppTextStyles.bodySemi(context).copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: context.h(8)),
          RdxTextField(
            controller: _emailController,
            maxLength: 50,
            keyboardType: TextInputType.emailAddress,
            hint: 'Enter your email address',
            prefixIcon: Icon(
              Icons.mail_outline_rounded,
              size: context.w(18),
            ),
          ),

          SizedBox(height: context.h(20)),

          // Password
          Text(
            'Password',
            style: AppTextStyles.bodySemi(context).copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: context.h(8)),
          RdxTextField(
            controller: _passwordController,
            maxLength: 50,
            obscureText: _obscurePassword,
            hint: 'Enter your password',
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              size: context.w(18),
            ),
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: context.w(18),
              ),
            ),
          ),

          SizedBox(height: context.h(10)),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: auth.isLoading ? null : _showForgotPassword,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(2),
                  vertical: context.h(4),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot password?',
                style: AppTextStyles.bodySemi(context).copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          SizedBox(height: context.h(24)),

          // Sign In button
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.w(24)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(context.w(24)),
                child: RdxActionButton(
                  label: 'Sign In',
                  onPressed: _submit,
                  isPrimary: true,
                  isLoading: auth.isLoading,
                ),
              ),
            ),
          ),

          SizedBox(height: context.h(22)),

          Center(
            child: Text(
              'Need access? Ask your restaurant admin\nto create an account.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(context).copyWith(
                color: AppColors.textMuted,
                fontSize: context.w(13),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
