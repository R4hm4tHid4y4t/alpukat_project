import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/exceptions.dart';
import '../../../data/datasources/deteksi_remote_datasource.dart';
import '../../../data/models/statistik_model.dart';

abstract class StatistikState {
  const StatistikState();
}

class StatistikInitial extends StatistikState {
  const StatistikInitial();
}

class StatistikLoading extends StatistikState {
  const StatistikLoading();
}

class StatistikLoaded extends StatistikState {
  final StatistikModel data;
  const StatistikLoaded(this.data);
}

class StatistikError extends StatistikState {
  final String message;
  const StatistikError(this.message);
}

/// Cubit sederhana untuk mengambil data statistik user.
/// Digunakan di Dashboard dan Riwayat page.
class StatistikCubit extends Cubit<StatistikState> {
  final DeteksiRemoteDataSource _remote;

  StatistikCubit(this._remote) : super(const StatistikInitial());

  Future<void> load() async {
    emit(const StatistikLoading());
    try {
      final result = await _remote.getStatistik();
      final data = StatistikModel.fromJson(result['data'] as Map<String, dynamic>);
      emit(StatistikLoaded(data));
    } on ServerException catch (e) {
      emit(StatistikError(e.message));
    } catch (e) {
      emit(const StatistikError('Gagal memuat statistik'));
    }
  }
}
