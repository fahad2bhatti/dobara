// lib/shared/models/cart_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String listingId;
  final String name;
  final double price;
  final String imageUrl;
  final String? size;
  final String sellerId;
  final int quantity;
  final DateTime? addedAt;

  const CartItem({
    required this.listingId,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.size,
    required this.sellerId,
    this.quantity = 1,
    this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'size': size,
      'sellerId': sellerId,
      'quantity': quantity,
      // Note: FieldValue.serverTimestamp() doesn't work inside arrays.
      // We use a client Timestamp here — acceptable for a non-critical
      // "addedAt" display field. Order writes still use serverTimestamp().
      'addedAt': addedAt != null
          ? Timestamp.fromDate(addedAt!)
          : Timestamp.now(),
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      listingId: map['listingId'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['imageUrl'] as String,
      size: map['size'] as String?,
      sellerId: map['sellerId'] as String,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      addedAt: (map['addedAt'] as Timestamp?)?.toDate(),
    );
  }

  CartItem copyWith({int? quantity}) {
    return CartItem(
      listingId: listingId,
      name: name,
      price: price,
      imageUrl: imageUrl,
      size: size,
      sellerId: sellerId,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt,
    );
  }

  double get subtotal => price * quantity;
}