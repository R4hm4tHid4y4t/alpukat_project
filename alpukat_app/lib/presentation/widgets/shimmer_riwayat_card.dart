import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';

class ShimmerRiwayatCard extends StatelessWidget {
  const ShimmerRiwayatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.borderColor,
      highlightColor: AppColors.backgroundWhite,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(width: 64, height: 64, decoration: BoxDecoration(
              color: Colors.grey, borderRadius: BorderRadius.circular(8),
            )),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 100, height: 14, color: Colors.grey),
                  const SizedBox(height: 8),
                  Container(width: 80, height: 12, color: Colors.grey),
                  const SizedBox(height: 8),
                  Container(width: 120, height: 10, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
