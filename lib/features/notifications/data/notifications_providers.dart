import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/notification_model.dart';
import '../../auth/domain/auth_provider.dart';
import 'notifications_repository.dart';

final notificationsRepositoryProvider =
Provider<NotificationsRepository>((ref) => NotificationsRepository());

/// Live notification feed for the signed-in user. Empty when signed out.
final notificationsStreamProvider =
StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref
      .watch(notificationsRepositoryProvider)
      .watchNotifications(user.uid);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final items = ref.watch(notificationsStreamProvider).asData?.value ?? const [];
  return items.where((n) => !n.read).length;
});

class NotificationsActions extends Notifier<void> {
  @override
  void build() {}

  Future<void> markRead(String notificationId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref
        .read(notificationsRepositoryProvider)
        .markRead(user.uid, notificationId);
  }

  Future<void> markAllRead() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(notificationsRepositoryProvider).markAllRead(user.uid);
  }
}

final notificationsActionsProvider =
NotifierProvider<NotificationsActions, void>(NotificationsActions.new);
