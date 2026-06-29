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
    } catch (_) {
      setState(() { _error = 'Tidak dapat terhubung ke server'; _loading = false; });
    }
  }

  Future<void> _toggleRole(Map<String, dynamic> user) async {
    try {
      await sl<AdminRemoteDataSource>().toggleUserRole(user['id'] as int);
      _load();
      if (mounted) _showSnackbar('Role berhasil diubah', success: true);
    } on ServerException catch (e) {
      if (mounted) _showSnackbar(e.message, success: false);
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> user) async {
    try {
      await sl<AdminRemoteDataSource>().toggleUserStatus(user['id'] as int);
      _load();
      if (mounted) _showSnackbar('Status berhasil diubah', success: true);
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

  int get _totalPengguna => _items.where((u) => u['role'] == 'pengguna').length;
  int get _userAktif => _items.where((u) => u['status_verifikasi'] == 1).length;
  int get _totalAdmin => _items.where((u) => u['role'] == 'admin').length;

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
        title: const Text('Kelola Pengguna', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryGreen), onPressed: _load, tooltip: 'Refresh'),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AdminDrawer(currentRoute: 'pengguna'),
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
                        // ── Stat Cards ─────────────────────────
                        isWide
                            ? Row(children: [
                                _buildStatCard('Total Pengguna', '$_totalPengguna', Icons.people_rounded, const Color(0xFF2D5A27), const Color(0xFFE8F5E3)),
                                const SizedBox(width: 12),
                                _buildStatCard('User Aktif', '$_userAktif', Icons.verified_rounded, const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
                                const SizedBox(width: 12),
                                _buildStatCard('Administrator', '$_totalAdmin', Icons.admin_panel_settings_rounded, const Color(0xFF6A1B9A), const Color(0xFFF3E5F5)),
                              ])
                            : Column(children: [
                                _buildStatCard('Total Pengguna', '$_totalPengguna', Icons.people_rounded, const Color(0xFF2D5A27), const Color(0xFFE8F5E3)),
                                const SizedBox(height: 8),
                                _buildStatCard('User Aktif', '$_userAktif', Icons.verified_rounded, const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
                                const SizedBox(height: 8),
                                _buildStatCard('Administrator', '$_totalAdmin', Icons.admin_panel_settings_rounded, const Color(0xFF6A1B9A), const Color(0xFFF3E5F5)),
                              ]),
                        const SizedBox(height: 20),

                        // ── Search + Filter ─────────────────────
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
                                  _buildRoleDropdown(),
                                  const SizedBox(width: 12),
                                  _buildSearchButton(),
                                ])
                              : Column(children: [
                                  _buildSearchField(),
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    Expanded(child: _buildRoleDropdown()),
                                    const SizedBox(width: 10),
                                    _buildSearchButton(),
                                  ]),
                                ]),
                        ),
                        const SizedBox(height: 20),

                        // ── User List ───────────────────────────
                        if (_items.isEmpty)
                          _buildEmptyState()
                        else
                          isWide
                              ? _buildUserTable()
                              : _buildUserCards(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchCtrl,
      decoration: InputDecoration(
        hintText: 'Cari nama atau email...',
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

  Widget _buildRoleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E8E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _roleFilter,
          hint: const Text('Semua Role', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
          isDense: true,
          items: const [
            DropdownMenuItem(value: null, child: Text('Semua Role', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'pengguna', child: Text('Pengguna', style: TextStyle(fontSize: 13))),
            DropdownMenuItem(value: 'admin', child: Text('Admin', style: TextStyle(fontSize: 13))),
          ],
          onChanged: (v) {
            setState(() => _roleFilter = v);
            _load();
          },
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return ElevatedButton(
      onPressed: _load,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: const Text('Cari', style: TextStyle(fontSize: 13)),
    );
  }

  Widget _buildUserTable() {
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
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 64,
                  columnSpacing: 20,
                  horizontalMargin: 20,
                  columns: const [
                    DataColumn(label: Expanded(child: Text('PENGGUNA'))),
                    DataColumn(label: Text('ROLE')),
                    DataColumn(label: Text('DETEKSI')),
                    DataColumn(label: Text('BERGABUNG')),
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
    final isAdmin = m['role'] == 'admin';
    final isActive = m['status_verifikasi'] == 1;
    String tanggal = '-';
    if (m['created_at'] != null) {
      final date = DateTime.tryParse(m['created_at'] as String);
      if (date != null) tanggal = '${date.day}/${date.month}/${date.year}';
    }

    return DataRow(cells: [
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isAdmin ? const Color(0xFFF3E5F5) : AppColors.extraLightGreen,
            child: Text(
              (m['nama'] as String? ?? 'U').substring(0, 1).toUpperCase(),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isAdmin ? const Color(0xFF6A1B9A) : AppColors.primaryGreen),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(m['nama'] as String? ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(m['email'] as String? ?? '-', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
            ],
          ),
        ],
      )),
      DataCell(_buildRoleBadge(m['role'] as String, isAdmin)),
      DataCell(Text('${m['total_deteksi'] ?? 0}', style: const TextStyle(fontSize: 13))),
      DataCell(Text(tanggal, style: const TextStyle(fontSize: 12, color: AppColors.textGrey))),
      DataCell(_buildStatusBadge(isActive)),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionChip('Ubah Role', isAdmin ? const Color(0xFF6A1B9A) : AppColors.primaryGreen, () => _toggleRole(m)),
          const SizedBox(width: 8),
          Switch(
            value: isActive,
            activeThumbColor: AppColors.successColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (_) => _toggleStatus(m),
          ),
        ],
      )),
    ]);
  }

  Widget _buildRoleBadge(String role, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFF3E5F5) : AppColors.extraLightGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(role, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isAdmin ? const Color(0xFF6A1B9A) : AppColors.primaryGreen)),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F5E3) : const Color(0xFFFBE9E7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? AppColors.successColor : AppColors.errorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Aktif' : 'Nonaktif',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? AppColors.successColor : AppColors.errorColor),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildUserCards() {
    return Column(
      children: _items.map((item) {
        final m = item as Map<String, dynamic>;
        final isAdmin = m['role'] == 'admin';
        final isActive = m['status_verifikasi'] == 1;
        String tanggal = '-';
        if (m['created_at'] != null) {
          final date = DateTime.tryParse(m['created_at'] as String);
          if (date != null) tanggal = '${date.day}/${date.month}/${date.year}';
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isAdmin ? const Color(0xFFF3E5F5) : AppColors.extraLightGreen,
                    child: Text(
                      (m['nama'] as String? ?? 'U').substring(0, 1).toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: isAdmin ? const Color(0xFF6A1B9A) : AppColors.primaryGreen),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['nama'] as String? ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(m['email'] as String? ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                      ],
                    ),
                  ),
                  _buildRoleBadge(m['role'] as String, isAdmin),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _infoChip(Icons.analytics_rounded, '${m['total_deteksi'] ?? 0} deteksi'),
                  const SizedBox(width: 8),
                  _infoChip(Icons.calendar_today_rounded, tanggal),
                  const Spacer(),
                  _buildStatusBadge(isActive),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildActionChip('Ubah Role', isAdmin ? const Color(0xFF6A1B9A) : AppColors.primaryGreen, () => _toggleRole(m))),
                  const SizedBox(width: 10),
                  Text(isActive ? 'Aktif' : 'Nonaktif', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                  Switch(value: isActive, activeThumbColor: AppColors.successColor, onChanged: (_) => _toggleStatus(m)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textGrey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
      ],
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
              child: const Icon(Icons.people_rounded, size: 48, color: AppColors.primaryGreen),
            ),
            const SizedBox(height: 16),
            const Text('Tidak ada pengguna ditemukan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Coba ubah filter pencarian', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}