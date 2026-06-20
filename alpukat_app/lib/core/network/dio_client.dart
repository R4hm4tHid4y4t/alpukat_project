import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class DioClient {
  static DioClient? _instance;
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DioClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(_buildInterceptor());
  }

  static DioClient get instance {
    _instance ??= DioClient._();
    return _instance!;
  }

  Dio get dio => _dio;

  InterceptorsWrapper _buildInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Tambahkan Bearer token ke setiap request
        final token = await _storage.read(key: AppConstants.accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },

      onError: (error, handler) async {
        // Jika 401 — coba refresh token
        if (error.response?.statusCode == 401) {
          try {
            final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
            if (refreshToken == null) {
              await _clearTokens();
              return handler.next(error);
            }

            // Request token baru
            final refreshDio = Dio(BaseOptions(baseUrl: AppConstants.apiUrl));
            final res = await refreshDio.post(
              '/auth/refresh',
              options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
            );

            final newToken = res.data['data']['access_token'];
            await _storage.write(key: AppConstants.accessTokenKey, value: newToken);

            // Retry request original dengan token baru
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newToken';
            final retryRes = await _dio.fetch(opts);
            return handler.resolve(retryRes);
          } catch (_) {
            // Refresh gagal — paksa logout
            await _clearTokens();
            return handler.next(error);
          }
        }
        return handler.next(error);
      },
    );
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }

  /// Helper: ekstrak pesan error dari response API
  static String extractErrorMessage(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    } catch (_) {}
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Koneksi timeout. Periksa jaringan Anda.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
