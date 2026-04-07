import 'package:sss/features/orders/data/datasources/local_order_datasource.dart';
import 'package:sss/features/orders/data/datasources/order_remote_datasource.dart';
import 'package:sss/features/orders/data/datasources/sap_invoice_datasource.dart';
import 'package:sss/features/orders/data/models/order_model.dart';
import 'package:sss/features/orders/domain/entities/order.dart';
import 'package:sss/features/orders/domain/repositories/order_repository.dart';

import 'package:sss/features/auth/domain/repositories/auth_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final LocalOrderDataSource localDataSource;
  final OrderRemoteDataSource remoteDataSource;
  final SapInvoiceDataSource sapInvoiceDataSource;
  final AuthRepository authRepository;

  OrderRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.sapInvoiceDataSource,
    required this.authRepository,
  });

  OrderDataSource get _dataSource => localDataSource;
      // ApiConfig.isMockMode ? localDataSource : remoteDataSource;

  @override
  Future<String> createOrder(Order order) async {
    final orderModel = OrderModel.fromEntity(order);
    
    // Capture CardCode at order time if not present
    final finalOrder = orderModel.sapCardCode == null || orderModel.sapCardCode!.isEmpty
        ? orderModel.copyWith(sapCardCode: await sapInvoiceDataSource.getSapAuthService().getActiveCardCode())
        : orderModel;

    final id = await _dataSource.saveOrder(finalOrder);
    
    final creds = await sapInvoiceDataSource.getSapAuthService().loadCredentials();
    final scheduledSyncTime = creds['scheduledSyncTime'];
    
    if (scheduledSyncTime != null && scheduledSyncTime.trim().isNotEmpty) {
      // Skip immediate sync, let the background scheduled sync handle it
    } else {
      // Asynchronously push to SAP as Invoice without blocking UI
      sapInvoiceDataSource.syncOrderAsInvoice(finalOrder);
    }
    
    return id;
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
    
    // Capture CardCode at order time if not present
    final finalOrder = orderModel.sapCardCode == null || orderModel.sapCardCode!.isEmpty
        ? orderModel.copyWith(sapCardCode: await sapInvoiceDataSource.getSapAuthService().getActiveCardCode())
        : orderModel;

    await _dataSource.saveFullOrder(finalOrder);
    
    final creds = await sapInvoiceDataSource.getSapAuthService().loadCredentials();
    final scheduledSyncTime = creds['scheduledSyncTime'];
    
    if (scheduledSyncTime != null && scheduledSyncTime.trim().isNotEmpty) {
      // Skip immediate sync
    } else {
      // Asynchronously push to SAP as Invoice
      sapInvoiceDataSource.syncOrderAsInvoice(finalOrder);
    }
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