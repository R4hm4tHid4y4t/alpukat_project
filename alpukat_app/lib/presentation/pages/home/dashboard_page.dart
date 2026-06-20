import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../injection/injection_container.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/riwayat/riwayat_bloc.dart';
import '../../blocs/riwayat/riwayat_event.dart';
import '../../blocs/riwayat/riwayat_state.dart';
import '../../blocs/statistik/statistik_cubit.dart';
import '../../widgets/riwayat_card.dart';
import '../../widgets/shimmer_riwayat_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<StatistikCubit>()..load()),
        BlocProvider(create: (_) => sl<RiwayatBloc>()..add(const LoadRiwayat())),
      ],
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<StatistikCubit>().load();
            context.read<RiwayatBloc>().add(const LoadRiwayat());
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header sapaan ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, ${user?.nama.split(' ').first ?? 'Pengguna'}! 👋',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Yuk, deteksi alpukat Anda hari ini',
                            style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/home/profil'),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.extraLightGreen,
                        backgroundImage: user?.fotoProfil != null
                            ? NetworkImage(user!.fotoProfil!)
                            : null,
                        child: user?.fotoProfil == null
                            ? const Icon(Icons.person, color: AppColors.primaryGreen)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Stat cards ─────────────────────────────
                BlocBuilder<StatistikCubit, StatistikState>(
                  builder: (context, state) {
                    if (state is StatistikLoaded) {
                      final s = state.data;
                      return Row(
                        children: [
                          _statCard('Total Deteksi', '${s.totalDeteksi}', Icons.analytics_outlined, AppColors.primaryGreen),
                          const SizedBox(width: 10),
                          _statCard('Bulan Ini', '${s.deteksiBulanIni}', Icons.calendar_month_outlined, AppColors.secondaryGreen),
                          const SizedBox(width: 10),
                          _statCard(
                            'Akurasi',
                            s.rataRataConfidence != null ? '${s.rataRataConfidence!.toStringAsFixed(0)}%' : '-',
                            Icons.percent,
                            AppColors.setengahColor,
                          ),
                        ],
                      );
                    }
                    if (state is StatistikLoading) {
                      return Row(
                        children: List.generate(3, (i) => Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                            height: 90,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          ),
                        )),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 24),

                // ── Tombol Deteksi Sekarang ────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/home/deteksi'),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Deteksi Sekarang'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Varietas yang Didukung ──────────────────
                const Text('Varietas yang Didukung', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _varietasCard(
                        '🟢', 'Aligator',
                        'Kulit kasar bertekstur, daging tebal kekuningan.',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _varietasCard(
                        '🟩', 'Miki',
                        'Kulit halus mengkilap, rasa gurih dan creamy.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Tingkat Kematangan ───────────────────────
                const Text('Tingkat Kematangan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _kematanganChip('Mentah', AppColors.mentahColor),
                    _kematanganChip('Setengah Matang', AppColors.setengahColor),
                    _kematanganChip('Matang', AppColors.matangColor),
                    _kematanganChip('Terlalu Matang', AppColors.terlalMatangColor),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Riwayat Terbaru ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Riwayat Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => context.go('/home/riwayat'),
                      child: const Text('Lihat Semua →'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                BlocBuilder<RiwayatBloc, RiwayatState>(
                  builder: (context, state) {
                    if (state is RiwayatLoading) {
                      return Column(
                        children: List.generate(2, (_) => const ShimmerRiwayatCard()),
                      );
                    }
                    if (state is RiwayatEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('Belum ada riwayat deteksi', style: TextStyle(color: AppColors.textGrey)),
                        ),
                      );
                    }
                    if (state is RiwayatLoaded) {
                      final items = state.items.take(3).toList();
                      return Column(
                        children: items
                            .map((item) => RiwayatCard(
                                  riwayat: item,
                                  onTap: () => context.push('/home/riwayat/${item.id}'),
                                ))
                            .toList(),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _varietasCard(String emoji, String nama, String deskripsi) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            deskripsi,
            style: const TextStyle(fontSize: 11, color: AppColors.textGrey, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _kematanganChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}