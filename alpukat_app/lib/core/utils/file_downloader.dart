// Entry point untuk download file (CSV, dsb).
//
// Memakai conditional import bawaan Dart agar satu kode sumber bisa
// berjalan baik di Flutter Web (download langsung lewat browser)
// maupun di Mobile/Desktop (simpan ke penyimpanan perangkat),
// tanpa perlu menambah dependency baru di pubspec.yaml.
import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart'
    if (dart.library.io) 'file_downloader_io.dart' as impl;

/// Menyimpan/mengunduh [bytes] dengan nama file [filename].
///
/// - Di Web: memicu download file langsung ke folder Downloads browser.
/// - Di Mobile/Desktop: menyimpan file ke direktori dokumen aplikasi
///   dan mengembalikan path lengkapnya agar bisa ditampilkan ke pengguna.
///
/// Mengembalikan deskripsi lokasi penyimpanan (path file, atau null
/// jika platform-nya web karena file langsung diunduh oleh browser).
Future<String?> downloadFile({
  required String filename,
  required List<int> bytes,
  String mimeType = 'text/csv',
}) {
  return impl.saveFile(filename: filename, bytes: bytes, mimeType: mimeType);
}