import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kfm_kiosk/core/database/daos/tenant_config_dao.dart';
import 'package:kfm_kiosk/di/injection.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/core/platform/platform_info.dart';
import 'package:kfm_kiosk/features/products/presentation/bloc/product/product_bloc.dart';
import 'package:kfm_kiosk/features/products/presentation/bloc/product/product_state.dart';
import 'package:kfm_kiosk/features/products/presentation/bloc/product/product_event.dart';
import 'package:kfm_kiosk/features/cart/presentation/bloc/cart/cart_bloc.dart';
import 'package:kfm_kiosk/features/cart/presentation/bloc/cart/cart_state.dart';
import 'package:kfm_kiosk/features/cart/presentation/bloc/cart/cart_event.dart';
import 'package:kfm_kiosk/features/products/presentation/widgets/product_card.dart';
import 'package:kfm_kiosk/features/cart/presentation/widgets/cart_item_widget.dart';
import 'package:kfm_kiosk/features/payment/presentation/screens/payment_screen_desktop.dart';
import 'package:kfm_kiosk/features/products/presentation/widgets/app_image.dart';

class CatalogScreenDesktop extends StatefulWidget {
  final String language;

  const CatalogScreenDesktop({super.key, required this.language});

  @override
  State<CatalogScreenDesktop> createState() => _CatalogScreenDesktopState();
}

class _CatalogScreenDesktopState extends State<CatalogScreenDesktop> {
  Color _primaryColor = Color(AppColors.primaryBlue);
  StreamSubscription? _configSubscription;

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setupStream() async {
    final prefs = await SharedPreferences.getInstance();
    final tenantId = prefs.getString('last_synced_tenant_id');
    if (tenantId != null) {
      _configSubscription?.cancel();
      _configSubscription = getIt<TenantConfigDao>().watchConfig(tenantId).listen((config) {
        if (config != null && mounted) {
          if (config.primaryColor != null) {
            final newColor = Color(config.primaryColor!);
            if (newColor != _primaryColor) {
              setState(() {
                _primaryColor = newColor;
              });
            }
          }
        }
      });
    }
  }

  void _showOrderConfirmationDialog(BuildContext context, CartLoaded state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<CartBloc>(),
        child: BlocConsumer<CartBloc, CartState>(
          listenWhen: (previous, current) {
            // Listen only to feedback states
            return current is CartItemAdded || current is CartItemRemoved;
          },
          listener: (context, state) {
            // Handle feedback states here if needed
            // The UI won't rebuild for these states
          },
          buildWhen: (previous, current) {
            // Only rebuild for CartLoaded and CartEmpty states
            // Ignore transient states like CartItemAdded, CartItemRemoved
            return current is CartLoaded || current is CartEmpty;
          },
          builder: (context, cartState) {
            // Only close dialog if cart is truly empty (CartEmpty state)
            if (cartState is CartEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.canPop(dialogContext)) {
                  Navigator.of(dialogContext).pop();
                }
              });
              return SizedBox();
            }

            // If not CartLoaded, don't render anything
            if (cartState is! CartLoaded) {
              return SizedBox();
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 600,
                constraints: BoxConstraints(maxHeight: 700),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 32,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppStrings.get('confirm_order', widget.language),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.get(
                                'review_order_message',
                                widget.language,
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 20),

                            // Order Items
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: cartState.items.length,
                                separatorBuilder: (context, index) =>
                                    Divider(height: 1, color: Colors.grey[300]),
                                itemBuilder: (context, index) {
                                  final item = cartState.items[index];
                                  return Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Product Image
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: AppImage(
                                              imageUrl: item.product.imageUrl,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16),

                                        // Product Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.product.name,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                '${item.product.brand} • ${item.product.size}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'KSh ${item.product.price.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Quantity Controls
                                        Container(
                                          decoration: BoxDecoration(
                                            color: _primaryColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              // Decrease button
                                              IconButton(
                                                onPressed: () {
                                                  if (item.quantity > 1) {
                                                    context.read<CartBloc>().add(
                                                      UpdateCartItemQuantity(
                                                        productId:
                                                            item.product.id,
                                                        quantity:
                                                            item.quantity - 1,
                                                      ),
                                                    );
                                                  } else {
                                                    context
                                                        .read<CartBloc>()
                                                        .add(
                                                          RemoveFromCart(
                                                            item.product.id,
                                                          ),
                                                        );
                                                  }
                                                },
                                                icon: Icon(
                                                  item.quantity > 1
                                                      ? Icons.remove
                                                      : Icons.delete_outline,
                                                  color: _primaryColor,
                                                ),
                                                iconSize: 20,
                                                padding: EdgeInsets.all(8),
                                                constraints: BoxConstraints(),
                                              ),

                                              // Quantity display
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                ),
                                                child: Text(
                                                  '${item.quantity}',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: _primaryColor,
                                                  ),
                                                ),
                                              ),

                                              // Increase button
                                              IconButton(
                                                onPressed: () {
                                                  context.read<CartBloc>().add(
                                                    UpdateCartItemQuantity(
                                                      productId:
                                                          item.product.id,
                                                      quantity:
                                                          item.quantity + 1,
                                                    ),
                                                  );
                                                },
                                                icon: Icon(
                                                  Icons.add,
                                                  color: _primaryColor,
                                                ),
                                                iconSize: 20,
                                                padding: EdgeInsets.all(8),
                                                constraints: BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                        ),

                                        SizedBox(width: 16),

                                        // Subtotal
                                        Text(
                                          'KSh ${item.subtotal.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: _primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            SizedBox(height: 20),

                            // Total
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      AppStrings.get('total', widget.language),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    'KSh ${cartState.total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: _primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Actions
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(
                                  color: _primaryColor,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                AppStrings.get('cancel', widget.language),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentScreenDesktop(
                                      language: widget.language,
                                      cartItems: cartState.items,
                                      total: cartState.total,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    Expanded(
                                      child: Text(
                                        AppStrings.get(
                                          'confirm_and_pay',
                                          widget.language,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('select_items', widget.language)),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // Products Section
          Expanded(
            flex: 2,
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                if (state is ProductLoaded) {
                  return Column(
                    children: [
                      // Category filters
                      Container(
                        height: 70,
                        color: Colors.grey[200],
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.all(12),
                          itemCount: state.categories.length,
                          itemBuilder: (context, index) {
                            final category = state.categories[index];
                            final isSelected =
                                category == state.selectedCategory;

                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text(
                                  category,
                                  style: TextStyle(fontSize: 16),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  context.read<ProductBloc>().add(
                                    FilterProductsByCategory(category),
                                  );
                                },
                                selectedColor: _primaryColor,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Products grid
                      Expanded(
                        child: GridView.builder(
                          padding: EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    ResponsiveUtils.getGridCrossAxisCount(
                                      width - 400,
                                    ),
                                childAspectRatio: 0.72,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: state.filteredProducts.length,
                          itemBuilder: (context, index) {
                            return ProductCard(
                              product: state.filteredProducts[index],
                              primaryColor: _primaryColor,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }

                return Center(child: Text('No products available'));
              },
            ),
          ),

          // Cart Section (Right Sidebar)
          Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: Offset(-5, 0),
                ),
              ],
            ),
            child: BlocConsumer<CartBloc, CartState>(
              listenWhen: (previous, current) {
                // Listen only to feedback states
                return current is CartItemAdded || current is CartItemRemoved;
              },
              listener: (context, state) {
                // Handle feedback states here if needed (e.g., show snackbar)
                // But don't rebuild the UI
              },
              buildWhen: (previous, current) {
                // Rebuild for CartLoaded (including after transient states)
                // Also rebuild for CartEmpty and CartInitial
                // This ensures the UI always has the latest cart data
                return current is CartLoaded ||
                    current is CartEmpty ||
                    current is CartInitial;
              },
              builder: (context, state) {
                // Handle CartLoaded state
                if (state is CartLoaded) {
                  final itemCount = state.itemCount;
                  final items = state.items;
                  final total = state.total;
                  final isEmpty = items.isEmpty;

                  return Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        color: _primaryColor,
                        child: Row(
                          children: [
                            Icon(
                              Icons.shopping_cart,
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                AppStrings.get('your_cart', widget.language),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$itemCount',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      AppStrings.get(
                                        'cart_empty',
                                        widget.language,
                                      ),
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.all(16),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  return CartItemWidget(
                                    item: items[index],
                                    isCompact: true,
                                  );
                                },
                              ),
                      ),

                      if (!isEmpty)
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: Offset(0, -5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppStrings.get('total', widget.language),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'KSh ${total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: _primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _showOrderConfirmationDialog(
                                    context,
                                    state,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    AppStrings.get(
                                      'proceed_to_payment',
                                      widget.language,
                                    ),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                }

                // Fallback for empty or other states
                return Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      color: _primaryColor,
                      child: Row(
                        children: [
                          Icon(
                            Icons.shopping_cart,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppStrings.get('your_cart', widget.language),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '0',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              AppStrings.get('cart_empty', widget.language),
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
