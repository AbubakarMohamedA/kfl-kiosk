import 'package:kfm_kiosk/core/configuration/app_configuration.dart';
import 'package:kfm_kiosk/domain/entities/product.dart';
import 'package:kfm_kiosk/domain/entities/order.dart';
import 'package:kfm_kiosk/domain/entities/cart_item.dart';

abstract class ProductRepository {
  /// Get all products from the data source
  Future<List<Product>> getAllProducts();

  /// Get all unique categories
  Future<List<String>> getCategories();

  /// Get a specific product by ID
  Future<Product?> getProductById(String id);

  /// Get products filtered by category
  Future<List<Product>> getProductsByCategory(String category);

  /// Search products by name, brand, category, or description
  Future<List<Product>> searchProducts(String query);

  /// Get products filtered by brand
  Future<List<Product>> getProductsByBrand(String brand);

  /// Get all unique brands
  Future<List<String>> getBrands();

  /// Get products within a price range
  Future<List<Product>> getProductsByPriceRange(double minPrice, double maxPrice);
}

abstract class OrderRepository {
  Future<String> createOrder(Order order);
  Future<List<Order>> getAllOrders();
  Future<Order?> getOrderById(String id);
  Future<void> updateOrderStatus(String orderId, String status);
  Future<void> saveFullOrder(Order order); // ✅ NEW
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

abstract class ConfigurationRepository {
  Future<AppConfiguration> getConfiguration();
  Future<void> saveConfiguration(AppConfiguration configuration);
}