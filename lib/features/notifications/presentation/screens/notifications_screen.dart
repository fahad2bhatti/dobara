import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../../shared/models/order_model.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../orders/domain/orders_provider.dart';
import '../../data/notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final itemsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (user != null)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsActionsProvider.notifier).markAllRead(),
              child: const Text('Mark all read',
                  style: TextStyle(fontSize: 12, color: AppColors.primary)),
            ),
        ],
      ),
      body: SafeArea(
        child: user == null
            ? _EmptyState(
          icon: Icons.notifications_none,
          title: 'Sign in to see updates',
          subtitle: 'Order updates and alerts will show up here.',
        )
            : itemsAsync.when(
          loading: () =>
          const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Could not load notifications.\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textTertiary)),
          ),
          data: (items) {
            if (items.isEmpty) {
              return _EmptyState(
                icon: Icons.notifications_none,
                title: 'No notifications yet',
                subtitle: "We'll let you know when there's an update on your orders.",
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = items[i];
                return _NotificationTile(notification: n);
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = notification;
    return GestureDetector(
      onTap: () async {
        if (!n.read) {
          ref.read(notificationsActionsProvider.notifier).markRead(n.id);
        }
        if (n.orderId != null) {
          final orders = ref.read(ordersStreamProvider).asData?.value ?? [];
          Order? order;
          for (final o in orders) {
            if (o.id == n.orderId) {
              order = o;
              break;
            }
          }
          if (order != null && context.mounted) {
            context.push('/order-history/detail', extra: order);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.read ? AppColors.surface : AppColors.muted,
          borderRadius: BorderRadius.circular(14),
          border: n.read
              ? null
              : Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!n.read)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 5, right: 10),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                          n.read ? FontWeight.w600 : FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(n.body,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4)),
                  const SizedBox(height: 6),
                  Text(_relativeTime(n.createdAt),
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textTertiary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${t.day}/${t.month}/${t.year}';
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 52,
                color: AppColors.textSecondary.withValues(alpha: 0.35)),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                )),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                  height: 1.6,
                )),
          ],
        ),
      ),
    );
  }
}
