import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/errors/exceptions.dart';
import '../../../data/datasources/admin_remote_datasource.dart';
import '../../../injection/injection_container.dart';
import '../../widgets/error_state_widget.dart';
import 'admin_drawer.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await sl<AdminRemoteDataSource>().getDashboard();
      setState(() {
        _data = result['data'] as Map<String, dynamic>;
        _loading = false;
      });
    } on ServerException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Gagal memuat dashboard'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(title: const Text('Dashboard Admin')),
      drawer: const AdminDrawer(currentRoute: 'dashboard'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorStateWidget(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: _buildContent(),
                  ),
                ),
    );
  }

  Widget _buildContent() {
    final d = _data!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stat Cards ─────────────────────────────────
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _statCard('Total Pengguna', '${d['total_pengguna']}', Icons.people_outline, AppColors.primaryGreen),
            _statCard('Total Deteksi', '${d['total_deteksi']}', Icons.analytics_outlined, AppColors.secondaryGreen),
            _statCard('Deteksi Bulan Ini', '${d['deteksi_bulan_ini']}', Icons.calendar_month_outlined, AppColors.setengahColor),
            _statCard('Perlu Ditinjau', '${d['total_flagged']}', Icons.flag_outlined, AppColors.errorColor),
          ],
        ),
        const SizedBox(height: 24),

        // ── Aksi Cepat ─────────────────────────────────
        const Text('Aksi Cepat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        Row(
          children: [
            _quickAction('Varietas', Icons.eco_outlined, () => context.go('/admin/varietas')),
            const SizedBox(width: 8),
            _quickAction('Kematangan', Icons.water_drop_outlined, () => context.go('/admin/kematangan')),
            const SizedBox(width: 8),
            _quickAction('Pengguna', Icons.people_outline, () => context.go('/admin/pengguna')),
            const SizedBox(width: 8),
            _quickAction('Model CNN', Icons.smart_toy_outlined, () => context.go('/admin/model')),
          ],
        ),
        const SizedBox(height: 24),

        // ── Akurasi Model ───────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
          child: Row(
            children: [
              const Icon(Icons.smart_toy, color: AppColors.primaryGreen, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Model Aktif: ${d['model_versi'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('Akurasi: ${d['akurasi_model']?.toString() ?? '-'}%', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Line Chart Tren Mingguan ─────────────────────
        const Text('Tren Deteksi 7 Hari Terakhir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
          child: _buildLineChart((d['tren_mingguan'] as List<dynamic>?) ?? []),
        ),
        const SizedBox(height: 24),

        // ── Pie Charts ────────────────────────────────────
        const Text('Distribusi Hasil Deteksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildPieCard('Varietas', (d['distribusi_varietas'] as List<dynamic>?) ?? [], _varietasColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildPieCard('Kematangan', (d['distribusi_kematangan'] as List<dynamic>?) ?? [], _kematanganColorFromLabel)),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Color _varietasColor(String nama, int index) {
    const colors = [AppColors.primaryGreen, AppColors.secondaryGreen, AppColors.setengahColor, AppColors.terlalMatangColor];
    return colors[index % colors.length];
  }

  Color _kematanganColorFromLabel(String label, int index) => AppColors.getKematanganColor(label);

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
        ],
      ),
    );
  }

  Widget _quickAction(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 22),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<dynamic> tren) {
    if (tren.isEmpty) {
      return const Center(child: Text('Belum ada data', style: TextStyle(color: AppColors.textGrey)));
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < tren.length; i++) {
      final jumlah = (tren[i]['jumlah'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), jumlah));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= tren.length) return const SizedBox.shrink();
                final tanggal = tren[idx]['tanggal'] as String;
                final day = tanggal.split('-').last;
                return Padding(padding: const EdgeInsets.only(top: 4), child: Text(day, style: const TextStyle(fontSize: 10)));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primaryGreen,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: AppColors.primaryGreen.withValues(alpha: 0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildPieCard(String title, List<dynamic> items, Color Function(String, int) colorFn) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Belum ada data', style: TextStyle(color: AppColors.textGrey, fontSize: 11)),
            )
          else ...[
            SizedBox(
              height: 120,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                  sections: List.generate(items.length, (i) {
                    final item = items[i];
                    final label = (item['nama'] ?? item['label']) as String;
                    final persen = (item['persentase'] as num).toDouble();
                    return PieChartSectionData(
                      value: persen,
                      title: '${persen.toStringAsFixed(0)}%',
                      color: colorFn(label, i),
                      radius: 35,
                      titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 4,
              children: List.generate(items.length, (i) {
                final item = items[i];
                final label = (item['nama'] ?? item['label']) as String;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: colorFn(label, i), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(label, style: const TextStyle(fontSize: 10)),
                  ],
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
