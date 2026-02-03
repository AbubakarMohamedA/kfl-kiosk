import 'package:kfm_kiosk/data/models/cart_item_model.dart';

class LocalCartDataSource {
  // In-memory cart storage (Map of productId -> CartItem)
  final Map<String, CartItemModel> _cart = {};

  // Add item to cart or update quantity if already exists
  Future<void> addItem(CartItemModel item) async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate async
    
    final productId = item.productModel.id;
    
    if (_cart.containsKey(productId)) {
      // Item already in cart, increment quantity
      final existingItem = _cart[productId]!;
      _cart[productId] = CartItemModel(
        productModel: existingItem.productModel,
        quantity: existingItem.quantity + item.quantity,
      );
    } else {
      // New item
      _cart[productId] = item;
    }
  }

  // Remove item from cart
  Future<void> removeItem(String productId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _cart.remove(productId);
  }

  // Update item quantity
  Future<void> updateQuantity(String productId, int quantity) async {
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (quantity <= 0) {
      _cart.remove(productId);
      return;
    }

    if (_cart.containsKey(productId)) {
      final item = _cart[productId]!;
      _cart[productId] = CartItemModel(
        productModel: item.productModel,
        quantity: quantity,
      );
    }
  }

  // Get all cart items
  Future<List<CartItemModel>> getItems() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _cart.values.toList();
  }

  // Get cart item by product ID
  Future<CartItemModel?> getItemByProductId(String productId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _cart[productId];
  }

  // Clear entire cart
  Future<void> clear() async {
    await Future.delayed(const Duration(milliseconds: 50));
    _cart.clear();
  }

  // Get total number of items
  Future<int> getItemCount() async {
    await Future.delayed(const Duration(milliseconds: 50));
    int total = 0;
    for (var item in _cart.values) {
      total += item.quantity;
    }
    return total;
  }

  // Get cart total price
  Future<double> getTotal() async {
    await Future.delayed(const Duration(milliseconds: 50));
    double total = 0.0;
    for (var item in _cart.values) {
      total += item.subtotal;
    }
    return total;
  }

  // Check if cart is empty
  Future<bool> isEmpty() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _cart.isEmpty;
  }

  // Check if product is in cart
  Future<bool> containsProduct(String productId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _cart.containsKey(productId);
  }

  // Get quantity of specific product in cart
  Future<int> getProductQuantity(String productId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _cart[productId]?.quantity ?? 0;
  }
}