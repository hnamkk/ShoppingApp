import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      quantity: map['quantity'] ?? 0,
    );
  }
}

class Order {
  final String? orderId;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final double subtotalAmount;
  final double discount;
  final String? voucherCode;
  final String? voucherId;
  final String deliveryAddress;
  final String note;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;

  Order({
    this.orderId,
    required this.userId,
    required this.items,
    required this.totalAmount,
    double? subtotalAmount,
    this.discount = 0,
    this.voucherCode,
    this.voucherId,
    required this.deliveryAddress,
    this.note = '',
    required this.paymentMethod,
    this.status = 'pending',
    DateTime? createdAt,
  })  : subtotalAmount = subtotalAmount ?? totalAmount + discount,
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'subtotalAmount': subtotalAmount,
      'discount': discount,
      'voucherCode': voucherCode,
      'voucherId': voucherId,
      'deliveryAddress': deliveryAddress,
      'note': note,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Order.fromMap(String id, Map<String, dynamic> map) {
    return Order(
      orderId: id,
      userId: map['userId'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      subtotalAmount: (map['subtotalAmount'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      voucherCode: map['voucherCode'],
      voucherId: map['voucherId'],
      deliveryAddress: map['deliveryAddress'] ?? '',
      note: map['note'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
