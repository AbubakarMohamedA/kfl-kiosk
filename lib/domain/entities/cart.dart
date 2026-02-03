import 'package:equatable/equatable.dart';
import 'package:kfm_kiosk/domain/entities/cart_item.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';

class Cart extends Equatable {
  final List<CartItem> items;

  const Cart({
    this.items = const [],
  });

  // Calculate total price of all items
  double get total {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  // Calculate total price of only PAID items
  double get paidTotal {
    return items
        .where((item) => item.status == AppConstants.statusPaid)
        .fold(0.0, (sum, item) => sum + item.subtotal);
  }

  // Calculate total price of only PENDING items
  double get pendingTotal {
    return items
        .where((item) => item.status == AppConstants.statusPaid)
        .fold(0.0, (sum, item) => sum + item.subtotal);
  }

  // Get total number of items (sum of all quantities)
  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Get number of unique products
  int get uniqueItemCount => items.length;

  // Check if cart is empty
  bool get isEmpty => items.isEmpty;

  // Check if cart has items
  bool get isNotEmpty => items.isNotEmpty;

  // Get only items with PAID status
  List<CartItem> get paidItems {
    return items.where((item) => item.status == AppConstants.statusPaid).toList();
  }

  // Get only items with PENDING status
  List<CartItem> get pendingItems {
    return items.where((item) => item.status == AppConstants.statusPaid).toList();
  }

  // Add item to cart or increase quantity if already exists
  Cart addItem(CartItem newItem) {
    final existingIndex = items.indexWhere(
      (item) => item.product.id == newItem.product.id,
    );

    if (existingIndex >= 0) {
      final updatedItems = List<CartItem>.from(items);
      updatedItems[existingIndex] = items[existingIndex].copyWith(
        quantity: items[existingIndex].quantity + newItem.quantity,
      );
      return Cart(items: updatedItems);
    } else {
      return Cart(items: [...items, newItem]);
    }
  }

  // Remove item from cart
  Cart removeItem(String productId) {
    return Cart(
      items: items.where((item) => item.product.id != productId).toList(),
    );
  }

  // Update item quantity
  Cart updateItemQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      return removeItem(productId);
    }

    final updatedItems = items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    return Cart(items: updatedItems);
  }

  // Increment item quantity
  Cart incrementItem(String productId) {
    final updatedItems = items.map((item) {
      if (item.product.id == productId) {
        return item.incrementQuantity();
      }
      return item;
    }).toList();

    return Cart(items: updatedItems);
  }

  // Decrement item quantity
  Cart decrementItem(String productId) {
    final updatedItems = items.map((item) {
      if (item.product.id == productId) {
        return item.decrementQuantity();
      }
      return item;
    }).toList();

    return Cart(items: updatedItems);
  }

  // Update the status of a specific item
  Cart updateItemStatus(String productId, String newStatus) {
    final updatedItems = items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(status: newStatus);
      }
      return item;
    }).toList();

    return Cart(items: updatedItems);
  }

  // Update the status of all items in the cart
  Cart updateAllItemsStatus(String newStatus) {
    final updatedItems =
        items.map((item) => item.copyWith(status: newStatus)).toList();
    return Cart(items: updatedItems);
  }

  // Clear all items from cart
  Cart clear() {
    return const Cart(items: []);
  }

  // Check if product exists in cart
  bool containsProduct(String productId) {
    return items.any((item) => item.product.id == productId);
  }

  // Get item by product ID
  CartItem? getItem(String productId) {
    try {
      return items.firstWhere((item) => item.product.id == productId);
    } catch (e) {
      return null;
    }
  }

  // Get quantity of a specific product
  int getProductQuantity(String productId) {
    final item = getItem(productId);
    return item?.quantity ?? 0;
  }

  // Convert entire cart to a list of maps for Firestore
  List<Map<String, dynamic>> toMapList() {
    return items.map((item) => item.toMap()).toList();
  }

  // Reconstruct cart from a list of maps from Firestore
  factory Cart.fromMapList(List<Map<String, dynamic>> mapList) {
    final items = mapList.map((map) => CartItem.fromMap(map)).toList();
    return Cart(items: items);
  }

  Cart copyWith({
    List<CartItem>? items,
  }) {
    return Cart(
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [items];

  @override
  String toString() {
    return 'Cart(items: ${items.length}, total: $total, totalItems: $totalItems)';
  }
}