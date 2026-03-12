import 'package:drift/drift.dart';
import 'package:sss/core/database/app_database.dart';

part 'orders_dao.g.dart';

@DriftAccessor(tables: [Orders, OrderItems])
class OrdersDao extends DatabaseAccessor<AppDatabase> with _$OrdersDaoMixin {
  final AppDatabase db;

  OrdersDao(this.db) : super(db);

  /// Fetch all orders
  Future<List<Order>> getAllOrders() => select(orders).get();

  /// Watch all orders
  Stream<List<Order>> watchAllOrders() => select(orders).watch();

  /// Fetch order by ID
  Future<Order?> getOrderById(String id) {
    return (select(orders)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Fetch items for an order
  Future<List<OrderItem>> getItemsForOrder(String orderId) {
    return (select(orderItems)..where((tbl) => tbl.orderId.equals(orderId))).get();
  }
  
  /// Get full order details (Order with items)
  Future<OrderWithItems?> getOrderWithItems(String orderId) async {
    final order = await getOrderById(orderId);
    if (order == null) return null;
    
    final items = await getItemsForOrder(orderId);
    return OrderWithItems(order, items);
  }

  /// Create a new order with items transactionally
  Future<void> createOrder(OrdersCompanion order, List<OrderItemsCompanion> items) {
    return transaction(() async {
      await into(orders).insert(order);
      for (final item in items) {
        await into(orderItems).insert(item);
      }
    });
  }

  /// Upsert an order (Insert or Update if exists)
  Future<void> upsertOrder(OrdersCompanion order, List<OrderItemsCompanion> items) {
    return transaction(() async {
      // 1. Upsert the order header
      await into(orders).insertOnConflictUpdate(order);
      
      // 2. Refresh items (Delete old and re-insert new to be safe)
      await (delete(orderItems)..where((tbl) => tbl.orderId.equals(order.id.value))).go();
      
      for (final item in items) {
        await into(orderItems).insert(item);
      }
    });
  }
  
  /// Update order status
  Future<int> updateOrderStatus(String id, String status) {
    return (update(orders)..where((tbl) => tbl.id.equals(id)))
      .write(OrdersCompanion(status: Value(status)));
  }
}

/// Helper class to hold Order + Items
class OrderWithItems {
  final Order order;
  final List<OrderItem> items;

  OrderWithItems(this.order, this.items);
}
