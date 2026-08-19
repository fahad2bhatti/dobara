  import 'package:flutter/material.dart';
  import 'package:flutter/gestures.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../../../../core/theme/app_colors.dart';
  import '../../domain/auth_provider.dart';
  //import 'login_screen.dart';
  import 'package:go_router/go_router.dart';

  class SignUpScreen extends ConsumerStatefulWidget {
    const SignUpScreen({super.key});

    @override
    ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
  }

  class _SignUpScreenState extends ConsumerState<SignUpScreen> {
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    bool _loading = false;
    String? _error;
    bool _obscure = true;

    @override
    void dispose() {
      _nameController.dispose();
      _emailController.dispose();
      _passwordController.dispose();
      super.dispose();
    }

    Future<void> _signUp() async {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        setState(() => _error = 'Please fill in all fields.');
        return;
      }
      if (password.length < 6) {
        setState(() => _error = 'Password should be at least 6 characters.');
        return;
      }

      setState(() {
        _loading = true;
        _error = null;
      });

      final service = ref.read(firebaseAuthServiceProvider);
      try {
        await service.signUp(name: name, email: email, password: password);
        if (mounted) context.go('/home');
      } catch (e) {
        setState(() => _error = service.friendlyError(e));
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'دوبارہ',
                  style: TextStyle(
                    fontFamily: 'Instrument Serif',
                    fontSize: 32,
                    color: AppColors.primary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Create your account',
                  style: TextStyle(
                    fontFamily: 'Instrument Serif',
                    fontSize: 24,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Buy better. Sell smarter. Give fashion another life.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),

                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.errorText),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                _label('FULL NAME'),
                const SizedBox(height: 7),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  decoration: _inputDecoration('Your name'),
                ),
                const SizedBox(height: 16),

                _label('EMAIL'),
                const SizedBox(height: 7),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  decoration: _inputDecoration('you@example.com'),
                ),
                const SizedBox(height: 16),

                _label('PASSWORD'),
                const SizedBox(height: 7),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  decoration: _inputDecoration('At least 6 characters').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.primaryForeground,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : const Text('Sign Up',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),

                Center(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textTertiary),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Log In',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => context.go('/login'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget _label(String text) => Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: AppColors.textTertiary,
      ),
    );

    InputDecoration _inputDecoration(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textPlaceholder),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );
    }
  }