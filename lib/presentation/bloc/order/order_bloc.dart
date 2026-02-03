import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/core/configuration/app_configuration.dart';
import 'package:kfm_kiosk/domain/entities/order.dart';
import 'package:kfm_kiosk/domain/repositories/repositories.dart';
import 'package:kfm_kiosk/domain/usecases/order_usecases.dart' as usecases;
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final usecases.CreateOrder createOrderUseCase;
  final usecases.GetAllOrders getAllOrdersUseCase;
  final usecases.UpdateOrderStatus updateOrderStatusUseCase;
  final usecases.GenerateOrderId generateOrderIdUseCase;
  final usecases.WatchOrders watchOrdersUseCase;
  final usecases.SaveFullOrder saveFullOrderUseCase;
  
  // ✅ NEW: Configuration repository dependency
  final ConfigurationRepository configurationRepository;

  StreamSubscription? _ordersSubscription;

  OrderBloc({
    required this.configurationRepository, // ✅ NEW
    required this.createOrderUseCase,
    required this.getAllOrdersUseCase,
    required this.updateOrderStatusUseCase,
    required this.generateOrderIdUseCase,
    required this.watchOrdersUseCase,
    required this.saveFullOrderUseCase,
  }) : super(const OrderInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<CreateOrder>(_onCreateOrder);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<UpdateWarehouseItemsStatus>(_onUpdateWarehouseItemsStatus);
    on<SearchOrders>(_onSearchOrders);
    on<FilterOrdersByStatus>(_onFilterByStatus);
    on<FilterOrders>(_onFilterOrders);
    on<SortOrders>(_onSortOrders);
    on<WatchOrdersStarted>(_onWatchOrdersStarted);
    on<OrdersUpdated>(_onOrdersUpdated);
  }

  // ✅ FIXED: Only show loading spinner on the very first load,
  // not on every 30-second auto-refresh
  Future<void> _onLoadOrders(
    LoadOrders event,
    Emitter<OrderState> emit,
  ) async {
    if (state is OrderInitial) {
      emit(const OrderLoading());
    }
    try {
      final orders = await getAllOrdersUseCase();
      // ✅ If we already have a loaded state, preserve filters/sort
      if (state is OrdersLoaded) {
        final currentState = state as OrdersLoaded;
        List<dynamic> filtered = orders;
        if (currentState.currentFilter != null &&
            currentState.currentFilter != 'all') {
          filtered = orders
              .where((order) =>
                  order.overallStatus == currentState.currentFilter)
              .toList();
        }
        if (currentState.currentSort != null) {
          filtered = _applySorting(filtered, currentState.currentSort!);
        }
        emit(currentState.copyWith(
          orders: orders,
          filteredOrders: filtered,
        ));
      } else {
        emit(OrdersLoaded(
          orders: orders,
          filteredOrders: orders,
        ));
      }
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
      add(const LoadOrders());
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  // ✅ UPDATED: Mode-aware status update with instant UI feedback (NO LOADING SPINNER!)
  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatus event,
    Emitter<OrderState> emit,
  ) async {
    try {
      // Get current configuration mode
      final config = await configurationRepository.getConfiguration();

      if (config.statusTrackingMode == StatusTrackingMode.orderLevel) {
        // ═══════════════════════════════════════════════════════════════
        // ORDER-LEVEL MODE: INSTANT UI UPDATE (Like Item-Level Mode)
        // ═══════════════════════════════════════════════════════════════
        if (state is OrdersLoaded) {
          final currentState = state as OrdersLoaded;
          final orderIndex = currentState.orders.indexWhere(
            (o) => o.id == event.orderId,
          );

          if (orderIndex != -1) {
            final order = currentState.orders[orderIndex];
            final updatedOrder = order.setAllItemsStatus(event.status);

            // ✅ STEP 1: Update UI IMMEDIATELY (no waiting for database)
            final updatedOrders = List<Order>.from(currentState.orders);
            updatedOrders[orderIndex] = updatedOrder;

            // Apply current filter to updated orders
            List<dynamic> filteredOrders = updatedOrders;
            if (currentState.currentFilter != null &&
                currentState.currentFilter != 'all') {
              filteredOrders = updatedOrders
                  .where((order) => order.overallStatus == currentState.currentFilter)
                  .toList();
            }
            
            // Apply current sort if exists
            if (currentState.currentSort != null) {
              filteredOrders = _applySorting(filteredOrders, currentState.currentSort!);
            }

            // ✅ Emit updated state INSTANTLY - NO loading spinner, NO delay!
            emit(currentState.copyWith(
              orders: updatedOrders,
              filteredOrders: filteredOrders,
            ));

            // ✅ STEP 2: Save to database in background (async, non-blocking)
            // The UI is already updated, so user sees instant feedback
            // If save fails, we could implement retry logic or show a warning
            saveFullOrderUseCase(updatedOrder).catchError((error) {
              // Log error but don't disrupt user experience
              // Could emit a non-critical warning state here if needed
            });

            // ✅ STEP 3: Emit success event (still instant)
            emit(OrderStatusUpdated(
              orderId: event.orderId,
              newStatus: event.status,
            ));
            return;
          }
        }
      }

      // ═══════════════════════════════════════════════════════════════
      // ITEM-LEVEL MODE: Standard flow (backward compatibility)
      // ═══════════════════════════════════════════════════════════════
      // Note: In item-level mode, UI should use UpdateWarehouseItemsStatus instead
      await updateOrderStatusUseCase(usecases.UpdateOrderStatusParams(
        orderId: event.orderId,
        status: event.status,
      ));

      emit(OrderStatusUpdated(
        orderId: event.orderId,
        newStatus: event.status,
      ));
      
      // ✅ Silent reload (LoadOrders won't show spinner since state is already OrdersLoaded)
      add(const LoadOrders());
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  // ✅ ALREADY OPTIMIZED: Warehouse updates are instant in item-level mode
  Future<void> _onUpdateWarehouseItemsStatus(
    UpdateWarehouseItemsStatus event,
    Emitter<OrderState> emit,
  ) async {
    try {
      // ONLY allow in item-level mode
      final config = await configurationRepository.getConfiguration();
      if (config.statusTrackingMode != StatusTrackingMode.itemLevel) {
        emit(OrderError(
            'Warehouse updates only available in Item-Level tracking mode'));
        return;
      }

      final currentState = state;
      if (currentState is OrdersLoaded) {
        final updatedOrders = currentState.orders.map((order) {
          if (order.id == event.orderId) {
            return order.updateWarehouseItemsStatus(
              event.warehouseCategory,
              event.newStatus,
            );
          }
          return order;
        }).toList();

        final updatedOrder = updatedOrders.firstWhere(
          (order) => order.id == event.orderId,
        );

        // Apply current filter
        List<dynamic> filteredOrders = updatedOrders;
        if (currentState.currentFilter != null &&
            currentState.currentFilter != 'all') {
          filteredOrders = updatedOrders
              .where((order) => order.overallStatus == currentState.currentFilter)
              .toList();
        }
        
        // Apply current sort
        if (currentState.currentSort != null) {
          filteredOrders = _applySorting(filteredOrders, currentState.currentSort!);
        }

        // ✅ Emit updated state immediately (already doing this correctly)
        emit(currentState.copyWith(
          orders: updatedOrders,
          filteredOrders: filteredOrders,
        ));

        // ✅ Persist in background
        saveFullOrderUseCase(updatedOrder).catchError((error) {
        });
      }
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
        List<dynamic> filtered = currentState.orders;
        if (currentState.currentFilter != null &&
            currentState.currentFilter != 'all') {
          filtered = currentState.orders
              .where((order) =>
                  (order).overallStatus == currentState.currentFilter)
              .toList();
        }
        emit(currentState.copyWith(filteredOrders: filtered));
        return;
      }
      List<dynamic> baseList = currentState.orders;
      if (currentState.currentFilter != null &&
          currentState.currentFilter != 'all') {
        baseList = currentState.orders
            .where((order) =>
                (order).overallStatus == currentState.currentFilter)
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
      // ✅ FIXED: Filter by overallStatus not order.status
      final filtered = currentState.orders
          .where((order) => order.overallStatus == event.status)
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
        // ✅ FIXED: Filter by overallStatus not order.status
        filtered = currentState.orders
            .where((order) => (order).overallStatus == event.filter)
            .toList();
      }
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
        orders.sort(
          (a, b) => (b as Order).timestamp.compareTo((a as Order).timestamp),
        );
        break;
      case 'Oldest First':
        orders.sort(
          (a, b) => (a as Order).timestamp.compareTo((b as Order).timestamp),
        );
        break;
      case 'Highest Value':
        orders.sort((a, b) => (b as Order).total.compareTo((a as Order).total));
        break;
      default:
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
      List<dynamic> filtered = event.orders;
      if (currentState.currentFilter != null &&
          currentState.currentFilter != 'all') {
        filtered = event.orders
            .where((order) =>
                (order).overallStatus == currentState.currentFilter)
            .toList();
      }
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