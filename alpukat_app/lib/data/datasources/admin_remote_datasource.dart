import 'package:dio/dio.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/dio_client.dart';

class AdminRemoteDataSource {
  final DioClient _client;
  const AdminRemoteDataSource(this._client);

  // ── Dashboard ──────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final res = await _client.dio.get('/admin/dashboard');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Pengguna ───────────────────────────────────────────
  Future<Map<String, dynamic>> getUsers({
    int page = 1, int perPage = 10, String? search, String? role, int? status,
  }) async {
    try {
      final res = await _client.dio.get('/admin/users', queryParameters: {
        'page': page, 'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
        if (role != null) 'role': role,
        if (status != null) 'status': status,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> toggleUserRole(int userId) async {
    try {
      final res = await _client.dio.put('/admin/users/$userId/toggle-role');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> toggleUserStatus(int userId) async {
    try {
      final res = await _client.dio.put('/admin/users/$userId/toggle-status');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Varietas CRUD ──────────────────────────────────────
  Future<Map<String, dynamic>> getVarietas() async {
    try {
      final res = await _client.dio.get('/admin/varietas');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> createVarietas({required String nama, String? deskripsi}) async {
    try {
      final res = await _client.dio.post('/admin/varietas', data: {
        'nama_varietas': nama,
        if (deskripsi != null) 'deskripsi': deskripsi,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> updateVarietas(int id, {String? nama, String? deskripsi}) async {
    try {
      final res = await _client.dio.put('/admin/varietas/$id', data: {
        if (nama != null) 'nama_varietas': nama,
        if (deskripsi != null) 'deskripsi': deskripsi,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  Future<void> deleteVarietas(int id) async {
    try {
      await _client.dio.delete('/admin/varietas/$id');
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Kematangan CRUD ────────────────────────────────────
  Future<Map<String, dynamic>> getKematangan() async {
    try {
      final res = await _client.dio.get('/admin/kematangan');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> createKematangan({
    required String label, String? deskripsi, String? ciriVisual,
  }) async {
    try {
      final res = await _client.dio.post('/admin/kematangan', data: {
        'label_kematangan': label,
        if (deskripsi != null) 'deskripsi': deskripsi,
        if (ciriVisual != null) 'ciri_visual': ciriVisual,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> updateKematangan(int id, {String? label, String? deskripsi, String? ciriVisual}) async {
    try {
      final res = await _client.dio.put('/admin/kematangan/$id', data: {
        if (label != null) 'label_kematangan': label,
        if (deskripsi != null) 'deskripsi': deskripsi,
        if (ciriVisual != null) 'ciri_visual': ciriVisual,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  Future<void> deleteKematangan(int id) async {
    try {
      await _client.dio.delete('/admin/kematangan/$id');
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Model CNN ──────────────────────────────────────────
  Future<Map<String, dynamic>> getModels() async {
    try {
      final res = await _client.dio.get('/admin/model');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> activateModel(int id) async {
    try {
      final res = await _client.dio.post('/admin/model/activate/$id');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Riwayat Global ─────────────────────────────────────
  Future<Map<String, dynamic>> getDeteksiGlobal({
    int page = 1, int perPage = 20, int? varietasId, int? kematanganId, String? flag, String? search,
  }) async {
    try {
      final res = await _client.dio.get('/admin/deteksi', queryParameters: {
        'page': page, 'per_page': perPage,
        if (varietasId != null) 'varietas_id': varietasId,
        if (kematanganId != null) 'kematangan_id': kematanganId,
        if (flag != null) 'flag': flag,
        if (search != null && search.isNotEmpty) 'search': search,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> flagDeteksi(int id, {required String statusFlag, String? catatan}) async {
    try {
      final res = await _client.dio.put('/admin/deteksi/$id/flag', data: {
        'status_flag': statusFlag,
        if (catatan != null) 'catatan_flag': catatan,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }

  /// Mengunduh data riwayat deteksi sebagai CSV.
  /// Menggunakan Dio (bukan URL langsung) agar header Authorization
  /// (Bearer token) otomatis ikut terkirim lewat interceptor [DioClient].
  Future<List<int>> exportDeteksiCsv() async {
    try {
      final res = await _client.dio.get<List<int>>(
        '/admin/deteksi/export',
        options: Options(responseType: ResponseType.bytes),
      );
      return res.data ?? <int>[];
    } on DioException catch (e) {
      throw ServerException(DioClient.extractErrorMessage(e), statusCode: e.response?.statusCode);
    }
  }
}