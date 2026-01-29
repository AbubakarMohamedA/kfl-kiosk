import 'package:flutter/material.dart';
import 'package:kfm_kiosk/domain/entities/cart_item.dart';
import 'package:kfm_kiosk/presentation/screens/desktop/payment_screen_desktop.dart';

class PaymentScreenWeb extends StatelessWidget {
  final String language;
  final List<CartItem> cartItems;
  final double total;

  const PaymentScreenWeb({
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