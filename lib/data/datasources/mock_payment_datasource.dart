import 'package:kfm_kiosk/core/utils/validators.dart';

class MockPaymentDataSource {
  // Simulate M-Pesa payment processing
  Future<PaymentResult> processPayment({
    required String phoneNumber,
    required double amount,
    required String orderId,
  }) async {
    // Validate inputs
    if (!Validators.isValidPhoneNumber(phoneNumber)) {
      return PaymentResult(
        success: false,
        transactionId: '',
        message: 'Invalid phone number',
        errorCode: 'INVALID_PHONE',
      );
    }

    if (!Validators.isValidPaymentAmount(amount)) {
      return PaymentResult(
        success: false,
        transactionId: '',
        message: 'Invalid payment amount',
        errorCode: 'INVALID_AMOUNT',
      );
    }

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 3));

    // Simulate payment processing
    // 95% success rate for demo purposes
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final isSuccess = random < 95;

    if (isSuccess) {
      final transactionId = _generateTransactionId();
      return PaymentResult(
        success: true,
        transactionId: transactionId,
        message: 'Payment successful',
        errorCode: '',
      );
    } else {
      return PaymentResult(
        success: false,
        transactionId: '',
        message: 'Payment failed. Please try again.',
        errorCode: 'PAYMENT_FAILED',
      );
    }
  }

  // Check payment status (for polling)
  Future<String> getPaymentStatus(String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Simulate status check
    // In real implementation, this would call M-Pesa API
    return 'COMPLETED';
  }

  // Verify transaction
  Future<bool> verifyTransaction(String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In real implementation, verify with M-Pesa
    return transactionId.isNotEmpty;
  }

  // Get transaction details
  Future<Map<String, dynamic>> getTransactionDetails(
      String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return {
      'transactionId': transactionId,
      'status': 'COMPLETED',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Generate mock transaction ID
  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'MPE${timestamp}KFM';
  }

  // Simulate refund (for future use)
  Future<RefundResult> processRefund({
    required String transactionId,
    required double amount,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    return RefundResult(
      success: true,
      refundId: 'REF${DateTime.now().millisecondsSinceEpoch}',
      message: 'Refund processed successfully',
    );
  }

  // Check balance (mock - for demo)
  Future<double> checkBalance(String phoneNumber) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Return mock balance
    return 10000.0; // KSh 10,000
  }

  // Validate phone number format before payment
  Future<bool> validatePhoneNumber(String phoneNumber) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Validators.isValidPhoneNumber(phoneNumber);
  }
}

// Payment result model
class PaymentResult {
  final bool success;
  final String transactionId;
  final String message;
  final String errorCode;

  PaymentResult({
    required this.success,
    required this.transactionId,
    required this.message,
    required this.errorCode,
  });
}

// Refund result model
class RefundResult {
  final bool success;
  final String refundId;
  final String message;

  RefundResult({
    required this.success,
    required this.refundId,
    required this.message,
  });
}