import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:kfm_kiosk/core/configuration/data/datasources/local_configuration_datasource.dart';
import 'package:kfm_kiosk/core/database/daos/orders_dao.dart';
import 'package:kfm_kiosk/core/services/license_service.dart';
import 'package:kfm_kiosk/core/services/local_server_service.dart';
import 'package:kfm_kiosk/core/services/sync_service.dart';
import 'package:kfm_kiosk/core/services/cloud_heartbeat_service.dart';
import 'package:kfm_kiosk/features/products/data/datasources/local_product_datasource.dart';
import 'package:kfm_kiosk/features/products/data/datasources/product_remote_datasource.dart';
import 'package:kfm_kiosk/features/products/data/datasources/sap_product_datasource.dart';
import 'package:kfm_kiosk/features/cart/data/datasources/local_cart_datasource.dart';
import 'package:kfm_kiosk/features/orders/data/datasources/local_order_datasource.dart';
import 'package:kfm_kiosk/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:kfm_kiosk/features/payment/data/datasources/mock_payment_datasource.dart';
import 'package:kfm_kiosk/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:kfm_kiosk/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:kfm_kiosk/core/configuration/data/repositories/configuration_repository_impl.dart';
import 'package:kfm_kiosk/features/warehouse/domain/services/warehouse_service.dart';
import 'package:kfm_kiosk/features/products/data/repositories/product_repository_impl.dart';
import 'package:kfm_kiosk/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:kfm_kiosk/features/orders/data/repositories/order_repository_impl.dart';
import 'package:kfm_kiosk/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:kfm_kiosk/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kfm_kiosk/core/configuration/domain/repositories/configuration_repository.dart';
import 'package:kfm_kiosk/features/products/domain/repositories/product_repository.dart';
import 'package:kfm_kiosk/features/cart/domain/repositories/cart_repository.dart';
import 'package:kfm_kiosk/features/orders/domain/repositories/order_repository.dart';
import 'package:kfm_kiosk/features/payment/domain/repositories/payment_repository.dart';
import 'package:kfm_kiosk/features/auth/domain/repositories/auth_repository.dart';
import 'package:kfm_kiosk/features/products/domain/usecases/product_usecases.dart';
import 'package:kfm_kiosk/features/cart/domain/usecases/cart_usecases.dart';
import 'package:kfm_kiosk/features/orders/domain/usecases/order_usecases.dart';
import 'package:kfm_kiosk/features/payment/domain/usecases/payment_usecases.dart';
import 'package:kfm_kiosk/features/products/presentation/bloc/product/product_bloc.dart';
import 'package:kfm_kiosk/features/cart/presentation/bloc/cart/cart_bloc.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:kfm_kiosk/features/payment/presentation/bloc/payment/payment_bloc.dart';
import 'package:kfm_kiosk/features/settings/presentation/bloc/language/language_cubit.dart';
import 'package:kfm_kiosk/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:kfm_kiosk/core/database/app_database.dart';
import 'package:kfm_kiosk/core/database/daos/products_dao.dart';
import 'package:kfm_kiosk/core/database/daos/app_config_dao.dart';
import 'package:http/http.dart' as http;

import 'package:kfm_kiosk/core/database/daos/branches_dao.dart';
import 'package:kfm_kiosk/core/database/daos/tenants_dao.dart';
import 'package:kfm_kiosk/core/database/daos/tiers_dao.dart';
import 'package:kfm_kiosk/core/database/daos/cart_dao.dart';
import 'package:kfm_kiosk/core/database/daos/tenant_config_dao.dart'; // NEW
import 'package:kfm_kiosk/features/auth/domain/services/tenant_service.dart';
import 'package:kfm_kiosk/core/repositories/image_repository.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Database
  final database = AppDatabase();
  getIt.registerSingleton<AppDatabase>(database);
  
  // DAOs
  getIt.registerSingleton<ProductsDao>(ProductsDao(database));
  getIt.registerSingleton<OrdersDao>(OrdersDao(database));
  getIt.registerSingleton<BranchesDao>(BranchesDao(database));
  getIt.registerSingleton<TenantsDao>(TenantsDao(database));
  getIt.registerSingleton<TiersDao>(TiersDao(database));
  getIt.registerLazySingleton<CartDao>(() => CartDao(getIt<AppDatabase>()));
  getIt.registerLazySingleton<TenantConfigDao>(() => TenantConfigDao(getIt<AppDatabase>())); // NEW
  getIt.registerLazySingleton<AppConfigDao>(() => AppConfigDao(getIt<AppDatabase>()));
  
  // Services
  getIt.registerLazySingleton<LicenseService>(() => LicenseService(getIt<AppDatabase>()));
  getIt.registerLazySingleton<WarehouseService>(() => WarehouseService(database));
  getIt.registerLazySingleton<LocalConfigurationDataSource>(() => LocalConfigurationDataSource(getIt<AppDatabase>())); // Fix: Pass AppDatabase
  getIt.registerLazySingleton<LocalServerService>(() => LocalServerService( // NEW
        getIt<TenantConfigDao>(), // NEW
        getIt<ProductsDao>(), // NEW
        getIt<OrdersDao>(), // NEW
        getIt<AppConfigDao>(), // NEW
      )); // NEW
  
  getIt.registerLazySingleton<SyncService>(() => SyncService(getIt<ConfigurationRepository>())); // NEW
  
  getIt.registerLazySingleton<CloudHeartbeatService>(() => CloudHeartbeatService(
    getIt<ConfigurationRepository>(),
    getIt<TenantService>(),
    getIt<LicenseService>(),
    getIt<AuthRepository>(),
    getIt<LocalServerService>(),
  ));

  // Initialize TenantService with DAOs
  final tenantService = TenantService();
  tenantService.setBranchesDao(getIt<BranchesDao>());
  tenantService.setTenantsDao(getIt<TenantsDao>());
  tenantService.setTiersDao(getIt<TiersDao>());
  await tenantService.initialize();
  
  // External
  getIt.registerLazySingleton(() => http.Client());

  // Data Sources
  getIt.registerLazySingleton<LocalProductDataSource>(() => LocalProductDataSource(getIt<ProductsDao>()));
  getIt.registerLazySingleton<ProductRemoteDataSource>(() => ProductRemoteDataSource(client: getIt()));
  
  getIt.registerLazySingleton<LocalCartDataSource>(() => LocalCartDataSource(getIt<CartDao>(), getIt<LocalProductDataSource>()));
  
  getIt.registerLazySingleton<LocalOrderDataSource>(() => LocalOrderDataSource(getIt<OrdersDao>(), getIt<AppConfigDao>(), getIt<http.Client>()));
  getIt.registerLazySingleton<OrderRemoteDataSource>(() => OrderRemoteDataSource(client: getIt()));

  getIt.registerLazySingleton<MockPaymentDataSource>(() => MockPaymentDataSource());
  
  getIt.registerLazySingleton<AuthMockDataSource>(() => AuthMockDataSource());
  getIt.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSource(client: getIt()));

  getIt.registerLazySingleton<SapProductDataSource>(() => SapProductDataSource());

  // Repositories
  getIt.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(
    localDataSource: getIt<LocalProductDataSource>(),
    remoteDataSource: getIt<ProductRemoteDataSource>(),
    sapDataSource: getIt<SapProductDataSource>(),
    authRepository: getIt<AuthRepository>(),
    configRepository: getIt<ConfigurationRepository>(), // ✅ Added
  ));
  getIt.registerLazySingleton<CartRepository>(() => CartRepositoryImpl(
    getIt<LocalCartDataSource>(),
    getIt<AuthRepository>(),
    getIt<ConfigurationRepository>(),
  ));
  getIt.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(
    localDataSource: getIt<LocalOrderDataSource>(),
    remoteDataSource: getIt<OrderRemoteDataSource>(),
    authRepository: getIt<AuthRepository>(),
  ));
  getIt.registerLazySingleton<PaymentRepository>(() => PaymentRepositoryImpl(getIt<MockPaymentDataSource>()));
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
    mockDataSource: getIt<AuthMockDataSource>(),
    remoteDataSource: getIt<AuthRemoteDataSource>(),
  ));

// getIt.registerLazySingleton<LocalConfigurationDataSource>(() => LocalConfigurationDataSource(getIt<AppDatabase>()));
getIt.registerLazySingleton<ConfigurationRepository>(() => ConfigurationRepositoryImpl(getIt<LocalConfigurationDataSource>()));
getIt.registerLazySingleton<ImageRepository>(() => ImageRepositoryImpl(client: getIt()));

  // Use Cases - Products
  getIt.registerLazySingleton(() => GetAllProducts(getIt<ProductRepository>()));
  getIt.registerLazySingleton(() => GetCategories(getIt<ProductRepository>()));
  getIt.registerLazySingleton(() => GetProductsByCategory(getIt<ProductRepository>()));
  getIt.registerLazySingleton(() => GetProductById(getIt<ProductRepository>()));
  getIt.registerLazySingleton(() => AddProduct(getIt<ProductRepository>()));
  getIt.registerLazySingleton(() => UpdateProduct(getIt<ProductRepository>()));
  getIt.registerLazySingleton(() => DeleteProduct(getIt<ProductRepository>()));

  // Use Cases - Cart
  getIt.registerLazySingleton(() => AddToCart(getIt<CartRepository>()));
  getIt.registerLazySingleton(() => RemoveFromCart(getIt<CartRepository>()));
  getIt.registerLazySingleton(() => UpdateCartQuantity(getIt<CartRepository>()));
  getIt.registerLazySingleton(() => GetCartItems(getIt<CartRepository>()));
  getIt.registerLazySingleton(() => ClearCart(getIt<CartRepository>()));
  getIt.registerLazySingleton(() => GetCartTotal(getIt<CartRepository>()));

  // Use Cases - Order
  getIt.registerLazySingleton(() => CreateOrder(getIt<OrderRepository>()));
  getIt.registerLazySingleton(() => GetAllOrders(getIt<OrderRepository>()));
  getIt.registerLazySingleton(() => GetOrderById(getIt<OrderRepository>()));
  getIt.registerLazySingleton(() => UpdateOrderStatus(getIt<OrderRepository>()));
  getIt.registerLazySingleton(() => GenerateOrderId(
    getIt<OrderRepository>(),
    getIt<AuthRepository>(),
    getIt<ConfigurationRepository>(),
  ));
  getIt.registerLazySingleton(() => WatchOrders(getIt<OrderRepository>()));
  getIt.registerLazySingleton<SaveFullOrder>(() => SaveFullOrder(getIt<OrderRepository>()),);

  // Use Cases - Payment
  getIt.registerLazySingleton(() => ProcessPayment(getIt<PaymentRepository>()));
  getIt.registerLazySingleton(() => GetPaymentStatus(getIt<PaymentRepository>()));

  // BLoCs
  getIt.registerFactory(() => ProductBloc(
    getAllProducts: getIt<GetAllProducts>(),
    getCategories: getIt<GetCategories>(),
    getProductsByCategory: getIt<GetProductsByCategory>(),
    addProduct: getIt<AddProduct>(),
    updateProduct: getIt<UpdateProduct>(),
    deleteProduct: getIt<DeleteProduct>(),
    configurationRepository: getIt(), // Added for Branch Isolation logic
  ));

  getIt.registerFactory(() => CartBloc(
    addToCartUseCase: getIt<AddToCart>(),
    removeFromCartUseCase: getIt<RemoveFromCart>(),
    updateQuantityUseCase: getIt<UpdateCartQuantity>(),
    getCartItemsUseCase: getIt<GetCartItems>(),
    clearCartUseCase: getIt<ClearCart>(),
    getCartTotalUseCase: getIt<GetCartTotal>(),
  ));



// Updated OrderBloc registration with saveFullOrderUseCase
getIt.registerFactory(() => OrderBloc(
  configurationRepository: getIt<ConfigurationRepository>(), 
  createOrderUseCase: getIt<CreateOrder>(),
  getAllOrdersUseCase: getIt<GetAllOrders>(),
  updateOrderStatusUseCase: getIt<UpdateOrderStatus>(),
  generateOrderIdUseCase: getIt<GenerateOrderId>(),
  watchOrdersUseCase: getIt<WatchOrders>(),
  saveFullOrderUseCase: getIt<SaveFullOrder>(),
  authRepository: getIt<AuthRepository>(), // ✅ NEW
));

  getIt.registerFactory(() => AuthBloc(
    authRepository: getIt<AuthRepository>(),
    localServerService: getIt<LocalServerService>(),
  ));

  getIt.registerFactory(() => PaymentBloc(
    processPaymentUseCase: getIt<ProcessPayment>(),
    getPaymentStatusUseCase: getIt<GetPaymentStatus>(),
  ));

  getIt.registerFactory(() => LanguageCubit());
}