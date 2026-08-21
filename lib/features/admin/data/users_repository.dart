import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/user_profile_model.dart';

class UsersRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Stream<List<UserProfile>> watchUsers() {
    return _users
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(UserProfile.fromDoc).toList());
  }

  Future<void> setBanned(String uid, bool banned) {
    return _users.doc(uid).update({'isBanned': banned});
  }
}