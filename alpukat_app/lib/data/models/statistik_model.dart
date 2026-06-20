class DistribusiItemModel {
  final String nama;
  final int jumlah;
  final double persentase;

  const DistribusiItemModel({
    required this.nama,
    required this.jumlah,
    required this.persentase,
  });

  factory DistribusiItemModel.fromJson(Map<String, dynamic> json) => DistribusiItemModel(
        nama: (json['nama'] ?? json['label']) as String,
        jumlah: json['jumlah'] as int,
        persentase: (json['persentase'] as num).toDouble(),
      );
}

class StatistikModel {
  final int totalDeteksi;
  final int deteksiBulanIni;
  final double? rataRataConfidence;
  final String? varietasTerbanyak;
  final List<DistribusiItemModel> distribusiVarietas;
  final List<DistribusiItemModel> distribusiKematangan;

  const StatistikModel({
    required this.totalDeteksi,
    required this.deteksiBulanIni,
    this.rataRataConfidence,
    this.varietasTerbanyak,
    this.distribusiVarietas = const [],
    this.distribusiKematangan = const [],
  });

  factory StatistikModel.fromJson(Map<String, dynamic> json) => StatistikModel(
        totalDeteksi: json['total_deteksi'] as int,
        deteksiBulanIni: json['deteksi_bulan_ini'] as int,
        rataRataConfidence: (json['rata_rata_confidence'] as num?)?.toDouble(),
        varietasTerbanyak: json['varietas_terbanyak'] as String?,
        distribusiVarietas: (json['distribusi_varietas'] as List<dynamic>?)
                ?.map((e) => DistribusiItemModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        distribusiKematangan: (json['distribusi_kematangan'] as List<dynamic>?)
                ?.map((e) => DistribusiItemModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
