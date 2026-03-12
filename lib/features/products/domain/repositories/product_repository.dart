import 'package:sss/features/products/domain/entities/product.dart';

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

  /// Add a new product
  Future<void> addProduct(Product product);

  /// Update an existing product
  Future<void> updateProduct(Product product);

  /// Delete a product by ID
  Future<void> deleteProduct(String id);
}
