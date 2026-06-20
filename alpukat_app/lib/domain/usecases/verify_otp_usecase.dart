import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/auth_response.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository _repository;
  const VerifyOtpUseCase(this._repository);

  Future<Either<Failure, AuthResponse>> call({
    required int userId,
    required String kodeOtp,
  }) => _repository.verifyOtp(userId: userId, kodeOtp: kodeOtp);
}
