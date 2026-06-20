import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/errors/exceptions.dart';
import '../../../data/datasources/admin_remote_datasource.dart';
import '../../../injection/injection_container.dart';
import '../../widgets/error_state_widget.dart';
import 'admin_drawer.dart';

class AdminVarietasPage extends StatefulWidget {
  const AdminVarietasPage({super.key});

  @override
  State<AdminVarietasPage> createState() => _AdminVarietasPageState();
}

class _AdminVarietasPageState extends State<AdminVarietasPage> {
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
      final result = await sl<AdminRemoteDataSource>().getVarietas();
      setState(() {
        _items = result['data'] as List<dynamic>;
        _loading = false;
      });
    } on ServerException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Gagal memuat data varietas'; _loading = false; });
    }
  }

  void _showForm({Map<String, dynamic>? item}) {
    final namaCtrl = TextEditingController(text: item?['nama_varietas'] as String? ?? '');
    final deskripsiCtrl = TextEditingController(text: item?['deskripsi'] as String? ?? '');
    final isEdit = item != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Varietas' : 'Tambah Varietas'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: 'Nama Varietas')),
              const SizedBox(height: 12),
              TextField(controller: deskripsiCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Deskripsi')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (namaCtrl.text.trim().isEmpty) return;
              try {
                final remote = sl<AdminRemoteDataSource>();
                if (isEdit) {
                  await remote.updateVarietas(item['id'] as int, nama: namaCtrl.text.trim(), deskripsi: deskripsiCtrl.text.trim());
                } else {
                  await remote.createVarietas(nama: namaCtrl.text.trim(), deskripsi: deskripsiCtrl.text.trim());
                }
                
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                
                if (!mounted) return;
                _load();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isEdit ? 'Varietas diperbarui' : 'Varietas ditambahkan'), backgroundColor: AppColors.successColor),
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
        title: const Text('Hapus Varietas'),
        content: Text('Hapus "${item['nama_varietas']}"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: AppColors.errorColor))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await sl<AdminRemoteDataSource>().deleteVarietas(item['id'] as int);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Varietas dihapus'), backgroundColor: AppColors.successColor));
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
      appBar: AppBar(title: const Text('Kelola Varietas')),
      drawer: const AdminDrawer(currentRoute: 'varietas'),
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
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Nama Varietas')),
                            DataColumn(label: Text('Deskripsi')),
                            DataColumn(label: Text('Total Deteksi')),
                            DataColumn(label: Text('Aksi')),
                          ],
                          rows: _items.map((item) {
                            final m = item as Map<String, dynamic>;
                            final deskripsi = (m['deskripsi'] as String? ?? '');
                            return DataRow(cells: [
                              DataCell(Text('${m['id']}')),
                              DataCell(Text(m['nama_varietas'] as String, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(SizedBox(
                                width: 250,
                                child: Text(
                                  deskripsi.length > 60 ? '${deskripsi.substring(0, 60)}...' : deskripsi,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              )),
                              DataCell(Text('${m['total_deteksi'] ?? 0}')),
                              DataCell(Row(
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, size: 18, color: AppColors.primaryGreen), onPressed: () => _showForm(item: m)),
                                  IconButton(icon: const Icon(Icons.delete, size: 18, color: AppColors.errorColor), onPressed: () => _delete(m)),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}