import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../injection/injection_container.dart';
import '../../blocs/riwayat/riwayat_bloc.dart';
import '../../blocs/riwayat/riwayat_event.dart';
import '../../blocs/riwayat/riwayat_state.dart';
import '../../blocs/statistik/statistik_cubit.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/filter_chip_row.dart';
import '../../widgets/riwayat_card.dart';
import '../../widgets/shimmer_riwayat_card.dart';

class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<RiwayatBloc>()..add(const LoadRiwayat())),
        BlocProvider(create: (_) => sl<StatistikCubit>()..load()),
      ],
      child: const _RiwayatView(),
    );
  }
}

class _RiwayatView extends StatefulWidget {
  const _RiwayatView();

  @override
  State<_RiwayatView> createState() => _RiwayatViewState();
}

class _RiwayatViewState extends State<_RiwayatView> {
  final _scrollController = ScrollController();

  // value: null=Semua, 1=Aligator, 2=Miki (sesuaikan dengan ID di DB hasil seeder)
  final List<FilterOption> _filterOptions = const [
    FilterOption(label: 'Semua', value: null),
    FilterOption(label: 'Aligator', value: 1),
    FilterOption(label: 'Miki', value: 2),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<RiwayatBloc>().add(const RiwayatLoadMore());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    context.read<RiwayatBloc>().add(const LoadRiwayat());
    context.read<StatistikCubit>().load();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(title: const Text('Riwayat Deteksi')),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ── Statistik header ──────────────────────────
            SliverToBoxAdapter(
              child: BlocBuilder<StatistikCubit, StatistikState>(
                builder: (context, state) {
                  if (state is StatistikLoaded) {
                    final stat = state.data;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          _buildStatCard('Total Deteksi', '${stat.totalDeteksi}', Icons.analytics_outlined),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            'Akurasi Rata-rata',
                            stat.rataRataConfidence != null
                                ? '${stat.rataRataConfidence!.toStringAsFixed(1)}%'
                                : '-',
                            Icons.percent,
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            'Varietas Terbanyak',
                            stat.varietasTerbanyak ?? '-',
                            Icons.eco_outlined,
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox(height: 16);
                },
              ),
            ),

            // ── Filter chips ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BlocBuilder<RiwayatBloc, RiwayatState>(
                  builder: (context, state) {
                    int? selected;
                    if (state is RiwayatLoaded) selected = state.selectedVarietasId;
                    if (state is RiwayatLoadingMore) selected = state.selectedVarietasId;

                    return FilterChipRow(
                      options: _filterOptions,
                      selectedValue: selected,
                      onSelected: (value) =>
                          context.read<RiwayatBloc>().add(FilterChanged(value as int?)),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── List riwayat ───────────────────────────────
            BlocBuilder<RiwayatBloc, RiwayatState>(
              builder: (context, state) {
                if (state is RiwayatLoading) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const ShimmerRiwayatCard(),
                        childCount: 4,
                      ),
                    ),
                  );
                }

                if (state is RiwayatError) {
                  return SliverFillRemaining(
                    child: ErrorStateWidget(
                      message: state.message,
                      onRetry: () => context.read<RiwayatBloc>().add(const LoadRiwayat()),
                    ),
                  );
                }

                if (state is RiwayatEmpty) {
                  return SliverFillRemaining(
                    child: EmptyStateWidget(
                      message: 'Belum ada riwayat deteksi',
                      icon: Icons.history,
                      actionLabel: 'Mulai Deteksi',
                      onAction: () => context.go('/home/deteksi'),
                    ),
                  );
                }

                final items = state is RiwayatLoaded
                    ? state.items
                    : state is RiwayatLoadingMore
                        ? state.items
                        : [];

                final hasMore = state is RiwayatLoaded && state.hasMore;

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }

                        final item = items[index];
                        return Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.errorColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Hapus Riwayat'),
                                content: const Text('Apakah Anda yakin ingin menghapus riwayat ini?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Hapus', style: TextStyle(color: AppColors.errorColor)),
                                  ),
                                ],
                              ),
                            ) ?? false;
                          },
                          onDismissed: (_) {
                            context.read<RiwayatBloc>().add(RiwayatDeleted(item.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Riwayat dihapus')),
                            );
                          },
                          child: RiwayatCard(
                            riwayat: item,
                            onTap: () => context.push('/home/riwayat/${item.id}'),
                          ),
                        );
                      },
                      childCount: items.length + (hasMore ? 1 : 0),
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}