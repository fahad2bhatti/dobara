import 'package:cloud_firestore/cloud_firestore.dart';

/// Standardized condition grades — sellers pick from these, never free text.
enum ConditionGrade {
  likeNew('Like New', 'Worn 1–2 times, no visible signs of use'),
  excellent('Excellent', 'Minimal signs of wear, still looks great'),
  good('Good', 'Light wear, small imperfections'),
  fair('Fair', 'Visible wear, clearly pre-loved'),
  wellWorn('Well Worn', 'Heavy use, significant signs of wear');

  final String label;
  final String description;

  const ConditionGrade(this.label, this.description);

  static ConditionGrade fromLabel(String label) {
    return ConditionGrade.values.firstWhere(
          (g) => g.label == label,
      orElse: () => ConditionGrade.good,
    );
  }
}

/// Denormalized seller snapshot stored on each listing at publish time
/// (trust score etc. reflect the seller's stats as of that moment).
class Seller {
  final String id; // Firebase Auth uid
  final String name;
  final double? trustScore; // null = New Seller
  final int completedSales;
  final String avatarUrl;

  const Seller({
    required this.id,
    required this.name,
    required this.trustScore,
    required this.completedSales,
    required this.avatarUrl,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'trustScore': trustScore,
    'completedSales': completedSales,
    'avatarUrl': avatarUrl,
  };

  factory Seller.fromMap(Map<String, dynamic> map) => Seller(
    id: map['id'] ?? '',
    name: map['name'] ?? 'Dobara Seller',
    trustScore: (map['trustScore'] as num?)?.toDouble(),
    completedSales: (map['completedSales'] as num?)?.toInt() ?? 0,
    avatarUrl: map['avatarUrl'] ?? '',
  );
}

class Product {
  final String id;
  final String name;
  final String brand;
  final int price; // PKR, whole rupees
  final ConditionGrade condition;
  final List<String> imageUrls;
  final String category;
  final String? size;
  final String city;
  final String description;
  final Seller seller;
  final DateTime? createdAt;
  final bool isSoldOut;
  final int viewCount;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.condition,
    required this.imageUrls,
    required this.category,
    this.size,
    required this.city,
    required this.description,
    required this.seller,
    this.createdAt,
    this.isSoldOut = false,
    this.viewCount = 0,
  });

  /// Convenience — first image, or a blank placeholder if none uploaded.
  String get imageUrl =>
      imageUrls.isNotEmpty ? imageUrls.first : '';

  Map<String, dynamic> toMap() => {
    'name': name,
    'brand': brand,
    'price': price,
    'condition': condition.label,
    'imageUrls': imageUrls,
    'category': category,
    'size': size,
    'city': city,
    'description': description,
    'sellerId': seller.id,
    'seller': seller.toMap(),
    'createdAt': FieldValue.serverTimestamp(),
    'isSoldOut': isSoldOut,
    'viewCount': viewCount,
  };

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data()!;
    return Product(
      id: doc.id,
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      condition: ConditionGrade.fromLabel(map['condition'] ?? 'Good'),
      imageUrls: List<String>.from(map['imageUrls'] ?? const []),
      category: map['category'] ?? '',
      size: map['size'],
      city: map['city'] ?? '',
      description: map['description'] ?? '',
      seller: Seller.fromMap(
          Map<String, dynamic>.from(map['seller'] ?? const {})),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      isSoldOut: map['isSoldOut'] ?? false,
      viewCount: (map['viewCount'] as num?)?.toInt() ?? 0,
    );
  }
}