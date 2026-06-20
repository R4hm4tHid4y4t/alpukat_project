import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Overlay loading saat proses analisis CNN berjalan.
/// Teks berganti otomatis untuk memberi kesan progres.
class LoadingOverlay extends StatefulWidget {
  final List<String> messages;
  const LoadingOverlay({
    super.key,
    this.messages = const [
      'Memproses gambar...',
      'Menganalisis varietas...',
      'Mendeteksi kematangan...',
    ],
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  int _index = 0;
  late final Stream<int> _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Stream.periodic(const Duration(milliseconds: 1500), (i) => i);
    _ticker.listen((_) {
      if (mounted) {
        setState(() => _index = (_index + 1) % widget.messages.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animasi loading sederhana (bisa diganti Lottie jika asset tersedia)
            SizedBox(
              width: 80, height: 80,
              child: CircularProgressIndicator(
                color: AppColors.lightGreen,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                widget.messages[_index],
                key: ValueKey(_index),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}