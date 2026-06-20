class User {
  final int id;
  final String nama;
  final String email;
  final String role;
  final int statusVerifikasi;
  final String? fotoProfil;
  final String? createdAt;

  const User({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    required this.statusVerifikasi,
    this.fotoProfil,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isVerified => statusVerifikasi == 1;
}
