import 'package:kfm_kiosk/core/usecases/usecase.dart';
import 'package:kfm_kiosk/features/orders/domain/entities/order.dart';
import 'package:kfm_kiosk/features/orders/domain/repositories/order_repository.dart';
import 'package:kfm_kiosk/features/auth/domain/repositories/auth_repository.dart';

class CreateOrder extends UseCase<String, Order> {
  final OrderRepository repository;
  CreateOrder(this.repository);

  @override
  Future<String> call(Order order) {
    return repository.createOrder(order);
  }
}

class GetAllOrders extends UseCaseNoParams<List<Order>> {
  final OrderRepository repository;
  GetAllOrders(this.repository);

  @override
  Future<List<Order>> call() {
    return repository.getAllOrders();
  }
}

class GetOrderById extends UseCase<Order?, String> {
  final OrderRepository repository;
  GetOrderById(this.repository);

  @override
  Future<Order?> call(String id) {
    return repository.getOrderById(id);
  }
}

class UpdateOrderStatus extends UseCase<void, UpdateOrderStatusParams> {
  final OrderRepository repository;
  UpdateOrderStatus(this.repository);

  @override
  Future<void> call(UpdateOrderStatusParams params) {
    return repository.updateOrderStatus(params.orderId, params.status);
  }
}

// ✅ NEW: Persists the full order including per-item statuses
class SaveFullOrder extends UseCase<void, Order> {
  final OrderRepository repository;
  SaveFullOrder(this.repository);

  @override
  Future<void> call(Order order) {
    return repository.saveFullOrder(order);
  }
}

class WatchOrders extends StreamUseCaseNoParams<List<Order>> {
  final OrderRepository repository;
  WatchOrders(this.repository);

  @override
  Stream<List<Order>> call() {
    return repository.watchOrders();
  }
}

class GenerateOrderId extends UseCaseNoParams<String> {
  final OrderRepository repository;
  final AuthRepository authRepository;

  GenerateOrderId(this.repository, this.authRepository);

  @override
  Future<String> call() async {
    final currentTenant = await authRepository.getCurrentTenant();
    final tenantId = currentTenant?.id;
    
    final counter = await repository.getOrderCounter(tenantId: tenantId);
    await repository.incrementOrderCounter(tenantId: tenantId);
    
    // ✅ Prefix tenant ID to ensure global uniqueness across devices/tenants
    // Format: TEN001-ORD0001
    final prefix = tenantId != null ? '$tenantId-' : '';
    return '${prefix}ORD${counter.toString().padLeft(4, '0')}';
  }
}

class UpdateOrderStatusParams {
  final String orderId;
  final String status;

  UpdateOrderStatusParams({
    required this.orderId,
    required this.status,
  });
}