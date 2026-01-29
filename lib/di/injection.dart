import 'package:get_it/get_it.dart';
import 'package:kfm_kiosk/data/datasources/local_product_datasource.dart';
import 'package:kfm_kiosk/data/datasources/local_cart_datasource.dart';
import 'package:kfm_kiosk/data/datasources/local_order_datasource.dart';
import 'package:kfm_kiosk/data/datasources/mock_payment_datasource.dart';
import 'package:kfm_kiosk/data/repositories/product_repository_impl.dart';
import 'package:kfm_kiosk/data/repositories/cart_repository_impl.dart';
import 'package:kfm_kiosk/data/repositories/order_repository_impl.dart';
import 'package:kfm_kiosk/data/repositories/payment_repository_impl.dart';
import 'package:kfm_kiosk/domain/repositories/repositories.dart';
import 'package:kfm_kiosk/domain/usecases/product_usecases.dart';
import 'package:kfm_kiosk/domain/usecases/cart_usecases.dart';
import 'package:kfm_kiosk/domain/usecases/order_usecases.dart';
import 'package:kfm_kiosk/domain/usecases/payment_usecases.dart';
import 'package:kfm_kiosk/presentation/bloc/product/product_bloc.dart';
import 'package:kfm_kiosk/presentation/bloc/cart/cart_bloc.dart';
import 'package:kfm_kiosk/presentation/bloc/order/order_bloc.dart';
import 'package:kfm_kiosk/presentation/bloc/payment/payment_bloc.dart';
import 'package:kfm_kiosk/presentation/bloc/language/language_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Data Sources
  getIt.registerLazySingleton<LocalProductDataSource>(() => LocalProductDataSource());
  getIt.registerLazySingleton<LocalCartDataSource>(() => LocalCartDataSource());
  getIt.registerLazySingleton<LocalOrderDataSource>(() => LocalOrderDataSource());
  getIt.registerLazySingleton<MockPaymentDataSource>(() => MockPaymentDataSource());

  // Repositories
  getIt.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(getIt<LocalProductDataSource>()));
  getIt.registerLazySingleton<CartRepository>(() => CartRepositoryImpl(getIt<LocalCartDataSource>()));
  getIt.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(getIt<LocalOrderDataSource>()));
  getIt.registerLazySingleton<PaymentRepository>(() => PaymentRepositoryImpl(getIt<MockPaymentDataSource>()));

  // Use Cases - Products
  getIt.registerLazySingleton(() => GetAllProducts(getIt<ProductRepository>()));
  getIt.registerLazySingleton(() => GetCategories(getIt<ProductRepository>()));
  getIt.registerLazySingleton(() => GetProductsByCategory(getIt<ProductRepository>()));
  getIt.registerLazySingleton(() => GetProductById(getIt<ProductRepository>()));

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
  getIt.registerLazySingleton(() => GenerateOrderId(getIt<OrderRepository>()));
  getIt.registerLazySingleton(() => WatchOrders(getIt<OrderRepository>()));

  // Use Cases - Payment
  getIt.registerLazySingleton(() => ProcessPayment(getIt<PaymentRepository>()));
  getIt.registerLazySingleton(() => GetPaymentStatus(getIt<PaymentRepository>()));

  // BLoCs
  getIt.registerFactory(() => ProductBloc(
    getAllProducts: getIt<GetAllProducts>(),
    getCategories: getIt<GetCategories>(),
    getProductsByCategory: getIt<GetProductsByCategory>(),
  ));

  getIt.registerFactory(() => CartBloc(
    addToCartUseCase: getIt<AddToCart>(),
    removeFromCartUseCase: getIt<RemoveFromCart>(),
    updateQuantityUseCase: getIt<UpdateCartQuantity>(),
    getCartItemsUseCase: getIt<GetCartItems>(),
    clearCartUseCase: getIt<ClearCart>(),
    getCartTotalUseCase: getIt<GetCartTotal>(),
  ));

  getIt.registerFactory(() => OrderBloc(
    createOrderUseCase: getIt<CreateOrder>(),
    getAllOrdersUseCase: getIt<GetAllOrders>(),
    updateOrderStatusUseCase: getIt<UpdateOrderStatus>(),
    generateOrderIdUseCase: getIt<GenerateOrderId>(),
    watchOrdersUseCase: getIt<WatchOrders>(),
  ));

  getIt.registerFactory(() => PaymentBloc(
    processPaymentUseCase: getIt<ProcessPayment>(),
    getPaymentStatusUseCase: getIt<GetPaymentStatus>(),
  ));

  getIt.registerFactory(() => LanguageCubit());
}