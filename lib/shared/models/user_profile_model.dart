import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role; // 'buyer' | 'admin'
  final double? trustScore;
  final int completedSales;
  final String avatarUrl;
  final String city;
  final bool isBanned;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.trustScore,
    required this.completedSales,
    required this.avatarUrl,
    required this.city,
    this.isBanned = false,
  });

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return UserProfile(
      id: doc.id,
      name: map['name'] ?? 'Dobara User',
      email: map['email'] ?? '',
      role: map['role'] ?? 'buyer',
      trustScore: (map['trustScore'] as num?)?.toDouble(),
      completedSales: (map['completedSales'] as num?)?.toInt() ?? 0,
      avatarUrl: map['avatarUrl'] ?? '',
      city: map['city'] ?? 'Lahore',
      isBanned: map['isBanned'] as bool? ?? false,
    );
  }
}