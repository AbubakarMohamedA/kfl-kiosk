import 'package:kfm_kiosk/data/datasources/local_order_datasource.dart';
import 'package:kfm_kiosk/data/models/order_model.dart';
import 'package:kfm_kiosk/domain/entities/order.dart';
import 'package:kfm_kiosk/domain/repositories/repositories.dart';

class OrderRepositoryImpl implements OrderRepository {
  final LocalOrderDataSource dataSource;

  OrderRepositoryImpl(this.dataSource);

  @override
  Future<String> createOrder(Order order) async {
    final orderModel = OrderModel.fromEntity(order);
    return await dataSource.saveOrder(orderModel);
  }

  @override
  Future<List<Order>> getAllOrders() async {
    final orders = await dataSource.getOrders();
    return orders.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Order?> getOrderById(String id) async {
    final orderModel = await dataSource.getOrderById(id);
    return orderModel?.toEntity();
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    await dataSource.updateOrderStatus(orderId, status);
  }

  // ✅ NEW: Saves the full order including per-item statuses
  @override
  Future<void> saveFullOrder(Order order) async {
    final orderModel = OrderModel.fromEntity(order);
    await dataSource.saveFullOrder(orderModel);
  }

  @override
  Future<int> getOrderCounter() async {
    return await dataSource.getOrderCounter();
  }

  @override
  Future<void> incrementOrderCounter() async {
    await dataSource.incrementOrderCounter();
  }

  @override
  Stream<List<Order>> watchOrders() {
    return dataSource.watchOrders().map(
          (orders) => orders.map((model) => model.toEntity()).toList(),
        );
  }
}