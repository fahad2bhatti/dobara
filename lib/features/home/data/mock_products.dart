import '../../../shared/models/product_model.dart';

/// Sample data — no longer used by Home/Explore (they read live
/// Firestore listings now), but kept as a reference/fallback for
/// screens not yet migrated (e.g. Admin listings moderation).
final List<Product> mockProducts = [
  Product(
    id: '1',
    name: "Levi's 501 Original",
    brand: "Levi's",
    price: 3200,
    condition: ConditionGrade.excellent,
    imageUrls: const [
      'https://images.unsplash.com/photo-1586084611164-a9accaeab607?w=400&h=520&fit=crop&auto=format'
    ],
    category: 'Clothing',
    size: '32×30',
    city: 'Lahore',
    description:
    "Classic 501s in excellent condition. Barely worn, no fading or tears.",
    seller: const Seller(
      id: 'mock-seller-1',
      name: 'Sara K.',
      trustScore: 4.9,
      completedSales: 34,
      avatarUrl:
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80&h=80&fit=crop&auto=format',
    ),
  ),
  Product(
    id: '2',
    name: 'Nike Air Force 1 Low',
    brand: 'Nike',
    price: 7500,
    condition: ConditionGrade.likeNew,
    imageUrls: const [
      'https://images.unsplash.com/photo-1608319331919-6c7cb6e34b7a?w=400&h=520&fit=crop&auto=format'
    ],
    category: 'Shoes',
    size: 'UK 9',
    city: 'Karachi',
    description:
    "Worn once for a photoshoot. Comes with original box and extra laces.",
    seller: const Seller(
      id: 'mock-seller-2',
      name: 'Ali R.',
      trustScore: 4.7,
      completedSales: 12,
      avatarUrl:
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80&h=80&fit=crop&auto=format',
    ),
  ),
  Product(
    id: '3',
    name: 'Wrangler Trucker Jacket',
    brand: 'Wrangler',
    price: 4800,
    condition: ConditionGrade.good,
    imageUrls: const [
      'https://images.unsplash.com/photo-1611312449408-fcece27cdbb7?w=400&h=520&fit=crop&auto=format'
    ],
    category: 'Clothing',
    size: 'L',
    city: 'Islamabad',
    description: "Classic vintage-wash trucker jacket. Light wear on elbows.",
    seller: const Seller(
      id: 'mock-seller-3',
      name: 'Zara M.',
      trustScore: 4.5,
      completedSales: 8,
      avatarUrl:
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=80&h=80&fit=crop&auto=format',
    ),
  ),
  Product(
    id: '4',
    name: 'Leather Crossbody Bag',
    brand: 'Unbranded',
    price: 2200,
    condition: ConditionGrade.excellent,
    imageUrls: const [
      'https://images.unsplash.com/photo-1559563458-527698bf5295?w=400&h=520&fit=crop&auto=format'
    ],
    category: 'Bags',
    city: 'Lahore',
    description:
    "Compact grey leather crossbody. No scratches, zipper works perfectly.",
    seller: const Seller(
      id: 'mock-seller-4',
      name: 'Hira N.',
      trustScore: null,
      completedSales: 0,
      avatarUrl:
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=80&h=80&fit=crop&auto=format',
    ),
  ),
  Product(
    id: '5',
    name: 'Zara Knit Sweater',
    brand: 'Zara',
    price: 1800,
    condition: ConditionGrade.likeNew,
    imageUrls: const [
      'https://images.unsplash.com/photo-1621198059871-0d5f9b449233?w=400&h=520&fit=crop&auto=format'
    ],
    category: 'Clothing',
    size: 'M',
    city: 'Rawalpindi',
    description: "White oversized knit from Zara last season. Worn twice.",
    seller: const Seller(
      id: 'mock-seller-5',
      name: 'Amna J.',
      trustScore: 4.8,
      completedSales: 19,
      avatarUrl:
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=80&h=80&fit=crop&auto=format',
    ),
  ),
  Product(
    id: '6',
    name: 'Minimalist Leather Tote',
    brand: 'H&M',
    price: 3500,
    condition: ConditionGrade.fair,
    imageUrls: const [
      'https://images.unsplash.com/photo-1605733513597-a8f8341084e6?w=400&h=520&fit=crop&auto=format'
    ],
    category: 'Bags',
    city: 'Karachi',
    description:
    "Classic black leather tote. Used daily for 8 months. Minor scuffs.",
    seller: const Seller(
      id: 'mock-seller-6',
      name: 'Fatima B.',
      trustScore: 4.6,
      completedSales: 27,
      avatarUrl:
      'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=80&h=80&fit=crop&auto=format',
    ),
  ),
];