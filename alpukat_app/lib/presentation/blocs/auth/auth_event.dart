import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String nama;
  final String email;
  final String password;
  final String confirmPassword;
  const RegisterRequested({
    required this.nama,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });
  @override
  List<Object?> get props => [nama, email, password];
}

class OtpVerifyRequested extends AuthEvent {
  final int userId;
  final String kodeOtp;
  const OtpVerifyRequested({required this.userId, required this.kodeOtp});
  @override
  List<Object?> get props => [userId, kodeOtp];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class ForgotPasswordRequested extends AuthEvent {
  final String email;
  const ForgotPasswordRequested(this.email);
  @override
  List<Object?> get props => [email];
}

class ResetPasswordRequested extends AuthEvent {
  final String email;
  final String kodeOtp;
  final String newPassword;
  final String confirmPassword;
  const ResetPasswordRequested({
    required this.email,
    required this.kodeOtp,
    required this.newPassword,
    required this.confirmPassword,
  });
  @override
  List<Object?> get props => [email, kodeOtp];
}
