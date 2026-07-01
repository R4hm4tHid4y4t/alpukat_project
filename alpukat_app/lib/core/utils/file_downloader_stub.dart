/// Stub fallback — seharusnya tidak pernah dipakai karena setiap target
/// kompilasi Flutter (web/android/ios/desktop) pasti punya dart:html
/// atau dart:io. Disediakan hanya agar conditional import valid.
Future<String?> saveFile({
  required String filename,
  required List<int> bytes,
  required String mimeType,
}) async {
  throw UnsupportedError('Platform tidak didukung untuk mengunduh file.');
}