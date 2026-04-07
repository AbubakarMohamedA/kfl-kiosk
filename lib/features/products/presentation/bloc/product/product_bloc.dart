import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sss/features/products/data/models/price_model.dart';
import 'package:sss/features/products/domain/usecases/product_usecases.dart';
import 'package:sss/core/configuration/domain/repositories/configuration_repository.dart';
import 'package:sss/di/injection.dart';
import 'package:sss/features/products/domain/repositories/product_repository.dart';
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
    on<UpdateProductImageLocalEvent>(_onUpdateProductImageLocal);
    on<ApplyCustomerPricing>(_onApplyCustomerPricing);
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
      final productWithScope = event.product.copyWith(
        tenantId: config.tenantId,
        branchId: config.tierId == 'enterprise' ? config.branchId : null,
      );

      await addProduct(productWithScope);
      add(const LoadProducts());
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
      add(const LoadProducts());
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
      add(const LoadProducts());
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  // ✅ Local-only image update — never touches SAP, never triggers a fetch.
  // Updates the in-memory product list directly so the UI reflects the new
  // image instantly without killing the SAP session.
  Future<void> _onUpdateProductImageLocal(
    UpdateProductImageLocalEvent event,
    Emitter<ProductState> emit,
  ) async {
    // ✅ Make SAP Data Source aware of the uploaded image
    getIt<ProductRepository>().cacheLocalImage(event.productId, event.imageUrl);

    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;

      final updatedProducts = currentState.products.map((p) {
        return p.id == event.productId
            ? p.copyWith(imageUrl: event.imageUrl)
            : p;
      }).toList();

      final updatedFiltered = currentState.filteredProducts.map((p) {
        return p.id == event.productId
            ? p.copyWith(imageUrl: event.imageUrl)
            : p;
      }).toList();

      emit(currentState.copyWith(
        products: updatedProducts,
        filteredProducts: updatedFiltered,
      ));
    }
  }

  Future<void> _onApplyCustomerPricing(
    ApplyCustomerPricing event,
    Emitter<ProductState> emit,
  ) async {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      
      try {
        final repository = getIt<ProductRepository>();
        final priceListNum = await repository.getCustomerPriceListNum();
        final specialPrices = await repository.getCustomerSpecialPrices();

        final updatedProducts = currentState.products.map((product) {
          double newPrice = product.price;

          if (specialPrices.containsKey(product.id) && specialPrices[product.id]! > 0) {
            newPrice = specialPrices[product.id]!;
          } else if (priceListNum != null && product.itemPrices.isNotEmpty) {
            final targetPrice = product.itemPrices.firstWhere(
              (p) => p.priceList == priceListNum,
              orElse: () => const PriceModel(priceList: -1, price: 0.0),
            );
            if (targetPrice.priceList != -1 && targetPrice.price > 0) {
              newPrice = targetPrice.price;
            }
          }
          
          return product.copyWith(price: newPrice);
        }).toList();

        final updatedFiltered = currentState.filteredProducts.map((product) {
           final baseProduct = updatedProducts.firstWhere(
             (p) => p.id == product.id, 
             orElse: () => product,
           );
           return baseProduct;
        }).toList();

        emit(currentState.copyWith(
          products: updatedProducts,
          filteredProducts: updatedFiltered,
        ));
      } catch (e) {
        debugPrint('ProductBloc.ApplyCustomerPricing ERROR: ');
      }
    }
  }
}
