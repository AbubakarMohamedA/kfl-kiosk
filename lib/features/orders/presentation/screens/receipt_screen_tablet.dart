import 'package:flutter/material.dart';
import 'package:sss/features/orders/domain/entities/order.dart';
import 'package:sss/features/orders/presentation/screens/receipt_screen_desktop.dart';

class ReceiptScreenTablet extends StatelessWidget {
  final String language;
  final Order order;

  const ReceiptScreenTablet({
    super.key,
    required this.language,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return ReceiptScreenDesktop(language: language, order: order);
  }
}