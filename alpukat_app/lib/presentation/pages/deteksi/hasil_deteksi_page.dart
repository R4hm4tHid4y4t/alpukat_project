import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/hasil_deteksi_model.dart';
import '../../widgets/confidence_bar.dart';

class HasilDeteksiPage extends StatelessWidget {
  final Map<String, dynamic> hasil;
  const HasilDeteksiPage({super.key, required this.hasil});

  @override
  Widget build(BuildContext context) {
    final data = HasilDeteksiModel.fromJson(hasil);
    final kematanganColor = AppColors.getKematanganColor(data.kematangan.label);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(title: const Text('Hasil Deteksi')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Image
            Hero(
              tag: 'hasil_deteksi_image',
              child: SizedBox(
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
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── WARNING BANNER ──────────────────────
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

                  // ── CARD VARIETAS ───────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.extraLightGreen,
                      borderRadius: BorderRadius.circular(12),
                      border: const Border(
                        left: BorderSide(color: AppColors.primaryGreen, width: 4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.eco, color: AppColors.primaryGreen, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'VARIETAS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data.varietas.nama,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        if (data.varietas.deskripsi != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            data.varietas.deskripsi!,
                            style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.5),
                          ),
                        ],
                        const SizedBox(height: 12),
                        ConfidenceBar(label: 'Akurasi', value: data.confidenceVarietas),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── CARD KEMATANGAN ─────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kematanganColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(color: kematanganColor, width: 4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(color: kematanganColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'TINGKAT KEMATANGAN',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: kematanganColor,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data.kematangan.label,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        if (data.kematangan.deskripsi != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            data.kematangan.deskripsi!,
                            style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.5),
                          ),
                        ],
                        if (data.kematangan.ciriVisual != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Ciri visual: ${data.kematangan.ciriVisual}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontStyle: FontStyle.italic),
                          ),
                        ],
                        const SizedBox(height: 12),
                        ConfidenceBar(label: 'Akurasi', value: data.confidenceKematangan),

                        // Rekomendasi konsumsi
                        if (data.kematangan.rekomendasi != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(_getRekomendasiEmoji(data.kematangan.label),
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    data.kematangan.rekomendasi!,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── INFO MODEL ──────────────────────────
                  if (data.modelVersi != null || data.inferenceTimeMs != null)
                    Center(
                      child: Text(
                        'Model ${data.modelVersi ?? 'v1.0'}'
                        '${data.inferenceTimeMs != null ? ' · Inferensi: ${data.inferenceTimeMs!.toStringAsFixed(0)}ms' : ''}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textLightGrey),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ── ROW AKSI ────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Hasil sudah tersimpan otomatis ke riwayat'),
                                backgroundColor: AppColors.successColor,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            minimumSize: Size.zero,
                          ),
                          icon: const Icon(Icons.bookmark_outline, size: 16),
                          label: const Text('Simpan', overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            minimumSize: Size.zero,
                          ),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Ulang', overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Rencana: integrasikan share_plus jika dibutuhkan
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Alpukat ${data.varietas.nama} - ${data.kematangan.label} '
                                  '(${data.confidenceVarietas.toStringAsFixed(1)}% / ${data.confidenceKematangan.toStringAsFixed(1)}%)',
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            minimumSize: Size.zero,
                          ),
                          icon: const Icon(Icons.share, size: 16),
                          label: const Text('Bagikan', overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRekomendasiEmoji(String label) {
    switch (label) {
      case 'Mentah':
        return '⏳';
      case 'Setengah Matang':
        return '🕐';
      case 'Matang':
        return '✅';
      case 'Terlalu Matang':
        return '⚠️';
      default:
        return 'ℹ️';
    }
  }
}