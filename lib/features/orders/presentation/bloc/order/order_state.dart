import 'package:equatable/equatable.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/features/orders/domain/entities/order.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {
  const OrderInitial();
}

class OrderLoading extends OrderState {
  const OrderLoading();
}

class OrderCreating extends OrderState {
  const OrderCreating();
}

class OrderCreated extends OrderState {
  final String orderId;
  final Order order;

  const OrderCreated({
    required this.orderId,
    required this.order,
  });

  @override
  List<Object?> get props => [orderId, order];
}

class OrdersLoaded extends OrderState {
  final List<Order> orders;
  final List<dynamic> filteredOrders;
  final String? selectedStatus;
  final String? currentFilter;
  final String? currentSort;

  const OrdersLoaded({
    required this.orders,
    required this.filteredOrders,
    this.selectedStatus,
    this.currentFilter,
    this.currentSort,
  });

  @override
  List<Object?> get props => [
        orders,
        filteredOrders,
        selectedStatus,
        currentFilter,
        currentSort,
      ];

  OrdersLoaded copyWith({
    List<Order>? orders,
    List<dynamic>? filteredOrders,
    String? selectedStatus,
    String? currentFilter,
    String? currentSort,
  }) {
    return OrdersLoaded(
      orders: orders ?? this.orders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      currentFilter: currentFilter ?? this.currentFilter,
      currentSort: currentSort ?? this.currentSort,
    );
  }

  // Basic counts — now derived from item-level statuses via overallStatus
  int get totalOrders => orders.length;

  int get paidCount =>
      orders.where((o) => o.overallStatus == AppConstants.statusPaid).length;

  int get preparingCount =>
      orders.where((o) => o.overallStatus == AppConstants.statusPreparing).length;

  int get readyCount =>
      orders.where((o) => o.overallStatus == AppConstants.statusReadyForPickup).length;

  int get fulfilledCount =>
      orders.where((o) => o.overallStatus == AppConstants.statusFulfilled).length;

  // Today's metrics
  double get todaysSales {
    final today = DateTime.now();
    return orders
        .where((o) =>
            o.timestamp.day == today.day &&
            o.timestamp.month == today.month &&
            o.timestamp.year == today.year)
        .fold(0.0, (sum, order) => sum + order.total);
  }

  int get todaysOrderCount {
    final today = DateTime.now();
    return orders
        .where((o) =>
            o.timestamp.day == today.day &&
            o.timestamp.month == today.month &&
            o.timestamp.year == today.year)
        .length;
  }

  // Enhanced analytics
  int get completedTodayCount {
    final today = DateTime.now();
    return orders
        .where((o) =>
            o.overallStatus == AppConstants.statusFulfilled &&
            o.timestamp.day == today.day &&
            o.timestamp.month == today.month &&
            o.timestamp.year == today.year)
        .length;
  }

  double get completionRate {
    if (todaysOrderCount == 0) return 0.0;
    return (completedTodayCount / todaysOrderCount) * 100;
  }

  double get averageOrderValue {
    if (todaysOrderCount == 0) return 0.0;
    return todaysSales / todaysOrderCount;
  }

  // ✅ FIXED: Use overallStatus instead of the stale top-level status field
  List<Order> get activeOrders =>
      orders.where((o) => o.overallStatus != AppConstants.statusFulfilled).toList();

  List<Order> get completedOrders =>
      orders.where((o) => o.overallStatus == AppConstants.statusFulfilled).toList();

  List<Order> get filteredActiveOrders => filteredOrders
      .where((o) => (o as Order).overallStatus != AppConstants.statusFulfilled)
      .cast<Order>()
      .toList();

  List<Order> get filteredCompletedOrders => filteredOrders
      .where((o) => (o as Order).overallStatus == AppConstants.statusFulfilled)
      .cast<Order>()
      .toList();

  // Weekly sales
  double get weeklySales {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return orders
        .where((o) => o.timestamp.isAfter(weekAgo))
        .fold(0.0, (sum, order) => sum + order.total);
  }

  // Monthly sales
  double get monthlySales {
    final now = DateTime.now();
    return orders
        .where((o) =>
            o.timestamp.month == now.month && o.timestamp.year == now.year)
        .fold(0.0, (sum, order) => sum + order.total);
  }

  // Peak hour detection
  int get peakHour {
    final today = DateTime.now();
    final todayOrders = orders.where((o) =>
        o.timestamp.day == today.day &&
        o.timestamp.month == today.month &&
        o.timestamp.year == today.year);

    if (todayOrders.isEmpty) return 0;

    final hourCounts = <int, int>{};
    for (var order in todayOrders) {
      final hour = order.timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    return hourCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  double get averagePrepTime {
    return 12.0;
  }

  // ✅ FIXED: Filter directly off `orders`, not `activeOrders`.
  // An order is "active" for a warehouse if it has at least one
  // non-FULFILLED item in that category.
  // ✅ FIXED: Filter directly off `orders`, not `activeOrders`.
  // An order is "active" for a warehouse if it has at least one
  // non-FULFILLED item in that category.
  List<Order> getWarehouseActiveOrders(List<String> warehouseCategories) {
    return orders.where((order) {
      final warehouseItems = order.getItemsForWarehouse(warehouseCategories);
      if (warehouseItems.isEmpty) return false;

      // Active = at least one item is NOT fulfilled
      return warehouseItems
          .any((item) => item.status != AppConstants.statusFulfilled);
    }).toList();
  }

  // ✅ FIXED: An order is "fulfilled" for a warehouse if ALL of its
  // items in that category are FULFILLED (and it has items).
  // ✅ FIXED: An order is "fulfilled" for a warehouse if ALL of its
  // items in that category are FULFILLED (and it has items).
  List<Order> getWarehouseFulfilledOrders(List<String> warehouseCategories) {
    return orders.where((order) {
      final warehouseItems = order.getItemsForWarehouse(warehouseCategories);
      if (warehouseItems.isEmpty) return false;

      return warehouseItems
          .every((item) => item.status == AppConstants.statusFulfilled);
    }).toList();
  }

  // ✅ FIXED: Count item.quantity, not just number of CartItem entries
  int getWarehouseItemCountByStatus(List<String> warehouseCategories, String status) {
    int count = 0;
    for (var order in orders) {
      final warehouseItems = order.getItemsForWarehouse(warehouseCategories);
      for (var item in warehouseItems) {
        if (item.status == status) {
          count += item.quantity;
        }
      }
    }
    return count;
  }

  // Today's warehouse order count
  int getTodaysWarehouseOrderCount(List<String> warehouseCategories) {
    final today = DateTime.now();
    return orders.where((order) {
      if (order.timestamp.year != today.year ||
          order.timestamp.month != today.month ||
          order.timestamp.day != today.day) {
        return false;
      }
      return order.getItemsForWarehouse(warehouseCategories).isNotEmpty;
    }).length;
  }

  // ✅ FIXED: Count item.quantity, not just number of CartItem entries
  int getTodaysWarehouseItemCount(List<String> warehouseCategories) {
    final today = DateTime.now();
    int count = 0;
    for (var order in orders) {
      if (order.timestamp.year == today.year &&
          order.timestamp.month == today.month &&
          order.timestamp.day == today.day) {
        final warehouseItems = order.getItemsForWarehouse(warehouseCategories);
        for (var item in warehouseItems) {
          count += item.quantity;
        }
      }
    }
    return count;
  }

  // ✅ FIXED: Count item.quantity for fulfilled items
  int getTodaysFulfilledWarehouseItemCount(List<String> warehouseCategories) {
    final today = DateTime.now();
    int count = 0;
    for (var order in orders) {
      if (order.timestamp.year == today.year &&
          order.timestamp.month == today.month &&
          order.timestamp.day == today.day) {
        final warehouseItems = order.getItemsForWarehouse(warehouseCategories);
        for (var item in warehouseItems) {
          if (item.status == AppConstants.statusFulfilled) {
            count += item.quantity;
          }
        }
      }
    }
    return count;
  }
}

class OrderStatusUpdated extends OrderState {
  final String orderId;
  final String newStatus;

  const OrderStatusUpdated({
    required this.orderId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [orderId, newStatus];
}

class OrderError extends OrderState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}