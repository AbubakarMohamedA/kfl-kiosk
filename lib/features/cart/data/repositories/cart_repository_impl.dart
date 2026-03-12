import 'package:sss/features/auth/domain/repositories/auth_repository.dart';
import 'package:sss/core/configuration/domain/repositories/configuration_repository.dart';
import 'package:sss/features/cart/data/datasources/local_cart_datasource.dart';
import 'package:sss/features/cart/data/models/cart_item_model.dart';
import 'package:sss/features/cart/domain/entities/cart_item.dart';
import 'package:sss/features/cart/domain/repositories/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  final LocalCartDataSource dataSource;
  final AuthRepository authRepository;
  final ConfigurationRepository configRepository;

  CartRepositoryImpl(
    this.dataSource,
    this.authRepository,
    this.configRepository,
  );

  Future<String> _getTenantId() async {
    final tenant = await authRepository.getCurrentTenant();
    if (tenant != null) return tenant.id;
    
    final config = await configRepository.getConfiguration();
    return config.tenantId ?? 'SUPER_ADMIN'; // Fallback
  }

  @override
  Future<void> addToCart(CartItem item) async {
    final tenantId = await _getTenantId();
    final cartItemModel = CartItemModel.fromEntity(item);
    await dataSource.addItem(cartItemModel, tenantId);
  }

  @override
  Future<void> removeFromCart(String productId) async {
    final tenantId = await _getTenantId();
    await dataSource.removeItem(productId, tenantId);
  }

  @override
  Future<void> updateQuantity(String productId, int quantity) async {
    final tenantId = await _getTenantId();
    await dataSource.updateQuantity(productId, quantity, tenantId);
  }

  @override
  Future<List<CartItem>> getCartItems() async {
    final tenantId = await _getTenantId();
    final items = await dataSource.getItems(tenantId);
    return items.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> clearCart() async {
    final tenantId = await _getTenantId();
    await dataSource.clear(tenantId);
  }

  @override
  Future<double> getCartTotal() async {
    final tenantId = await _getTenantId();
    return await dataSource.getTotal(tenantId);
  }
}