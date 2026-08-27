import 'package:cloud_firestore/cloud_firestore.dart';

/// A user's saved delivery address, stored at
/// addresses/{uid}/items/{addressId} — same pattern as notifications.
/// A user can have several of these (Home, Office, Other...).
class SavedAddress {
  final String id;
  final String label;
  final String customerName;
  final String phone;
  final String address;
  final String province;
  final String city;
  final DateTime? createdAt;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.province,
    required this.city,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'label': label,
    'customerName': customerName,
    'phone': phone,
    'address': address,
    'province': province,
    'city': city,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory SavedAddress.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data()!;
    return SavedAddress(
      id: doc.id,
      label: map['label'] ?? 'Home',
      customerName: map['customerName'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      province: map['province'] ?? '',
      city: map['city'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}