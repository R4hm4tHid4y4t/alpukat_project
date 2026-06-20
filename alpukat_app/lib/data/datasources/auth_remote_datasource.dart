import 'package:dio/dio.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/dio_client.dart';

class AuthRemoteDataSource {
  final DioClient _client;

  const AuthRemoteDataSource(this._client);

  Future<Map<String, dynamic>> register({
    required String nama,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final res = await _client.dio.post('/auth/register', data: {
        'nama': nama,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required int userId,
    required String kodeOtp,
  }) async {
    try {
      final res = await _client.dio.post('/auth/verify-otp', data: {
        'user_id': userId,
        'kode_otp': kodeOtp,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final res = await _client.dio.post('/auth/forgot-password', data: {'email': email});
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String kodeOtp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final res = await _client.dio.post('/auth/reset-password', data: {
        'email': email,
        'kode_otp': kodeOtp,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final res = await _client.dio.post(
        '/auth/refresh',
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  Future<void> logout() async {
    try {
      await _client.dio.post('/auth/logout');
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e));
    }
  }
}
