import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class AdminDrawer extends StatelessWidget {
  final String currentRoute;
  const AdminDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final nama = authState is AuthAuthenticated ? authState.user.nama : 'Admin';
    final email = authState is AuthAuthenticated ? authState.user.email : '-';

    return Drawer(
      backgroundColor: const Color(0xFF1A2E1A),
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2D5A27), Color(0xFF1A3A15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🥑', style: TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Alpukat CNN',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Panel Admin', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),

          // ── Menu Items ─────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              children: [
                _sectionLabel('NAVIGASI'),
                _menuItem(context, 'dashboard', Icons.dashboard_rounded, 'Dashboard', '/admin/dashboard'),
                _menuItem(context, 'varietas', Icons.eco_rounded, 'Varietas', '/admin/varietas'),
                _menuItem(context, 'kematangan', Icons.water_drop_rounded, 'Tingkat Kematangan', '/admin/kematangan'),
                const SizedBox(height: 8),
                _sectionLabel('MANAJEMEN'),
                _menuItem(context, 'pengguna', Icons.people_rounded, 'Kelola Pengguna', '/admin/pengguna'),
                _menuItem(context, 'riwayat', Icons.history_rounded, 'Riwayat Deteksi', '/admin/riwayat'),
                const SizedBox(height: 8),
                _sectionLabel('SISTEM'),
                _menuItem(context, 'model', Icons.smart_toy_rounded, 'Model CNN', '/admin/model'),
              ],
            ),
          ),

          // ── Footer / User Info ─────────────────────────
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white70, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nama, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(email, style: const TextStyle(color: Colors.white38, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white38, size: 18),
                  tooltip: 'Logout',
                  onPressed: () => _confirmLogout(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Text(label, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
    );
  }

  Widget _menuItem(BuildContext context, String key, IconData icon, String label, String route) {
    final isActive = currentRoute == key;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (!isActive) context.go(route);
            if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryGreen.withValues(alpha: 0.25) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive ? Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.4), width: 1) : null,
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: isActive ? AppColors.primaryGreen : Colors.white38),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isActive ? Colors.white : Colors.white60,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorColor),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}