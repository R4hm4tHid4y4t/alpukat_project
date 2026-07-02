/// Helper terpusat untuk parsing timestamp yang dikirim backend.
///
/// LATAR BELAKANG BUG:
/// Backend (FastAPI) menyimpan `created_at` sebagai UTC (kolom MySQL
/// `TIMESTAMP`), lalu mengirimnya ke Flutter lewat `datetime.isoformat()`
/// di Python — yang menghasilkan string TANPA suffix 'Z' atau offset,
/// misalnya `"2026-07-02T13:49:22"`.
///
/// `DateTime.parse()` di Dart, kalau tidak menemukan 'Z'/offset pada
/// string, akan menganggap angka-angkanya sebagai waktu LOKAL apa adanya
/// (tidak ada konversi apapun). Akibatnya jam yang sebenarnya UTC
/// (13:49) malah ditampilkan mentah-mentah seolah itu sudah WIB — telat
/// 7 jam dari waktu asli (harusnya 20:49 WIB).
///
/// Fix: tandai string sebagai UTC secara eksplisit sebelum parsing,
/// baru konversi ke waktu lokal perangkat dengan `.toLocal()`.
class DateTimeHelper {
  DateTimeHelper._();

  /// Parse timestamp dari API (asumsi UTC jika tidak ada info timezone)
  /// dan kembalikan sebagai [DateTime] lokal siap-tampil.
  static DateTime? parseApiUtc(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return null;
    try {
      final hasTzInfo = isoDate.endsWith('Z') ||
          RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(isoDate);
      final normalized = hasTzInfo ? isoDate : '${isoDate}Z';
      return DateTime.parse(normalized).toLocal();
    } catch (_) {
      return null;
    }
  }

  static const _bulanPendek = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  /// Format: "2 Jul 2026 · 20:49"
  static String formatTanggalJam(String? isoDate) {
    final date = parseApiUtc(isoDate);
    if (date == null) return '-';
    final jam = date.hour.toString().padLeft(2, '0');
    final menit = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${_bulanPendek[date.month - 1]} ${date.year} · $jam:$menit';
  }

  /// Format: "Jul 2026" (dipakai di halaman profil, "Bergabung sejak")
  static String formatBulanTahun(String? isoDate) {
    final date = parseApiUtc(isoDate);
    if (date == null) return '-';
    return '${_bulanPendek[date.month - 1]} ${date.year}';
  }
}
