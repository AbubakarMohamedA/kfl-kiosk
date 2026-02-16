abstract class PaymentRepository {
  Future<bool> processPayment({
    required String phoneNumber,
    required double amount,
    required String orderId,
  });
  Future<String> getPaymentStatus(String transactionId);
}
