import 'package:equatable/equatable.dart';
import '../../../data/models/riwayat_model.dart';

abstract class RiwayatState extends Equatable {
  const RiwayatState();
  @override
  List<Object?> get props => [];
}

class RiwayatInitial extends RiwayatState {
  const RiwayatInitial();
}

class RiwayatLoading extends RiwayatState {
  const RiwayatLoading();
}

class RiwayatLoaded extends RiwayatState {
  final List<RiwayatModel> items;
  final bool hasMore;
  final int currentPage;
  final int? selectedVarietasId;

  const RiwayatLoaded({
    required this.items,
    required this.hasMore,
    required this.currentPage,
    this.selectedVarietasId,
  });

  RiwayatLoaded copyWith({
    List<RiwayatModel>? items,
    bool? hasMore,
    int? currentPage,
    int? selectedVarietasId,
    bool clearFilter = false,
  }) =>
      RiwayatLoaded(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        currentPage: currentPage ?? this.currentPage,
        selectedVarietasId: clearFilter ? null : (selectedVarietasId ?? this.selectedVarietasId),
      );

  @override
  List<Object?> get props => [items, hasMore, currentPage, selectedVarietasId];
}

class RiwayatLoadingMore extends RiwayatState {
  final List<RiwayatModel> items;
  final int? selectedVarietasId;
  const RiwayatLoadingMore({required this.items, this.selectedVarietasId});
  @override
  List<Object?> get props => [items];
}

class RiwayatEmpty extends RiwayatState {
  const RiwayatEmpty();
}

class RiwayatError extends RiwayatState {
  final String message;
  const RiwayatError(this.message);
  @override
  List<Object?> get props => [message];
}
