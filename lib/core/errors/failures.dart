import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error occurred']);
}

// Product failures
class ProductNotFoundFailure extends Failure {
  const ProductNotFoundFailure([super.message = 'Product not found']);
}

class ProductLoadFailure extends Failure {
  const ProductLoadFailure([super.message = 'Failed to load products']);
}

// Cart failures
class CartFailure extends Failure {
  const CartFailure([super.message = 'Cart operation failed']);
}

class CartEmptyFailure extends Failure {
  const CartEmptyFailure([super.message = 'Cart is empty']);
}

class InvalidQuantityFailure extends Failure {
  const InvalidQuantityFailure([super.message = 'Invalid quantity']);
}

// Order failures
class OrderCreationFailure extends Failure {
  const OrderCreationFailure([super.message = 'Failed to create order']);
}

class OrderNotFoundFailure extends Failure {
  const OrderNotFoundFailure([super.message = 'Order not found']);
}

class OrderUpdateFailure extends Failure {
  const OrderUpdateFailure([super.message = 'Failed to update order']);
}

// Payment failures
class PaymentFailure extends Failure {
  const PaymentFailure([super.message = 'Payment failed']);
}

class InvalidPhoneNumberFailure extends Failure {
  const InvalidPhoneNumberFailure(
      [super.message = 'Invalid phone number provided']);
}

class InsufficientFundsFailure extends Failure {
  const InsufficientFundsFailure([super.message = 'Insufficient funds']);
}

class PaymentTimeoutFailure extends Failure {
  const PaymentTimeoutFailure([super.message = 'Payment timeout']);
}

// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed']);
}