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

  /// Get orders that failed SAP sync
  Future<List<Order>> getFailedSapOrders() {
    return (select(orders)..where((tbl) => tbl.sapSyncStatus.equals('failed'))).get();
  }

  /// Watch orders that failed SAP sync (live stream for UI)
  Stream<List<Order>> watchFailedSapOrders() {
    return (select(orders)..where((tbl) => tbl.sapSyncStatus.equals('failed'))).watch();
  }

  /// Permanently cancel SAP sync for an order — background retry will no longer pick it up
  Future<int> cancelSapSync(String id) {
    return (update(orders)..where((tbl) => tbl.id.equals(id)))
        .write(const OrdersCompanion(sapSyncStatus: Value('cancelled_sync')));
  }

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
      await into(orders).insertOnConflictUpdate(OrdersCompanion(
        id: order.id,
        totalAmount: order.totalAmount,
        status: order.status,
        createdAt: order.createdAt,
        customerPhone: order.customerPhone,
        tenantId: order.tenantId,
        branchId: order.branchId,
        terminalId: order.terminalId,
        sapSyncStatus: order.sapSyncStatus,
        sapDocEntry: order.sapDocEntry,
        sapCardCode: order.sapCardCode,
      ));
      
      // 2. Refresh items (Delete old and re-insert new to be safe)
      await (delete(orderItems)..where((tbl) => tbl.orderId.equals(order.id.value))).go();
      
      for (final item in items) {
        await into(orderItems).insert(item);
      }
    });
  }
  
  /// Update SAP sync status
  Future<int> updateSapSyncStatus(String id, String status, {int? docEntry}) {
    return (update(orders)..where((tbl) => tbl.id.equals(id)))
      .write(OrdersCompanion(
        sapSyncStatus: Value(status),
        sapDocEntry: docEntry != null ? Value(docEntry) : const Value.absent(),
      ));
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
