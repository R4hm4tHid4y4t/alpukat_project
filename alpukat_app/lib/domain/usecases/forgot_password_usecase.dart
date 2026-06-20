import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository _repository;
  const ForgotPasswordUseCase(this._repository);

  Future<Either<Failure, void>> call(String email) =>
      _repository.forgotPassword(email);
}
