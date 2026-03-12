import 'package:drift/drift.dart';
import 'package:sss/core/database/app_database.dart';

part 'cart_dao.g.dart';

@DriftAccessor(tables: [CartItems])
class CartDao extends DatabaseAccessor<AppDatabase> with _$CartDaoMixin {
  final AppDatabase db;

  CartDao(this.db) : super(db);

  Future<List<CartItem>> getAllItems(String tenantId) => 
      (select(cartItems)..where((tbl) => tbl.tenantId.equals(tenantId))).get();

  Stream<List<CartItem>> watchAllItems(String tenantId) => 
      (select(cartItems)..where((tbl) => tbl.tenantId.equals(tenantId))).watch();

  Future<void> addItem(CartItemsCompanion item, String tenantId) async {
    // Check if product already in cart for THIS tenant
    final existing = await (select(cartItems)
          ..where((tbl) => tbl.productId.equals(item.productId.value))
          ..where((tbl) => tbl.tenantId.equals(tenantId)))
        .getSingleOrNull();

    if (existing != null) {
      // Update quantity
      await (update(cartItems)..where((tbl) => tbl.id.equals(existing.id)))
          .write(CartItemsCompanion(
        quantity: Value(existing.quantity + item.quantity.value),
      ));
    } else {
      // Insert new with tenantId
      await into(cartItems).insert(item.copyWith(tenantId: Value(tenantId)));
    }
  }

  Future<void> updateQuantity(String productId, int quantity, String tenantId) async {
    if (quantity <= 0) {
      await removeItem(productId, tenantId);
      return;
    }
    await (update(cartItems)
          ..where((tbl) => tbl.productId.equals(productId))
          ..where((tbl) => tbl.tenantId.equals(tenantId)))
        .write(CartItemsCompanion(quantity: Value(quantity)));
  }

  Future<void> removeItem(String productId, String tenantId) async {
    await (delete(cartItems)
          ..where((tbl) => tbl.productId.equals(productId))
          ..where((tbl) => tbl.tenantId.equals(tenantId)))
        .go();
  }

  Future<void> clearCart(String tenantId) async {
    await (delete(cartItems)..where((tbl) => tbl.tenantId.equals(tenantId))).go();
  }
}
