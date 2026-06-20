import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

/// Drawer navigasi untuk Panel Admin Web.
/// currentRoute digunakan untuk highlight menu yang aktif.
class AdminDrawer extends StatelessWidget {
  final String currentRoute;
  const AdminDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final nama = authState is AuthAuthenticated ? authState.user.nama : 'Admin';
    final email = authState is AuthAuthenticated ? authState.user.email : '-';

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            color: AppColors.primaryGreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🥑', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                const Text('Panel Admin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Alpukat CNN', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),

          // Menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _menuItem(context, 'dashboard', Icons.dashboard_outlined, 'Dashboard', '/admin/dashboard'),
                _menuItem(context, 'varietas', Icons.eco_outlined, 'Varietas', '/admin/varietas'),
                _menuItem(context, 'kematangan', Icons.water_drop_outlined, 'Tingkat Kematangan', '/admin/kematangan'),
                _menuItem(context, 'pengguna', Icons.people_outline, 'Kelola Pengguna', '/admin/pengguna'),
                _menuItem(context, 'model', Icons.smart_toy_outlined, 'Model CNN', '/admin/model'),
                _menuItem(context, 'riwayat', Icons.history, 'Riwayat Deteksi', '/admin/riwayat'),
              ],
            ),
          ),

          // Footer
          const Divider(height: 1),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.extraLightGreen,
              child: Icon(Icons.person, color: AppColors.primaryGreen),
            ),
            title: Text(nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text(email, style: const TextStyle(fontSize: 11)),
            trailing: IconButton(
              icon: const Icon(Icons.logout, color: AppColors.errorColor, size: 20),
              onPressed: () => context.read<AuthBloc>().add(const LogoutRequested()),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, String key, IconData icon, String label, String route) {
    final isActive = currentRoute == key;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.extraLightGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? AppColors.primaryGreen : AppColors.textGrey, size: 20),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isActive ? AppColors.primaryGreen : AppColors.textDark,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          if (!isActive) context.go(route);
          if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
        },
      ),
    );
  }
}
