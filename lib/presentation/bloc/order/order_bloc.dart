import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/domain/entities/order.dart';
import 'package:kfm_kiosk/domain/usecases/order_usecases.dart' as usecases;
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final usecases.CreateOrder createOrderUseCase;
  final usecases.GetAllOrders getAllOrdersUseCase;
  final usecases.UpdateOrderStatus updateOrderStatusUseCase;
  final usecases.GenerateOrderId generateOrderIdUseCase;
  final usecases.WatchOrders watchOrdersUseCase;

  StreamSubscription? _ordersSubscription;

  OrderBloc({
    required this.createOrderUseCase,
    required this.getAllOrdersUseCase,
    required this.updateOrderStatusUseCase,
    required this.generateOrderIdUseCase,
    required this.watchOrdersUseCase,
  }) : super(const OrderInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<CreateOrder>(_onCreateOrder);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<SearchOrders>(_onSearchOrders);
    on<FilterOrdersByStatus>(_onFilterByStatus);
    on<FilterOrders>(_onFilterOrders);
    on<SortOrders>(_onSortOrders);
    on<WatchOrdersStarted>(_onWatchOrdersStarted);
    on<OrdersUpdated>(_onOrdersUpdated);
  }

  Future<void> _onLoadOrders(
    LoadOrders event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    try {
      final orders = await getAllOrdersUseCase();

      emit(OrdersLoaded(
        orders: orders,
        filteredOrders: orders,
      ));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onCreateOrder(
    CreateOrder event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderCreating());
    try {
      final orderId = await createOrderUseCase(event.order);

      emit(OrderCreated(
        orderId: orderId,
        order: event.order,
      ));

      // Reload orders after creating
      add(const LoadOrders());
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatus event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await updateOrderStatusUseCase(usecases.UpdateOrderStatusParams(
        orderId: event.orderId,
        status: event.status,
      ));

      emit(OrderStatusUpdated(
        orderId: event.orderId,
        newStatus: event.status,
      ));

      // Reload orders after updating
      add(const LoadOrders());
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onSearchOrders(
    SearchOrders event,
    Emitter<OrderState> emit,
  ) async {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      final query = event.query.toLowerCase();

      if (query.isEmpty) {
        // Apply current filter if any
        List<dynamic> filtered = currentState.orders;
        if (currentState.currentFilter != null &&
            currentState.currentFilter != 'all') {
          filtered = currentState.orders
              .where((order) => (order).status == currentState.currentFilter)
              .toList();
        }

        emit(currentState.copyWith(filteredOrders: filtered));
        return;
      }

      // Apply search to current filtered list
      List<dynamic> baseList = currentState.orders;
      if (currentState.currentFilter != null &&
          currentState.currentFilter != 'all') {
        baseList = currentState.orders
            .where((order) => (order).status == currentState.currentFilter)
            .toList();
      }

      final filtered = baseList.where((order) {
        final o = order as Order;
        return o.id.toLowerCase().contains(query) ||
            o.phone.contains(query);
      }).toList();

      emit(currentState.copyWith(filteredOrders: filtered));
    }
  }

  Future<void> _onFilterByStatus(
    FilterOrdersByStatus event,
    Emitter<OrderState> emit,
  ) async {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;

      if (event.status.isEmpty || event.status == 'ALL') {
        emit(currentState.copyWith(
          filteredOrders: currentState.orders,
          selectedStatus: null,
        ));
        return;
      }

      final filtered = currentState.orders
          .where((order) => order.status == event.status)
          .toList();

      emit(currentState.copyWith(
        filteredOrders: filtered,
        selectedStatus: event.status,
      ));
    }
  }

  Future<void> _onFilterOrders(
    FilterOrders event,
    Emitter<OrderState> emit,
  ) async {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      List<dynamic> filtered;

      if (event.filter == 'all') {
        filtered = currentState.orders;
      } else {
        filtered = currentState.orders
            .where((order) => (order).status == event.filter)
            .toList();
      }

      // Apply current sort if any
      if (currentState.currentSort != null) {
        filtered = _applySorting(filtered, currentState.currentSort!);
      }

      emit(currentState.copyWith(
        filteredOrders: filtered,
        currentFilter: event.filter,
      ));
    }
  }

  Future<void> _onSortOrders(
    SortOrders event,
    Emitter<OrderState> emit,
  ) async {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      final sorted = _applySorting(
        List.from(currentState.filteredOrders),
        event.sortType,
      );

      emit(currentState.copyWith(
        filteredOrders: sorted,
        currentSort: event.sortType,
      ));
    }
  }

  List<dynamic> _applySorting(List<dynamic> orders, String sortType) {
    switch (sortType) {
      case 'Newest First':
        orders.sort((a, b) => (b as Order).timestamp.compareTo((a as Order).timestamp));
        break;
      case 'Oldest First':
        orders.sort((a, b) => (a as Order).timestamp.compareTo((b as Order).timestamp));
        break;
      case 'Highest Value':
        orders.sort((a, b) => (b as Order).total.compareTo((a as Order).total));
        break;
      default:
        // Keep original order
        break;
    }
    return orders;
  }

  Future<void> _onWatchOrdersStarted(
    WatchOrdersStarted event,
    Emitter<OrderState> emit,
  ) async {
    await _ordersSubscription?.cancel();

    _ordersSubscription = watchOrdersUseCase().listen(
      (orders) {
        add(OrdersUpdated(orders));
      },
    );
  }

  Future<void> _onOrdersUpdated(
    OrdersUpdated event,
    Emitter<OrderState> emit,
  ) async {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;

      // Maintain current filters and sorting
      List<dynamic> filtered = event.orders;

      // Apply filter
      if (currentState.currentFilter != null &&
          currentState.currentFilter != 'all') {
        filtered = event.orders
            .where((order) => (order).status == currentState.currentFilter)
            .toList();
      }

      // Apply sort
      if (currentState.currentSort != null) {
        filtered = _applySorting(filtered, currentState.currentSort!);
      }

      emit(currentState.copyWith(
        orders: event.orders,
        filteredOrders: filtered,
      ));
    } else {
      emit(OrdersLoaded(
        orders: event.orders,
        filteredOrders: event.orders,
      ));
    }
  }

  @override
  Future<void> close() {
    _ordersSubscription?.cancel();
    return super.close();
  }
}