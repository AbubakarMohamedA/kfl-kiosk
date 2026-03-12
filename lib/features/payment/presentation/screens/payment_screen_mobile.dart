import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sss/core/constants/app_constants.dart';
import 'package:sss/features/cart/domain/entities/cart_item.dart';
import 'package:sss/features/orders/domain/entities/order.dart';
import 'package:sss/features/payment/presentation/bloc/payment/payment_bloc.dart';
import 'package:sss/features/payment/presentation/bloc/payment/payment_event.dart';
import 'package:sss/features/payment/presentation/bloc/payment/payment_state.dart';
import 'package:sss/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:sss/features/orders/presentation/bloc/order/order_event.dart';
import 'package:sss/features/cart/presentation/bloc/cart/cart_bloc.dart';
import 'package:sss/features/cart/presentation/bloc/cart/cart_event.dart';
import 'package:sss/features/orders/presentation/screens/receipt_screen_mobile.dart';
// Note: CartItemWidget import might also be needed if used, but it's not used in PaymentScreenMobile based on previous view?
// Wait, previous build error said `CartItemWidget` isn't defined in `lib/features/cart/presentation/screens/cart_screen_mobile.dart`.
// Ah, the error I saw was for `cart_screen_mobile.dart` NOT `payment_screen_mobile.dart`.
// "lib/features/cart/presentation/screens/cart_screen_mobile.dart:186:40: Error: The method 'CartItemWidget' isn't defined"
// But for `payment_screen_mobile.dart`:
// "lib/features/payment/presentation/screens/payment_screen_mobile.dart:61:39: Error: The method 'ReceiptScreenMobile' isn't defined"
// So I need to fix `PaymentScreenMobile` to import `ReceiptScreenMobile`.

class PaymentScreenMobile extends StatefulWidget {
  final String language;
  final List<CartItem> cartItems;
  final double total;

  const PaymentScreenMobile({
    super.key,
    required this.language,
    required this.cartItems,
    required this.total,
  });

  @override
  State<PaymentScreenMobile> createState() => _PaymentScreenMobileState();
}

class _PaymentScreenMobileState extends State<PaymentScreenMobile> {
  String phoneNumber = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('payment', widget.language)),
        backgroundColor: const Color(AppColors.primaryBlue),
        foregroundColor: Colors.white,
      ),
      body: BlocListener<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
             _createOrder(context, widget.cartItems, widget.total, phoneNumber);
          }
        },
        child: BlocBuilder<PaymentBloc, PaymentState>(
          builder: (context, state) {
            if (state is PaymentProcessing) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(AppStrings.get('waiting_confirmation', widget.language), style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 8),
                    Text(AppStrings.get('check_phone', widget.language), style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(AppStrings.get('enter_mpesa', widget.language), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!, width: 2), borderRadius: BorderRadius.circular(16)),
                    child: Text(phoneNumber.isEmpty ? '0712345678' : phoneNumber, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2, color: phoneNumber.isEmpty ? Colors.grey : Colors.black)),
                  ),
                  const SizedBox(height: 32),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      ...[1,2,3,4,5,6,7,8,9].map((n) => _buildButton('$n')),
                      _buildButton('⌫', isBackspace: true),
                      _buildButton('0'),
                      _buildButton('✓', isConfirm: true),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.get('total', widget.language),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('KSh ${widget.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(AppColors.primaryBlue))),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildButton(String value, {bool isBackspace = false, bool isConfirm = false}) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          if (isBackspace) {
            if (phoneNumber.isNotEmpty) phoneNumber = phoneNumber.substring(0, phoneNumber.length - 1);
          } else if (isConfirm) {
            if (phoneNumber.length >= 10) {
              context.read<PaymentBloc>().add(InitiatePayment(phoneNumber: phoneNumber, amount: widget.total, orderId: 'temp'));
            }
          } else {
            if (phoneNumber.length < 10) phoneNumber += value;
          }
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isConfirm ? Colors.green : isBackspace ? Colors.red[100] : Colors.grey[200],
        foregroundColor: isConfirm ? Colors.white : isBackspace ? Colors.red : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    );
    }

  Future<void> _createOrder(BuildContext context, List<CartItem> items, double total, String phone) async {
    try {
      final orderBloc = context.read<OrderBloc>();
      // Use the actual use case to get the next sequential ID
      final orderId = await orderBloc.generateOrderIdUseCase();
      
      final order = Order(
        id: orderId,
        items: items,
        total: total,
        phone: phone,
        timestamp: DateTime.now(),
        status: AppConstants.statusPaid,
      );
      
      if (!mounted) return;
      
      context.read<OrderBloc>().add(CreateOrder(order));
      context.read<CartBloc>().add(const ClearCart());
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptScreenMobile(
            language: widget.language,
            order: order,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create order: $e'), backgroundColor: Colors.red),
      );
    }
  }
}