import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/address_model.dart';

/// Firestore CRUD for a user's saved addresses at
/// addresses/{uid}/items/{addressId}.
class AddressesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _db.collection('addresses').doc(uid).collection('items');

  Stream<List<SavedAddress>> watchAddresses(String uid) {
    return _items(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => SavedAddress.fromDoc(d)).toList());
  }

  Future<void> addAddress(String uid, SavedAddress address) {
    return _items(uid).add(address.toMap());
  }

  Future<void> deleteAddress(String uid, String addressId) {
    return _items(uid).doc(addressId).delete();
  }
}