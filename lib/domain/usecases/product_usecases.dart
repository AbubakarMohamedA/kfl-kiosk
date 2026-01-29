import 'package:kfm_kiosk/core/usecases/usecase.dart';
import 'package:kfm_kiosk/domain/entities/product.dart';
import 'package:kfm_kiosk/domain/repositories/repositories.dart';

class GetAllProducts extends UseCaseNoParams<List<Product>> {
  final ProductRepository repository;

  GetAllProducts(this.repository);

  @override
  Future<List<Product>> call() {
    return repository.getAllProducts();
  }
}

class GetProductsByCategory extends UseCase<List<Product>, String> {
  final ProductRepository repository;

  GetProductsByCategory(this.repository);

  @override
  Future<List<Product>> call(String category) {
    return repository.getProductsByCategory(category);
  }
}

class GetCategories extends UseCaseNoParams<List<String>> {
  final ProductRepository repository;

  GetCategories(this.repository);

  @override
  Future<List<String>> call() {
    return repository.getCategories();
  }
}

class GetProductById extends UseCase<Product?, String> {
  final ProductRepository repository;

  GetProductById(this.repository);

  @override
  Future<Product?> call(String id) {
    return repository.getProductById(id);
  }
}