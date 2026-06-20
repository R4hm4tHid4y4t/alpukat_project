import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/errors/exceptions.dart';
import '../../../data/datasources/profil_remote_datasource.dart';
import '../../../injection/injection_container.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/statistik/statistik_cubit.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final _namaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _fotoUrl;
  String? _bergabungSejak;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final remote = sl<ProfilRemoteDataSource>();
      final result = await remote.getProfile();
      final data = result['data'] as Map<String, dynamic>;

      _namaCtrl.text = data['nama'] as String? ?? '';
      _emailCtrl.text = data['email'] as String? ?? '';
      _fotoUrl = data['foto_profil'] as String?;

      final createdAt = data['created_at'] as String?;
      if (createdAt != null) {
        final date = DateTime.parse(createdAt);
        _bergabungSejak = '${_bulan(date.month)} ${date.year}';
      }
    } catch (_) {
      // Gunakan data dari AuthBloc sebagai fallback
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _namaCtrl.text = authState.user.nama;
        _emailCtrl.text = authState.user.email;
        _fotoUrl = authState.user.fotoProfil;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _bulan(int month) {
    const months = ['Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];
    return months[month - 1];
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await sl<ProfilRemoteDataSource>().updateProfile(nama: _namaCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui'), backgroundColor: AppColors.successColor),
        );
      }
    } on ServerException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    try {
      final result = await sl<ProfilRemoteDataSource>().uploadAvatar(File(picked.path));
      final data = result['data'] as Map<String, dynamic>;
      setState(() => _fotoUrl = data['foto_profil_url'] as String?);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui'), backgroundColor: AppColors.successColor),
        );
      }
    } on ServerException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.errorColor),
        );
      }
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<StatistikCubit>()..load()),
      ],
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        appBar: AppBar(title: const Text('Profil Saya')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── Profile Card ────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: AppColors.extraLightGreen,
                                backgroundImage: _fotoUrl != null ? NetworkImage(_fotoUrl!) : null,
                                child: _fotoUrl == null
                                    ? const Icon(Icons.person, size: 50, color: AppColors.primaryGreen)
                                    : null,
                              ),
                              Positioned(
                                right: 0, bottom: 0,
                                child: GestureDetector(
                                  onTap: _changeAvatar,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(_namaCtrl.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(_emailCtrl.text, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.successColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 14, color: AppColors.successColor),
                                SizedBox(width: 4),
                                Text('Aktif', style: TextStyle(fontSize: 12, color: AppColors.successColor, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Form Edit ───────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Informasi Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 12),
                          const Text('Nama Lengkap', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _namaCtrl,
                            decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline)),
                          ),
                          const SizedBox(height: 12),
                          const Text('Email', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _emailCtrl,
                            enabled: false,
                            decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined)),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _saveProfile,
                              child: _saving
                                  ? const SizedBox(
                                      height: 18, width: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text('Simpan Perubahan'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Statistik Penggunaan ────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Statistik Penggunaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 12),
                          BlocBuilder<StatistikCubit, StatistikState>(
                            builder: (context, state) {
                              if (state is StatistikLoaded) {
                                final s = state.data;
                                return GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  childAspectRatio: 2.2,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  children: [
                                    _statTile('Total Deteksi', '${s.totalDeteksi}', Icons.analytics_outlined),
                                    _statTile('Bulan Ini', '${s.deteksiBulanIni}', Icons.calendar_month_outlined),
                                    _statTile('Akurasi', s.rataRataConfidence != null ? '${s.rataRataConfidence!.toStringAsFixed(1)}%' : '-', Icons.percent),
                                    _statTile('Bergabung', _bergabungSejak ?? '-', Icons.event_outlined),
                                  ],
                                );
                              }
                              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Menu Lainnya ─────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.lock_outline, color: AppColors.primaryGreen),
                            title: const Text('Ganti Password'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/home/profil/ganti-password'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.logout, color: AppColors.errorColor),
                            title: const Text('Keluar', style: TextStyle(color: AppColors.errorColor)),
                            onTap: () => _confirmLogout(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            child: const Text('Keluar', style: TextStyle(color: AppColors.errorColor)),
          ),
        ],
      ),
    );
  }
}