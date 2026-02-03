import 'package:equatable/equatable.dart';
import 'package:kfm_kiosk/domain/entities/order.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrders extends OrderEvent {
  const LoadOrders();
}

class CreateOrder extends OrderEvent {
  final Order order;

  const CreateOrder(this.order);

  @override
  List<Object?> get props => [order];
}

class UpdateOrderStatus extends OrderEvent {
  final String orderId;
  final String status;

  const UpdateOrderStatus({
    required this.orderId,
    required this.status,
  });

  @override
  List<Object?> get props => [orderId, status];
}

// ✅ NEW: Update status for warehouse items only
class UpdateWarehouseItemsStatus extends OrderEvent {
  final String orderId;
  final String warehouseCategory;
  final String newStatus;

  const UpdateWarehouseItemsStatus({
    required this.orderId,
    required this.warehouseCategory,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [orderId, warehouseCategory, newStatus];
}

class SearchOrders extends OrderEvent {
  final String query;

  const SearchOrders(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterOrdersByStatus extends OrderEvent {
  final String status;

  const FilterOrdersByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

// Event for the enhanced staff panel
class FilterOrders extends OrderEvent {
  final String filter;

  const FilterOrders(this.filter);

  @override
  List<Object?> get props => [filter];
}

// Event for sorting orders
class SortOrders extends OrderEvent {
  final String sortType;

  const SortOrders(this.sortType);

  @override
  List<Object?> get props => [sortType];
}

class WatchOrdersStarted extends OrderEvent {
  const WatchOrdersStarted();
}

class OrdersUpdated extends OrderEvent {
  final List<Order> orders;

  const OrdersUpdated(this.orders);

  @override
  List<Object?> get props => [orders];
}