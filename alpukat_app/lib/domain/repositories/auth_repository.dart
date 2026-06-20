import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/auth_response.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, Map<String, dynamic>>> register({
    required String nama,
    required String email,
    required String password,
    required String confirmPassword,
  });

  Future<Either<Failure, AuthResponse>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthResponse>> verifyOtp({
    required int userId,
    required String kodeOtp,
  });

  Future<Either<Failure, void>> forgotPassword(String email);

  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String kodeOtp,
    required String newPassword,
    required String confirmPassword,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, User>> getCurrentUser();
}
