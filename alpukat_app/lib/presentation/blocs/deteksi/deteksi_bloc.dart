import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/errors/exceptions.dart';
import '../../../data/datasources/deteksi_remote_datasource.dart';
import '../../../data/models/hasil_deteksi_model.dart';
import 'deteksi_event.dart';
import 'deteksi_state.dart';

class DeteksiBloc extends Bloc<DeteksiEvent, DeteksiState> {
  final DeteksiRemoteDataSource _remote;
  final ImagePicker _picker = ImagePicker();

  DeteksiBloc(this._remote) : super(const DeteksiInitial()) {
    on<ImageSourceSelected>(_onImageSourceSelected);
    on<DeteksiSubmitted>(_onDeteksiSubmitted);
    on<DeteksiReset>(_onDeteksiReset);
  }

  Future<void> _onImageSourceSelected(
      ImageSourceSelected event, Emitter<DeteksiState> emit) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: event.source,
        imageQuality: 85,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (pickedFile == null) return; // User membatalkan

      var file = File(pickedFile.path);

      // Compress jika ukuran > 2MB
      final sizeInBytes = await file.length();
      if (sizeInBytes > 2 * 1024 * 1024) {
        file = await _compressImage(file);
      }

      final bytes = await file.readAsBytes();
      emit(ImagePicked(file: file, previewBytes: bytes));
    } catch (e) {
      emit(DeteksiError('Gagal memilih gambar: ${e.toString()}'));
    }
  }

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 800,
      minHeight: 800,
    );

    return result != null ? File(result.path) : file;
  }

  Future<void> _onDeteksiSubmitted(
      DeteksiSubmitted event, Emitter<DeteksiState> emit) async {
    final currentState = state;
    if (currentState is! ImagePicked) return;

    emit(const DeteksiLoading('Mengunggah gambar...'));

    try {
      // Simulasi tahapan loading untuk UX yang lebih baik
      await Future.delayed(const Duration(milliseconds: 300));
      emit(const DeteksiLoading('Menganalisis varietas...'));

      final result = await _remote.uploadDeteksi(currentState.file);

      emit(const DeteksiLoading('Mendeteksi kematangan...'));
      await Future.delayed(const Duration(milliseconds: 200));

      final hasil = HasilDeteksiModel.fromJson(result['data'] as Map<String, dynamic>);
      emit(DeteksiSuccess(hasil));
    } on ServerException catch (e) {
      emit(DeteksiError(e.message));
    } catch (e) {
      emit(DeteksiError('Gagal menganalisis gambar. Silakan coba lagi.'));
    }
  }

  void _onDeteksiReset(DeteksiReset event, Emitter<DeteksiState> emit) {
    emit(const DeteksiInitial());
  }
}
