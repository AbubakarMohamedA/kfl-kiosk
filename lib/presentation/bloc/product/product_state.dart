import 'package:equatable/equatable.dart';
import 'package:kfm_kiosk/domain/entities/product.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {
  const ProductInitial();
}

class ProductLoading extends ProductState {
  const ProductLoading();
}

class ProductLoaded extends ProductState {
  final List<Product> products;
  final List<Product> filteredProducts;
  final List<String> categories;
  final String selectedCategory;

  const ProductLoaded({
    required this.products,
    required this.filteredProducts,
    required this.categories,
    this.selectedCategory = 'All',
  });

  @override
  List<Object?> get props => [products, filteredProducts, categories, selectedCategory];

  ProductLoaded copyWith({
    List<Product>? products,
    List<Product>? filteredProducts,
    List<String>? categories,
    String? selectedCategory,
  }) {
    return ProductLoaded(
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}