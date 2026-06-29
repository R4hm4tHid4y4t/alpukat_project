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
    } catch (_) {
      setState(() { _error = 'Tidak dapat terhubung ke server'; _loading = false; });
    }
  }

  void _showForm({Map<String, dynamic>? item}) {
    final labelCtrl = TextEditingController(text: item?['label_kematangan'] as String? ?? '');
    final deskripsiCtrl = TextEditingController(text: item?['deskripsi'] as String? ?? '');
    final ciriCtrl = TextEditingController(text: item?['ciri_visual'] as String? ?? '');
    final isEdit = item != null;

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.water_drop_rounded, color: Color(0xFF1565C0), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(isEdit ? 'Edit Tingkat Kematangan' : 'Tambah Tingkat Kematangan',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
                ],
              ),
              const SizedBox(height: 20),
              _buildInputField('Nama Tingkat', labelCtrl, hint: 'cth: Matang, Mentah'),
              const SizedBox(height: 14),
              _buildInputField('Deskripsi', deskripsiCtrl, hint: 'Deskripsi tingkat kematangan...', maxLines: 3),
              const SizedBox(height: 14),
              _buildInputField('Ciri Visual', ciriCtrl, hint: 'Ciri-ciri visual yang terlihat...', maxLines: 3),
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
                        if (labelCtrl.text.trim().isEmpty) return;
                        try {
                          final remote = sl<AdminRemoteDataSource>();
                          if (isEdit) {
                            await remote.updateKematangan(item['id'] as int,
                                label: labelCtrl.text.trim(),
                                deskripsi: deskripsiCtrl.text.trim(),
                                ciriVisual: ciriCtrl.text.trim());
                          } else {
                            await remote.createKematangan(
                                label: labelCtrl.text.trim(),
                                deskripsi: deskripsiCtrl.text.trim(),
                                ciriVisual: ciriCtrl.text.trim());
                          }
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          _load();
                          _showSnackbar(isEdit ? 'Berhasil diperbarui' : 'Berhasil ditambahkan', success: true);
                        } on ServerException catch (e) {
                          if (mounted) _showSnackbar(e.message, success: false);
                        }
                      },
                      child: Text(isEdit ? 'Perbarui' : 'Simpan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_rounded, color: AppColors.errorColor, size: 22),
          SizedBox(width: 8),
          Text('Hapus Tingkat Kematangan', style: TextStyle(fontSize: 15)),
        ]),
        content: Text('Hapus "${item['label_kematangan']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorColor, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await sl<AdminRemoteDataSource>().deleteKematangan(item['id'] as int);
      _load();
      if (mounted) _showSnackbar('Berhasil dihapus', success: true);
    } on ServerException catch (e) {
      if (mounted) _showSnackbar(e.message, success: false);
    }
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

  Widget _buildInputField(String label, TextEditingController ctrl, {String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A2E1A))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textLightGrey, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF8FAF8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E8E0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E8E0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1000 ? 4 : (screenWidth > 700 ? 3 : (screenWidth > 480 ? 2 : 1));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF1A2E1A)),
        title: const Text('Tingkat Kematangan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ],
      ),
      drawer: const AdminDrawer(currentRoute: 'kematangan'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _error != null
              ? ErrorStateWidget(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primaryGreen,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(20),
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.95,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _items.length,
                        itemBuilder: (_, i) => _buildKematanganCard(_items[i] as Map<String, dynamic>),
                      ),
                    ),
    );
  }

  Widget _buildKematanganCard(Map<String, dynamic> m) {
    final label = m['label_kematangan'] as String;
    final deskripsi = m['deskripsi'] as String? ?? '-';
    final ciriVisual = m['ciri_visual'] as String? ?? '-';
    final totalDeteksi = m['total_deteksi'] as int? ?? 0;
    final color = AppColors.getKematanganColor(label);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top accent bar
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label + Actions
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const Spacer(),
                      Material(
                        color: Colors.transparent,
                        child: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (v) {
                            if (v == 'edit') _showForm(item: m);
                            if (v == 'delete') _delete(m);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 16, color: AppColors.primaryGreen), SizedBox(width: 8), Text('Edit')])),
                            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 16, color: AppColors.errorColor), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: AppColors.errorColor))])),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Deskripsi
                  Text(deskripsi,
                      style: const TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.5),
                      maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),

                  // Ciri Visual
                  if (ciriVisual != '-') ...[
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.remove_red_eye_outlined, size: 13, color: color),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(ciriVisual,
                              style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8), fontStyle: FontStyle.italic),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],

                  const Spacer(),

                  // Total deteksi
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.analytics_rounded, size: 13, color: color),
                        const SizedBox(width: 5),
                        Text('$totalDeteksi deteksi', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle),
            child: const Icon(Icons.water_drop_rounded, size: 48, color: Color(0xFF1565C0)),
          ),
          const SizedBox(height: 16),
          const Text('Belum ada tingkat kematangan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tambahkan tingkat kematangan pertama', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showForm(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}