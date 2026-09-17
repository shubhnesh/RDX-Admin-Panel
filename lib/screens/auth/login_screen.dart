import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/resuable_options/rdx_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isRegister = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = ref.read(authProvider);
    final ok = _isRegister
        ? await auth.register(_emailCtrl.text, _passCtrl.text)
        : await auth.signIn(_emailCtrl.text, _passCtrl.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'RDX Admin',
                    // style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    //       fontWeight: FontWeight.bold,
                    //       color: AppColors.primary,
                    //     ),
                    style: AppTextStyles.heading(context)
                        .copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRegister
                        ? 'Create admin account'
                        : 'Sign in to continue',
                    // style: Theme.of(context).textTheme.bodyMedium,
                    style: AppTextStyles.bodySecondary(context),
                  ),
                  const SizedBox(height: 32),
                  // TextField(
                  //   controller: _emailCtrl,
                  //   keyboardType: TextInputType.emailAddress,
                  //   decoration: const InputDecoration(
                  //     labelText: 'Email',
                  //     border: OutlineInputBorder(),
                  //     prefixIcon: Icon(Icons.email_outlined),
                  //   ),
                  // ),
                  RdxTextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    hint: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  const SizedBox(height: 16),
                  // TextField(
                  //   controller: _passCtrl,
                  //   obscureText: _obscure,
                  //   decoration: InputDecoration(
                  //     labelText: 'Password',
                  //     border: const OutlineInputBorder(),
                  //     prefixIcon: const Icon(Icons.lock_outline),
                  //     suffixIcon: IconButton(
                  //       icon: Icon(
                  //           _obscure ? Icons.visibility : Icons.visibility_off),
                  //       onPressed: () => setState(() => _obscure = !_obscure),
                  //     ),
                  //   ),
                  // ),
                  RdxTextField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    hint: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: RdxActionButton(
                      label: _isRegister ? 'Create Account' : 'Sign In',
                      onPressed: auth.isLoading ? null : _submit,
                      isPrimary: true,
                      isLoading: auth.isLoading,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => _isRegister = !_isRegister),
                    child: Text(
                      _isRegister
                          ? 'Already have an account? Sign in'
                          : 'First time? Create admin account',
                      style: AppTextStyles.label(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
