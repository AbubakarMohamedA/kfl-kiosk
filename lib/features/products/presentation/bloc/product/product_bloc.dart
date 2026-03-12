import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sss/features/products/domain/usecases/product_usecases.dart';
import 'package:sss/core/configuration/domain/repositories/configuration_repository.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetAllProducts getAllProducts;
  final GetCategories getCategories;
  final GetProductsByCategory getProductsByCategory;
  final AddProduct addProduct;
  final UpdateProduct updateProduct;
  final DeleteProduct deleteProduct;
  final ConfigurationRepository configurationRepository;

  ProductBloc({
    required this.getAllProducts,
    required this.getCategories,
    required this.getProductsByCategory,
    required this.addProduct,
    required this.updateProduct,
    required this.deleteProduct,
    required this.configurationRepository,
  }) : super(const ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<FilterProductsByCategory>(_onFilterByCategory);
    on<SearchProducts>(_onSearchProducts);
    on<LoadCategories>(_onLoadCategories);
    on<AddProductEvent>(_onAddProduct);
    on<UpdateProductEvent>(_onUpdateProduct);
    on<DeleteProductEvent>(_onDeleteProduct);
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

  Future<void> _onAddProduct(
    AddProductEvent event,
    Emitter<ProductState> emit,
  ) async {
    try {
      final config = await configurationRepository.getConfiguration();
      // Ensure the product gets the correct enterprise scoping
      final productWithScope = event.product.copyWith(
        tenantId: config.tenantId,
        branchId: config.tierId == 'enterprise' ? config.branchId : null,
      );
      
      await addProduct(productWithScope);
      add(const LoadProducts()); // Reload products after adding
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onUpdateProduct(
    UpdateProductEvent event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await updateProduct(event.product);
      add(const LoadProducts()); // Reload products after updating
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProductEvent event,
    Emitter<ProductState> emit,
  ) async {
    try {
      await deleteProduct(event.productId);
      add(const LoadProducts()); // Reload products after deleting
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}