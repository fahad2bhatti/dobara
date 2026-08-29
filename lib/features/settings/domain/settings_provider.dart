import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/auth_provider.dart';
import '../data/settings_repository.dart';

final settingsRepositoryProvider =
Provider<SettingsRepository>((ref) => SettingsRepository());

class SettingsActions extends Notifier<void> {
  @override
  void build() {}

  Future<void> updateProfile({required String name, required String phone}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(settingsRepositoryProvider).updateProfile(
      user.uid,
      name: name,
      phone: phone,
    );
    // Keep FirebaseAuth's own displayName in sync too, since some
    // screens (e.g. review author fallback) read it directly.
    await user.updateDisplayName(name);
  }

  Future<void> updateNotificationPrefs({
    required bool notifyOrderUpdates,
    required bool notifyPromotions,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(settingsRepositoryProvider).updateNotificationPrefs(
      user.uid,
      notifyOrderUpdates: notifyOrderUpdates,
      notifyPromotions: notifyPromotions,
    );
  }

  Future<void> sendPasswordReset() async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.email == null) return;
    await ref.read(firebaseAuthServiceProvider).sendPasswordReset(user.email!);
  }

  /// Re-proves the password (Firebase requires a recent login for this),
  /// then deletes everything this client can and revokes the account.
  Future<void> deleteAccount(String password) async {
    final auth = ref.read(firebaseAuthServiceProvider);
    await auth.reauthenticate(password);
    await auth.deleteAccount();
  }
}

final settingsActionsProvider =
NotifierProvider<SettingsActions, void>(SettingsActions.new);
