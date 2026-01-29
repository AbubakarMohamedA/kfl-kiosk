import 'package:equatable/equatable.dart';
import 'cart_item.dart';

class Order extends Equatable {
  final String id;
  final List<CartItem> items;
  final double total;
  final String phone;
  final DateTime timestamp;
  final String status;

  const Order({
    required this.id,
    required this.items,
    required this.total,
    required this.phone,
    required this.timestamp,
    required this.status,
  });

  @override
  List<Object?> get props => [id, items, total, phone, timestamp, status];

  Order copyWith({
    String? id,
    List<CartItem>? items,
    double? total,
    String? phone,
    DateTime? timestamp,
    String? status,
  }) {
    return Order(
      id: id ?? this.id,
      items: items ?? this.items,
      total: total ?? this.total,
      phone: phone ?? this.phone,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}