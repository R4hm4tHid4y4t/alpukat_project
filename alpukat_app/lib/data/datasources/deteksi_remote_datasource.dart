import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/dio_client.dart';

class DeteksiRemoteDataSource {
  final DioClient _client;

  const DeteksiRemoteDataSource(this._client);

  /// Upload gambar untuk deteksi CNN — multipart/form-data
  Future<Map<String, dynamic>> uploadDeteksi(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'gambar': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final res = await _client.dio.post(
        '/deteksi',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          // Inferensi CNN bisa butuh waktu lebih lama
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  /// GET /riwayat dengan pagination & filter
  Future<Map<String, dynamic>> getRiwayat({
    int page = 1,
    int perPage = 10,
    int? varietasId,
    int? kematanganId,
    String sort = 'desc',
  }) async {
    try {
      final res = await _client.dio.get('/riwayat', queryParameters: {
        'page': page,
        'per_page': perPage,
        if (varietasId != null) 'varietas_id': varietasId,
        if (kematanganId != null) 'kematangan_id': kematanganId,
        'sort': sort,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  /// GET /riwayat/{id} — detail satu hasil deteksi
  Future<Map<String, dynamic>> getDetailDeteksi(int id) async {
    try {
      final res = await _client.dio.get('/riwayat/$id');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  /// GET /statistik
  Future<Map<String, dynamic>> getStatistik() async {
    try {
      final res = await _client.dio.get('/statistik');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  /// DELETE /riwayat/{id}
  Future<void> deleteRiwayat(int id) async {
    try {
      await _client.dio.delete('/riwayat/$id');
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }
}
