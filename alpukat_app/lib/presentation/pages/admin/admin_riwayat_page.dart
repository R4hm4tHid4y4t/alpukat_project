import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../data/datasources/admin_remote_datasource.dart';
import '../../../injection/injection_container.dart';
import '../../widgets/error_state_widget.dart';
import 'admin_drawer.dart';

class AdminRiwayatPage extends StatefulWidget {
  const AdminRiwayatPage({super.key});

  @override
  State<AdminRiwayatPage> createState() => _AdminRiwayatPageState();
}

class _AdminRiwayatPageState extends State<AdminRiwayatPage> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String? _flagFilter;
  int? _varietasFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await sl<AdminRemoteDataSource>().getDeteksiGlobal(
        perPage: 100,
        search: _search.isEmpty ? null : _search,
        flag: _flagFilter,
        varietasId: _varietasFilter,
      );
      final data = result['data'] as Map<String, dynamic>;
      setState(() {
        _items = data['items'] as List<dynamic>;
        _loading = false;
      });
    } on ServerException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Gagal memuat riwayat deteksi'; _loading = false; });
    }
  }

  void _showFlagDialog(Map<String, dynamic> item) {
    final catatanCtrl = TextEditingController(text: item['catatan_flag'] as String? ?? '');
    String selectedFlag = item['status_flag'] as String? ?? 'normal';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Tandai Hasil Deteksi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status Flag', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  value: selectedFlag,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'perlu_ditinjau', child: Text('Perlu Ditinjau')),
                    DropdownMenuItem(value: 'sudah_ditinjau', child: Text('Sudah Ditinjau')),
                  ],
                  onChanged: (v) => setStateDialog(() => selectedFlag = v ?? selectedFlag),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: catatanCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await sl<AdminRemoteDataSource>().flagDeteksi(
                    item['id'] as int,
                    statusFlag: selectedFlag,
                    catatan: catatanCtrl.text.trim(),
                  );
                  
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  
                  if (!mounted) return;
                  _load();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status berhasil diperbarui'), backgroundColor: AppColors.successColor),
                  );
                } on ServerException catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.errorColor));
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  int get _totalDeteksi => _items.length;
  int get _totalMiki => _items.where((i) => (i as Map)['varietas_nama'] == 'Miki').length;
  int get _totalAligator => _items.where((i) => (i as Map)['varietas_nama'] == 'Aligator').length;
  double get _akurasiRata {
    if (_items.isEmpty) return 0;
    double sum = 0;
    int count = 0;
    for (final i in _items) {
      final m = i as Map;
      if (m['confidence_varietas'] != null) { sum += (m['confidence_varietas'] as num).toDouble(); count++; }
      if (m['confidence_kematangan'] != null) { sum += (m['confidence_kematangan'] as num).toDouble(); count++; }
    }
    return count > 0 ? sum / count : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(title: const Text('Riwayat Deteksi Global')),
      drawer: const AdminDrawer(currentRoute: 'riwayat'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorStateWidget(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stat header
                        Row(
                          children: [
                            _statChip('Total', '$_totalDeteksi', AppColors.primaryGreen),
                            const SizedBox(width: 8),
                            _statChip('Aligator', '$_totalAligator', AppColors.secondaryGreen),
                            const SizedBox(width: 8),
                            _statChip('Miki', '$_totalMiki', AppColors.setengahColor),
                            const SizedBox(width: 8),
                            _statChip('Akurasi Rata-rata', '${_akurasiRata.toStringAsFixed(1)}%', AppColors.matangColor),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Filter + Export
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Cari nama atau email pengguna...',
                                  prefixIcon: Icon(Icons.search),
                                  isDense: true,
                                ),
                                onChanged: (v) => _search = v,
                                onSubmitted: (_) => _load(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String?>(
                              value: _flagFilter,
                              hint: const Text('Semua Status'),
                              items: const [
                                DropdownMenuItem(value: null, child: Text('Semua Status')),
                                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                                DropdownMenuItem(value: 'perlu_ditinjau', child: Text('Perlu Ditinjau')),
                                DropdownMenuItem(value: 'sudah_ditinjau', child: Text('Sudah Ditinjau')),
                              ],
                              onChanged: (v) {
                                setState(() => _flagFilter = v);
                                _load();
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                final url = '${AppConstants.apiUrl}${sl<AdminRemoteDataSource>().getExportUrl()}';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Export CSV tersedia di: $url')),
                                );
                              },
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text('Export CSV'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // DataTable
                        Card(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Pengguna')),
                                DataColumn(label: Text('Varietas')),
                                DataColumn(label: Text('Kematangan')),
                                DataColumn(label: Text('Akurasi')),
                                DataColumn(label: Text('Tanggal')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Aksi')),
                              ],
                              rows: _items.map((item) {
                                final m = item as Map<String, dynamic>;
                                final pengguna = m['pengguna'] as Map<String, dynamic>?;
                                final statusFlag = m['status_flag'] as String? ?? 'normal';
                                final isFlagged = statusFlag == 'perlu_ditinjau';

                                String tanggal = '-';
                                if (m['created_at'] != null) {
                                  final date = DateTime.tryParse(m['created_at'] as String);
                                  if (date != null) tanggal = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                                }

                                return DataRow(
                                  color: isFlagged ? WidgetStateProperty.all(AppColors.warningColor.withValues(alpha: 0.08)) : null,
                                  cells: [
                                    DataCell(Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(pengguna?['nama'] as String? ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                        Text(pengguna?['email'] as String? ?? '-', style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
                                      ],
                                    )),
                                    DataCell(Text(m['varietas_nama'] as String? ?? '-')),
                                    DataCell(Text(m['kematangan_label'] as String? ?? '-')),
                                    DataCell(Text(
                                      'V: ${(m['confidence_varietas'] as num?)?.toStringAsFixed(1) ?? '-'}%\n'
                                      'K: ${(m['confidence_kematangan'] as num?)?.toStringAsFixed(1) ?? '-'}%',
                                      style: const TextStyle(fontSize: 11),
                                    )),
                                    DataCell(Text(tanggal, style: const TextStyle(fontSize: 11))),
                                    DataCell(Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isFlagged ? AppColors.warningColor.withValues(alpha: 0.2) : AppColors.successColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(statusFlag, style: TextStyle(fontSize: 10, color: isFlagged ? AppColors.warningColor : AppColors.successColor)),
                                    )),
                                    DataCell(IconButton(
                                      icon: const Icon(Icons.flag_outlined, size: 18, color: AppColors.primaryGreen),
                                      onPressed: () => _showFlagDialog(m),
                                    )),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGrey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}