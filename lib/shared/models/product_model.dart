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
}

class Seller {
  final String name;
  final double? trustScore; // null = New Seller
  final int completedSales;
  final String avatarUrl;

  const Seller({
    required this.name,
    required this.trustScore,
    required this.completedSales,
    required this.avatarUrl,
  });
}

class Product {
  final String id;
  final String name;
  final String brand;
  final int price; // PKR, whole rupees
  final ConditionGrade condition;
  final String imageUrl;
  final String category;
  final String? size;
  final String city;
  final String description;
  final Seller seller;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.condition,
    required this.imageUrl,
    required this.category,
    this.size,
    required this.city,
    required this.description,
    required this.seller,
  });
}
