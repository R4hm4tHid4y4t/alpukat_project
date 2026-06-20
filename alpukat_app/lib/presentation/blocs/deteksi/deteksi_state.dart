import 'dart:io';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../../data/models/hasil_deteksi_model.dart';

abstract class DeteksiState extends Equatable {
  const DeteksiState();
  @override
  List<Object?> get props => [];
}

class DeteksiInitial extends DeteksiState {
  const DeteksiInitial();
}

/// Gambar sudah dipilih, siap untuk dianalisis
class ImagePicked extends DeteksiState {
  final File file;
  final Uint8List previewBytes;
  const ImagePicked({required this.file, required this.previewBytes});
  @override
  List<Object?> get props => [file.path];
}

/// Sedang mengirim & menganalisis gambar
class DeteksiLoading extends DeteksiState {
  final String message;
  const DeteksiLoading([this.message = 'Memproses gambar...']);
  @override
  List<Object?> get props => [message];
}

/// Analisis berhasil
class DeteksiSuccess extends DeteksiState {
  final HasilDeteksiModel hasil;
  const DeteksiSuccess(this.hasil);
  @override
  List<Object?> get props => [hasil.id];
}

/// Terjadi error
class DeteksiError extends DeteksiState {
  final String message;
  const DeteksiError(this.message);
  @override
  List<Object?> get props => [message];
}
