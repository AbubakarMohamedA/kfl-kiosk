import 'package:flutter/foundation.dart';
import 'package:sss/core/config/api_config.dart';
import 'package:sss/features/products/data/datasources/local_product_datasource.dart';
import 'package:sss/features/products/data/datasources/product_remote_datasource.dart';
import 'package:sss/features/products/domain/entities/product.dart';
import 'package:sss/features/products/domain/repositories/product_repository.dart';
import 'package:sss/features/products/data/datasources/sap_product_datasource.dart';
import 'package:sss/features/products/data/models/product_model.dart';
import 'package:sss/features/auth/domain/repositories/auth_repository.dart';
import 'package:sss/core/configuration/domain/repositories/configuration_repository.dart';
import 'package:sss/core/database/daos/app_config_dao.dart';
import 'package:sss/core/services/sap_auth_service.dart';
import 'package:sss/di/injection.dart';

class ProductRepositoryImpl implements ProductRepository {
  final LocalProductDataSource localDataSource;
  final ProductRemoteDataSource remoteDataSource;
  final SapProductDataSource sapDataSource;
  final AuthRepository authRepository;
  final ConfigurationRepository configRepository;

  // ✅ Cache resolved datasource — avoids re-evaluating on every call
  ProductDataSource? _resolvedDataSource;

  ProductRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.sapDataSource,
    required this.authRepository,
    required this.configRepository,
  });

  // ─── Get Tenant ID ────────────────────────────────────────────────────────

  Future<String?> _getTenantId() async {
    final tenant = await authRepository.getCurrentTenant();
    if (tenant != null) return tenant.id;
    final config = await configRepository.getConfiguration();
    return config.tenantId;
  }

  // ─── Resolve DataSource ───────────────────────────────────────────────────

  Future<ProductDataSource> get _dataSource async {
    if (_resolvedDataSource != null) {
      debugPrint(
        'ProductRepository → using cached DataSource: '
        '${_resolvedDataSource.runtimeType}',
      );
      return _resolvedDataSource!;
    }

    // 1. SAP configured?
    final sapAuth = getIt<SapAuthService>();
    final isSapConfigured = await sapAuth.isConfigured();

    if (isSapConfigured) {
      debugPrint('ProductRepository → using SapProductDataSource');
      _resolvedDataSource = sapDataSource;
      return _resolvedDataSource!;
    }

    // 2. Tenant-level SAP override
    final tenantId = await _getTenantId();

    if (tenantId != null) {
      final appConfigDao = getIt<AppConfigDao>();
      final isSapEnabled =
          await appConfigDao.getValue('sap_enabled_$tenantId') == 'true';

      if (isSapEnabled) {
        debugPrint('ProductRepository → SAP enabled via AppConfig');
        _resolvedDataSource = sapDataSource;
        return _resolvedDataSource!;
      }

      // 3. Tenant tier
      final currentTenant = await authRepository.getCurrentTenant();
      if (currentTenant != null) {
        debugPrint('ProductRepository → tenant tier: ${currentTenant.tierId}');

        switch (currentTenant.tierId) {
          case 'enterprise':
            debugPrint(
              'ProductRepository → enterprise, SAP not configured yet, '
              'using localDataSource (NOT caching — SAP may be configured soon)',
            );
            // ✅ DO NOT cache for enterprise without SAP
            // so next call re-evaluates after SAP login
            return localDataSource;

          case 'alone':
            debugPrint('ProductRepository → alone tier, using localDataSource');
            _resolvedDataSource = localDataSource;
            return _resolvedDataSource!;

          default:
            break;
        }
      }
    }

    // 4. Default fallback
    if (ApiConfig.isMockMode) {
      debugPrint('ProductRepository → mock mode, using localDataSource');
      _resolvedDataSource = localDataSource;
      return _resolvedDataSource!;
    }

    debugPrint('ProductRepository → using remoteDataSource');
    _resolvedDataSource = remoteDataSource;
    return _resolvedDataSource!;
  }

  @override
  void invalidateDataSource() {
    _resolvedDataSource = null;
    sapDataSource.clearCache();
    debugPrint('ProductRepository → dataSource cache invalidated');
  }

  // ─── Get All Products ─────────────────────────────────────────────────────

  @override
  Future<List<Product>> getAllProducts() async {
    try {
      final dataSource = await _dataSource;
      final tenantId = await _getTenantId();

      debugPrint('ProductRepository.getAllProducts → tenantId: $tenantId');

      final products = await dataSource.fetchProducts(tenantId: tenantId);

      debugPrint(
        'ProductRepository.getAllProducts → fetched ${products.length} products',
      );

      return products.map((model) => model.toEntity()).toList();
    } catch (e) {
      debugPrint('ProductRepository.getAllProducts ERROR: $e');
      rethrow;
    }
  }

  // ─── Get Categories ───────────────────────────────────────────────────────

  @override
  Future<List<String>> getCategories() async {
    final products = await getAllProducts();
    final categories =
        products.map((p) => p.category).toSet().toList()..sort();
    return ['All', ...categories];
  }

  // ─── Get Product By ID ────────────────────────────────────────────────────

  @override
  Future<Product?> getProductById(String id) async {
    try {
      final dataSource = await _dataSource;
      final productModel = await dataSource.getProductById(id);
      return productModel?.toEntity();
    } catch (e) {
      debugPrint('ProductRepository.getProductById ERROR: $e');
      rethrow;
    }
  }

  // ─── Get Products By Category ─────────────────────────────────────────────

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    final products = await getAllProducts();
    if (category == 'All') return products;
    return products.where((p) => p.category == category).toList();
  }

  // ─── Search Products ──────────────────────────────────────────────────────

  @override
  Future<List<Product>> searchProducts(String query) async {
    final products = await getAllProducts();
    final q = query.toLowerCase();
    return products.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();
  }

  // ─── Get Products By Brand ────────────────────────────────────────────────

  @override
  Future<List<Product>> getProductsByBrand(String brand) async {
    final products = await getAllProducts();
    return products.where((p) => p.brand == brand).toList();
  }

  // ─── Get Brands ───────────────────────────────────────────────────────────

  @override
  Future<List<String>> getBrands() async {
    final products = await getAllProducts();
    final brands = products.map((p) => p.brand).toSet().toList()..sort();
    return brands;
  }

  // ─── Get Products By Price Range ──────────────────────────────────────────

  @override
  Future<List<Product>> getProductsByPriceRange(
    double minPrice,
    double maxPrice,
  ) async {
    final products = await getAllProducts();
    return products
        .where((p) => p.price >= minPrice && p.price <= maxPrice)
        .toList();
  }

  // ─── Add Product ──────────────────────────────────────────────────────────

  @override
  Future<void> addProduct(Product product) async {
    try {
      final dataSource = await _dataSource;
      final tenantId = await _getTenantId();
      final productWithTenant = product.copyWith(tenantId: tenantId);
      final productModel = ProductModel.fromEntity(productWithTenant);

      debugPrint(
        'ProductRepository.addProduct → id: ${product.id}, '
        'source: ${dataSource.runtimeType}',
      );

      await dataSource.addProduct(productModel);
    } catch (e) {
      debugPrint('ProductRepository.addProduct ERROR: $e');
      rethrow;
    }
  }

  // ─── Update Product ───────────────────────────────────────────────────────

  @override
  Future<void> updateProduct(Product product) async {
    try {
      final dataSource = await _dataSource;
      final tenantId = await _getTenantId();
      final productWithTenant = product.copyWith(tenantId: tenantId);
      final productModel = ProductModel.fromEntity(productWithTenant);

      debugPrint(
        'ProductRepository.updateProduct → id: ${product.id}, '
        'source: ${dataSource.runtimeType}',
      );

      await dataSource.updateProduct(productModel);
    } catch (e) {
      debugPrint('ProductRepository.updateProduct ERROR: $e');
      rethrow;
    }
  }

  // ─── Delete Product ───────────────────────────────────────────────────────

  @override
  Future<void> deleteProduct(String id) async {
    try {
      final dataSource = await _dataSource;

      debugPrint(
        'ProductRepository.deleteProduct → id: $id, '
        'source: ${dataSource.runtimeType}',
      );

      await dataSource.deleteProduct(id);
    } catch (e) {
      debugPrint('ProductRepository.deleteProduct ERROR: $e');
      rethrow;
    }
  }

  // ─── Cache Local Image ────────────────────────────────────────────────────

  @override
  void cacheLocalImage(String productId, String imageUrl) {
    if (_resolvedDataSource == sapDataSource) {
      sapDataSource.updateLocalImage(productId, imageUrl);
      debugPrint('ProductRepository.cacheLocalImage → SAP Cache Updated: $productId');
    }
  }
}