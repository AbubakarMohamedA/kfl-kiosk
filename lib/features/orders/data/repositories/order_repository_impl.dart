import 'package:kfm_kiosk/core/config/api_config.dart';
import 'package:kfm_kiosk/features/orders/data/datasources/local_order_datasource.dart';
import 'package:kfm_kiosk/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:kfm_kiosk/features/orders/data/models/order_model.dart';
import 'package:kfm_kiosk/features/orders/domain/entities/order.dart';
import 'package:kfm_kiosk/features/orders/domain/repositories/order_repository.dart';

import 'package:kfm_kiosk/features/auth/domain/repositories/auth_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final LocalOrderDataSource localDataSource;
  final OrderRemoteDataSource remoteDataSource;
  final AuthRepository authRepository;

  OrderRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.authRepository,
  });

  OrderDataSource get _dataSource => localDataSource;
      // ApiConfig.isMockMode ? localDataSource : remoteDataSource;

  @override
  Future<String> createOrder(Order order) async {
    final orderModel = OrderModel.fromEntity(order);
    return await _dataSource.saveOrder(orderModel);
  }

  @override
  Future<List<Order>> getAllOrders() async {
    final currentTenant = await authRepository.getCurrentTenant();
    final orders = await _dataSource.getOrders(tenantId: currentTenant?.id);
    return orders.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Order?> getOrderById(String id) async {
    final orderModel = await _dataSource.getOrderById(id);
    return orderModel?.toEntity();
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _dataSource.updateOrderStatus(orderId, status);
  }

  // ✅ NEW: Saves the full order including per-item statuses
  @override
  Future<void> saveFullOrder(Order order) async {
    final orderModel = OrderModel.fromEntity(order);
    await _dataSource.saveFullOrder(orderModel);
  }

  @override
  Future<int> getOrderCounter({String? tenantId, String? branchId}) async {
    return await _dataSource.getOrderCounter(tenantId: tenantId, branchId: branchId);
  }

  @override
  Future<void> incrementOrderCounter({String? tenantId, String? branchId}) async {
    await _dataSource.incrementOrderCounter(tenantId: tenantId, branchId: branchId);
  }

  @override
  Stream<List<Order>> watchOrders() async* {
    final currentTenant = await authRepository.getCurrentTenant();
    yield* _dataSource.watchOrders(tenantId: currentTenant?.id).map(
          (orders) => orders.map((model) => model.toEntity()).toList(),
        );
  }
}