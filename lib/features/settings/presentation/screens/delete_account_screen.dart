import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../domain/settings_provider.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  bool _understood = false;
  bool _deleting = false;
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndDelete() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
            'This can\'t be undone. Are you absolutely sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _delete();
            },
            child: const Text('Delete Forever',
                style: TextStyle(color: AppColors.errorText)),
          ),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    try {
      await ref
          .read(settingsActionsProvider.notifier)
          .deleteAccount(_passwordController.text);
      if (!mounted) return;
      // Deleting the Auth user signs it out too — currentUserProvider
      // will go null and the router would redirect on its own, but we
      // go explicitly so there's no flash of a now-broken settings
      // screen while that catches up.
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      final message = e is FirebaseAuthException
          ? ref.read(firebaseAuthServiceProvider).friendlyError(e)
          : 'Could not delete account: $e';
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  bool get _canSubmit =>
      _understood && _passwordController.text.isNotEmpty && !_deleting;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Delete Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.errorText.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border:
                  Border.all(color: AppColors.errorText.withValues(alpha: 0.25)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This will permanently delete:',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.errorText)),
                    SizedBox(height: 8),
                    _Bullet('Your profile and account'),
                    _Bullet('Saved addresses'),
                    _Bullet('Cart and wishlist items'),
                    _Bullet('Notifications'),
                    SizedBox(height: 8),
                    Text(
                      'Your past orders will remain on record for bookkeeping, but will no longer be linked to a visible profile.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textBody,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _understood,
                onChanged: (v) => setState(() => _understood = v ?? false),
                title: const Text(
                  'I understand this action is permanent and cannot be undone.',
                  style: TextStyle(fontSize: 12, color: AppColors.textBody),
                ),
              ),
              const SizedBox(height: 8),
              const Text('CONFIRM PASSWORD',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.textTertiary)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Your password',
                  hintStyle: const TextStyle(
                      fontSize: 13, color: AppColors.textPlaceholder),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(14),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        size: 18),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: AppColors.border, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: AppColors.border, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _confirmAndDelete : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorText,
                    disabledBackgroundColor:
                    AppColors.errorText.withValues(alpha: 0.35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _deleting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Delete My Account',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text('•  $text',
          style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
    );
  }
}
