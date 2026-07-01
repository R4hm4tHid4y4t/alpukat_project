import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Implementasi untuk Mobile (Android/iOS) & Desktop (macOS/Linux/Windows).
/// Menyimpan [bytes] sebagai file ke direktori dokumen aplikasi karena
/// direktori ini bisa diakses tanpa izin storage tambahan di semua platform.
Future<String?> saveFile({
  required String filename,
  required List<int> bytes,
  required String mimeType,
}) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}