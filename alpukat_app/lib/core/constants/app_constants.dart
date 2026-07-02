class AppConstants {
  AppConstants._();

  // ============================================================
  // DEV LOKAL (default jika --dart-define TIDAK diisi):
  //   baseUrl sama untuk Web & Mobile, karena pakai `adb reverse`:
  //     adb reverse tcp:8000 tcp:8000
  //   Jalankan command itu setiap kali HP baru dicolok/restart debug session.
  //   Tidak perlu IP WiFi, tidak perlu HP & laptop satu network.
  //
  // PRODUCTION (build APK/Web via GitHub Actions):
  //   URL server online di-inject saat build lewat:
  //     flutter build apk --dart-define=API_BASE_URL=https://xxxx.up.railway.app
  //   Tidak perlu edit file ini setiap kali deploy ulang — cukup ubah
  //   secret/variable API_BASE_URL di GitHub Actions.
  // ============================================================

  static String get baseUrl => const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8000',
      );

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