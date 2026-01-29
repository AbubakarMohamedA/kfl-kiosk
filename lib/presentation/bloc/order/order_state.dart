import 'package:equatable/equatable.dart';
import 'package:kfm_kiosk/domain/entities/order.dart';

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

  // Basic counts
  int get totalOrders => orders.length;
  int get paidCount => orders.where((o) => o.status == 'PAID').length;
  int get preparingCount => orders.where((o) => o.status == 'PREPARING').length;
  int get readyCount => orders.where((o) => o.status == 'READY FOR PICKUP').length;
  int get fulfilledCount => orders.where((o) => o.status == 'FULFILLED').length;

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
            o.status == 'FULFILLED' &&
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

  // Active orders (non-fulfilled)
  List<Order> get activeOrders =>
      orders.where((o) => o.status != 'FULFILLED').toList();

  // Completed orders
  List<Order> get completedOrders =>
      orders.where((o) => o.status == 'FULFILLED').toList();

  // Filtered active orders
  List<Order> get filteredActiveOrders =>
      filteredOrders.where((o) => (o as Order).status != 'FULFILLED').cast<Order>().toList();

  // Filtered completed orders
  List<Order> get filteredCompletedOrders =>
      filteredOrders.where((o) => (o as Order).status == 'FULFILLED').cast<Order>().toList();

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

  // Peak hour detection (hour with most orders today)
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

  // Average preparation time estimate (in minutes)
  // This is a placeholder - you should track actual timestamps
  double get averagePrepTime {
    // Implement based on your actual timestamp tracking
    // For now, return a default estimate
    return 12.0;
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