import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/login_usecase.dart';
import '../../../domain/usecases/register_usecase.dart';
import '../../../domain/usecases/verify_otp_usecase.dart';
import '../../../domain/usecases/logout_usecase.dart';
import '../../../domain/usecases/get_current_user_usecase.dart';
import '../../../domain/usecases/forgot_password_usecase.dart';
import '../../../domain/usecases/reset_password_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _login;
  final RegisterUseCase _register;
  final VerifyOtpUseCase _verifyOtp;
  final LogoutUseCase _logout;
  final GetCurrentUserUseCase _getCurrentUser;
  final ForgotPasswordUseCase _forgotPassword;
  final ResetPasswordUseCase _resetPassword;

  AuthBloc({
    required LoginUseCase login,
    required RegisterUseCase register,
    required VerifyOtpUseCase verifyOtp,
    required LogoutUseCase logout,
    required GetCurrentUserUseCase getCurrentUser,
    required ForgotPasswordUseCase forgotPassword,
    required ResetPasswordUseCase resetPassword,
  })  : _login = login,
        _register = register,
        _verifyOtp = verifyOtp,
        _logout = logout,
        _getCurrentUser = getCurrentUser,
        _forgotPassword = forgotPassword,
        _resetPassword = resetPassword,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<OtpVerifyRequested>(_onOtpVerifyRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
  }

  Future<void> _onCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _getCurrentUser();
    result.fold(
      (_) => emit(const AuthUnauthenticated()),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _login(email: event.email, password: event.password);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (auth) => emit(AuthAuthenticated(auth.user)),
    );
  }

  Future<void> _onRegisterRequested(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _register(
      nama: event.nama, email: event.email,
      password: event.password, confirmPassword: event.confirmPassword,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (data) => emit(AuthOtpRequired(
        userId: data['user_id'] as int,
        email: data['email'] as String,
      )),
    );
  }

  Future<void> _onOtpVerifyRequested(OtpVerifyRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _verifyOtp(userId: event.userId, kodeOtp: event.kodeOtp);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (auth) => emit(AuthAuthenticated(auth.user)),
    );
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await _logout();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onForgotPasswordRequested(
      ForgotPasswordRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _forgotPassword(event.email);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthPasswordResetSent()),
    );
  }

  Future<void> _onResetPasswordRequested(
      ResetPasswordRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _resetPassword(
      email: event.email, kodeOtp: event.kodeOtp,
      newPassword: event.newPassword, confirmPassword: event.confirmPassword,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthPasswordResetSuccess()),
    );
  }
}
