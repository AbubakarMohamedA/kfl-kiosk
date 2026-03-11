import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kfm_kiosk/features/auth/domain/entities/tenant.dart';
import 'package:kfm_kiosk/features/auth/domain/repositories/auth_repository.dart';
import 'package:kfm_kiosk/core/services/local_server_service.dart';


// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

class LogoutRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final Tenant tenant;
  const AuthAuthenticated(this.tenant);
  @override
  List<Object> get props => [tenant];
}
class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
  @override
  List<Object> get props => [message];
}

class AuthUnauthenticated extends AuthState {}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final LocalServerService localServerService;

  AuthBloc({
    required this.authRepository,
    required this.localServerService,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final tenant = await authRepository.getCurrentTenant();
    if (tenant != null) {
      emit(AuthAuthenticated(tenant));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final tenant = await authRepository.login(event.email, event.password);
      emit(AuthAuthenticated(tenant));
    } catch (e) {
      String message = e.toString();
      if (e.toString().contains('SocketException')) {
        message = 'Connection Failed: Unable to reach the server. Please check your internet connection or server IP address.';
      } else if (e.toString().contains('TimeoutException')) {
        message = 'Request Timed Out: The server is taking too long to respond.';
      } else if (e.toString().contains('ClientException')) {
        message = 'Network Error: Please ensure you are connected to the correct network.';
      }
      emit(AuthFailure(message));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await authRepository.logout();
    
    localServerService.setActiveTenantId(''); // Clear server tenant
    emit(AuthUnauthenticated());
  }
}
