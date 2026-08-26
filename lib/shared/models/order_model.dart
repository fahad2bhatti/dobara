import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_model.dart';

enum OrderStatus {
  placed('Order Placed'),
  confirmed('Confirmed'),
  packed('Packed'),
  shipped('Shipped'),
  outForDelivery('Out for Delivery'),
  delivered('Delivered'),
  cancelled('Cancelled');

  final String label;
  const OrderStatus(this.label);

  static OrderStatus fromValue(String value) {
    return OrderStatus.values.firstWhere(
          (s) => s.name == value,
      orElse: () => OrderStatus.placed,
    );
  }
}

/// Frozen snapshot of a cart item at order time. Deliberately decoupled
/// from the live CartItem/Product so editing or deleting a listing later
/// never changes what a past order shows. No FieldValue.serverTimestamp()
/// here — that sentinel is only legal on top-level document fields, never
/// inside a list/array (which is how items are embedded on the order doc).
class OrderItem {
  final String listingId;
  final String name;
  final int price;
  final String imageUrl;
  final String sellerId;
  final String sellerName;
  final int quantity;

  const OrderItem({
    required this.listingId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    this.quantity = 1,
  });

  int get subtotal => price * quantity;

  factory OrderItem.fromCartItem(CartItem item) => OrderItem(
    listingId: item.listingId,
    name: item.name,
    price: item.price,
    imageUrl: item.imageUrl,
    sellerId: item.sellerId,
    sellerName: item.sellerName,
    quantity: item.quantity,
  );

  Map<String, dynamic> toMap() => {
    'listingId': listingId,
    'name': name,
    'price': price,
    'imageUrl': imageUrl,
    'sellerId': sellerId,
    'sellerName': sellerName,
    'quantity': quantity,
  };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    listingId: map['listingId'] ?? '',
    name: map['name'] ?? '',
    price: (map['price'] as num?)?.toInt() ?? 0,
    imageUrl: map['imageUrl'] ?? '',
    sellerId: map['sellerId'] ?? '',
    sellerName: map['sellerName'] ?? 'Dobara Seller',
    quantity: (map['quantity'] as num?)?.toInt() ?? 1,
  );
}

class Order {
  final String id;
  final String buyerId;
  final List<OrderItem> items;
  final int subtotal;
  final int deliveryFee;
  final int total;
  final String customerName;
  final String phone;
  final String address;
  final String city;
  final OrderStatus status;
  final DateTime placedAt;
  final String? trackingNumber;
  final String? courierName;
  final DateTime? statusUpdatedAt;

  const Order({
    required this.id,
    required this.buyerId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.city,
    required this.status,
    required this.placedAt,
    this.trackingNumber,
    this.courierName,
    this.statusUpdatedAt,
  });

  Order copyWith({
    OrderStatus? status,
    String? trackingNumber,
    String? courierName,
    DateTime? statusUpdatedAt,
  }) =>
      Order(
        id: id,
        buyerId: buyerId,
        items: items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        customerName: customerName,
        phone: phone,
        address: address,
        city: city,
        status: status ?? this.status,
        placedAt: placedAt,
        trackingNumber: trackingNumber ?? this.trackingNumber,
        courierName: courierName ?? this.courierName,
        statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      );

  /// sellerIds is denormalized alongside items so a future "seller order
  /// list" screen can query orders with `array-contains` on a seller's uid
  /// without reading every buyer's order.
  Map<String, dynamic> toMap() => {
    'buyerId': buyerId,
    'items': items.map((i) => i.toMap()).toList(),
    'sellerIds': items.map((i) => i.sellerId).toSet().toList(),
    'subtotal': subtotal,
    'deliveryFee': deliveryFee,
    'total': total,
    'customerName': customerName,
    'phone': phone,
    'address': address,
    'city': city,
    'status': status.name,
    'placedAt': FieldValue.serverTimestamp(),
    'trackingNumber': trackingNumber,
    'courierName': courierName,
  };

  factory Order.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data()!;
    return Order(
      id: doc.id,
      buyerId: map['buyerId'] ?? '',
      items: (map['items'] as List<dynamic>? ?? const [])
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      subtotal: (map['subtotal'] as num?)?.toInt() ?? 0,
      deliveryFee: (map['deliveryFee'] as num?)?.toInt() ?? 0,
      total: (map['total'] as num?)?.toInt() ?? 0,
      customerName: map['customerName'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      status: OrderStatus.fromValue(map['status'] ?? 'placed'),
      // serverTimestamp() resolves async — a doc read right after write
      // (e.g. from cache before the server ack) may briefly have a null
      // placedAt. Fall back to now so the UI never shows a broken date.
      placedAt: (map['placedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      trackingNumber: map['trackingNumber'] as String?,
      courierName: map['courierName'] as String?,
      statusUpdatedAt: (map['statusUpdatedAt'] as Timestamp?)?.toDate(),
    );
  }
}