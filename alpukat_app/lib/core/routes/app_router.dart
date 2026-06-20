import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/auth/auth_state.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/auth/onboarding_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/auth/otp_verification_page.dart';
import '../../presentation/pages/auth/forgot_password_page.dart';
import '../../presentation/pages/auth/reset_password_page.dart';
import '../../presentation/pages/home/dashboard_page.dart';
import '../../presentation/pages/deteksi/deteksi_page.dart';
import '../../presentation/pages/deteksi/hasil_deteksi_page.dart';
import '../../presentation/pages/riwayat/riwayat_page.dart';
import '../../presentation/pages/riwayat/detail_riwayat_page.dart';
import '../../presentation/pages/profil/profil_page.dart';
import '../../presentation/pages/profil/ganti_password_page.dart';
import '../../presentation/pages/admin/admin_dashboard_page.dart';
import '../../presentation/pages/admin/admin_varietas_page.dart';
import '../../presentation/pages/admin/admin_kematangan_page.dart';
import '../../presentation/pages/admin/admin_pengguna_page.dart';
import '../../presentation/pages/admin/admin_model_page.dart';
import '../../presentation/pages/admin/admin_riwayat_page.dart';
import '../../presentation/widgets/main_navigation.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),

    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuth = authState is AuthAuthenticated;
      final isAdmin = isAuth && authState.user.isAdmin;
      final isOnAuthPage = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/splash') ||
          state.matchedLocation.startsWith('/onboarding') ||
          state.matchedLocation.startsWith('/verify-otp') ||
          state.matchedLocation.startsWith('/forgot-password') ||
          state.matchedLocation.startsWith('/reset-password');
      final isOnAdminPage = state.matchedLocation.startsWith('/admin');

      if (!isAuth && !isOnAuthPage) return '/login';

      // Admin login → langsung ke panel admin
      if (isAuth && isAdmin && (state.matchedLocation == '/login' || state.matchedLocation == '/register')) {
        return '/admin/dashboard';
      }
      // User biasa login → ke dashboard mobile
      if (isAuth && !isAdmin && (state.matchedLocation == '/login' || state.matchedLocation == '/register')) {
        return '/home/dashboard';
      }
      // Cegah user biasa mengakses panel admin
      if (isAuth && !isAdmin && isOnAdminPage) return '/home/dashboard';

      return null;
    },

    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(
        path: '/verify-otp',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OtpVerificationPage(
            userId: extra['user_id'] as int,
            email: extra['email'] as String,
          );
        },
      ),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordPage()),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ResetPasswordPage(email: extra['email'] as String? ?? '');
        },
      ),

      // Admin Web Routes — menggunakan Drawer, bukan BottomNav
      GoRoute(path: '/admin/dashboard', builder: (_, __) => const AdminDashboardPage()),
      GoRoute(path: '/admin/varietas', builder: (_, __) => const AdminVarietasPage()),
      GoRoute(path: '/admin/kematangan', builder: (_, __) => const AdminKematanganPage()),
      GoRoute(path: '/admin/pengguna', builder: (_, __) => const AdminPenggunaPage()),
      GoRoute(path: '/admin/model', builder: (_, __) => const AdminModelPage()),
      GoRoute(path: '/admin/riwayat', builder: (_, __) => const AdminRiwayatPage()),

      // Shell route — Home dengan BottomNavigationBar
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => MainNavigation(child: child),
        routes: [
          GoRoute(
            path: '/home/dashboard',
            builder: (_, __) => const DashboardPage(),
          ),
          GoRoute(
            path: '/home/deteksi',
            builder: (_, __) => const DeteksiPage(),
            routes: [
              GoRoute(
                path: 'hasil',
                builder: (_, state) => HasilDeteksiPage(
                  hasil: state.extra as Map<String, dynamic>,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/home/riwayat',
            builder: (_, __) => const RiwayatPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => DetailRiwayatPage(
                  id: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/home/profil',
            builder: (_, __) => const ProfilPage(),
            routes: [
              GoRoute(
                path: 'ganti-password',
                builder: (_, __) => const GantiPasswordPage(),
              ),
            ],
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Halaman tidak ditemukan: ${state.error}')),
    ),
  );
}

/// Helper untuk refresh router saat AuthBloc state berubah
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream stream) {
    stream.listen((_) => notifyListeners());
  }
}
