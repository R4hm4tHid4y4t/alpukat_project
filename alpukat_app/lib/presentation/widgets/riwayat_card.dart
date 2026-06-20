import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/riwayat_model.dart';

class RiwayatCard extends StatelessWidget {
  final RiwayatModel riwayat;
  final VoidCallback? onTap;

  const RiwayatCard({super.key, required this.riwayat, this.onTap});

  String _formatTanggal(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('d MMM yyyy · HH:mm', 'id_ID').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kematanganColor = riwayat.kematanganLabel != null
        ? AppColors.getKematanganColor(riwayat.kematanganLabel!)
        : AppColors.primaryGreen;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: riwayat.gambarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: riwayat.gambarUrl!,
                        width: 64, height: 64, fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 64, height: 64, color: AppColors.borderColor,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 64, height: 64, color: AppColors.borderColor,
                          child: const Icon(Icons.image_not_supported, color: AppColors.textLightGrey),
                        ),
                      )
                    : Container(
                        width: 64, height: 64,
                        color: AppColors.extraLightGreen,
                        child: const Icon(Icons.eco, color: AppColors.primaryGreen),
                      ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          riwayat.varietasNama ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        if (riwayat.statusFlag == 'perlu_ditinjau') ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.flag, size: 14, color: AppColors.warningColor),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: kematanganColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        riwayat.kematanganLabel ?? '-',
                        style: TextStyle(fontSize: 11, color: kematanganColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTanggal(riwayat.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${riwayat.confidenceVarietas?.toStringAsFixed(1) ?? '-'}% varietas · '
                      '${riwayat.confidenceKematangan?.toStringAsFixed(1) ?? '-'}% kematangan',
                      style: const TextStyle(fontSize: 11, color: AppColors.textLightGrey),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: AppColors.textLightGrey),
            ],
          ),
        ),
      ),
    );
  }
}