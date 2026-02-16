import 'package:equatable/equatable.dart';
import 'package:kfm_kiosk/features/products/domain/entities/product.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';

class CartItem extends Equatable {
  final Product product;
  final int quantity;
  final String status;

  const CartItem({
    required this.product,
    required this.quantity,
    this.status = AppConstants.statusPaid,
  });

  double get subtotal => product.price * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    String? status,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
    );
  }

  CartItem incrementQuantity() {
    return copyWith(quantity: quantity + 1);
  }

  CartItem decrementQuantity() {
    if (quantity > 1) {
      return copyWith(quantity: quantity - 1);
    }
    return this;
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(),
      'quantity': quantity,
      'status': status,
    };
  }

  // Create from Firestore map
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      product: Product.fromMap(map['product'] as Map<String, dynamic>),
      quantity: map['quantity'] ?? 1,
      status: map['status'] ?? AppConstants.statusPaid,
    );
  }

  @override
  List<Object?> get props => [product, quantity, status];

  @override
  String toString() {
    return 'CartItem(product: ${product.name}, quantity: $quantity, subtotal: $subtotal, status: $status)';
  }
}