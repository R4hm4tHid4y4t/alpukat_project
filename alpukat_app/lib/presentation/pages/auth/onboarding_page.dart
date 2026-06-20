import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../injection/injection_container.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _slides = const [
    _SlideData(
      emoji: '🌿',
      title: 'Kenali 2 Varietas Alpukat',
      subtitle: 'Identifikasi varietas Aligator dan Miki dengan akurasi hingga 100% menggunakan teknologi AI.',
    ),
    _SlideData(
      emoji: '🔍',
      title: 'Deteksi 4 Tingkat Kematangan',
      subtitle: 'Ketahui apakah alpukat Mentah, Setengah Matang, Matang, atau Terlalu Matang hanya dengan foto.',
    ),
    _SlideData(
      emoji: '📋',
      title: 'Simpan & Pantau Riwayat',
      subtitle: 'Semua hasil deteksi tersimpan otomatis. Pantau statistik penggunaan Anda kapan saja.',
    ),
  ];

  void _goToLogin() async {
    await sl<AuthLocalDataSource>().saveOnboardingDone();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _goToLogin,
                child: const Text('Lewati', style: TextStyle(color: AppColors.textGrey)),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _buildSlide(_slides[i]),
              ),
            ),

            // Dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? AppColors.primaryGreen
                        : AppColors.borderColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol navigasi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _goToLogin();
                    }
                  },
                  child: Text(
                    _currentPage < _slides.length - 1 ? 'Selanjutnya' : 'Mulai Sekarang',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_SlideData slide) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(slide.emoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 32),
          Text(
            slide.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.subtitle,
            style: const TextStyle(fontSize: 15, color: AppColors.textGrey, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SlideData {
  final String emoji;
  final String title;
  final String subtitle;
  const _SlideData({required this.emoji, required this.title, required this.subtitle});
}
