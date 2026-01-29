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
import 'package:kfm_kiosk/presentation/screens/desktop/receipt_screen_desktop.dart';

class PaymentScreenDesktop extends StatefulWidget {
  final String language;
  final List<CartItem> cartItems;
  final double total;

  const PaymentScreenDesktop({
    super.key,
    required this.language,
    required this.cartItems,
    required this.total,
  });

  @override
  State<PaymentScreenDesktop> createState() => _PaymentScreenDesktopState();
}

class _PaymentScreenDesktopState extends State<PaymentScreenDesktop> {
  String phoneNumber = '';
  String? errorMessage;
  String? generatedOrderId;
  bool isGeneratingOrderId = true;

  @override
  void initState() {
    super.initState();
    _generateOrderId();
  }

  Future<void> _generateOrderId() async {
    try {
      // Access the OrderBloc's generateOrderIdUseCase directly
      final orderBloc = context.read<OrderBloc>();
      final orderId = await orderBloc.generateOrderIdUseCase();
      
      if (mounted) {
        setState(() {
          generatedOrderId = orderId;
          isGeneratingOrderId = false;
        });
      }
    } catch (e) {
      // Fallback to timestamp-based ID if generation fails
      if (mounted) {
        setState(() {
          generatedOrderId = 'ORD${DateTime.now().millisecondsSinceEpoch % 10000}';
          isGeneratingOrderId = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.get('payment', widget.language),
          style: const TextStyle(fontSize: 28),
        ),
        backgroundColor: const Color(AppColors.primaryBlue),
        foregroundColor: Colors.white,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            final order = Order(
              id: generatedOrderId ?? 'ORD0000001',
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
                builder: (context) => ReceiptScreenDesktop(
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
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.message,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                padding: const EdgeInsets.all(20),
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
                    const SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(strokeWidth: 6),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      AppStrings.get('waiting_confirmation', widget.language),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.get('check_phone', widget.language),
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!isGeneratingOrderId && generatedOrderId != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              AppStrings.get('order_number', widget.language),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              generatedOrderId!,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(AppColors.primaryBlue),
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      // Order ID Display
                      if (!isGeneratingOrderId && generatedOrderId != null) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(AppColors.primaryBlue).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(AppColors.primaryBlue).withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.receipt_long,
                                color: Color(AppColors.primaryBlue),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.get('order_number', widget.language),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    generatedOrderId!,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(AppColors.primaryBlue),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      
                      // Loading indicator while generating order ID
                      if (isGeneratingOrderId) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Generating order number...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      
                      // Title
                      Text(
                        AppStrings.get('enter_mpesa', widget.language),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      
                      // Phone number display with prefix
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: errorMessage != null 
                                ? Colors.red 
                                : const Color(AppColors.primaryBlue),
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.grey[50],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '+254 ',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            Flexible(
                              child: Text(
                                phoneNumber.isEmpty ? '_________' : phoneNumber,
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                  color: phoneNumber.isEmpty 
                                      ? Colors.grey[400] 
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Error message
                      if (errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red[300]!, width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[700], size: 28),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 48),
                      
                      // Numpad
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        childAspectRatio: 1.8,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          ...[1, 2, 3, 4, 5, 6, 7, 8, 9].map((n) => _buildButton('$n')),
                          _buildButton('⌫', isBackspace: true),
                          _buildButton('0'),
                          _buildButton('PAY', isConfirm: true),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Total amount
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(AppColors.primaryBlue).withValues(alpha: 0.1),
                              const Color(AppColors.lightBlue).withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(AppColors.primaryBlue).withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppStrings.get('total', widget.language),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'KSh ${widget.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 32,
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
                : Colors.white,
        foregroundColor: isConfirm 
            ? Colors.white 
            : isBackspace 
                ? Colors.red 
                : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        elevation: isConfirm ? 8 : 2,
        shadowColor: isConfirm ? Colors.green.withValues(alpha: 0.5) : null,
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: isConfirm ? 28 : 36,
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
    // Check if order ID is ready
    if (isGeneratingOrderId || generatedOrderId == null) {
      setState(() {
        errorMessage = 'Please wait, generating order number...';
      });
      return;
    }

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
        orderId: generatedOrderId!,
      ),
    );
  }
}