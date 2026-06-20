import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/errors/exceptions.dart';
import '../../../data/datasources/admin_remote_datasource.dart';
import '../../../injection/injection_container.dart';
import '../../widgets/error_state_widget.dart';
import 'admin_drawer.dart';

class AdminPenggunaPage extends StatefulWidget {
  const AdminPenggunaPage({super.key});

  @override
  State<AdminPenggunaPage> createState() => _AdminPenggunaPageState();
}

class _AdminPenggunaPageState extends State<AdminPenggunaPage> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String? _roleFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await sl<AdminRemoteDataSource>().getUsers(
        perPage: 100, search: _search.isEmpty ? null : _search, role: _roleFilter,
      );
      final data = result['data'] as Map<String, dynamic>;
      setState(() {
        _items = data['items'] as List<dynamic>;
        _loading = false;
      });
    } on ServerException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Gagal memuat data pengguna'; _loading = false; });
    }
  }

  Future<void> _toggleRole(Map<String, dynamic> user) async {
    try {
      await sl<AdminRemoteDataSource>().toggleUserRole(user['id'] as int);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role berhasil diubah'), backgroundColor: AppColors.successColor));
      }
    } on ServerException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.errorColor));
      }
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> user) async {
    try {
      await sl<AdminRemoteDataSource>().toggleUserStatus(user['id'] as int);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status berhasil diubah'), backgroundColor: AppColors.successColor));
      }
    } on ServerException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.errorColor));
      }
    }
  }

  int get _totalPengguna => _items.where((u) => u['role'] == 'pengguna').length;
  int get _userAktif => _items.where((u) => u['status_verifikasi'] == 1).length;
  int get _totalAdmin => _items.where((u) => u['role'] == 'admin').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(title: const Text('Kelola Pengguna')),
      drawer: const AdminDrawer(currentRoute: 'pengguna'),
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
                            _statChip('Total Pengguna', '$_totalPengguna', AppColors.primaryGreen),
                            const SizedBox(width: 8),
                            _statChip('User Aktif', '$_userAktif', AppColors.successColor),
                            const SizedBox(width: 8),
                            _statChip('Administrator', '$_totalAdmin', AppColors.setengahColor),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Search + Filter
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Cari nama atau email...',
                                  prefixIcon: Icon(Icons.search),
                                  isDense: true,
                                ),
                                onChanged: (v) => _search = v,
                                onSubmitted: (_) => _load(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String?>(
                              value: _roleFilter,
                              hint: const Text('Semua Role'),
                              items: const [
                                DropdownMenuItem(value: null, child: Text('Semua Role')),
                                DropdownMenuItem(value: 'pengguna', child: Text('Pengguna')),
                                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                              ],
                              onChanged: (v) {
                                setState(() => _roleFilter = v);
                                _load();
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(icon: const Icon(Icons.search), onPressed: _load),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // DataTable
                        Card(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Nama')),
                                DataColumn(label: Text('Email')),
                                DataColumn(label: Text('Role')),
                                DataColumn(label: Text('Total Deteksi')),
                                DataColumn(label: Text('Bergabung')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Aksi')),
                              ],
                              rows: _items.map((item) {
                                final m = item as Map<String, dynamic>;
                                final isAdmin = m['role'] == 'admin';
                                final isActive = m['status_verifikasi'] == 1;
                                String tanggal = '-';
                                if (m['created_at'] != null) {
                                  final date = DateTime.tryParse(m['created_at'] as String);
                                  if (date != null) tanggal = '${date.day}/${date.month}/${date.year}';
                                }

                                return DataRow(cells: [
                                  DataCell(Text(m['nama'] as String, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Text(m['email'] as String, style: const TextStyle(fontSize: 12))),
                                  DataCell(Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isAdmin ? AppColors.setengahColor.withValues(alpha: 0.15) : AppColors.extraLightGreen,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(m['role'] as String, style: TextStyle(fontSize: 11, color: isAdmin ? AppColors.setengahColor : AppColors.primaryGreen)),
                                  )),
                                  DataCell(Text('${m['total_deteksi'] ?? 0}')),
                                  DataCell(Text(tanggal, style: const TextStyle(fontSize: 12))),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(isActive ? Icons.check_circle : Icons.cancel, size: 14, color: isActive ? AppColors.successColor : AppColors.errorColor),
                                      const SizedBox(width: 4),
                                      Text(isActive ? 'Aktif' : 'Nonaktif', style: TextStyle(fontSize: 11, color: isActive ? AppColors.successColor : AppColors.errorColor)),
                                    ],
                                  )),
                                  DataCell(Row(
                                    children: [
                                      TextButton(
                                        onPressed: () => _toggleRole(m),
                                        child: Text('Toggle Role', style: TextStyle(fontSize: 11, color: AppColors.primaryGreen)),
                                      ),
                                      Switch(
                                        value: isActive,
                                        activeThumbColor: AppColors.successColor,
                                        onChanged: (_) => _toggleStatus(m),
                                      ),
                                    ],
                                  )),
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

  Widget _statChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}