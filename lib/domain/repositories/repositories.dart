import 'package:kfm_kiosk/domain/entities/product.dart';
import 'package:kfm_kiosk/domain/entities/order.dart';
import 'package:kfm_kiosk/domain/entities/cart_item.dart';

abstract class ProductRepository {
  Future<List<Product>> getAllProducts();
  Future<List<Product>> getProductsByCategory(String category);
  Future<List<String>> getCategories();
  Future<Product?> getProductById(String id);
}

abstract class OrderRepository {
  Future<String> createOrder(Order order);
  Future<List<Order>> getAllOrders();
  Future<Order?> getOrderById(String id);
  Future<void> updateOrderStatus(String orderId, String status);
  Future<int> getOrderCounter();
  Future<void> incrementOrderCounter();
  Stream<List<Order>> watchOrders();
}

abstract class CartRepository {
  Future<void> addToCart(CartItem item);
  Future<void> removeFromCart(String productId);
  Future<void> updateQuantity(String productId, int quantity);
  Future<List<CartItem>> getCartItems();
  Future<void> clearCart();
  Future<double> getCartTotal();
}

abstract class PaymentRepository {
  Future<bool> processPayment({
    required String phoneNumber,
    required double amount,
    required String orderId,
  });
  Future<String> getPaymentStatus(String transactionId);
}