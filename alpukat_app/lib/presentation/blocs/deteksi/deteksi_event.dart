import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

abstract class DeteksiEvent extends Equatable {
  const DeteksiEvent();
  @override
  List<Object?> get props => [];
}

/// User memilih sumber gambar (kamera atau galeri)
class ImageSourceSelected extends DeteksiEvent {
  final ImageSource source;
  const ImageSourceSelected(this.source);
  @override
  List<Object?> get props => [source];
}

/// User menekan tombol "Analisis Sekarang"
class DeteksiSubmitted extends DeteksiEvent {
  const DeteksiSubmitted();
}

/// Reset state — kembali ke kondisi awal untuk deteksi ulang
class DeteksiReset extends DeteksiEvent {
  const DeteksiReset();
}
