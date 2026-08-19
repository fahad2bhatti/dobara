import 'package:cloud_firestore/cloud_firestore.dart';

/// A single item in a user's cart, stored at
/// cart/{uid}/items/{listingId} — doc id IS the listingId, so adding
/// the same listing twice just increments quantity instead of
/// duplicating a row.
class CartItem {
  final String listingId;
  final String name;
  final int price;
  final String imageUrl;
  final String? size;
  final String sellerId;
  final String sellerName;
  final int quantity;
  final DateTime? addedAt;

  const CartItem({
    required this.listingId,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.size,
    required this.sellerId,
    required this.sellerName,
    this.quantity = 1,
    this.addedAt,
  });

  int get subtotal => price * quantity;

  Map<String, dynamic> toMap() => {
    'listingId': listingId,
    'name': name,
    'price': price,
    'imageUrl': imageUrl,
    'size': size,
    'sellerId': sellerId,
    'quantity': quantity,
    'addedAt': FieldValue.serverTimestamp(),
  };

  factory CartItem.fromMap(String id, Map<String, dynamic> map) {
    return CartItem(
      listingId: id,
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      imageUrl: map['imageUrl'] ?? '',
      size: map['size'],
      sellerId: map['sellerId'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      addedAt: (map['addedAt'] as Timestamp?)?.toDate(), sellerName: '',
    );
  }

  CartItem copyWith({int? quantity}) => CartItem(
    listingId: listingId,
    name: name,
    price: price,
    imageUrl: imageUrl,
    size: size,
    sellerId: sellerId,
    quantity: quantity ?? this.quantity,
    addedAt: addedAt, sellerName: sellerName,
  );
}