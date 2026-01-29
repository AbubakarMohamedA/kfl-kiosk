import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/domain/usecases/product_usecases.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetAllProducts getAllProducts;
  final GetCategories getCategories;
  final GetProductsByCategory getProductsByCategory;

  ProductBloc({
    required this.getAllProducts,
    required this.getCategories,
    required this.getProductsByCategory,
  }) : super(const ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<FilterProductsByCategory>(_onFilterByCategory);
    on<SearchProducts>(_onSearchProducts);
    on<LoadCategories>(_onLoadCategories);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    try {
      final products = await getAllProducts();
      final categories = await getCategories();

      emit(ProductLoaded(
        products: products,
        filteredProducts: products,
        categories: categories,
        selectedCategory: 'All',
      ));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onFilterByCategory(
    FilterProductsByCategory event,
    Emitter<ProductState> emit,
  ) async {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      try {
        final filtered = await getProductsByCategory(event.category);
        emit(currentState.copyWith(
          filteredProducts: filtered,
          selectedCategory: event.category,
        ));
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    }
  }

  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<ProductState> emit,
  ) async {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      final query = event.query.toLowerCase();

      final filtered = currentState.products.where((product) {
        return product.name.toLowerCase().contains(query) ||
            product.brand.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query);
      }).toList();

      emit(currentState.copyWith(
        filteredProducts: filtered,
      ));
    }
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<ProductState> emit,
  ) async {
    try {
      final categories = await getCategories();
      if (state is ProductLoaded) {
        final currentState = state as ProductLoaded;
        emit(currentState.copyWith(categories: categories));
      }
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}