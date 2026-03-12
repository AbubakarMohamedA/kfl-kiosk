import 'package:sss/features/cart/domain/entities/cart_item.dart';

abstract class CartRepository {
  Future<void> addToCart(CartItem item);
  Future<void> removeFromCart(String productId);
  Future<void> updateQuantity(String productId, int quantity);
  Future<List<CartItem>> getCartItems();
  Future<void> clearCart();
  Future<double> getCartTotal();
}
