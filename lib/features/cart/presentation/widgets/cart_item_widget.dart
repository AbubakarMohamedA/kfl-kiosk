import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/features/cart/domain/entities/cart_item.dart';
import 'package:kfm_kiosk/features/cart/presentation/bloc/cart/cart_bloc.dart';
import 'package:kfm_kiosk/features/cart/presentation/bloc/cart/cart_event.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final bool isCompact;

  const CartItemWidget({
    super.key,
    required this.item,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 8 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.product.brand} • ${item.product.size}',
                    style: TextStyle(
                      fontSize: isCompact ? 12 : 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'KSh ${item.product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: isCompact ? 12 : 14,
                          color: const Color(AppColors.primaryBlue),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(' × '),
                      Text(
                        '${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text(' = '),
                      Text(
                        'KSh ${item.subtotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: isCompact ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(AppColors.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quantity Controls
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        item.quantity > 1
                            ? Icons.remove_circle_outline
                            : Icons.delete_outline,
                        size: isCompact ? 20 : 24,
                      ),
                      onPressed: () {
                        context
                            .read<CartBloc>()
                            .add(DecrementQuantity(item.product.id));
                      },
                      color: item.quantity > 1 ? Colors.grey : Colors.red,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 8 : 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: TextStyle(
                          fontSize: isCompact ? 16 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        size: isCompact ? 20 : 24,
                      ),
                      onPressed: () {
                        context
                            .read<CartBloc>()
                            .add(IncrementQuantity(item.product.id));
                      },
                      color: const Color(AppColors.primaryBlue),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}