import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/models/auth_models.dart';
import '../../../../core/network/api_client.dart';

// ─── Events ───────────────────────────────────────────────
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}
class AuthLogoutRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  AuthLoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  final String role;
  final int? specialtyId;
  final double? consultationFee;
  AuthRegisterRequested({
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
    this.specialtyId,
    this.consultationFee,
  });
  @override
  List<Object?> get props => [fullName, email, role];
}

// ─── States ───────────────────────────────────────────────
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthUnauthenticated extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthDatasource _datasource;

  AuthBloc(this._datasource) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onCheck(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = await _datasource.getCachedUser();
    final hasToken = await _datasource.hasValidSession();
    if (user != null && hasToken) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await _datasource.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(result.user));
    } on Failure catch (f) {
      emit(AuthError(f.message));
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await _datasource.register(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
        role: event.role,
        specialtyId: event.specialtyId,
        consultationFee: event.consultationFee,
      );
      emit(AuthAuthenticated(result.user));
    } on Failure catch (f) {
      emit(AuthError(f.message));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _datasource.logout();
    emit(AuthUnauthenticated());
  }
}
