import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/user_profile_model.dart';
import '../../../../shared/models/order_model.dart';
import '../../../orders/domain/orders_provider.dart';
import '../../domain/users_provider.dart';

class UsersListScreen extends ConsumerWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersStreamProvider);
    // Watched once here (not per-tile) so all rows' trust tiers derive
    // from the same snapshot without each tile re-subscribing.
    final allOrders = ref.watch(adminOrdersStreamProvider).asData?.value ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Users')),
      body: SafeArea(
        child: usersAsync.when(
          data: (users) => users.isEmpty
              ? const Center(child: Text('No users found.'))
              : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _userTile(context, ref, users[i], allOrders),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load users: $e')),
        ),
      ),
    );
  }

  Widget _userTile(
      BuildContext context, WidgetRef ref, UserProfile user, List<Order> allOrders) {
    final isAdminUser = user.role == 'admin';
    final userOrders = allOrders.where((o) => o.buyerId == user.id).toList();
    final completedPurchases =
        userOrders.where((o) => o.status == OrderStatus.delivered).length;
    final tier = trustTierLabel(completedPurchases);
    // user.city is a fake signup default (always "Lahore", never actually
    // set by the user) — use the real delivery city from their most
    // recent order instead. No orders yet → no city shown at all, rather
    // than a made-up one.
    final realCity = userOrders.isNotEmpty
        ? (userOrders..sort((a, b) => b.placedAt.compareTo(a.placedAt)))
        .first
        .city
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.neutral200,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user.name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    if (isAdminUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('ADMIN',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ),
                    ] else ...[
                      const SizedBox(width: 6),
                      _trustBadge(tier),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(user.email,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textTertiary)),
                const SizedBox(height: 2),
                Text(
                  isAdminUser
                      ? (realCity ?? '')
                      : '$completedPurchases completed purchase${completedPurchases == 1 ? '' : 's'}'
                      '${realCity != null ? ' · $realCity' : ''}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          if (!isAdminUser)
            _banButton(context, ref, user)
          else
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.shield_outlined,
                  size: 18, color: AppColors.textTertiary),
            ),
        ],
      ),
    );
  }

  Widget _trustBadge(String tier) {
    final (bg, fg) = switch (tier) {
      'Gold' => (const Color(0xFFFCEFC7), const Color(0xFF8A6300)),
      'Silver' => (const Color(0xFFE7E7E7), const Color(0xFF5A5A5A)),
      'Bronze' => (const Color(0xFFF3E0D2), const Color(0xFF8A4B1E)),
      _ => (AppColors.muted, AppColors.textTertiary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(tier,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _banButton(BuildContext context, WidgetRef ref, UserProfile user) {
    return TextButton(
      onPressed: () => _confirmToggle(context, ref, user),
      style: TextButton.styleFrom(
        backgroundColor:
        user.isBanned ? AppColors.successBg : AppColors.errorBg,
        foregroundColor:
        user.isBanned ? AppColors.successText : AppColors.errorText,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: Text(
        user.isBanned ? 'Unban' : 'Ban',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _confirmToggle(
      BuildContext context, WidgetRef ref, UserProfile user) async {
    final action = user.isBanned ? 'unban' : 'ban';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action[0].toUpperCase()}${action.substring(1)} user?'),
        content: Text(
            'Are you sure you want to $action ${user.name}? ${user.isBanned ? '' : 'They will be blocked from posting listings, adding to cart, or placing orders.'}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action[0].toUpperCase() + action.substring(1)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(usersActionsProvider.notifier)
          .setBanned(user.id, !user.isBanned);
    }
  }
}
