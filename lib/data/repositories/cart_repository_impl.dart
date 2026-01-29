import 'package:kfm_kiosk/data/datasources/local_cart_datasource.dart';
import 'package:kfm_kiosk/data/models/cart_item_model.dart';
import 'package:kfm_kiosk/domain/entities/cart_item.dart';
import 'package:kfm_kiosk/domain/repositories/repositories.dart';

class CartRepositoryImpl implements CartRepository {
  final LocalCartDataSource dataSource;

  CartRepositoryImpl(this.dataSource);

  @override
  Future<void> addToCart(CartItem item) async {
    final cartItemModel = CartItemModel.fromEntity(item);
    await dataSource.addItem(cartItemModel);
  }

  @override
  Future<void> removeFromCart(String productId) async {
    await dataSource.removeItem(productId);
  }

  @override
  Future<void> updateQuantity(String productId, int quantity) async {
    await dataSource.updateQuantity(productId, quantity);
  }

  @override
  Future<List<CartItem>> getCartItems() async {
    final items = await dataSource.getItems();
    return items.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> clearCart() async {
    await dataSource.clear();
  }

  @override
  Future<double> getCartTotal() async {
    return await dataSource.getTotal();
  }
}