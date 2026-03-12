import 'package:sss/core/usecases/usecase.dart';
import 'package:sss/features/products/domain/entities/product.dart';
import 'package:sss/features/products/domain/repositories/product_repository.dart';

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

class AddProduct extends UseCase<void, Product> {
  final ProductRepository repository;

  AddProduct(this.repository);

  @override
  Future<void> call(Product product) {
    return repository.addProduct(product);
  }
}

class UpdateProduct extends UseCase<void, Product> {
  final ProductRepository repository;

  UpdateProduct(this.repository);

  @override
  Future<void> call(Product product) {
    return repository.updateProduct(product);
  }
}

class DeleteProduct extends UseCase<void, String> {
  final ProductRepository repository;

  DeleteProduct(this.repository);

  @override
  Future<void> call(String id) {
    return repository.deleteProduct(id);
  }
}