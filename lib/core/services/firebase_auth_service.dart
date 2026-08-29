import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin wrapper around FirebaseAuth — the single place the rest of
/// the app talks to for sign up / sign in / sign out. Keeps
/// FirebaseAuth calls out of widgets.
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    await user?.updateDisplayName(name);
    await user?.reload();

    // Create the matching Firestore profile — this is what listings,
    // seller trust score, and admin role checks read from.
    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'role': 'buyer',
        'trustScore': null,
        'completedSales': 0,
        'avatarUrl': '',
        'city': 'Lahore',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return _auth.currentUser;
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => _auth.signOut();

  /// Firebase requires a "recent" login before letting an account be
  /// deleted — this re-proves the current password so deleteAccount()
  /// below doesn't hit a requires-recent-login error.
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  /// Deletes everything this client is allowed to remove for the
  /// signed-in user, then revokes the Auth account itself. Orders are
  /// deliberately left alone — Firestore rules block client delete/update
  /// on them by design (so anonymizing needs a Cloud Function, tracked
  /// separately); the caller should tell the user their order history
  /// may remain for record-keeping.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    for (final collection in ['addresses', 'cart', 'wishlist', 'notifications']) {
      final items = await _db.collection(collection).doc(uid).collection('items').get();
      final batch = _db.batch();
      for (final doc in items.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_db.collection(collection).doc(uid));
      await batch.commit();
    }

    // Reviews live under listings/{listingId}/reviews/{uid}, so a plain
    // collection() lookup can't find them all — collectionGroup by the
    // stored userId field catches every listing this uid reviewed.
    final reviews = await _db
        .collectionGroup('reviews')
        .where('userId', isEqualTo: uid)
        .get();
    for (final doc in reviews.docs) {
      await doc.reference.delete();
    }

    await _db.collection('users').doc(uid).delete();
    await user.delete();
  }

  /// Turns FirebaseAuthException codes into short, friendly copy.
  String friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'weak-password':
          return 'Password should be at least 6 characters.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again shortly.';
        case 'network-request-failed':
          return 'Network error. Check your connection.';
        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}