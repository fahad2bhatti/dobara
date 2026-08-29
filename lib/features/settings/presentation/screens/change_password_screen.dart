import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../domain/settings_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  bool _sending = false;
  bool _sent = false;

  Future<void> _sendResetLink() async {
    setState(() => _sending = true);
    try {
      await ref.read(settingsActionsProvider.notifier).sendPasswordReset();
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send reset link: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Change Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_sent) ...[
                const Icon(Icons.mark_email_read_outlined,
                    size: 44, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  'We sent a password reset link to $email. Open it to set a new password, then come back and sign in.',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textBody, height: 1.5),
                ),
              ] else ...[
                const Text(
                  'For your security, password changes happen through a reset link — not typed in-app.',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textBody, height: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'We\'ll email a reset link to $email.',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _sendResetLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.primaryForeground,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _sending
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : const Text('Send Reset Link',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
