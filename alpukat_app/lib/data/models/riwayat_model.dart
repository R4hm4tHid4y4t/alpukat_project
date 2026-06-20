class RiwayatModel {
  final int id;
  final String? varietasNama;
  final String? kematanganLabel;
  final double? confidenceVarietas;
  final double? confidenceKematangan;
  final String? gambarUrl;
  final String statusFlag;
  final String? createdAt;

  const RiwayatModel({
    required this.id,
    this.varietasNama,
    this.kematanganLabel,
    this.confidenceVarietas,
    this.confidenceKematangan,
    this.gambarUrl,
    required this.statusFlag,
    this.createdAt,
  });

  factory RiwayatModel.fromJson(Map<String, dynamic> json) => RiwayatModel(
        id: json['id'] as int,
        varietasNama: json['varietas_nama'] as String?,
        kematanganLabel: json['kematangan_label'] as String?,
        confidenceVarietas: (json['confidence_varietas'] as num?)?.toDouble(),
        confidenceKematangan: (json['confidence_kematangan'] as num?)?.toDouble(),
        gambarUrl: json['gambar_url'] as String?,
        statusFlag: json['status_flag'] as String? ?? 'normal',
        createdAt: json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'varietas_nama': varietasNama,
        'kematangan_label': kematanganLabel,
        'confidence_varietas': confidenceVarietas,
        'confidence_kematangan': confidenceKematangan,
        'gambar_url': gambarUrl,
        'status_flag': statusFlag,
        'created_at': createdAt,
      };
}

class PaginationMeta {
  final int total;
  final int page;
  final int perPage;
  final int lastPage;

  const PaginationMeta({
    required this.total,
    required this.page,
    required this.perPage,
    required this.lastPage,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) => PaginationMeta(
        total: json['total'] as int,
        page: json['page'] as int,
        perPage: json['per_page'] as int,
        lastPage: json['last_page'] as int,
      );

  bool get hasMore => page < lastPage;
}
