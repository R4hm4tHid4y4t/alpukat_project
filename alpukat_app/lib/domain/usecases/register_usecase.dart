import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;
  const RegisterUseCase(this._repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String nama,
    required String email,
    required String password,
    required String confirmPassword,
  }) => _repository.register(
        nama: nama, email: email,
        password: password, confirmPassword: confirmPassword,
      );
}
