import 'package:sss/core/usecases/usecase.dart';
import 'package:sss/features/cart/domain/entities/cart_item.dart';
import 'package:sss/features/cart/domain/repositories/cart_repository.dart';

class AddToCart extends UseCase<void, CartItem> {
  final CartRepository repository;

  AddToCart(this.repository);

  @override
  Future<void> call(CartItem item) {
    return repository.addToCart(item);
  }
}

class RemoveFromCart extends UseCase<void, String> {
  final CartRepository repository;

  RemoveFromCart(this.repository);

  @override
  Future<void> call(String productId) {
    return repository.removeFromCart(productId);
  }
}

class UpdateCartQuantity extends UseCase<void, UpdateQuantityParams> {
  final CartRepository repository;

  UpdateCartQuantity(this.repository);

  @override
  Future<void> call(UpdateQuantityParams params) {
    return repository.updateQuantity(params.productId, params.quantity);
  }
}

class GetCartItems extends UseCaseNoParams<List<CartItem>> {
  final CartRepository repository;

  GetCartItems(this.repository);

  @override
  Future<List<CartItem>> call() {
    return repository.getCartItems();
  }
}

class ClearCart extends UseCaseNoParams<void> {
  final CartRepository repository;

  ClearCart(this.repository);

  @override
  Future<void> call() {
    return repository.clearCart();
  }
}

class GetCartTotal extends UseCaseNoParams<double> {
  final CartRepository repository;

  GetCartTotal(this.repository);

  @override
  Future<double> call() {
    return repository.getCartTotal();
  }
}

class UpdateQuantityParams {
  final String productId;
  final int quantity;

  UpdateQuantityParams({
    required this.productId,
    required this.quantity,
  });
}