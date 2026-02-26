import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kfm_kiosk/core/constants/app_constants.dart';
import 'package:kfm_kiosk/features/cart/domain/entities/cart_item.dart';
import 'package:kfm_kiosk/features/orders/domain/entities/order.dart';
import 'package:kfm_kiosk/features/payment/presentation/bloc/payment/payment_bloc.dart';
import 'package:kfm_kiosk/features/payment/presentation/bloc/payment/payment_event.dart';
import 'package:kfm_kiosk/features/payment/presentation/bloc/payment/payment_state.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_bloc.dart';
import 'package:kfm_kiosk/features/orders/presentation/bloc/order/order_event.dart';
import 'package:kfm_kiosk/features/cart/presentation/bloc/cart/cart_bloc.dart';
import 'package:kfm_kiosk/features/cart/presentation/bloc/cart/cart_event.dart';
import 'package:kfm_kiosk/features/orders/presentation/screens/receipt_screen_desktop.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kfm_kiosk/core/database/daos/tenant_config_dao.dart';
import 'package:kfm_kiosk/di/injection.dart';

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

  Color _primaryColor = const Color(0xFF006838);
  Color _secondaryColor = const Color(0xFFFF7F50);
  StreamSubscription? _configSubscription;

  @override
  void initState() {
    super.initState();
    _generateOrderId();
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
          setState(() {
            if (config.primaryColor != null) {
              _primaryColor = Color(config.primaryColor!);
            }
            if (config.secondaryColor != null) {
              _secondaryColor = Color(config.secondaryColor!);
            }
          });
        }
      });
    }
  }

  Future<void> _generateOrderId() async {
    try {
      final orderBloc = context.read<OrderBloc>();
      final orderId = await orderBloc.generateOrderIdUseCase();

      if (mounted) {
        setState(() {
          generatedOrderId = orderId;
          isGeneratingOrderId = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          generatedOrderId =
              'ORD${DateTime.now().millisecondsSinceEpoch % 10000}';
          isGeneratingOrderId = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.10),
        child: AppBar(
          title: Text(
            'PAYMENT',
            style: TextStyle(
              fontSize: screenHeight * 0.04,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          centerTitle: true,
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
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
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
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
              return _buildProcessingView(screenHeight, screenWidth);
            }

            return _buildPaymentView(screenHeight, screenWidth);
          },
        ),
      ),
    );
  }

  Widget _buildProcessingView(double screenHeight, double screenWidth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: screenHeight * 0.12,
            height: screenHeight * 0.12,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              color: _primaryColor,
            ),
          ),
          SizedBox(height: screenHeight * 0.04),
          Text(
            AppStrings.get('waiting_confirmation', widget.language),
            style: TextStyle(
              fontSize: screenHeight * 0.035,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            AppStrings.get('check_phone', widget.language),
            style: TextStyle(
              fontSize: screenHeight * 0.025,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (!isGeneratingOrderId && generatedOrderId != null) ...[
            SizedBox(height: screenHeight * 0.01),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,
                vertical: screenHeight * 0.02,
              ),
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/images/OrderIcon.svg',
                    width: screenHeight * 0.04,
                    height: screenHeight * 0.04,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Text(
                    generatedOrderId!,
                    style: TextStyle(
                      fontSize: screenHeight * 0.035,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentView(double screenHeight, double screenWidth) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: screenWidth * 0.4,
                  maxHeight: screenHeight * 0.85,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Order ID Badge
                    if (!isGeneratingOrderId && generatedOrderId != null)
                      _buildOrderBadge(screenHeight, screenWidth)
                    else
                      _buildLoadingBadge(screenHeight, screenWidth),

                    SizedBox(height: screenHeight * 0.01),

                    // Title
                    Text(
                      'Enter M-pesa Phone Number',
                      style: TextStyle(
                        fontSize: screenHeight * 0.028,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: screenHeight * 0.025),

                    // Phone Number Display
                    _buildPhoneDisplay(screenHeight, screenWidth),

                    SizedBox(height: screenHeight * 0.025),

                    // Numpad
                    _buildNumpad(screenHeight, screenWidth),

                    SizedBox(height: screenHeight * 0.025),

                    // Total Display
                    _buildTotalDisplay(screenHeight, screenWidth),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderBadge(double screenHeight, double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.025,
        vertical: screenHeight * 0.015,
      ),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/images/OrderIcon.svg',
            width: screenHeight * 0.03,
            height: screenHeight * 0.03,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          SizedBox(width: screenWidth * 0.008),
          Text(
            generatedOrderId!,
            style: TextStyle(
              fontSize: screenHeight * 0.024,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBadge(double screenHeight, double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.025,
        vertical: screenHeight * 0.015,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: screenHeight * 0.02,
            height: screenHeight * 0.02,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(width: screenWidth * 0.01),
          Text(
            'Generating...',
            style: TextStyle(
              fontSize: screenHeight * 0.018,
              color: Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneDisplay(double screenHeight, double screenWidth) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorMessage != null ? Colors.red : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              phoneNumber.isEmpty ? '+254 _________' : '+254 $phoneNumber',
              style: TextStyle(
                fontSize: screenHeight * 0.032,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
                color: phoneNumber.isEmpty ? Colors.grey[400] : Colors.black,
              ),
            ),
          ),
        ),

        // Error Message Display
        if (errorMessage != null) ...[
          SizedBox(height: screenHeight * 0.012),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.02,
              vertical: screenHeight * 0.012,
            ),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[700],
                  size: screenHeight * 0.022,
                ),
                SizedBox(width: screenWidth * 0.008),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: screenHeight * 0.018,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNumpad(double screenHeight, double screenWidth) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          // Row 1-3
          _buildNumpadRow(['1', '2', '3'], screenHeight, screenWidth),
          SizedBox(height: screenHeight * 0.012),

          // Row 4-6
          _buildNumpadRow(['4', '5', '6'], screenHeight, screenWidth),
          SizedBox(height: screenHeight * 0.012),

          // Row 7-9
          _buildNumpadRow(['7', '8', '9'], screenHeight, screenWidth),
          SizedBox(height: screenHeight * 0.012),

          // Bottom row: Delete, 0, Pay
          Row(
            children: [
              Expanded(
                child: _buildNumpadButton(
                  'delete',
                  screenHeight,
                  isBackspace: true,
                ),
              ),
              SizedBox(width: screenWidth * 0.012),
              Expanded(child: _buildNumpadButton('0', screenHeight)),
              SizedBox(width: screenWidth * 0.012),
              Expanded(
                child: _buildNumpadButton('PAY', screenHeight, isConfirm: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumpadRow(
    List<String> values,
    double screenHeight,
    double screenWidth,
  ) {
    return Row(
      children: [
        for (int i = 0; i < values.length; i++) ...[
          if (i > 0) SizedBox(width: screenWidth * 0.012),
          Expanded(child: _buildNumpadButton(values[i], screenHeight)),
        ],
      ],
    );
  }

  Widget _buildNumpadButton(
    String value,
    double screenHeight, {
    bool isBackspace = false,
    bool isConfirm = false,
  }) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          errorMessage = null;

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
            ? _primaryColor
            : isBackspace
            ? _secondaryColor
            : Colors.white,
        foregroundColor: isConfirm || isBackspace ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.022),
        elevation: 0,
        side: BorderSide(
          color: isConfirm || isBackspace
              ? Colors.transparent
              : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: isBackspace
          ? SvgPicture.asset(
              'assets/images/Delete_Icon.svg',
              width: screenHeight * 0.028,
              height: screenHeight * 0.028,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            )
          : Text(
              value,
              style: TextStyle(
                fontSize: isConfirm
                    ? screenHeight * 0.026
                    : screenHeight * 0.028,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildTotalDisplay(double screenHeight, double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.025,
        vertical: screenHeight * 0.018,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4D6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'TOTAL',
              style: TextStyle(
                fontSize: screenHeight * 0.026,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'KSH. ${widget.total.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: screenHeight * 0.026,
              fontWeight: FontWeight.bold,
              color: _secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNumberInput(String digit) {
    if (phoneNumber.length >= 9) {
      setState(() {
        errorMessage = 'Maximum 9 digits allowed';
      });
      return;
    }

    if (phoneNumber.isEmpty && digit != '1' && digit != '7') {
      setState(() {
        errorMessage = 'Phone number must start with 1 or 7';
      });
      return;
    }

    phoneNumber += digit;
  }

  void _handleConfirmPayment() {
    if (isGeneratingOrderId || generatedOrderId == null) {
      setState(() {
        errorMessage = 'Please wait, generating order number...';
      });
      return;
    }

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

    if (!RegExp(r'^\d+$').hasMatch(phoneNumber)) {
      setState(() {
        errorMessage = 'Phone number must contain only digits';
      });
      return;
    }

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
