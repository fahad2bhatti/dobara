import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_profile_model.dart';
import '../data/users_repository.dart';
import '../../auth/domain/auth_provider.dart';

final usersRepositoryProvider =
Provider<UsersRepository>((ref) => UsersRepository());

final usersStreamProvider = StreamProvider<List<UserProfile>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(usersRepositoryProvider).watchUsers();
});

class UsersActions extends Notifier<void> {
  @override
  void build() {}

  Future<void> setBanned(String uid, bool banned) {
    return ref.read(usersRepositoryProvider).setBanned(uid, banned);
  }
}

final usersActionsProvider =
NotifierProvider<UsersActions, void>(UsersActions.new);