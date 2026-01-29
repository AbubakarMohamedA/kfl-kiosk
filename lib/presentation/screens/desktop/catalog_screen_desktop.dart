import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/core/platform/platform_info.dart';
import 'package:kfm_kiosk/presentation/bloc/product/product_bloc.dart';
import 'package:kfm_kiosk/presentation/bloc/product/product_state.dart';
import 'package:kfm_kiosk/presentation/bloc/product/product_event.dart';
import 'package:kfm_kiosk/presentation/bloc/cart/cart_bloc.dart';
import 'package:kfm_kiosk/presentation/bloc/cart/cart_state.dart';
import 'package:kfm_kiosk/presentation/widgets/common/product_card.dart';
import 'package:kfm_kiosk/presentation/widgets/common/cart_item_widget.dart';
import 'package:kfm_kiosk/presentation/screens/desktop/payment_screen_desktop.dart';

class CatalogScreenDesktop extends StatelessWidget {
  final String language;

  const CatalogScreenDesktop({super.key, required this.language});

  void _showOrderConfirmationDialog(BuildContext context, CartLoaded state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(AppColors.primaryBlue),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.get('confirm_order', language),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.get('review_order_message', language),
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 20),
                      
                      // Order Items
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.items.length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
                          itemBuilder: (context, index) {
                            final item = state.items[index];
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Product Image (if available)
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.fastfood, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Product Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'KSh ${item.product.price.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Quantity
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(AppColors.primaryBlue).withValues(alpha:0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          AppStrings.get('qty', language),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(AppColors.primaryBlue),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 16),
                                  
                                  // Subtotal
                                  Text(
                                    'KSh ${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(AppColors.primaryBlue),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Total
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppStrings.get('total', language),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'KSh ${state.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(AppColors.primaryBlue),
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(AppColors.primaryBlue), width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          AppStrings.get('modify_order', language),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(AppColors.primaryBlue),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentScreenDesktop(
                                language: language,
                                cartItems: state.items,
                                total: state.total,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(AppColors.primaryBlue),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.get('confirm_and_pay', language),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, color: Colors.white),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('select_items', language)),
        backgroundColor: const Color(AppColors.primaryBlue),
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
                  return const Center(child: CircularProgressIndicator());
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
                          padding: const EdgeInsets.all(12),
                          itemCount: state.categories.length,
                          itemBuilder: (context, index) {
                            final category = state.categories[index];
                            final isSelected = category == state.selectedCategory;
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text(category, style: const TextStyle(fontSize: 16)),
                                selected: isSelected,
                                onSelected: (selected) {
                                  context.read<ProductBloc>().add(
                                    FilterProductsByCategory(category),
                                  );
                                },
                                selectedColor: const Color(AppColors.primaryBlue),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Products grid
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: ResponsiveUtils.getGridCrossAxisCount(width - 400),
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: state.filteredProducts.length,
                          itemBuilder: (context, index) {
                            return ProductCard(product: state.filteredProducts[index]);
                          },
                        ),
                      ),
                    ],
                  );
                }

                return const Center(child: Text('No products available'));
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
                  color: Colors.black.withValues(alpha:0.1),
                  blurRadius: 10,
                  offset: const Offset(-5, 0),
                ),
              ],
            ),
            child: BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                if (state is CartLoaded) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        color: const Color(AppColors.primaryBlue),
                        child: Row(
                          children: [
                            const Icon(Icons.shopping_cart, color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              AppStrings.get('your_cart', language),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${state.itemCount}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(AppColors.primaryBlue),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Expanded(
                        child: state.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(AppStrings.get('cart_empty', language), style: TextStyle(fontSize: 20, color: Colors.grey[600])),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: state.items.length,
                                itemBuilder: (context, index) {
                                  return CartItemWidget(item: state.items[index], isCompact: true);
                                },
                              ),
                      ),
                      
                      if (state.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha:0.1),
                                blurRadius: 10,
                                offset: const Offset(0, -5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(AppStrings.get('total', language), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                  Text('KSh ${state.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(AppColors.primaryBlue))),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _showOrderConfirmationDialog(context, state),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(AppColors.primaryBlue),
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(
                                    AppStrings.get('proceed_to_payment', language),
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                }

                return const Center(child: Text('Loading cart...'));
              },
            ),
          ),
        ],
      ),
    );
  }
}