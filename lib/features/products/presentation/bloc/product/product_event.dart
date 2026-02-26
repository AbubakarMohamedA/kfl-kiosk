import 'package:equatable/equatable.dart';
import 'package:kfm_kiosk/features/products/domain/entities/product.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {
  const LoadProducts();
}

class FilterProductsByCategory extends ProductEvent {
  final String category;

  const FilterProductsByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class SearchProducts extends ProductEvent {
  final String query;

  const SearchProducts(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadCategories extends ProductEvent {
  const LoadCategories();
}

class AddProductEvent extends ProductEvent {
  final Product product;

  const AddProductEvent(this.product);

  @override
  List<Object?> get props => [product];
}

class UpdateProductEvent extends ProductEvent {
  final Product product;

  const UpdateProductEvent(this.product);

  @override
  List<Object?> get props => [product];
}

class DeleteProductEvent extends ProductEvent {
  final String productId;

  const DeleteProductEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}