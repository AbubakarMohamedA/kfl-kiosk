import 'package:kfm_kiosk/core/config/api_config.dart';
import 'package:kfm_kiosk/features/products/data/datasources/local_product_datasource.dart';
import 'package:kfm_kiosk/features/products/data/datasources/product_remote_datasource.dart';
import 'package:kfm_kiosk/features/products/domain/entities/product.dart';
import 'package:kfm_kiosk/features/products/domain/repositories/product_repository.dart';
import 'package:kfm_kiosk/features/products/data/datasources/sap_product_datasource.dart';
import 'package:kfm_kiosk/features/products/data/models/product_model.dart';
import 'package:kfm_kiosk/features/auth/domain/repositories/auth_repository.dart';
import 'package:kfm_kiosk/core/configuration/domain/repositories/configuration_repository.dart';
import 'package:kfm_kiosk/core/database/daos/app_config_dao.dart';
import 'package:kfm_kiosk/di/injection.dart';

class ProductRepositoryImpl implements ProductRepository {
  final LocalProductDataSource localDataSource;
  final ProductRemoteDataSource remoteDataSource;
  final SapProductDataSource sapDataSource;
  final AuthRepository authRepository;
  final ConfigurationRepository configRepository; // NEW

  ProductRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.sapDataSource,
    required this.authRepository,
    required this.configRepository,
  });

  Future<String?> _getTenantId() async {
    final tenant = await authRepository.getCurrentTenant();
    if (tenant != null) return tenant.id;
    
    // Fallback to configuration (for mobile/tablet zero-login sync)
    final config = await configRepository.getConfiguration();
    return config.tenantId;
  }

  Future<ProductDataSource> get _dataSource async {
    final tenantId = await _getTenantId();

    if (tenantId != null) {
      // 1. Check AppConfig for custom SAP override
      final appConfigDao = getIt<AppConfigDao>();
      final isSapEnabled = await appConfigDao.getValue('sap_enabled_$tenantId') == 'true';
      if (isSapEnabled) {
        return sapDataSource;
      }

      // 2. Check tenant tier defaults
      final currentTenant = await authRepository.getCurrentTenant();
      if (currentTenant != null) {
        if (currentTenant.tierId == 'enterprise') return sapDataSource;
        if (currentTenant.tierId == 'alone') return localDataSource;
      }
    }

    return ApiConfig.isMockMode ? localDataSource : remoteDataSource;
  }


  @override
  Future<List<Product>> getAllProducts() async {
    final dataSource = await _dataSource;
    final tenantId = await _getTenantId();
    final products = await dataSource.fetchProducts(tenantId: tenantId);
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
    final dataSource = await _dataSource;
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

  @override
  Future<void> addProduct(Product product) async {
    final dataSource = await _dataSource;
    final tenantId = await _getTenantId();
    final productWithTenant = product.copyWith(tenantId: tenantId);
    final productModel = ProductModel.fromEntity(productWithTenant);
    await dataSource.addProduct(productModel);
  }

  @override
  Future<void> updateProduct(Product product) async {
    final dataSource = await _dataSource;
    final tenantId = await _getTenantId();
    // Ensure we don't lose the original tenantId if it exists, or enforce current?
    // Enforcing current is safer for multi-tenant isolation, 
    // effectively "taking ownership" or ensuring no cross-tenant update.
    final productWithTenant = product.copyWith(tenantId: tenantId);
    final productModel = ProductModel.fromEntity(productWithTenant);
    await dataSource.updateProduct(productModel);
  }

  @override
  Future<void> deleteProduct(String id) async {
    final dataSource = await _dataSource;
    await dataSource.deleteProduct(id);
  }
}