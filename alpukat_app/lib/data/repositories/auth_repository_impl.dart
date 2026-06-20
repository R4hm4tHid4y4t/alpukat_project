import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  const AuthRepositoryImpl(this._remote, this._local);

  @override
  Future<Either<Failure, Map<String, dynamic>>> register({
    required String nama,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final result = await _remote.register(
        nama: nama, email: email,
        password: password, confirmPassword: confirmPassword,
      );
      return Right(result['data'] as Map<String, dynamic>);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _remote.login(email: email, password: password);
      final authModel = AuthResponseModel.fromJson(result['data'] as Map<String, dynamic>);
      await _local.saveTokens(authModel.accessToken, authModel.refreshToken);
      await _local.saveUser(authModel.user);
      return Right(_toAuthResponse(authModel));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, AuthResponse>> verifyOtp({
    required int userId,
    required String kodeOtp,
  }) async {
    try {
      final result = await _remote.verifyOtp(userId: userId, kodeOtp: kodeOtp);
      final authModel = AuthResponseModel.fromJson(result['data'] as Map<String, dynamic>);
      await _local.saveTokens(authModel.accessToken, authModel.refreshToken);
      await _local.saveUser(authModel.user);
      return Right(_toAuthResponse(authModel));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    try {
      await _remote.forgotPassword(email);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String kodeOtp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _remote.resetPassword(
        email: email, kodeOtp: kodeOtp,
        newPassword: newPassword, confirmPassword: confirmPassword,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remote.logout();
    } catch (_) {}
    await _local.clearTokens();
    return const Right(null);
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    final user = await _local.getUser();
    if (user == null) return const Left(AuthFailure('Belum login'));
    return Right(_toUser(user));
  }

  // Helper: konversi model ke entity
  AuthResponse _toAuthResponse(AuthResponseModel model) => AuthResponse(
        accessToken: model.accessToken,
        refreshToken: model.refreshToken,
        user: _toUser(model.user),
      );

  User _toUser(UserModel model) => User(
        id: model.id,
        nama: model.nama,
        email: model.email,
        role: model.role,
        statusVerifikasi: model.statusVerifikasi,
        fotoProfil: model.fotoProfil,
        createdAt: model.createdAt,
      );
}
