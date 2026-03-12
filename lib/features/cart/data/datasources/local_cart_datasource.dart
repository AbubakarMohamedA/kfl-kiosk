import 'package:drift/drift.dart';
import 'package:sss/core/database/app_database.dart' hide Product;
import 'package:sss/core/database/daos/cart_dao.dart';
import 'package:sss/features/cart/data/models/cart_item_model.dart';
import 'package:sss/features/products/data/datasources/local_product_datasource.dart';
import 'package:sss/features/products/data/models/product_model.dart';

class LocalCartDataSource {
  final CartDao _cartDao;
  final LocalProductDataSource _productDataSource;

  LocalCartDataSource(this._cartDao, this._productDataSource);

  
  // Add item to cart or update quantity if already exists
  Future<void> addItem(CartItemModel item, String tenantId) async {
    await _cartDao.addItem(
      CartItemsCompanion(
        productId: Value(item.productModel.id),
        quantity: Value(item.quantity),
        productName: Value(item.productModel.name),
        productPrice: Value(item.productModel.price),
        productImage: Value(item.productModel.imageUrl),
      ),
      tenantId,
    );
  }
 
  // Remove item from cart
  Future<void> removeItem(String productId, String tenantId) async {
    await _cartDao.removeItem(productId, tenantId);
  }
 
  // Update item quantity
  Future<void> updateQuantity(String productId, int quantity, String tenantId) async {
    await _cartDao.updateQuantity(productId, quantity, tenantId);
  }
 
  // Get all cart items
  Future<List<CartItemModel>> getItems(String tenantId) async {
    final dbItems = await _cartDao.getAllItems(tenantId);
    final List<CartItemModel> models = [];
    
    for (final item in dbItems) {
      // 1. Try local lookup
      var product = await _productDataSource.getProductById(item.productId);
      
      // 2. Fallback to snapshot if local lookup fails (Thin client or out of sync)
      if (product == null && item.productName != null) {
        product = ProductModel(
          id: item.productId,
          name: item.productName!,
          price: item.productPrice ?? 0.0,
          imageUrl: item.productImage ?? '',
          brand: '', // Snapshot doesn't keep everything to save space
          category: '',
          size: '',
          description: '',
        );
      }

      if (product != null) {
        models.add(CartItemModel(
          productModel: product,
          quantity: item.quantity,
        ));
      }
    }
    return models;
  }
 
  // Get cart item by product ID
  Future<CartItemModel?> getItemByProductId(String productId, String tenantId) async {
    final items = await getItems(tenantId);
    try {
      return items.firstWhere((i) => i.productModel.id == productId);
    } catch (e) {
      return null;
    }
  }
 
  // Clear entire cart
  Future<void> clear(String tenantId) async {
    await _cartDao.clearCart(tenantId);
  }
 
  // Get total number of items
  Future<int> getItemCount(String tenantId) async {
    final items = await _cartDao.getAllItems(tenantId);
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }
 
  // Get cart total price
  Future<double> getTotal(String tenantId) async {
    final items = await getItems(tenantId);
    return items.fold<double>(0.0, (sum, item) => sum + item.subtotal);
  }
 
  // Check if cart is empty
  Future<bool> isEmpty(String tenantId) async {
    final items = await _cartDao.getAllItems(tenantId);
    return items.isEmpty;
  }
 
  // Check if product is in cart
  Future<bool> containsProduct(String productId, String tenantId) async {
    final items = await _cartDao.getAllItems(tenantId);
    return items.any((i) => i.productId == productId);
  }
 
  // Get quantity of specific product in cart
  Future<int> getProductQuantity(String productId, String tenantId) async {
    final items = await _cartDao.getAllItems(tenantId);
    try {
      return items.firstWhere((i) => i.productId == productId).quantity;
    } catch (e) {
      return 0;
    }
  }
}