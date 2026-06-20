import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Progress bar dengan animasi untuk menampilkan confidence score (0-100)
class ConfidenceBar extends StatelessWidget {
  final String label;
  final double value; // 0-100
  final Duration duration;

  const ConfidenceBar({
    super.key,
    required this.label,
    required this.value,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getConfidenceColor(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: duration,
              curve: Curves.easeOut,
              builder: (context, val, _) => Text(
                '${val.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value / 100),
            duration: duration,
            curve: Curves.easeOut,
            builder: (context, val, _) => LinearProgressIndicator(
              value: val,
              minHeight: 8,
              backgroundColor: AppColors.borderColor,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
