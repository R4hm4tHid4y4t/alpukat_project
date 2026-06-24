class AppConstants {
  AppConstants._();

  // ============================================================
  // baseUrl sama untuk Web & Mobile, karena pakai `adb reverse`:
  //   adb reverse tcp:8000 tcp:8000
  // Jalankan command itu setiap kali HP baru dicolok/restart debug session.
  // Tidak perlu IP WiFi, tidak perlu HP & laptop satu network.
  // ============================================================

  static String get baseUrl => 'http://localhost:8000';

  static String get apiUrl => '$baseUrl/api';
  static String get storageUrl => '$baseUrl/storage';

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