import 'package:flutter/material.dart';
import 'package:kfm_kiosk/domain/entities/order.dart';
import 'package:kfm_kiosk/presentation/screens/desktop/receipt_screen_desktop.dart';

class ReceiptScreenWeb extends StatelessWidget {
  final String language;
  final Order order;

  const ReceiptScreenWeb({
    super.key,
    required this.language,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return ReceiptScreenDesktop(language: language, order: order);
  }
}