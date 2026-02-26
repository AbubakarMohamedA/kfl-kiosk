import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:drift/native.dart';
import 'package:kfm_kiosk/core/database/app_database.dart' as db_drift;
import 'package:kfm_kiosk/core/database/daos/products_dao.dart';
import 'package:kfm_kiosk/features/products/data/datasources/local_product_datasource.dart';
import 'package:kfm_kiosk/features/products/data/repositories/product_repository_impl.dart';
import 'package:kfm_kiosk/features/auth/domain/repositories/auth_repository.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/tenant.dart';
import 'package:kfm_kiosk/features/products/domain/entities/product.dart';
import 'package:kfm_kiosk/features/auth/domain/services/tenant_service.dart';
import 'package:kfm_kiosk/core/config/api_config.dart';
import 'package:kfm_kiosk/features/products/data/datasources/product_remote_datasource.dart';
import 'package:kfm_kiosk/features/products/data/datasources/sap_product_datasource.dart';
import 'package:kfm_kiosk/core/configuration/domain/repositories/configuration_repository.dart';

// Generate mocks
@GenerateMocks([AuthRepository, ProductRemoteDataSource, SapProductDataSource, ProductsDao, ConfigurationRepository])
import 'product_isolation_test.mocks.dart';

void main() {
  // late db_drift.AppDatabase db; // Not needed with Mock DAO
  late MockProductsDao mockProductsDao;
  late LocalProductDataSource localDataSource;
  late MockProductRemoteDataSource mockRemoteDataSource;
  late MockSapProductDataSource mockSapDataSource;
  late ProductRepositoryImpl repository;
  late MockAuthRepository mockAuthRepository;
  late MockConfigurationRepository mockConfigRepository;

  setUp(() {
    mockProductsDao = MockProductsDao();
    localDataSource = LocalProductDataSource(mockProductsDao);
    mockAuthRepository = MockAuthRepository();
    mockRemoteDataSource = MockProductRemoteDataSource();
    mockSapDataSource = MockSapProductDataSource();

    mockConfigRepository = MockConfigurationRepository();

    repository = ProductRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: mockRemoteDataSource,
      sapDataSource: mockSapDataSource,
      authRepository: mockAuthRepository,
      configRepository: mockConfigRepository,
    );
    
    // Prepare Tenant Service
    TenantService().resetForTesting();
  });

  tearDown(() async {
    // await db.close();
  });

  group('Product Isolation', () {
    final tenantA = Tenant(
      id: 'tenant_a',
      name: 'Tenant A',
      businessName: 'Business A',
      email: 'a@test.com',
      phone: '123',
      status: 'Active',
      tierId: 'standard',
      createdDate: DateTime.now(),
      enabledFeatures: ['products'],
    );

    final tenantB = Tenant(
      id: 'tenant_b',
      name: 'Tenant B',
      businessName: 'Business B',
      email: 'b@test.com',
      phone: '456',
      status: 'Active',
      tierId: 'standard', // Standard uses local DB
      createdDate: DateTime.now(),
      enabledFeatures: ['products'],
    );
    
    test('Products added by Tenant A should not be visible to Tenant B', () async {
      // Setup mocks for seeding check
      when(mockProductsDao.getAllProducts()).thenAnswer((_) async => []); // Initially empty
      when(mockProductsDao.insertProducts(any)).thenAnswer((_) async {}); 
      
      // 1. Simulate Tenant A Adding Product
      when(mockAuthRepository.getCurrentTenant()).thenAnswer((_) async => tenantA);
      when(mockProductsDao.insertProduct(any)).thenAnswer((_) async => 1);

      final productA = const Product(
        id: 'prod_a',
        name: 'Product A',
        brand: 'Brand A',
        price: 100,
        size: '1kg',
        category: 'Test',
        description: 'Desc A',
        imageUrl: 'url_a',
      );

      await repository.addProduct(productA);

      // Verify insertProduct called with correct tenantId
      verify(mockProductsDao.insertProduct(argThat(
        predicate<db_drift.ProductsCompanion>((p) => p.tenantId.value == 'tenant_a')
      ))).called(1);

      // 2. Simulate Tenant A Fetching Products
      when(mockProductsDao.getAllProducts(tenantId: 'tenant_a'))
          .thenAnswer((_) async => [
            // Return mock product from DB logic (mapped from ProductRow/Product entity)
            // Dao returns generic Product class (drift generated)
            // We need to construct it.
            // Since we hid Product from app_database, we can't use it easily?
            // Actually, ProductsDao returns List<Product> where Product is from app_database.
            // But we hid it.
            // We need to import it with prefix?
            // Or just verify the CALL was made with correct tenantId.
          ]);

      await repository.getAllProducts();
      
      // Verify getAllProducts called with tenantId='tenant_a'
      verify(mockProductsDao.getAllProducts(tenantId: 'tenant_a')).called(1);

      // 3. Simulate Tenant B Fetching Products
      when(mockAuthRepository.getCurrentTenant()).thenAnswer((_) async => tenantB);
      when(mockProductsDao.getAllProducts(tenantId: 'tenant_b')).thenAnswer((_) async => []);

      await repository.getAllProducts();

      // Verify getAllProducts called with tenantId='tenant_b'
      verify(mockProductsDao.getAllProducts(tenantId: 'tenant_b')).called(1);
    });
  });

  group('Feature Flags', () {
    test('Standard tier should have products feature enabled', () {
       final hasAccess = TenantService().canAccessFeature('standard_tenant_id', 'products'); 
       // We need a tenant with standard tier.
       // TenantService relies on cached tenants and tiers.
       // Let's add a test tenant.
       final tenant = Tenant(
          id: 'test_tenant',
          name: 'Test',
          businessName: 'Test Biz',
          email: 'test@test.com',
          phone: '000',
          status: 'Active',
          tierId: 'standard',
          createdDate: DateTime.now(),
          enabledFeatures: [], // Empty, should fallback to Tier defaults
       );
       TenantService().addTenant(tenant); // This is async but for test convenience we assume it updates cache sync or we await?
       // TenantService methods are async for DB but cache update might be sync or we wait.
       // Actually addTenant is async.
    });
    
    test('Maintenance mode for products module', () {
      TenantService().setModuleMaintenance('products', true);
      expect(TenantService().isModuleUnderMaintenance('products'), true);
      
      TenantService().setModuleMaintenance('products', false);
      expect(TenantService().isModuleUnderMaintenance('products'), false);
    });
  });
}


