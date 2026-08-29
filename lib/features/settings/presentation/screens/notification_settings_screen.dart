import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../domain/settings_provider.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool? _orderUpdates;
  bool? _promotions;
  bool _saving = false;

  Future<void> _update({bool? orderUpdates, bool? promotions}) async {
    setState(() {
      if (orderUpdates != null) _orderUpdates = orderUpdates;
      if (promotions != null) _promotions = promotions;
      _saving = true;
    });
    try {
      await ref.read(settingsActionsProvider.notifier).updateNotificationPrefs(
        notifyOrderUpdates: _orderUpdates!,
        notifyPromotions: _promotions!,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save preference: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load preferences: $e')),
          data: (profile) {
            _orderUpdates ??= profile?.notifyOrderUpdates ?? true;
            _promotions ??= profile?.notifyPromotions ?? true;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _toggleTile(
                  icon: '📦',
                  title: 'Order Updates',
                  subtitle: 'Delivery status changes for your orders.',
                  value: _orderUpdates!,
                  onChanged: _saving
                      ? null
                      : (v) => _update(orderUpdates: v),
                ),
                const SizedBox(height: 10),
                _toggleTile(
                  icon: '🎉',
                  title: 'Promotions',
                  subtitle: 'New arrivals, sales, and offers.',
                  value: _promotions!,
                  onChanged: _saving
                      ? null
                      : (v) => _update(promotions: v),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _toggleTile({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeThumbColor: AppColors.primary,
        secondary: Text(icon, style: const TextStyle(fontSize: 18)),
        title: Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
