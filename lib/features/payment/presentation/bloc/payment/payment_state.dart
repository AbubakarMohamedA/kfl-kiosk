import 'package:equatable/equatable.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentProcessing extends PaymentState {
  final String phoneNumber;
  final double amount;

  const PaymentProcessing({
    required this.phoneNumber,
    required this.amount,
  });

  @override
  List<Object?> get props => [phoneNumber, amount];
}

class PaymentSuccess extends PaymentState {
  final String transactionId;
  final double amount;

  const PaymentSuccess({
    required this.transactionId,
    required this.amount,
  });

  @override
  List<Object?> get props => [transactionId, amount];
}

class PaymentFailed extends PaymentState {
  final String message;
  final String? errorCode;

  const PaymentFailed({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

class PaymentTimeout extends PaymentState {
  const PaymentTimeout();
}

class PaymentError extends PaymentState {
  final String message;

  const PaymentError(this.message);

  @override
  List<Object?> get props => [message];
}