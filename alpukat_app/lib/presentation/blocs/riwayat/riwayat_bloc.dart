import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/exceptions.dart';
import '../../../data/datasources/deteksi_remote_datasource.dart';
import '../../../data/models/riwayat_model.dart';
import 'riwayat_event.dart';
import 'riwayat_state.dart';

const int _perPage = 10;

class RiwayatBloc extends Bloc<RiwayatEvent, RiwayatState> {
  final DeteksiRemoteDataSource _remote;

  RiwayatBloc(this._remote) : super(const RiwayatInitial()) {
    on<LoadRiwayat>(_onLoaded);
    on<RiwayatLoadMore>(_onLoadMore);
    on<FilterChanged>(_onFilterChanged);
    on<RiwayatDeleted>(_onDeleted);
  }

  Future<void> _fetchPage(
    Emitter<RiwayatState> emit, {
    required int page,
    int? varietasId,
    List<RiwayatModel> existing = const [],
  }) async {
    try {
      final result = await _remote.getRiwayat(
        page: page,
        perPage: _perPage,
        varietasId: varietasId,
      );

      final data = result['data'] as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>)
          .map((e) => RiwayatModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final meta = PaginationMeta.fromJson(data['meta'] as Map<String, dynamic>);

      final allItems = [...existing, ...items];

      if (allItems.isEmpty) {
        emit(const RiwayatEmpty());
        return;
      }

      emit(RiwayatLoaded(
        items: allItems,
        hasMore: meta.hasMore,
        currentPage: meta.page,
        selectedVarietasId: varietasId,
      ));
    } on ServerException catch (e) {
      emit(RiwayatError(e.message));
    } catch (e) {
      emit(const RiwayatError('Gagal memuat riwayat. Silakan coba lagi.'));
    }
  }

  Future<void> _onLoaded(LoadRiwayat event, Emitter<RiwayatState> emit) async {
    emit(const RiwayatLoading());
    int? varietasId;
    if (state is RiwayatLoaded) {
      varietasId = (state as RiwayatLoaded).selectedVarietasId;
    }
    await _fetchPage(emit, page: 1, varietasId: varietasId);
  }

  Future<void> _onLoadMore(RiwayatLoadMore event, Emitter<RiwayatState> emit) async {
    final currentState = state;
    if (currentState is! RiwayatLoaded || !currentState.hasMore) return;

    emit(RiwayatLoadingMore(
      items: currentState.items,
      selectedVarietasId: currentState.selectedVarietasId,
    ));

    await _fetchPage(
      emit,
      page: currentState.currentPage + 1,
      varietasId: currentState.selectedVarietasId,
      existing: currentState.items,
    );
  }

  Future<void> _onFilterChanged(FilterChanged event, Emitter<RiwayatState> emit) async {
    emit(const RiwayatLoading());
    await _fetchPage(emit, page: 1, varietasId: event.varietasId);
  }

  Future<void> _onDeleted(RiwayatDeleted event, Emitter<RiwayatState> emit) async {
    final currentState = state;
    if (currentState is! RiwayatLoaded) return;

    try {
      await _remote.deleteRiwayat(event.id);
      final updatedItems = currentState.items.where((item) => item.id != event.id).toList();

      if (updatedItems.isEmpty) {
        emit(const RiwayatEmpty());
      } else {
        emit(currentState.copyWith(items: updatedItems));
      }
    } on ServerException catch (e) {
      emit(RiwayatError(e.message));
    }
  }
}