import 'package:kfm_kiosk/data/datasources/local_product_datasource.dart';
import 'package:kfm_kiosk/domain/entities/product.dart';
import 'package:kfm_kiosk/domain/repositories/repositories.dart';

class ProductRepositoryImpl implements ProductRepository {
  final LocalProductDataSource dataSource;

  ProductRepositoryImpl(this.dataSource);

  @override
  Future<List<Product>> getAllProducts() async {
    final products = await dataSource.fetchProducts();
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
    final productModel = await dataSource.getProductById(id);
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
}