import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kfm_kiosk/features/payment/domain/usecases/payment_usecases.dart';
import 'package:kfm_kiosk/core/utils/validators.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final ProcessPayment processPaymentUseCase;
  final GetPaymentStatus getPaymentStatusUseCase;

  PaymentBloc({
    required this.processPaymentUseCase,
    required this.getPaymentStatusUseCase,
  }) : super(const PaymentInitial()) {
    on<InitiatePayment>(_onInitiatePayment);
    on<CheckPaymentStatus>(_onCheckPaymentStatus);
    on<ResetPayment>(_onResetPayment);
    on<RetryPayment>(_onRetryPayment);
  }

  Future<void> _onInitiatePayment(
    InitiatePayment event,
    Emitter<PaymentState> emit,
  ) async {
    // Validate phone number
    if (!Validators.isValidPhoneNumber(event.phoneNumber)) {
      emit(const PaymentFailed(
        message: 'Invalid phone number. Please enter a valid Kenyan number.',
        errorCode: 'INVALID_PHONE',
      ));
      return;
    }

    // Validate amount
    if (!Validators.isValidPaymentAmount(event.amount)) {
      emit(const PaymentFailed(
        message: 'Invalid payment amount.',
        errorCode: 'INVALID_AMOUNT',
      ));
      return;
    }

    emit(PaymentProcessing(
      phoneNumber: event.phoneNumber,
      amount: event.amount,
    ));

    try {
      final success = await processPaymentUseCase(ProcessPaymentParams(
        phoneNumber: event.phoneNumber,
        amount: event.amount,
        orderId: event.orderId,
      ));

      if (success) {
        // Generate mock transaction ID
        final transactionId = 'MPE${DateTime.now().millisecondsSinceEpoch}';
        
        emit(PaymentSuccess(
          transactionId: transactionId,
          amount: event.amount,
        ));
      } else {
        emit(const PaymentFailed(
          message: 'Payment failed. Please try again.',
          errorCode: 'PAYMENT_FAILED',
        ));
      }
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onCheckPaymentStatus(
    CheckPaymentStatus event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      final status = await getPaymentStatusUseCase(event.transactionId);
      
      if (status == 'COMPLETED') {
        // Payment is successful
        if (state is PaymentProcessing) {
          final currentState = state as PaymentProcessing;
          emit(PaymentSuccess(
            transactionId: event.transactionId,
            amount: currentState.amount,
          ));
        }
      } else if (status == 'FAILED') {
        emit(const PaymentFailed(
          message: 'Payment failed.',
          errorCode: 'PAYMENT_FAILED',
        ));
      } else if (status == 'TIMEOUT') {
        emit(const PaymentTimeout());
      }
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onResetPayment(
    ResetPayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentInitial());
  }

  Future<void> _onRetryPayment(
    RetryPayment event,
    Emitter<PaymentState> emit,
  ) async {
    // Can only retry from failed state
    if (state is PaymentFailed) {
      emit(const PaymentInitial());
    }
  }
}