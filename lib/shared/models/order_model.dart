import 'product_model.dart';

enum OrderStatus {
  placed('Order Placed'),
  confirmed('Confirmed'),
  shipped('Shipped'),
  delivered('Delivered'),
  cancelled('Cancelled');

  final String label;
  const OrderStatus(this.label);
}

class Order {
  final String id;
  final List<Product> items;
  final int subtotal;
  final int deliveryFee;
  final int total;
  final String customerName;
  final String phone;
  final String address;
  final String city;
  final OrderStatus status;
  final DateTime placedAt;

  const Order({
    required this.id,
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
  });

  Order copyWith({OrderStatus? status}) {
    return Order(
      id: id,
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
    );
  }
}