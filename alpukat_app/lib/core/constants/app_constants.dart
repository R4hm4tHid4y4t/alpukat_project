class AppConstants {
  AppConstants._();

  // ============================================================
  // PENTING: Sesuaikan baseUrl berdasarkan device yang digunakan
  // IP Anda saat ini menurut ipconfig adalah: 192.168.1.21
  // ============================================================
  
  static const String baseUrl = "http://10.20.27.43:8000";
  static const String apiUrl = '$baseUrl/api';
  static const String storageUrl = '$baseUrl/storage';

  // App Info
  static const String appName = 'Alpukat CNN';
  static const String appVersion = '1.0.0';
  static const String appAuthor = 'Rahmat Hidayat';

  // Storage Keys (flutter_secure_storage)
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  // SharedPreferences Keys
  static const String onboardingKey = 'onboarding_done';

  // Pagination
  static const int defaultPerPage = 10;

  // Timeout
  static const int connectTimeoutMs = 30000;
  static const int receiveTimeoutMs = 30000;
}