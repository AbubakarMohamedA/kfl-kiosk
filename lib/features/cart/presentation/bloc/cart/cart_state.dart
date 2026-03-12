import 'package:equatable/equatable.dart';
import 'package:sss/features/cart/domain/entities/cart_item.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {
  const CartInitial();
}

class CartLoading extends CartState {
  const CartLoading();
}

class CartLoaded extends CartState {
  final List<CartItem> items;
  final double total;
  final int itemCount;

  const CartLoaded({
    required this.items,
    required this.total,
    required this.itemCount,
  });

  @override
  List<Object?> get props => [items, total, itemCount];

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  CartLoaded copyWith({
    List<CartItem>? items,
    double? total,
    int? itemCount,
  }) {
    return CartLoaded(
      items: items ?? this.items,
      total: total ?? this.total,
      itemCount: itemCount ?? this.itemCount,
    );
  }
}

class CartEmpty extends CartState {
  const CartEmpty();
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}

class CartItemAdded extends CartState {
  final String productName;

  const CartItemAdded(this.productName);

  @override
  List<Object?> get props => [productName];
}

class CartItemRemoved extends CartState {
  final String productName;

  const CartItemRemoved(this.productName);

  @override
  List<Object?> get props => [productName];
}