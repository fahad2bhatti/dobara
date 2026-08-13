import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../shared/models/user_profile_model.dart';

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

/// Live auth state — null when signed out. Widgets watch this to
/// decide what to show (Guest vs signed-in Profile, route guards, etc).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthServiceProvider).authStateChanges;
});

/// Convenience: current user, or null. Avoids unwrapping AsyncValue
/// everywhere a quick check is needed.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).asData?.value;
});

/// Live Firestore profile (name, role, trust score, etc.) for the
/// signed-in user. Null when signed out or profile not yet created.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists ? UserProfile.fromDoc(doc) : null);
});

final isAdminProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider).asData?.value;
  return profile?.role == 'admin';
});