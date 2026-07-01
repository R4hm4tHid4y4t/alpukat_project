import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Implementasi untuk Flutter Web menggunakan package:web + dart:js_interop
/// (pengganti resmi dart:html yang sudah deprecated).
/// Membuat Blob dari [bytes] lalu memicu download memakai elemen <a>
/// tersembunyi — ini cara standar download file di Flutter Web.
Future<String?> saveFile({
  required String filename,
  required List<int> bytes,
  required String mimeType,
}) async {
  final jsBytes = Uint8List.fromList(bytes).toJS;
  final blobParts = [jsBytes].toJS;
  final blob = web.Blob(blobParts, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);

  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);

  // Di web, browser yang menangani lokasi penyimpanan (folder Downloads),
  // jadi tidak ada path lokal yang bisa dikembalikan.
  return null;
}