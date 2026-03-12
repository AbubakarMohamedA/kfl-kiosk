import 'package:sss/features/orders/domain/entities/order.dart';

abstract class OrderRepository {
  Future<String> createOrder(Order order);
  Future<List<Order>> getAllOrders();
  Future<Order?> getOrderById(String id);
  Future<void> updateOrderStatus(String orderId, String status);
  Future<void> saveFullOrder(Order order);
  Future<int> getOrderCounter({String? tenantId, String? branchId});
  Future<void> incrementOrderCounter({String? tenantId, String? branchId});
  Stream<List<Order>> watchOrders();
}
