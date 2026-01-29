import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/domain/entities/cart_item.dart';
import 'package:kfm_kiosk/domain/usecases/cart_usecases.dart' as usecases;
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final usecases.AddToCart addToCartUseCase;
  final usecases.RemoveFromCart removeFromCartUseCase;
  final usecases.UpdateCartQuantity updateQuantityUseCase;
  final usecases.GetCartItems getCartItemsUseCase;
  final usecases.ClearCart clearCartUseCase;
  final usecases.GetCartTotal getCartTotalUseCase;

  CartBloc({
    required this.addToCartUseCase,
    required this.removeFromCartUseCase,
    required this.updateQuantityUseCase,
    required this.getCartItemsUseCase,
    required this.clearCartUseCase,
    required this.getCartTotalUseCase,
  }) : super(const CartInitial()) {
    on<LoadCart>(_onLoadCart);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateCartItemQuantity>(_onUpdateQuantity);
    on<IncrementQuantity>(_onIncrementQuantity);
    on<DecrementQuantity>(_onDecrementQuantity);
    on<ClearCart>(_onClearCart);
  }

  Future<void> _onLoadCart(
    LoadCart event,
    Emitter<CartState> emit,
  ) async {
    emit(const CartLoading());
    try {
      final items = await getCartItemsUseCase();
      final total = await getCartTotalUseCase();
      final itemCount = items.fold(0, (sum, item) => sum + item.quantity);

      if (items.isEmpty) {
        emit(const CartEmpty());
      } else {
        emit(CartLoaded(
          items: items,
          total: total,
          itemCount: itemCount,
        ));
      }
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> _onAddToCart(
    AddToCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      final cartItem = CartItem(
        product: event.product,
        quantity: event.quantity,
      );

      await addToCartUseCase(cartItem);

      // Reload cart
      final items = await getCartItemsUseCase();
      final total = await getCartTotalUseCase();
      final itemCount = items.fold(0, (sum, item) => sum + item.quantity);

      emit(CartLoaded(
        items: items,
        total: total,
        itemCount: itemCount,
      ));

      // Emit temporary state to show snackbar
      emit(CartItemAdded(event.product.name));

      // Return to loaded state
      emit(CartLoaded(
        items: items,
        total: total,
        itemCount: itemCount,
      ));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> _onRemoveFromCart(
    RemoveFromCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      // Get product name before removing
      String? productName;
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final item = currentState.items.firstWhere(
          (item) => item.product.id == event.productId,
          orElse: () => currentState.items.first,
        );
        productName = item.product.name;
      }

      await removeFromCartUseCase(event.productId);

      // Reload cart
      final items = await getCartItemsUseCase();
      final total = await getCartTotalUseCase();
      final itemCount = items.fold(0, (sum, item) => sum + item.quantity);

      if (items.isEmpty) {
        emit(const CartEmpty());
      } else {
        emit(CartLoaded(
          items: items,
          total: total,
          itemCount: itemCount,
        ));
      }

      if (productName != null) {
        emit(CartItemRemoved(productName));
      }
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> _onUpdateQuantity(
    UpdateCartItemQuantity event,
    Emitter<CartState> emit,
  ) async {
    try {
      await updateQuantityUseCase(usecases.UpdateQuantityParams(
        productId: event.productId,
        quantity: event.quantity,
      ));

      // Reload cart
      final items = await getCartItemsUseCase();
      final total = await getCartTotalUseCase();
      final itemCount = items.fold(0, (sum, item) => sum + item.quantity);

      if (items.isEmpty) {
        emit(const CartEmpty());
      } else {
        emit(CartLoaded(
          items: items,
          total: total,
          itemCount: itemCount,
        ));
      }
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> _onIncrementQuantity(
    IncrementQuantity event,
    Emitter<CartState> emit,
  ) async {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      final item = currentState.items.firstWhere(
        (item) => item.product.id == event.productId,
      );

      add(UpdateCartItemQuantity(
        productId: event.productId,
        quantity: item.quantity + 1,
      ));
    }
  }

  Future<void> _onDecrementQuantity(
    DecrementQuantity event,
    Emitter<CartState> emit,
  ) async {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      final item = currentState.items.firstWhere(
        (item) => item.product.id == event.productId,
      );

      if (item.quantity > 1) {
        add(UpdateCartItemQuantity(
          productId: event.productId,
          quantity: item.quantity - 1,
        ));
      } else {
        add(RemoveFromCart(event.productId));
      }
    }
  }

  Future<void> _onClearCart(
    ClearCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      await clearCartUseCase();
      emit(const CartEmpty());
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }
}