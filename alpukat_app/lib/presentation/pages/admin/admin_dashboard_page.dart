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
      setState(() { _error = 'Tidak dapat terhubung ke server'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: _buildAppBar(),
      drawer: const AdminDrawer(currentRoute: 'dashboard'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _error != null
              ? ErrorStateWidget(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primaryGreen,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: _buildContent(),
                  ),
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black12,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Color(0xFF1A2E1A)),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
          Text('Selamat datang kembali', style: TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.normal)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryGreen),
          onPressed: _load,
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildContent() {
    final d = _data!;
    final tren = (d['tren_mingguan'] as List<dynamic>?) ?? [];
    final distribusiVarietas = (d['distribusi_varietas'] as List<dynamic>?) ?? [];
    final distribusiKematangan = (d['distribusi_kematangan'] as List<dynamic>?) ?? [];
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;
    final isMedium = screenWidth > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stat Cards ──────────────────────────────────
        _buildStatCards(d, isMedium),
        const SizedBox(height: 24),

        // ── Model Aktif ─────────────────────────────────
        _buildModelAktifBanner(d),
        const SizedBox(height: 24),

        // ── Quick Actions ───────────────────────────────
        _buildSectionTitle('Aksi Cepat'),
        const SizedBox(height: 12),
        _buildQuickActions(),
        const SizedBox(height: 24),

        // ── Chart + Distribusi ─────────────────────────
        _buildSectionTitle('Tren Deteksi 7 Hari Terakhir'),
        const SizedBox(height: 12),
        _buildTrenChart(tren),
        const SizedBox(height: 24),

        _buildSectionTitle('Distribusi Hasil Deteksi'),
        const SizedBox(height: 12),
        isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildDistribusiCard('Varietas', distribusiVarietas, _varietasColor)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDistribusiCard('Kematangan', distribusiKematangan, _kematanganColor)),
                ],
              )
            : Column(
                children: [
                  _buildDistribusiCard('Varietas', distribusiVarietas, _varietasColor),
                  const SizedBox(height: 16),
                  _buildDistribusiCard('Kematangan', distribusiKematangan, _kematanganColor),
                ],
              ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatCards(Map<String, dynamic> d, bool isMedium) {
    final cards = [
      _StatData('Total Pengguna', '${d['total_pengguna'] ?? 0}', Icons.people_rounded, const Color(0xFF2D5A27), const Color(0xFFE8F5E3)),
      _StatData('Total Deteksi', '${d['total_deteksi'] ?? 0}', Icons.analytics_rounded, const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
      _StatData('Deteksi Bulan Ini', '${d['deteksi_bulan_ini'] ?? 0}', Icons.calendar_month_rounded, const Color(0xFF6A1B9A), const Color(0xFFF3E5F5)),
      _StatData('Perlu Ditinjau', '${d['total_flagged'] ?? 0}', Icons.flag_rounded, const Color(0xFFBF360C), const Color(0xFFFBE9E7)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMedium ? 4 : 2,
        childAspectRatio: isMedium ? 1.6 : 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _buildStatCard(cards[i]),
    );
  }

  Widget _buildStatCard(_StatData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: data.bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(data.icon, color: data.color, size: 18),
          ),
          const Spacer(),
          Text(data.value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: data.color, height: 1)),
          const SizedBox(height: 2),
          Text(data.label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildModelAktifBanner(Map<String, dynamic> d) {
    final versi = d['model_versi'] as String?;
    final akurasi = d['akurasi_model'];
    if (versi == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2D5A27), Color(0xFF4CAF50)], begin: Alignment.centerLeft, end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Model Aktif', style: TextStyle(color: Colors.white70, fontSize: 11)),
                Text(versi, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('${akurasi ?? '-'}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction('Varietas', Icons.eco_rounded, const Color(0xFF2D5A27), () => context.go('/admin/varietas')),
      _QuickAction('Kematangan', Icons.water_drop_rounded, const Color(0xFF1565C0), () => context.go('/admin/kematangan')),
      _QuickAction('Pengguna', Icons.people_rounded, const Color(0xFF6A1B9A), () => context.go('/admin/pengguna')),
      _QuickAction('Model CNN', Icons.smart_toy_rounded, const Color(0xFFBF360C), () => context.go('/admin/model')),
    ];

    return Row(
      children: actions.map((a) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: a == actions.last ? 0 : 10),
          child: _buildQuickActionCard(a),
        ),
      )).toList(),
    );
  }

  Widget _buildQuickActionCard(_QuickAction a) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: a.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: a.color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(a.icon, color: a.color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(a.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrenChart(List<dynamic> tren) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: tren.isEmpty
          ? const SizedBox(
              height: 180,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 40, color: AppColors.textLightGrey),
                    SizedBox(height: 8),
                    Text('Belum ada data deteksi minggu ini', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                  ],
                ),
              ),
            )
          : SizedBox(
              height: 200,
              child: LineChart(_buildLineChartData(tren)),
            ),
    );
  }

  LineChartData _buildLineChartData(List<dynamic> tren) {
    final spots = <FlSpot>[];
    for (int i = 0; i < tren.length; i++) {
      spots.add(FlSpot(i.toDouble(), (tren[i]['jumlah'] as num).toDouble()));
    }
    final maxY = spots.isEmpty ? 10.0 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;

    return LineChartData(
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY > 5 ? (maxY / 5).ceilToDouble() : 1,
        getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: maxY > 5 ? (maxY / 5).ceilToDouble() : 1,
            getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= tren.length) return const SizedBox.shrink();
              final tanggal = tren[idx]['tanggal'] as String;
              final parts = tanggal.split('-');
              final label = parts.length >= 3 ? '${parts[2]}/${parts[1]}' : tanggal;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textGrey)),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
            '${s.y.toInt()} deteksi',
            const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          )).toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: AppColors.primaryGreen,
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 4,
              color: Colors.white,
              strokeWidth: 2.5,
              strokeColor: AppColors.primaryGreen,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [AppColors.primaryGreen.withValues(alpha: 0.2), AppColors.primaryGreen.withValues(alpha: 0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDistribusiCard(String title, List<dynamic> items, Color Function(String, int) colorFn) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A2E1A))),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Container(
              height: 120,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 36, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  const Text('Belum ada data', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                ],
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 32,
                      sections: List.generate(items.length, (i) {
                        final item = items[i];
                        final label = (item['nama'] ?? item['label']) as String;
                        final persen = (item['persentase'] as num).toDouble();
                        return PieChartSectionData(
                          value: persen,
                          title: '${persen.toStringAsFixed(0)}%',
                          color: colorFn(label, i),
                          radius: 38,
                          titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(items.length, (i) {
                      final item = items[i];
                      final label = (item['nama'] ?? item['label']) as String;
                      final jumlah = item['jumlah'] as int;
                      final persen = (item['persentase'] as num).toDouble();
                      final color = colorFn(label, i);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text('$jumlah data · ${persen.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A2E1A)));
  }

  Color _varietasColor(String nama, int index) {
    const colors = [Color(0xFF2D5A27), Color(0xFF66BB6A), Color(0xFF26A69A), Color(0xFF42A5F5)];
    return colors[index % colors.length];
  }

  Color _kematanganColor(String label, int index) => AppColors.getKematanganColor(label);
}

class _StatData {
  final String label, value;
  final IconData icon;
  final Color color, bgColor;
  const _StatData(this.label, this.value, this.icon, this.color, this.bgColor);
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.label, this.icon, this.color, this.onTap);
}