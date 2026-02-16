import 'package:kfm_kiosk/core/config/api_config.dart';
import 'package:kfm_kiosk/features/products/data/datasources/local_product_datasource.dart';
import 'package:kfm_kiosk/features/products/data/datasources/product_remote_datasource.dart';
import 'package:kfm_kiosk/features/products/domain/entities/product.dart';
import 'package:kfm_kiosk/features/products/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final LocalProductDataSource localDataSource;
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  ProductDataSource get _dataSource => 
      ApiConfig.isMockMode ? localDataSource : remoteDataSource;


  @override
  Future<List<Product>> getAllProducts() async {
    final products = await _dataSource.fetchProducts();
    return products.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<String>> getCategories() async {
    final products = await getAllProducts();
    final categories = products.map((p) => p.category).toSet().toList();
    return ['All', ...categories];
  }

  @override
  Future<Product?> getProductById(String id) async {
    final productModel = await _dataSource.getProductById(id);
    return productModel?.toEntity();
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    final products = await getAllProducts();
    if (category == 'All') {
      return products;
    }
    return products.where((p) => p.category == category).toList();
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    final products = await getAllProducts();
    final lowercaseQuery = query.toLowerCase();
    
    return products.where((product) {
      return product.name.toLowerCase().contains(lowercaseQuery) ||
          product.brand.toLowerCase().contains(lowercaseQuery) ||
          product.category.toLowerCase().contains(lowercaseQuery) ||
          product.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  @override
  Future<List<Product>> getProductsByBrand(String brand) async {
    final products = await getAllProducts();
    return products.where((p) => p.brand == brand).toList();
  }

  @override
  Future<List<String>> getBrands() async {
    final products = await getAllProducts();
    final brands = products.map((p) => p.brand).toSet().toList();
    brands.sort(); // Sort alphabetically
    return brands;
  }

  @override
  Future<List<Product>> getProductsByPriceRange(
      double minPrice, double maxPrice) async {
    final products = await getAllProducts();
    return products
        .where((p) => p.price >= minPrice && p.price <= maxPrice)
        .toList();
  }
}