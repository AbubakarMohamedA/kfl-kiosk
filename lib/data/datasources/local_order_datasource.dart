import 'dart:async';
import 'package:kfm_kiosk/data/models/order_model.dart';

class LocalOrderDataSource {
  // In-memory order storage
  final List<OrderModel> _orders = [];
  int _orderCounter = 1;

  // Stream controller for real-time order updates
  final _ordersStreamController = StreamController<List<OrderModel>>.broadcast();

  Stream<List<OrderModel>> watchOrders() {
    return _ordersStreamController.stream;
  }

  // Create/Save order
  Future<String> saveOrder(OrderModel order) async {
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate async
    
    _orders.add(order);
    _ordersStreamController.add(List.from(_orders));
    
    return order.id;
  }

  // Get all orders
  Future<List<OrderModel>> getOrders() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_orders);
  }

  // Get order by ID
  Future<OrderModel?> getOrderById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    try {
      return _orders.firstWhere((order) => order.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    final index = _orders.indexWhere((order) => order.id == orderId);
    
    if (index != -1) {
      final order = _orders[index];
      _orders[index] = OrderModel(
        id: order.id,
        items: order.items,
        total: order.total,
        phone: order.phone,
        timestamp: order.timestamp,
        status: status,
      );
      
      _ordersStreamController.add(List.from(_orders));
    }
  }

  // Get orders by status
  Future<List<OrderModel>> getOrdersByStatus(String status) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _orders.where((order) => order.status == status).toList();
  }

  // Get orders by date
  Future<List<OrderModel>> getOrdersByDate(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    return _orders.where((order) {
      return order.timestamp.year == date.year &&
          order.timestamp.month == date.month &&
          order.timestamp.day == date.day;
    }).toList();
  }

  // Get today's orders
  Future<List<OrderModel>> getTodaysOrders() async {
    final today = DateTime.now();
    return getOrdersByDate(today);
  }

  // Get order counter
  Future<int> getOrderCounter() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _orderCounter;
  }

  // Increment order counter
  Future<void> incrementOrderCounter() async {
    await Future.delayed(const Duration(milliseconds: 50));
    _orderCounter++;
  }

  // Set order counter (useful for initialization)
  Future<void> setOrderCounter(int value) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _orderCounter = value;
  }

  // Delete order (for testing/admin purposes)
  Future<void> deleteOrder(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    _orders.removeWhere((order) => order.id == orderId);
    _ordersStreamController.add(List.from(_orders));
  }

  // Get total sales for today getTodaysSales todaysOrders
  Future<double> getTodaysSales() async {
  final todaysOrders = await getTodaysOrders();
  double total = 0.0;
  
  for (var order in todaysOrders) {
    total += order.total;
  }
  
  return total;
}

  // Get order count by status
  Future<int> getOrderCountByStatus(String status) async {
    final orders = await getOrdersByStatus(status);
    return orders.length;
  }

  // Search orders by phone number
  Future<List<OrderModel>> searchByPhone(String phone) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    return _orders.where((order) => order.phone.contains(phone)).toList();
  }

  // Search orders by order ID
  Future<List<OrderModel>> searchByOrderId(String query) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    return _orders
        .where((order) => order.id.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Clear all orders (for testing)
  Future<void> clearAllOrders() async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    _orders.clear();
    _ordersStreamController.add(List.from(_orders));
  }

  // Dispose stream controller
  void dispose() {
    _ordersStreamController.close();
  }
}