import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/errors/exceptions.dart';
import '../../../data/datasources/admin_remote_datasource.dart';
import '../../../injection/injection_container.dart';
import '../../widgets/error_state_widget.dart';
import 'admin_drawer.dart';

class AdminKematanganPage extends StatefulWidget {
  const AdminKematanganPage({super.key});

  @override
  State<AdminKematanganPage> createState() => _AdminKematanganPageState();
}

class _AdminKematanganPageState extends State<AdminKematanganPage> {
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
      final result = await sl<AdminRemoteDataSource>().getKematangan();
      setState(() {
        _items = result['data'] as List<dynamic>;
        _loading = false;
      });
    } on ServerException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Gagal memuat data tingkat kematangan'; _loading = false; });
    }
  }

  void _showForm({Map<String, dynamic>? item}) {
    final labelCtrl = TextEditingController(text: item?['label_kematangan'] as String? ?? '');
    final deskripsiCtrl = TextEditingController(text: item?['deskripsi'] as String? ?? '');
    final ciriCtrl = TextEditingController(text: item?['ciri_visual'] as String? ?? '');
    final isEdit = item != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Tingkat Kematangan' : 'Tambah Tingkat Kematangan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Nama Tingkat')),
              const SizedBox(height: 12),
              TextField(controller: deskripsiCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Deskripsi')),
              const SizedBox(height: 12),
              TextField(controller: ciriCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Ciri Visual')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (labelCtrl.text.trim().isEmpty) return;
              try {
                final remote = sl<AdminRemoteDataSource>();
                if (isEdit) {
                  await remote.updateKematangan(item['id'] as int,
                      label: labelCtrl.text.trim(), deskripsi: deskripsiCtrl.text.trim(), ciriVisual: ciriCtrl.text.trim());
                } else {
                  await remote.createKematangan(
                      label: labelCtrl.text.trim(), deskripsi: deskripsiCtrl.text.trim(), ciriVisual: ciriCtrl.text.trim());
                }
                
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                
                if (!mounted) return;
                _load();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isEdit ? 'Berhasil diperbarui' : 'Berhasil ditambahkan'), backgroundColor: AppColors.successColor),
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
    );
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tingkat Kematangan'),
        content: Text('Hapus "${item['label_kematangan']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: AppColors.errorColor))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await sl<AdminRemoteDataSource>().deleteKematangan(item['id'] as int);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil dihapus'), backgroundColor: AppColors.successColor));
      }
    } on ServerException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.errorColor));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(title: const Text('Tingkat Kematangan')),
      drawer: const AdminDrawer(currentRoute: 'kematangan'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorStateWidget(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 320,
                      mainAxisExtent: 180,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final m = _items[index] as Map<String, dynamic>;
                      final label = m['label_kematangan'] as String;
                      final color = AppColors.getKematanganColor(label);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(left: BorderSide(color: color, width: 5)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                  child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                Row(
                                  children: [
                                    IconButton(icon: const Icon(Icons.edit, size: 16, color: AppColors.primaryGreen), onPressed: () => _showForm(item: m)),
                                    IconButton(icon: const Icon(Icons.delete, size: 16, color: AppColors.errorColor), onPressed: () => _delete(m)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              m['deskripsi'] as String? ?? '-',
                              style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ciri: ${m['ciri_visual'] ?? '-'}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textLightGrey, fontStyle: FontStyle.italic),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Text('Total Deteksi: ${m['total_deteksi'] ?? 0}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}