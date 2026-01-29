import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/domain/entities/cart_item.dart';
import 'package:kfm_kiosk/domain/entities/order.dart';
import 'package:kfm_kiosk/presentation/bloc/payment/payment_bloc.dart';
import 'package:kfm_kiosk/presentation/bloc/payment/payment_event.dart';
import 'package:kfm_kiosk/presentation/bloc/payment/payment_state.dart';
import 'package:kfm_kiosk/presentation/bloc/order/order_bloc.dart';
import 'package:kfm_kiosk/presentation/bloc/order/order_event.dart';
import 'package:kfm_kiosk/presentation/bloc/cart/cart_bloc.dart';
import 'package:kfm_kiosk/presentation/bloc/cart/cart_event.dart';
import 'package:kfm_kiosk/presentation/screens/mobile/receipt_screen_mobile.dart';

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
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width >= 360 && size.width < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('payment', widget.language)),
        backgroundColor: const Color(AppColors.primaryBlue),
        foregroundColor: Colors.white,
      ),
      body: BlocListener<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch % 10000}';
            final order = Order(
              id: orderId,
              items: widget.cartItems,
              total: widget.total,
              phone: '+254$phoneNumber',
              timestamp: DateTime.now(),
              status: AppConstants.statusPaid,
            );
            
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
          } else if (state is PaymentError) {
            setState(() {
              errorMessage = state.message;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
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
                    SizedBox(height: size.height * 0.03),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        AppStrings.get('waiting_confirmation', widget.language),
                        style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: size.height * 0.01),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        AppStrings.get('check_phone', widget.language),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Column(
                    children: [
                      Text(
                        AppStrings.get('enter_mpesa', widget.language),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : isMediumScreen ? 22 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: size.height * 0.03),
                      
                      // Phone number display with prefix
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: errorMessage != null 
                                ? Colors.red 
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '+254 ',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 24 : isMediumScreen ? 28 : 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            Flexible(
                              child: Text(
                                phoneNumber.isEmpty ? '_________' : phoneNumber,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 24 : isMediumScreen ? 28 : 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  color: phoneNumber.isEmpty ? Colors.grey : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Error message
                      if (errorMessage != null) ...[
                        SizedBox(height: size.height * 0.01),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: isSmallScreen ? 12 : 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      SizedBox(height: size.height * 0.03),
                      
                      // Numpad
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        childAspectRatio: isSmallScreen ? 1.3 : 1.5,
                        mainAxisSpacing: isSmallScreen ? 8 : 12,
                        crossAxisSpacing: isSmallScreen ? 8 : 12,
                        children: [
                          ...[1, 2, 3, 4, 5, 6, 7, 8, 9].map((n) => _buildButton('$n', size)),
                          _buildButton('⌫', size, isBackspace: true),
                          _buildButton('0', size),
                          _buildButton('✓', size, isConfirm: true),
                        ],
                      ),
                      
                      SizedBox(height: size.height * 0.02),
                      
                      // Total amount
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppStrings.get('total', widget.language),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'KSh ${widget.total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(AppColors.primaryBlue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildButton(String value, Size screenSize, {bool isBackspace = false, bool isConfirm = false}) {
    final isSmallScreen = screenSize.width < 360;
    
    return ElevatedButton(
      onPressed: () {
        setState(() {
          errorMessage = null; // Clear error on new input
          
          if (isBackspace) {
            if (phoneNumber.isNotEmpty) {
              phoneNumber = phoneNumber.substring(0, phoneNumber.length - 1);
            }
          } else if (isConfirm) {
            _handleConfirmPayment();
          } else {
            _handleNumberInput(value);
          }
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isConfirm 
            ? Colors.green 
            : isBackspace 
                ? Colors.red[100] 
                : Colors.grey[200],
        foregroundColor: isConfirm 
            ? Colors.white 
            : isBackspace 
                ? Colors.red 
                : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: isSmallScreen ? 20 : 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _handleNumberInput(String digit) {
    // Phone number can only be 9 digits (excluding +254 prefix)
    if (phoneNumber.length >= 9) {
      setState(() {
        errorMessage = 'Maximum 9 digits allowed';
      });
      return;
    }

    // First digit must be 1 or 7
    if (phoneNumber.isEmpty && digit != '1' && digit != '7') {
      setState(() {
        errorMessage = 'Phone number must start with 1 or 7';
      });
      return;
    }

    phoneNumber += digit;
  }

  void _handleConfirmPayment() {
    // Validate phone number
    if (phoneNumber.isEmpty) {
      setState(() {
        errorMessage = 'Please enter a phone number';
      });
      return;
    }

    if (phoneNumber.length != 9) {
      setState(() {
        errorMessage = 'Phone number must be exactly 9 digits';
      });
      return;
    }

    if (!phoneNumber.startsWith('1') && !phoneNumber.startsWith('7')) {
      setState(() {
        errorMessage = 'Phone number must start with 1 or 7';
      });
      return;
    }

    // Validate that all characters are digits
    if (!RegExp(r'^\d+$').hasMatch(phoneNumber)) {
      setState(() {
        errorMessage = 'Phone number must contain only digits';
      });
      return;
    }

    // All validations passed, proceed with payment
    final fullPhoneNumber = '+254$phoneNumber';
    context.read<PaymentBloc>().add(
      InitiatePayment(
        phoneNumber: fullPhoneNumber,
        amount: widget.total,
        orderId: 'temp',
      ),
    );
  }
}