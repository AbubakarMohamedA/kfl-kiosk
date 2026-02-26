import 'package:kfm_kiosk/core/usecases/usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kfm_kiosk/features/orders/domain/entities/order.dart';
import 'package:kfm_kiosk/features/orders/domain/repositories/order_repository.dart';
import 'package:kfm_kiosk/features/auth/domain/repositories/auth_repository.dart';
import 'package:kfm_kiosk/core/configuration/domain/repositories/configuration_repository.dart';

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
  final ConfigurationRepository configurationRepository; // Added for Branch Isolation

  GenerateOrderId(this.repository, this.authRepository, this.configurationRepository);

  @override
  Future<String> call() async {
    final currentTenant = await authRepository.getCurrentTenant();
    String? tenantId = currentTenant?.id;
    
    if (tenantId == null) {
      final prefs = await SharedPreferences.getInstance();
      tenantId = prefs.getString('last_synced_tenant_id');
    }

    final config = await configurationRepository.getConfiguration();
    // Only enterprise branches isolate their counters
    final branchId = config.tierId == 'enterprise' ? config.branchId : null;
    
    final counter = await repository.getOrderCounter(tenantId: tenantId, branchId: branchId);
    await repository.incrementOrderCounter(tenantId: tenantId, branchId: branchId);
    
    // Format: ORD0001
    final displayCounter = counter + 1; // Make 0-based counter into human readable 1-based order
    return 'ORD${displayCounter.toString().padLeft(4, '0')}';
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