// ignore_for_file: unused_local_variable

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sss/features/products/data/repositories/product_repository_impl.dart';
import 'package:sss/features/products/data/datasources/local_product_datasource.dart';
import 'package:sss/features/products/data/datasources/product_remote_datasource.dart';
import 'package:sss/features/products/data/datasources/sap_product_datasource.dart';
import 'package:sss/features/auth/domain/repositories/auth_repository.dart';
import 'package:sss/core/configuration/domain/repositories/configuration_repository.dart';
import 'package:sss/core/configuration/domain/entities/app_configuration.dart';
import 'package:sss/features/auth/domain/entities/tenant.dart';
import 'package:sss/features/products/data/models/product_model.dart';
import 'package:sss/core/config/api_config.dart';

import 'product_repository_source_test.mocks.dart';

@GenerateMocks([
  LocalProductDataSource,
  ProductRemoteDataSource,
  SapProductDataSource,
  AuthRepository,
  ConfigurationRepository
])
void main() {
  late ProductRepositoryImpl repository;
  late MockLocalProductDataSource mockLocalDataSource;
  late MockProductRemoteDataSource mockRemoteDataSource;
  late MockSapProductDataSource mockSapDataSource;
  late MockAuthRepository mockAuthRepository;
  late MockConfigurationRepository mockConfigRepository;

  setUp(() {
    mockLocalDataSource = MockLocalProductDataSource();
    mockRemoteDataSource = MockProductRemoteDataSource();
    mockSapDataSource = MockSapProductDataSource();
    mockAuthRepository = MockAuthRepository();

    mockConfigRepository = MockConfigurationRepository();

    repository = ProductRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      sapDataSource: mockSapDataSource,
      authRepository: mockAuthRepository,
      configRepository: mockConfigRepository,
    );
  });

  final tStandardTenant = Tenant(
    id: 'standard_tenant',
    name: 'Standard Tenant',
    businessName: 'Standard Biz',
    email: 'standard@test.com',
    phone: '1234567890',
    status: 'Active',
    tierId: 'standard', // Important
    createdDate: DateTime(2023, 1, 1), 
    lastLogin: null,
    ordersCount: 0,
    revenue: 0,
    isMaintenanceMode: false,
    enabledFeatures: [],
  );

  final tEnterpriseTenant = Tenant(
    id: 'ent_tenant',
    name: 'Enterprise Tenant',
    businessName: 'Enterprise Biz',
    email: 'ent@test.com',
    phone: '0987654321',
    status: 'Active',
    tierId: 'enterprise', // Important
    createdDate: DateTime(2023, 1, 1), 
    lastLogin: null,
    ordersCount: 0,
    revenue: 0,
    isMaintenanceMode: false,
    enabledFeatures: [],
  );

  final tProductModel = ProductModel(
    id: '1',
    name: 'Test Product',
    brand: 'Test Brand',
    price: 100,
    size: '1kg',
    category: 'Test',
    description: 'Desc',
    imageUrl: 'img.png',
  );

  group('ProductRepositoryImpl Data Source Switching', () {
    test('should use LocalProductDataSource when tenant is Standard and MockMode is true', () async {
      // Arrange
      ApiConfig.setFlavor(AppFlavor.mock); // Force mock mode (default usually)
      when(mockAuthRepository.getCurrentTenant())
          .thenAnswer((_) async => tStandardTenant);
      when(mockLocalDataSource.fetchProducts())
          .thenAnswer((_) async => [tProductModel]);

      // Act
      final result = await repository.getAllProducts();

      // Assert
      verify(mockAuthRepository.getCurrentTenant());
      verify(mockConfigRepository.getConfiguration()); // Added
      verify(mockLocalDataSource.fetchProducts(tenantId: anyNamed('tenantId')));
      verifyZeroInteractions(mockSapDataSource);
      verifyZeroInteractions(mockRemoteDataSource);
      expect(result.length, 1);
    });

    test('should use SapProductDataSource when tenant is Enterprise', () async {
      // Arrange
      ApiConfig.setFlavor(AppFlavor.mock); // Even if mock mode is on
      when(mockAuthRepository.getCurrentTenant())
          .thenAnswer((_) async => tEnterpriseTenant);
      when(mockSapDataSource.fetchProducts())
          .thenAnswer((_) async => [tProductModel]);

      // Act
      final result = await repository.getAllProducts();

      // Assert
      verify(mockAuthRepository.getCurrentTenant());
      verify(mockSapDataSource.fetchProducts(tenantId: anyNamed('tenantId')));
      verifyZeroInteractions(mockLocalDataSource);
      // verifyZeroInteractions(mockRemoteDataSource); // might be accessed if logic falls through, but shouldn't
    });

    test('should use ProductRemoteDataSource when tenant is Standard and MockMode is FALSE', () async {
      // Arrange
      ApiConfig.setFlavor(AppFlavor.prod); // Force PROD mode
      when(mockAuthRepository.getCurrentTenant())
          .thenAnswer((_) async => tStandardTenant);
      when(mockRemoteDataSource.fetchProducts())
          .thenAnswer((_) async => [tProductModel]);

      // Act
      final result = await repository.getAllProducts();

      // Assert
      verify(mockAuthRepository.getCurrentTenant());
      verify(mockRemoteDataSource.fetchProducts(tenantId: anyNamed('tenantId')));
      verifyZeroInteractions(mockLocalDataSource);
      verifyZeroInteractions(mockSapDataSource);
    });

    test('should use LocalProductDataSource when tenant is Alone (even in PROD mode)', () async {
      // Arrange
      ApiConfig.setFlavor(AppFlavor.prod); // Force PROD mode
      final tAloneTenant = Tenant(
        id: 'alone_tenant',
        name: 'Alone Tenant',
        businessName: 'Alone Biz',
        email: 'alone@test.com',
        phone: '1112223333',
        status: 'Active',
        tierId: 'alone', // Important
        createdDate: DateTime(2023, 1, 1),
        lastLogin: null,
        ordersCount: 0,
        revenue: 0,
        isMaintenanceMode: false,
        enabledFeatures: [],
      );

      when(mockAuthRepository.getCurrentTenant())
          .thenAnswer((_) async => tAloneTenant);
      when(mockLocalDataSource.fetchProducts())
          .thenAnswer((_) async => [tProductModel]);

      // Act
      final result = await repository.getAllProducts();

      // Assert
      verify(mockAuthRepository.getCurrentTenant());
      verify(mockLocalDataSource.fetchProducts(tenantId: anyNamed('tenantId')));
      verifyZeroInteractions(mockRemoteDataSource);
      verifyZeroInteractions(mockSapDataSource);
    });

    test('should default to local/remote when tenant is null (e.g. not logged in fully or error)', () async {
      // Arrange
      ApiConfig.setFlavor(AppFlavor.mock);
      when(mockAuthRepository.getCurrentTenant())
          .thenAnswer((_) async => null);
      final tConfig = AppConfiguration(
        tenantId: 'standard_tenant',
        isConfigured: true,
      );
      when(mockConfigRepository.getConfiguration()).thenAnswer((_) async => tConfig);

      // Act
      final result = await repository.getAllProducts();

      // Assert
      verify(mockLocalDataSource.fetchProducts(tenantId: 'standard_tenant'));
      verifyZeroInteractions(mockSapDataSource);
    });
  });
}
