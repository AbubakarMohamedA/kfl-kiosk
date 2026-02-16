import 'package:equatable/equatable.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class InitiatePayment extends PaymentEvent {
  final String phoneNumber;
  final double amount;
  final String orderId;

  const InitiatePayment({
    required this.phoneNumber,
    required this.amount,
    required this.orderId,
  });

  @override
  List<Object?> get props => [phoneNumber, amount, orderId];
}

class CheckPaymentStatus extends PaymentEvent {
  final String transactionId;

  const CheckPaymentStatus(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

class ResetPayment extends PaymentEvent {
  const ResetPayment();
}

class RetryPayment extends PaymentEvent {
  const RetryPayment();
}