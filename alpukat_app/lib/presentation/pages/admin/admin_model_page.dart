import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
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
    } catch (e) {
      setState(() { _error = 'Gagal memuat data model'; _loading = false; });
    }
  }

  Future<void> _activate(Map<String, dynamic> model) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aktifkan Model'),
        content: Text('Aktifkan model "${model['versi']}"? Model yang sedang aktif akan dinonaktifkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aktifkan')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await sl<AdminRemoteDataSource>().activateModel(model['id'] as int);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Model ${model['versi']} berhasil diaktifkan'), backgroundColor: AppColors.successColor),
        );
      }
    } on ServerException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.errorColor));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final aktif = _items.where((m) => (m as Map)['status_aktif'] == 1).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(title: const Text('Model CNN')),
      drawer: const AdminDrawer(currentRoute: 'model'),
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
                        // ── Model Aktif ──────────────────────
                        const Text('Model Aktif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 12),
                        if (aktif.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            child: const Text('Belum ada model aktif', style: TextStyle(color: AppColors.textGrey)),
                          )
                        else
                          ...aktif.map((m) => _activeModelCard(m as Map<String, dynamic>)),
                        const SizedBox(height: 24),

                        // ── Aksi ──────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Fitur upload model: gunakan endpoint POST /admin/model dari panel khusus')),
                                  );
                                },
                                icon: const Icon(Icons.upload_file, size: 18),
                                label: const Text('Upload Model'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.download, size: 18),
                                label: const Text('Download'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.model_training, size: 18),
                                label: const Text('Train Model'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Arsitektur ───────────────────────
                        const Text('Arsitektur Model', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
                          child: Column(
                            children: const [
                              _ArchStep(label: 'Input Layer', detail: '224 × 224 × 3 (RGB)'),
                              _ArchArrow(),
                              _ArchStep(label: 'MobileNetV2 Base', detail: 'Pretrained ImageNet, frozen layers'),
                              _ArchArrow(),
                              _ArchStep(label: 'Global Average Pooling', detail: ''),
                              _ArchArrow(),
                              _ArchStep(label: 'Dense Layer', detail: '256 units, ReLU'),
                              _ArchArrow(),
                              _ArchStep(label: 'Dropout', detail: '0.3'),
                              _ArchArrow(),
                              _ArchStep(label: 'Output Layer', detail: 'Softmax (2 atau 4 kelas)'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── History ───────────────────────────
                        const Text('Riwayat Versi Model', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 12),
                        Card(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Versi')),
                                DataColumn(label: Text('Akurasi')),
                                DataColumn(label: Text('Format')),
                                DataColumn(label: Text('Deskripsi')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Aksi')),
                              ],
                              rows: _items.map((item) {
                                final m = item as Map<String, dynamic>;
                                final isActive = m['status_aktif'] == 1;
                                final deskripsi = (m['deskripsi'] as String? ?? '');
                                return DataRow(cells: [
                                  DataCell(Text(m['versi'] as String, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Text('${m['akurasi'] ?? '-'}%')),
                                  DataCell(Text(m['format_file'] as String? ?? '-')),
                                  DataCell(SizedBox(width: 200, child: Text(
                                    deskripsi.length > 50 ? '${deskripsi.substring(0, 50)}...' : deskripsi,
                                    style: const TextStyle(fontSize: 12),
                                  ))),
                                  DataCell(isActive
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: AppColors.successColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                          child: const Text('Aktif', style: TextStyle(fontSize: 11, color: AppColors.successColor)),
                                        )
                                      : const Text('-', style: TextStyle(color: AppColors.textGrey))),
                                  DataCell(isActive
                                      ? const SizedBox.shrink()
                                      : TextButton(onPressed: () => _activate(m), child: const Text('Aktifkan'))),
                                ]);
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

  Widget _activeModelCard(Map<String, dynamic> m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.extraLightGreen,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: AppColors.primaryGreen, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Text(m['versi'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text(m['deskripsi'] as String? ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3,
            mainAxisSpacing: 8, crossAxisSpacing: 8,
            children: [
              _metricBox('Akurasi', '${m['akurasi'] ?? '-'}%'),
              _metricBox('Format', m['format_file'] as String? ?? '-'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ArchStep extends StatelessWidget {
  final String label;
  final String detail;
  const _ArchStep({required this.label, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.extraLightGreen, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          if (detail.isNotEmpty) Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
        ],
      ),
    );
  }
}

class _ArchArrow extends StatelessWidget {
  const _ArchArrow();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Icon(Icons.arrow_downward, size: 16, color: AppColors.textLightGrey),
    );
  }
}
