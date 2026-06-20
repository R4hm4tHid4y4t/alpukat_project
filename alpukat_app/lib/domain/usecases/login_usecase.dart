import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/auth_response.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;
  const LoginUseCase(this._repository);

  Future<Either<Failure, AuthResponse>> call({
    required String email,
    required String password,
  }) => _repository.login(email: email, password: password);
}
