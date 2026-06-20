class VarietasModel {
  final int? id;
  final String nama;
  final String? deskripsi;

  const VarietasModel({this.id, required this.nama, this.deskripsi});

  factory VarietasModel.fromJson(Map<String, dynamic> json) => VarietasModel(
        id: json['id'] as int?,
        nama: json['nama'] as String,
        deskripsi: json['deskripsi'] as String?,
      );

  Map<String, dynamic> toJson() => {'id': id, 'nama': nama, 'deskripsi': deskripsi};
}

class KematanganModel {
  final int? id;
  final String label;
  final String? deskripsi;
  final String? ciriVisual;
  final String? rekomendasi;

  const KematanganModel({
    this.id,
    required this.label,
    this.deskripsi,
    this.ciriVisual,
    this.rekomendasi,
  });

  factory KematanganModel.fromJson(Map<String, dynamic> json) => KematanganModel(
        id: json['id'] as int?,
        label: json['label'] as String,
        deskripsi: json['deskripsi'] as String?,
        ciriVisual: json['ciri_visual'] as String?,
        rekomendasi: json['rekomendasi'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'deskripsi': deskripsi,
        'ciri_visual': ciriVisual,
        'rekomendasi': rekomendasi,
      };
}

class HasilDeteksiModel {
  final int id;
  final VarietasModel varietas;
  final KematanganModel kematangan;
  final double confidenceVarietas;
  final double confidenceKematangan;
  final Map<String, dynamic>? allProbsVarietas;
  final Map<String, dynamic>? allProbsKematangan;
  final String statusFlag;
  final String? gambarUrl;
  final String? modelVersi;
  final double? inferenceTimeMs;
  final String? createdAt;

  const HasilDeteksiModel({
    required this.id,
    required this.varietas,
    required this.kematangan,
    required this.confidenceVarietas,
    required this.confidenceKematangan,
    this.allProbsVarietas,
    this.allProbsKematangan,
    required this.statusFlag,
    this.gambarUrl,
    this.modelVersi,
    this.inferenceTimeMs,
    this.createdAt,
  });

  bool get perluDitinjau => statusFlag == 'perlu_ditinjau';

  factory HasilDeteksiModel.fromJson(Map<String, dynamic> json) => HasilDeteksiModel(
        id: json['id'] as int,
        varietas: VarietasModel.fromJson(json['varietas'] as Map<String, dynamic>),
        kematangan: KematanganModel.fromJson(json['kematangan'] as Map<String, dynamic>),
        confidenceVarietas: (json['confidence_varietas'] as num).toDouble(),
        confidenceKematangan: (json['confidence_kematangan'] as num).toDouble(),
        allProbsVarietas: json['all_probs_varietas'] as Map<String, dynamic>?,
        allProbsKematangan: json['all_probs_kematangan'] as Map<String, dynamic>?,
        statusFlag: json['status_flag'] as String,
        gambarUrl: json['gambar_url'] as String?,
        modelVersi: json['model_versi'] as String?,
        inferenceTimeMs: (json['inference_time_ms'] as num?)?.toDouble(),
        createdAt: json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'varietas': varietas.toJson(),
        'kematangan': kematangan.toJson(),
        'confidence_varietas': confidenceVarietas,
        'confidence_kematangan': confidenceKematangan,
        'all_probs_varietas': allProbsVarietas,
        'all_probs_kematangan': allProbsKematangan,
        'status_flag': statusFlag,
        'gambar_url': gambarUrl,
        'model_versi': modelVersi,
        'inference_time_ms': inferenceTimeMs,
        'created_at': createdAt,
      };
}
