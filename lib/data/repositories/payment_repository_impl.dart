import 'package:kfm_kiosk/data/datasources/mock_payment_datasource.dart';
import 'package:kfm_kiosk/domain/repositories/repositories.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final MockPaymentDataSource dataSource;

  PaymentRepositoryImpl(this.dataSource);

  @override
  Future<bool> processPayment({
    required String phoneNumber,
    required double amount,
    required String orderId,
  }) async {
    final result = await dataSource.processPayment(
      phoneNumber: phoneNumber,
      amount: amount,
      orderId: orderId,
    );

    return result.success;
  }

  @override
  Future<String> getPaymentStatus(String transactionId) async {
    return await dataSource.getPaymentStatus(transactionId);
  }
}