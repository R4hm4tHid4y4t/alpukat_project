import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository _repository;
  const ResetPasswordUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String email,
    required String kodeOtp,
    required String newPassword,
    required String confirmPassword,
  }) => _repository.resetPassword(
        email: email, kodeOtp: kodeOtp,
        newPassword: newPassword, confirmPassword: confirmPassword,
      );
}
