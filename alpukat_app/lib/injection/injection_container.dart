import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../core/network/dio_client.dart';
import '../data/datasources/auth_local_datasource.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../data/datasources/deteksi_remote_datasource.dart';
import '../data/datasources/profil_remote_datasource.dart';
import '../data/datasources/admin_remote_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/register_usecase.dart';
import '../domain/usecases/verify_otp_usecase.dart';
import '../domain/usecases/logout_usecase.dart';
import '../domain/usecases/get_current_user_usecase.dart';
import '../domain/usecases/forgot_password_usecase.dart';
import '../domain/usecases/reset_password_usecase.dart';
import '../presentation/blocs/auth/auth_bloc.dart';
import '../presentation/blocs/deteksi/deteksi_bloc.dart';
import '../presentation/blocs/riwayat/riwayat_bloc.dart';
import '../presentation/blocs/statistik/statistik_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ── Core ──────────────────────────────────────────────
  sl.registerLazySingleton<DioClient>(() => DioClient.instance);
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // ── Data Sources ──────────────────────────────────────
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSource(sl<FlutterSecureStorage>()),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton<DeteksiRemoteDataSource>(
    () => DeteksiRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton<ProfilRemoteDataSource>(
    () => ProfilRemoteDataSource(sl<DioClient>()),
  );
  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => AdminRemoteDataSource(sl<DioClient>()),
  );

  // ── Repositories ──────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      sl<AuthRemoteDataSource>(),
      sl<AuthLocalDataSource>(),
    ),
  );

  // ── Use Cases ─────────────────────────────────────────
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl<AuthRepository>()));

  // ── BLoC / Cubit ──────────────────────────────────────
  sl.registerFactory(() => AuthBloc(
        login: sl<LoginUseCase>(),
        register: sl<RegisterUseCase>(),
        verifyOtp: sl<VerifyOtpUseCase>(),
        logout: sl<LogoutUseCase>(),
        getCurrentUser: sl<GetCurrentUserUseCase>(),
        forgotPassword: sl<ForgotPasswordUseCase>(),
        resetPassword: sl<ResetPasswordUseCase>(),
      ));

  sl.registerFactory(() => DeteksiBloc(sl<DeteksiRemoteDataSource>()));
  sl.registerFactory(() => RiwayatBloc(sl<DeteksiRemoteDataSource>()));
  sl.registerFactory(() => StatistikCubit(sl<DeteksiRemoteDataSource>()));
}
