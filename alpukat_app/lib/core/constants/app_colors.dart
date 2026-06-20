import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primaryGreen     = Color(0xFF2D6A4F);
  static const Color secondaryGreen   = Color(0xFF52B788);
  static const Color lightGreen       = Color(0xFFB7E4C7);
  static const Color extraLightGreen  = Color(0xFFE8F5E9);

  // Kematangan — indikator warna sesuai laporan
  static const Color mentahColor      = Color(0xFFE63946); // Merah
  static const Color setengahColor    = Color(0xFFF4A261); // Kuning-oranye
  static const Color matangColor      = Color(0xFF2D6A4F); // Hijau
  static const Color terlalMatangColor= Color(0xFFE76F51); // Oranye gelap

  // Background & Text
  static const Color backgroundWhite  = Color(0xFFF8F9FA);
  static const Color textDark         = Color(0xFF1A1A2E);
  static const Color textGrey         = Color(0xFF6C757D);
  static const Color textLightGrey    = Color(0xFFADB5BD);

  // Status
  static const Color successColor     = Color(0xFF28A745);
  static const Color warningColor     = Color(0xFFFFC107);
  static const Color errorColor       = Color(0xFFDC3545);
  static const Color infoColor        = Color(0xFF17A2B8);

  // Card & Border
  static const Color cardColor        = Color(0xFFFFFFFF);
  static const Color borderColor      = Color(0xFFDEE2E6);
  static const Color dividerColor     = Color(0xFFE9ECEF);

  /// Ambil warna berdasarkan label kematangan
  static Color getKematanganColor(String label) {
    switch (label.toLowerCase()) {
      case 'mentah':
        return mentahColor;
      case 'setengah matang':
        return setengahColor;
      case 'matang':
        return matangColor;
      case 'terlalu matang':
        return terlalMatangColor;
      default:
        return primaryGreen;
    }
  }

  /// Warna confidence bar berdasarkan nilai (0-100)
  static Color getConfidenceColor(double value) {
    if (value >= 80) return successColor;
    if (value >= 60) return warningColor;
    return errorColor;
  }
}
