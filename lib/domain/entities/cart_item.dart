import 'package:equatable/equatable.dart';
import 'product.dart';

class CartItem extends Equatable {
  final Product product;
  final int quantity;

  const CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get total => product.price * quantity;

  @override
  List<Object?> get props => [product, quantity];

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  CartItem incrementQuantity() {
    return copyWith(quantity: quantity + 1);
  }

  CartItem decrementQuantity() {
    return copyWith(quantity: quantity - 1);
  }
}