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
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await sl<AdminRemoteDataSource>().getDeteksiGlobal(
        perPage: 100,
        search: _search.isEmpty ? null : _search,
        flag: _flagFilter,
      );
      final data = result['data'] as Map<String, dynamic>;
      setState(() {
        _items = data['items'] as List<dynamic>;
        _loading = false;
      });
    } on ServerException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Tidak dapat terhubung ke server'; _loading = false; });
    }
  }

  void _showFlagDialog(Map<String, dynamic> item) {
    final catatanCtrl = TextEditingController(text: item['catatan_flag'] as String? ?? '');
    String selectedFlag = item['status_flag'] as String? ?? 'normal';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.extraLightGreen, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.flag_rounded, color: AppColors.primaryGreen, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Tandai Hasil Deteksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Status Flag', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2E1A))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAF8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE0E8E0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedFlag,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'normal', child: Row(children: [Icon(Icons.check_circle_rounded, color: AppColors.successColor, size: 16), SizedBox(width: 8), Text('Normal', style: TextStyle(fontSize: 13))])),
                        DropdownMenuItem(value: 'perlu_ditinjau', child: Row(children: [Icon(Icons.warning_rounded, color: AppColors.warningColor, size: 16), SizedBox(width: 8), Text('Perlu Ditinjau', style: TextStyle(fontSize: 13))])),
                        DropdownMenuItem(value: 'sudah_ditinjau', child: Row(children: [Icon(Icons.verified_rounded, color: Color(0xFF1565C0), size: 16), SizedBox(width: 8), Text('Sudah Ditinjau', style: TextStyle(fontSize: 13))])),
                      ],
                      onChanged: (v) => setStateDialog(() => selectedFlag = v ?? selectedFlag),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Catatan (opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2E1A))),
                const SizedBox(height: 8),
                TextField(
                  controller: catatanCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Tambahkan catatan...',
                    hintStyle: const TextStyle(color: AppColors.textLightGrey, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF8FAF8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E8E0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E8E0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
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
                            _showSnackbar('Status berhasil diperbarui', success: true);
                          } on ServerException catch (e) {
                            if (mounted) _showSnackbar(e.message, success: false);
                          }
                        },
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackbar(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(success ? Icons.check_circle_rounded : Icons.error_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg),
      ]),
      backgroundColor: success ? AppColors.successColor : AppColors.errorColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _exportCSV() {
    final url = '${AppConstants.apiUrl}/admin/deteksi/export';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.download_rounded, color: AppColors.primaryGreen, size: 22),
                  SizedBox(width: 10),
                  Text('Export Data CSV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Akses URL berikut di browser untuk mengunduh file CSV (pastikan sudah login):', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF8FAF8), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE0E8E0))),
                child: SelectableText(url, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.primaryGreen)),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int get _totalDeteksi => _items.length;
  int get _totalAligator => _items.where((i) => (i as Map)['varietas_nama'] == 'Aligator').length;
  int get _totalMiki => _items.where((i) => (i as Map)['varietas_nama'] == 'Miki').length;
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

  Color _getFlagColor(String flag) {
    switch (flag) {
      case 'perlu_ditinjau': return AppColors.warningColor;
      case 'sudah_ditinjau': return const Color(0xFF1565C0);
      default: return AppColors.successColor;
    }
  }

  Color _getFlagBgColor(String flag) {
    switch (flag) {
      case 'perlu_ditinjau': return AppColors.warningColor.withValues(alpha: 0.1);
      case 'sudah_ditinjau': return const Color(0xFFE3F2FD);
      default: return const Color(0xFFE8F5E3);
    }
  }

  String _getFlagLabel(String flag) {
    switch (flag) {
      case 'perlu_ditinjau': return 'Perlu Ditinjau';
      case 'sudah_ditinjau': return 'Sudah Ditinjau';
      default: return 'Normal';
    }
  }

  IconData _getFlagIcon(String flag) {
    switch (flag) {
      case 'perlu_ditinjau': return Icons.warning_rounded;
      case 'sudah_ditinjau': return Icons.verified_rounded;
      default: return Icons.check_circle_rounded;
    }
  }

  String _formatTanggal(String? raw) {
    if (raw == null) return '-';
    final date = DateTime.tryParse(raw);
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF1A2E1A)),
        title: const Text('Riwayat Deteksi Global', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryGreen), onPressed: _load, tooltip: 'Refresh'),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AdminDrawer(currentRoute: 'riwayat'),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Stat Cards ──────────────────────────
                        isWide
                            ? Row(children: [
                                _buildStatCard('Total', '$_totalDeteksi', Icons.analytics_rounded, const Color(0xFF2D5A27), const Color(0xFFE8F5E3)),
                                const SizedBox(width: 10),
                                _buildStatCard('Aligator', '$_totalAligator', Icons.eco_rounded, const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
                                const SizedBox(width: 10),
                                _buildStatCard('Miki', '$_totalMiki', Icons.eco_outlined, const Color(0xFF6A1B9A), const Color(0xFFF3E5F5)),
                                const SizedBox(width: 10),
                                _buildStatCard('Akurasi Rata-rata', '${_akurasiRata.toStringAsFixed(1)}%', Icons.speed_rounded, const Color(0xFF00695C), const Color(0xFFE0F2F1)),
                              ])
                            : GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: 1.8,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                children: [
                                  _buildStatCardItem('Total', '$_totalDeteksi', Icons.analytics_rounded, const Color(0xFF2D5A27), const Color(0xFFE8F5E3)),
                                  _buildStatCardItem('Aligator', '$_totalAligator', Icons.eco_rounded, const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
                                  _buildStatCardItem('Miki', '$_totalMiki', Icons.eco_outlined, const Color(0xFF6A1B9A), const Color(0xFFF3E5F5)),
                                  _buildStatCardItem('Akurasi', '${_akurasiRata.toStringAsFixed(1)}%', Icons.speed_rounded, const Color(0xFF00695C), const Color(0xFFE0F2F1)),
                                ],
                              ),
                        const SizedBox(height: 20),

                        // ── Filter + Export ─────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: isWide
                              ? Row(children: [
                                  Expanded(child: _buildSearchField()),
                                  const SizedBox(width: 12),
                                  _buildFlagDropdown(),
                                  const SizedBox(width: 12),
                                  _buildExportButton(),
                                ])
                              : Column(children: [
                                  _buildSearchField(),
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    Expanded(child: _buildFlagDropdown()),
                                    const SizedBox(width: 10),
                                    _buildExportButton(),
                                  ]),
                                ]),
                        ),
                        const SizedBox(height: 20),

                        // ── Data Table / Cards ──────────────────
                        if (_items.isEmpty)
                          _buildEmptyState()
                        else
                          isWide
                              ? _buildDeteksiTable()
                              : _buildDeteksiCards(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
                  Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardItem(String label, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchCtrl,
      decoration: InputDecoration(
        hintText: 'Cari nama atau email pengguna...',
        hintStyle: const TextStyle(color: AppColors.textLightGrey, fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textGrey, size: 20),
        suffixIcon: _search.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textGrey),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _search = '');
                  _load();
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8FAF8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E8E0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E8E0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
      onChanged: (v) => setState(() => _search = v),
      onSubmitted: (_) => _load(),
    );
  }

  Widget _buildFlagDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E8E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _flagFilter,
          hint: const Text('Semua Status', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
          isDense: true,
          items: const [
            DropdownMenuItem(value: null, child: Text('Semua Status', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'normal', child: Text('Normal', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'perlu_ditinjau', child: Text('Perlu Ditinjau', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'sudah_ditinjau', child: Text('Sudah Ditinjau', style: TextStyle(fontSize: 13))),
          ],
          onChanged: (v) {
            setState(() => _flagFilter = v);
            _load();
          },
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return ElevatedButton.icon(
      onPressed: _exportCSV,
      icon: const Icon(Icons.download_rounded, size: 16),
      label: const Text('Export CSV', style: TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDeteksiTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAF8)),
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textGrey),
                  dataRowMinHeight: 60,
                  dataRowMaxHeight: 72,
                  columnSpacing: 20,
                  horizontalMargin: 20,
                  columns: const [
                    DataColumn(label: Expanded(child: Text('PENGGUNA'))),
                    DataColumn(label: Text('VARIETAS')),
                    DataColumn(label: Text('KEMATANGAN')),
                    DataColumn(label: Text('AKURASI')),
                    DataColumn(label: Text('TANGGAL')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('AKSI')),
                  ],
                  rows: _items.map((item) {
                    final m = item as Map<String, dynamic>;
                    return _buildTableRow(m);
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildTableRow(Map<String, dynamic> m) {
    final pengguna = m['pengguna'] as Map<String, dynamic>?;
    final statusFlag = m['status_flag'] as String? ?? 'normal';
    final isFlagged = statusFlag == 'perlu_ditinjau';
    final confidenceV = (m['confidence_varietas'] as num?)?.toStringAsFixed(1) ?? '-';
    final confidenceK = (m['confidence_kematangan'] as num?)?.toStringAsFixed(1) ?? '-';

    return DataRow(
      color: isFlagged ? WidgetStateProperty.all(AppColors.warningColor.withValues(alpha: 0.04)) : null,
      cells: [
        DataCell(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(pengguna?['nama'] as String? ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(pengguna?['email'] as String? ?? '-', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
          ],
        )),
        DataCell(m['varietas_nama'] != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.extraLightGreen, borderRadius: BorderRadius.circular(6)),
                child: Text(m['varietas_nama'] as String, style: const TextStyle(fontSize: 12, color: AppColors.primaryGreen, fontWeight: FontWeight.w500)),
              )
            : const Text('-', style: TextStyle(color: AppColors.textGrey))),
        DataCell(m['kematangan_label'] != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.getKematanganColor(m['kematangan_label'] as String).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(m['kematangan_label'] as String,
                    style: TextStyle(fontSize: 12, color: AppColors.getKematanganColor(m['kematangan_label'] as String), fontWeight: FontWeight.w500)),
              )
            : const Text('-', style: TextStyle(color: AppColors.textGrey))),
        DataCell(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildConfidenceChip('V', '$confidenceV%', AppColors.primaryGreen),
            const SizedBox(height: 2),
            _buildConfidenceChip('K', '$confidenceK%', const Color(0xFF1565C0)),
          ],
        )),
        DataCell(Text(_formatTanggal(m['created_at'] as String?), style: const TextStyle(fontSize: 11, color: AppColors.textGrey))),
        DataCell(_buildFlagBadge(statusFlag)),
        DataCell(Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showFlagDialog(m),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.extraLightGreen, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.flag_rounded, size: 16, color: AppColors.primaryGreen),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildConfidenceChip(String prefix, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
          child: Center(child: Text(prefix, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildFlagBadge(String flag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: _getFlagBgColor(flag), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getFlagIcon(flag), size: 11, color: _getFlagColor(flag)),
          const SizedBox(width: 4),
          Text(_getFlagLabel(flag), style: TextStyle(fontSize: 10, color: _getFlagColor(flag), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDeteksiCards() {
    return Column(
      children: _items.map((item) {
        final m = item as Map<String, dynamic>;
        final pengguna = m['pengguna'] as Map<String, dynamic>?;
        final statusFlag = m['status_flag'] as String? ?? 'normal';
        final isFlagged = statusFlag == 'perlu_ditinjau';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: isFlagged ? Border.all(color: AppColors.warningColor.withValues(alpha: 0.4)) : null,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isFlagged ? AppColors.warningColor.withValues(alpha: 0.05) : const Color(0xFFF8FAF8),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.extraLightGreen,
                      child: Text(
                        (pengguna?['nama'] as String? ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pengguna?['nama'] as String? ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(pengguna?['email'] as String? ?? '-', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                        ],
                      ),
                    ),
                    _buildFlagBadge(statusFlag),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildInfoItem('Varietas', m['varietas_nama'] as String? ?? '-', AppColors.primaryGreen)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildInfoItem('Kematangan', m['kematangan_label'] as String? ?? '-', const Color(0xFF1565C0))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildInfoItem('Conf. Varietas', '${(m['confidence_varietas'] as num?)?.toStringAsFixed(1) ?? '-'}%', AppColors.primaryGreen)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildInfoItem('Conf. Kematangan', '${(m['confidence_kematangan'] as num?)?.toStringAsFixed(1) ?? '-'}%', const Color(0xFF1565C0))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textGrey),
                        const SizedBox(width: 4),
                        Text(_formatTanggal(m['created_at'] as String?), style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                        const Spacer(),
                        InkWell(
                          onTap: () => _showFlagDialog(m),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.extraLightGreen, borderRadius: BorderRadius.circular(8)),
                            child: const Row(
                              children: [
                                Icon(Icons.flag_rounded, size: 14, color: AppColors.primaryGreen),
                                SizedBox(width: 4),
                                Text('Tandai', style: TextStyle(fontSize: 12, color: AppColors.primaryGreen, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.extraLightGreen, shape: BoxShape.circle),
              child: const Icon(Icons.history_rounded, size: 48, color: AppColors.primaryGreen),
            ),
            const SizedBox(height: 16),
            const Text('Tidak ada riwayat deteksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Belum ada data atau coba ubah filter', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}