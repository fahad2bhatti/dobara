import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/address_model.dart';
import '../../auth/domain/auth_provider.dart';
import 'addresses_repository.dart';

final addressesRepositoryProvider =
Provider<AddressesRepository>((ref) => AddressesRepository());

/// Live list of the signed-in user's saved addresses. Empty when signed
/// out (checkout already requires sign-in, so this should always have
/// a real user by the time it's watched there).
final addressesStreamProvider = StreamProvider<List<SavedAddress>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(addressesRepositoryProvider).watchAddresses(user.uid);
});

class AddressesActions extends Notifier<void> {
  @override
  void build() {}

  Future<void> addAddress(SavedAddress address) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(addressesRepositoryProvider).addAddress(user.uid, address);
  }

  Future<void> deleteAddress(String addressId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref
        .read(addressesRepositoryProvider)
        .deleteAddress(user.uid, addressId);
  }
}

final addressesActionsProvider =
NotifierProvider<AddressesActions, void>(AddressesActions.new);