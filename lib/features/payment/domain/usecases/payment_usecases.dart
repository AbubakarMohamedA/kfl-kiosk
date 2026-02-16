import 'package:kfm_kiosk/core/usecases/usecase.dart';
import 'package:kfm_kiosk/features/payment/domain/repositories/payment_repository.dart';

class ProcessPayment extends UseCase<bool, ProcessPaymentParams> {
  final PaymentRepository repository;

  ProcessPayment(this.repository);

  @override
  Future<bool> call(ProcessPaymentParams params) {
    return repository.processPayment(
      phoneNumber: params.phoneNumber,
      amount: params.amount,
      orderId: params.orderId,
    );
  }
}

class GetPaymentStatus extends UseCase<String, String> {
  final PaymentRepository repository;

  GetPaymentStatus(this.repository);

  @override
  Future<String> call(String transactionId) {
    return repository.getPaymentStatus(transactionId);
  }
}

class ProcessPaymentParams {
  final String phoneNumber;
  final double amount;
  final String orderId;

  ProcessPaymentParams({
    required this.phoneNumber,
    required this.amount,
    required this.orderId,
  });
}