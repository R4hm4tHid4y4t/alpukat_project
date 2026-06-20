import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../injection/injection_container.dart';
import '../../blocs/deteksi/deteksi_bloc.dart';
import '../../blocs/deteksi/deteksi_event.dart';
import '../../blocs/deteksi/deteksi_state.dart';
import '../../widgets/loading_overlay.dart';

class DeteksiPage extends StatelessWidget {
  const DeteksiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DeteksiBloc>(),
      child: const _DeteksiView(),
    );
  }
}

class _DeteksiView extends StatelessWidget {
  const _DeteksiView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(title: const Text('Deteksi Alpukat')),
      body: BlocConsumer<DeteksiBloc, DeteksiState>(
        listener: (context, state) {
          if (state is DeteksiError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.errorColor),
            );
          }
          if (state is DeteksiSuccess) {
            context.push('/home/deteksi/hasil', extra: state.hasil.toJson()).then((_) {
              // Reset state setelah kembali dari hasil
              if (context.mounted) {
                context.read<DeteksiBloc>().add(const DeteksiReset());
              }
            });
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Preview Container
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: state is ImagePicked
                              ? null
                              : Border.all(
                                  color: AppColors.borderColor,
                                  width: 2,
                                  strokeAlign: BorderSide.strokeAlignInside,
                                ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildPreview(state),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tip
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.extraLightGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Text('💡', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pastikan buah alpukat terlihat jelas dan pencahayaan cukup',
                              style: TextStyle(fontSize: 12, color: AppColors.textDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Row tombol pilih gambar
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context
                                .read<DeteksiBloc>()
                                .add(const ImageSourceSelected(ImageSource.camera)),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Kamera'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context
                                .read<DeteksiBloc>()
                                .add(const ImageSourceSelected(ImageSource.gallery)),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Galeri'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tombol Analisis
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (state is ImagePicked)
                            ? () => context.read<DeteksiBloc>().add(const DeteksiSubmitted())
                            : null,
                        icon: const Icon(Icons.search),
                        label: const Text('Analisis Sekarang'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Loading overlay
              if (state is DeteksiLoading)
                Positioned.fill(
                  child: LoadingOverlay(
                    messages: [state.message],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPreview(DeteksiState state) {
    if (state is ImagePicked) {
      return Image.memory(state.previewBytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.add_a_photo_outlined, size: 56, color: AppColors.textLightGrey),
        SizedBox(height: 12),
        Text(
          'Pilih foto buah alpukat\nuntuk dianalisis',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textGrey, fontSize: 13),
        ),
      ],
    );
  }
}
