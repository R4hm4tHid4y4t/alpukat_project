import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'injection/injection_container.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const AlpukatApp());
}

class AlpukatApp extends StatelessWidget {
  const AlpukatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
      child: Builder(
        builder: (context) {
          final authBloc = context.read<AuthBloc>();
          final router = createRouter(authBloc);
          return MaterialApp.router(
            title: 'Alpukat CNN',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
