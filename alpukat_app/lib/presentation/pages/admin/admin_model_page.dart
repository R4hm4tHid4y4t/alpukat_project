import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../data/datasources/admin_remote_datasource.dart';
import '../../../injection/injection_container.dart';
import '../../widgets/error_state_widget.dart';
import 'admin_drawer.dart';

class AdminModelPage extends StatefulWidget {
  const AdminModelPage({super.key});

  @override
  State<AdminModelPage> createState() => _AdminModelPageState();
}

class _AdminModelPageState extends State<AdminModelPage> {
  List<dynamic> _items = [];
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
      final result = await sl<AdminRemoteDataSource>().getModels();
      setState(() {
        _items = result['data'] as List<dynamic>;
        _loading = false;
      });
    } on ServerException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Tidak dapat terhubung ke server'; _loading = false; });
    }
  }

  Future<void> _activate(Map<String, dynamic> model) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.power_settings_new_rounded, color: AppColors.primaryGreen, size: 22),
          SizedBox(width: 8),
          Text('Aktifkan Model', style: TextStyle(fontSize: 16)),
        ]),
        content: Text('Aktifkan model "${model['versi']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await sl<AdminRemoteDataSource>().activateModel(model['id'] as int);
      _load();
      if (mounted) _showSnackbar('Model ${model['versi']} berhasil diaktifkan', success: true);
    } on ServerException catch (e) {
      if (mounted) _showSnackbar(e.message, success: false);
    }
  }

  void _showUploadInfo() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.upload_file_rounded, color: AppColors.primaryGreen, size: 24),
                  SizedBox(width: 12),
                  Text('Upload Model TFLite', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Model TFLite dikelola langsung di server. Gunakan perintah berikut untuk mengaktifkan model:', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
              const SizedBox(height: 16),
              _buildCodeBlock('# Login & dapatkan token\ncurl -X POST "${AppConstants.apiUrl}/auth/login" \\\n  -H "Content-Type: application/json" \\\n  -d \'{"email":"admin@alpukat.id","password":"Admin@123"}\''),
              const SizedBox(height: 12),
              _buildCodeBlock('# Aktifkan model (ganti 1 dengan ID model)\ncurl -X POST "${AppConstants.apiUrl}/admin/model/activate/1" \\\n  -H "Authorization: Bearer \$TOKEN"'),
              const SizedBox(height: 20),
              _buildInfoRow(Icons.folder_rounded, 'Lokasi model di server:', 'alpukat_api/models_tflite/'),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.info_rounded, 'Format yang didukung:', 'TensorFlow Lite (.tflite)'),
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

  void _showDownloadInfo() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.download_rounded, color: Color(0xFF1565C0), size: 24),
                  SizedBox(width: 12),
                  Text('Download Model', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('File model tersedia langsung di server. Salin path berikut:', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
              const SizedBox(height: 16),
              ..._items.map((m) {
                final mm = m as Map<String, dynamic>;
                final versi = mm['versi'] as String;
                final isVarietas = versi.contains('varietas');
                final path = 'alpukat_api/models_tflite/${isVarietas ? 'model_varietas' : 'model_kematangan'}.tflite';
                return _buildDownloadItem(versi, path, mm['akurasi'], mm['status_aktif'] == 1);
              }),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
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

  void _showTrainInfo() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.model_training_rounded, color: Color(0xFF6A1B9A), size: 24),
                  SizedBox(width: 12),
                  Text('Train Model', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Pelatihan model dilakukan menggunakan Jupyter Notebook atau Google Colab. Gunakan langkah berikut:', style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.5)),
              const SizedBox(height: 16),
              _buildStepItem('1', 'Siapkan dataset gambar alpukat (format JPG/PNG)'),
              _buildStepItem('2', 'Buka notebook training di folder model_training/'),
              _buildStepItem('3', 'Jalankan training dengan MobileNetV2 sebagai base model'),
              _buildStepItem('4', 'Export model ke format .tflite'),
              _buildStepItem('5', 'Tempatkan file .tflite di folder models_tflite/'),
              _buildStepItem('6', 'Aktifkan model melalui halaman ini'),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A1B9A), foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Mengerti'),
                ),
              ),
            ],
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

  @override
  Widget build(BuildContext context) {
    final aktif = _items.where((m) => (m as Map)['status_aktif'] == 1).toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF1A2E1A)),
        title: const Text('Model CNN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryGreen), onPressed: _load, tooltip: 'Refresh'),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AdminDrawer(currentRoute: 'model'),
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
                        // ── Model Aktif ──────────────────────────
                        const Text('Model Aktif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A2E1A))),
                        const SizedBox(height: 12),
                        if (aktif.isEmpty)
                          _buildEmptyModelCard()
                        else
                          isWide
                              ? Row(
                                  children: aktif.map((m) => Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(right: m == aktif.last ? 0 : 16),
                                      child: _buildActiveModelCard(m as Map<String, dynamic>),
                                    ),
                                  )).toList(),
                                )
                              : Column(children: aktif.map((m) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildActiveModelCard(m as Map<String, dynamic>),
                                  )).toList()),
                        const SizedBox(height: 24),

                        // ── Aksi ────────────────────────────────
                        const Text('Manajemen Model', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A2E1A))),
                        const SizedBox(height: 12),
                        isWide
                            ? Row(children: [
                                _buildActionCard(Icons.upload_file_rounded, 'Upload Model', 'Tambah model .tflite baru ke sistem', const Color(0xFF2D5A27), const Color(0xFFE8F5E3), _showUploadInfo),
                                const SizedBox(width: 12),
                                _buildActionCard(Icons.download_rounded, 'Download Model', 'Unduh file model dari server', const Color(0xFF1565C0), const Color(0xFFE3F2FD), _showDownloadInfo),
                                const SizedBox(width: 12),
                                _buildActionCard(Icons.model_training_rounded, 'Panduan Training', 'Cara melatih model CNN baru', const Color(0xFF6A1B9A), const Color(0xFFF3E5F5), _showTrainInfo),
                              ])
                            : Column(children: [
                                _buildActionCard(Icons.upload_file_rounded, 'Upload Model', 'Tambah model .tflite baru ke sistem', const Color(0xFF2D5A27), const Color(0xFFE8F5E3), _showUploadInfo),
                                const SizedBox(height: 10),
                                _buildActionCard(Icons.download_rounded, 'Download Model', 'Unduh file model dari server', const Color(0xFF1565C0), const Color(0xFFE3F2FD), _showDownloadInfo),
                                const SizedBox(height: 10),
                                _buildActionCard(Icons.model_training_rounded, 'Panduan Training', 'Cara melatih model CNN baru', const Color(0xFF6A1B9A), const Color(0xFFF3E5F5), _showTrainInfo),
                              ]),
                        const SizedBox(height: 24),

                        // ── Arsitektur ───────────────────────────
                        const Text('Arsitektur Model', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A2E1A))),
                        const SizedBox(height: 12),
                        _buildArsitekturCard(),
                        const SizedBox(height: 24),

                        // ── Riwayat Versi ────────────────────────
                        const Text('Riwayat Versi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A2E1A))),
                        const SizedBox(height: 12),
                        _buildRiwayatTable(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildActiveModelCard(Map<String, dynamic> m) {
    final isVarietas = (m['versi'] as String).contains('varietas');
    final color = isVarietas ? const Color(0xFF2D5A27) : const Color(0xFF1565C0);
    final bgColor = isVarietas ? const Color(0xFFE8F5E3) : const Color(0xFFE3F2FD);
    final icon = isVarietas ? Icons.eco_rounded : Icons.water_drop_rounded;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: const Text('AKTIF', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.successColor, letterSpacing: 1)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(m['versi'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(m['deskripsi'] as String? ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildMetric('Akurasi', '${m['akurasi'] ?? '-'}%', color)),
              const SizedBox(width: 10),
              Expanded(child: _buildMetric('Format', m['format_file'] as String? ?? '-', color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF5F7F5), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildEmptyModelCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E8E0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.textGrey, size: 20),
          SizedBox(width: 12),
          Text('Belum ada model aktif', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle, Color color, Color bgColor, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade300),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArsitekturCard() {
    const steps = [
      ('Input Layer', '224 × 224 × 3 (RGB)'),
      ('MobileNetV2 Base', 'Pretrained ImageNet, frozen layers'),
      ('Global Average Pooling', ''),
      ('Dense Layer', '256 units, ReLU'),
      ('Dropout', '0.3'),
      ('Output Layer', 'Softmax (2 atau 4 kelas)'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            _buildArchStep(steps[i].$1, steps[i].$2, i),
            if (i < steps.length - 1) _buildArchArrow(),
          ],
        ],
      ),
    );
  }

  Widget _buildArchStep(String label, String detail, int index) {
    const colors = [Color(0xFF2D5A27), Color(0xFF1565C0), Color(0xFF6A1B9A), Color(0xFFBF360C), Color(0xFF00695C), Color(0xFF2D5A27)];
    final color = colors[index % colors.length];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
            child: Center(child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
                if (detail.isNotEmpty) Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Icon(Icons.arrow_downward_rounded, size: 16, color: AppColors.textLightGrey),
    );
  }

  Widget _buildRiwayatTable() {
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
                  columnSpacing: 20,
                  horizontalMargin: 20,
                  columns: const [
                    DataColumn(label: Expanded(child: Text('VERSI'))),
                    DataColumn(label: Text('AKURASI')),
                    DataColumn(label: Text('FORMAT')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('AKSI')),
                  ],
            rows: _items.map((item) {
              final m = item as Map<String, dynamic>;
              final isActive = m['status_aktif'] == 1;
              return DataRow(cells: [
                DataCell(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(m['versi'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(
                      (m['deskripsi'] as String? ?? '').length > 40
                          ? '${(m['deskripsi'] as String).substring(0, 40)}...'
                          : m['deskripsi'] as String? ?? '',
                      style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                    ),
                  ],
                )),
                DataCell(Text('${m['akurasi'] ?? '-'}%', style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFF5F7F5), borderRadius: BorderRadius.circular(6)),
                  child: Text(m['format_file'] as String? ?? '-', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                )),
                DataCell(isActive
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFE8F5E3), borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 12, color: AppColors.successColor),
                            SizedBox(width: 4),
                            Text('Aktif', style: TextStyle(fontSize: 11, color: AppColors.successColor, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Nonaktif', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                      )),
                DataCell(isActive
                    ? const SizedBox.shrink()
                    : ElevatedButton(
                        onPressed: () => _activate(m),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Aktifkan', style: TextStyle(fontSize: 12)),
                      )),
              ]);
                }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCodeBlock(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1A2E1A), borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(code, style: const TextStyle(color: Color(0xFF8BC34A), fontSize: 11, fontFamily: 'monospace', height: 1.6))),
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Colors.white38, size: 16),
            onPressed: () => Clipboard.setData(ClipboardData(text: code)).then((_) {
              if (mounted) _showSnackbar('Kode disalin', success: true);
            }),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadItem(String versi, String path, dynamic akurasi, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E8E0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_rounded, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(versi, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(path, style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontFamily: 'monospace')),
                if (akurasi != null) Text('Akurasi: $akurasi%', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
              ],
            ),
          ),
          if (isActive) const Icon(Icons.check_circle_rounded, color: AppColors.successColor, size: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primaryGreen),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
        const SizedBox(width: 4),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
      ],
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(color: Color(0xFF6A1B9A), shape: BoxShape.circle),
            child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.4))),
        ],
      ),
    );
  }
}