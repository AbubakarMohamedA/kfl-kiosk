import 'package:flutter/material.dart';
import 'package:sss/features/cart/domain/entities/cart_item.dart';
import 'package:sss/features/payment/presentation/screens/payment_screen_desktop.dart';

class PaymentScreenTablet extends StatelessWidget {
  final String language;
  final List<CartItem> cartItems;
  final double total;

  const PaymentScreenTablet({
    super.key,
    required this.language,
    required this.cartItems,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return PaymentScreenDesktop(
      language: language,
      cartItems: cartItems,
      total: total,
    );
  }
}