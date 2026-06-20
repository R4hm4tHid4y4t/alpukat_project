import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/dio_client.dart';

class ProfilRemoteDataSource {
  final DioClient _client;
  const ProfilRemoteDataSource(this._client);

  /// GET /user/profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final res = await _client.dio.get('/user/profile');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  /// PUT /user/profile
  Future<Map<String, dynamic>> updateProfile({
    String? nama,
    String? bio,
    String? noTelepon,
  }) async {
    try {
      final res = await _client.dio.put('/user/profile', data: {
        if (nama != null) 'nama': nama,
        if (bio != null) 'bio': bio,
        if (noTelepon != null) 'no_telepon': noTelepon,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  /// POST /user/avatar — multipart
  Future<Map<String, dynamic>> uploadAvatar(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });
      final res = await _client.dio.post(
        '/user/avatar',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  /// PUT /user/password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final res = await _client.dio.put('/user/password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }
}
