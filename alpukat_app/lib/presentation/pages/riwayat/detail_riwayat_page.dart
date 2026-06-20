import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/errors/exceptions.dart';
import '../../../data/datasources/deteksi_remote_datasource.dart';
import '../../../data/models/hasil_deteksi_model.dart';
import '../../../injection/injection_container.dart';
import '../../widgets/confidence_bar.dart';
import '../../widgets/error_state_widget.dart';

class DetailRiwayatPage extends StatefulWidget {
  final int id;
  const DetailRiwayatPage({super.key, required this.id});

  @override
  State<DetailRiwayatPage> createState() => _DetailRiwayatPageState();
}

class _DetailRiwayatPageState extends State<DetailRiwayatPage> {
  HasilDeteksiModel? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final remote = sl<DeteksiRemoteDataSource>();
      final result = await remote.getDetailDeteksi(widget.id);
      final raw = result['data'] as Map<String, dynamic>;

      // Normalisasi struktur response detail ke HasilDeteksiModel
      final normalized = {
        'id': raw['id'],
        'varietas': raw['varietas'],
        'kematangan': {
          ...raw['kematangan'] as Map<String, dynamic>,
          'rekomendasi': _getRekomendasi((raw['kematangan'] as Map)['label'] as String?),
        },
        'confidence_varietas': raw['confidence_varietas'] ?? 0,
        'confidence_kematangan': raw['confidence_kematangan'] ?? 0,
        'status_flag': raw['status_flag'] ?? 'normal',
        'gambar_url': raw['gambar_url'],
        'created_at': raw['created_at'],
      };

      setState(() {
        _data = HasilDeteksiModel.fromJson(normalized);
        _loading = false;
      });
    } on ServerException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat detail riwayat';
        _loading = false;
      });
    }
  }

  String? _getRekomendasi(String? label) {
    switch (label) {
      case 'Mentah':
        return 'Tunggu 5–7 hari sebelum dikonsumsi.';
      case 'Setengah Matang':
        return 'Akan siap dikonsumsi dalam 2–3 hari.';
      case 'Matang':
        return 'Siap dikonsumsi! Segera nikmati.';
      case 'Terlalu Matang':
        return 'Segera konsumsi atau olah menjadi jus/guacamole.';
      default:
        return null;
    }
  }

  Future<void> _deleteRiwayat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: const Text('Apakah Anda yakin ingin menghapus riwayat ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.errorColor)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await sl<DeteksiRemoteDataSource>().deleteRiwayat(widget.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Riwayat berhasil dihapus'), backgroundColor: AppColors.successColor),
        );
        context.pop();
      }
    } on ServerException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.errorColor),
        );
      }
    }
  }

  String _formatTanggal(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day} ${_bulan(date.month)} ${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  String _bulan(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(title: const Text('Detail Riwayat')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorStateWidget(message: _error!, onRetry: _loadDetail);
    }

    final data = _data!;
    final kematanganColor = AppColors.getKematanganColor(data.kematangan.label);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Image
          SizedBox(
            height: 240,
            width: double.infinity,
            child: data.gambarUrl != null
                ? CachedNetworkImage(
                    imageUrl: data.gambarUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.borderColor),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.borderColor,
                      child: const Icon(Icons.image_not_supported, size: 48),
                    ),
                  )
                : Container(
                    color: AppColors.extraLightGreen,
                    child: const Center(child: Text('🥑', style: TextStyle(fontSize: 64))),
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tanggal deteksi
                Center(
                  child: Text(
                    'Dideteksi pada ${_formatTanggal(data.createdAt)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                ),
                const SizedBox(height: 16),

                // Warning banner
                if (data.perluDitinjau) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warningColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warningColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: AppColors.warningColor),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Confidence rendah (di bawah 80%). Hasil mungkin kurang akurat.',
                            style: TextStyle(fontSize: 12, color: AppColors.textDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Card Varietas
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.extraLightGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(left: BorderSide(color: AppColors.primaryGreen, width: 4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.eco, color: AppColors.primaryGreen, size: 18),
                          SizedBox(width: 6),
                          Text('VARIETAS',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen, letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(data.varietas.nama, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      if (data.varietas.deskripsi != null) ...[
                        const SizedBox(height: 4),
                        Text(data.varietas.deskripsi!, style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.5)),
                      ],
                      const SizedBox(height: 12),
                      ConfidenceBar(label: 'Akurasi', value: data.confidenceVarietas),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Card Kematangan
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kematanganColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(left: BorderSide(color: kematanganColor, width: 4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: kematanganColor, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('TINGKAT KEMATANGAN',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kematanganColor, letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(data.kematangan.label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      if (data.kematangan.deskripsi != null) ...[
                        const SizedBox(height: 4),
                        Text(data.kematangan.deskripsi!, style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.5)),
                      ],
                      if (data.kematangan.ciriVisual != null) ...[
                        const SizedBox(height: 6),
                        Text('Ciri visual: ${data.kematangan.ciriVisual}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontStyle: FontStyle.italic)),
                      ],
                      const SizedBox(height: 12),
                      ConfidenceBar(label: 'Akurasi', value: data.confidenceKematangan),
                      if (data.kematangan.rekomendasi != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            data.kematangan.rekomendasi!,
                            style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol hapus
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _deleteRiwayat,
                    icon: const Icon(Icons.delete_outline, color: AppColors.errorColor),
                    label: const Text('Hapus dari Riwayat', style: TextStyle(color: AppColors.errorColor)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.errorColor)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}