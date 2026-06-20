class UserModel {
  final int id;
  final String nama;
  final String email;
  final String role;
  final int statusVerifikasi;
  final String? fotoProfil;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    required this.statusVerifikasi,
    this.fotoProfil,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        nama: json['nama'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        statusVerifikasi: json['status_verifikasi'] as int,
        fotoProfil: json['foto_profil'] as String?,
        createdAt: json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'email': email,
        'role': role,
        'status_verifikasi': statusVerifikasi,
        'foto_profil': fotoProfil,
        'created_at': createdAt,
      };

  UserModel copyWith({
    int? id,
    String? nama,
    String? email,
    String? role,
    int? statusVerifikasi,
    String? fotoProfil,
    String? createdAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        nama: nama ?? this.nama,
        email: email ?? this.email,
        role: role ?? this.role,
        statusVerifikasi: statusVerifikasi ?? this.statusVerifikasi,
        fotoProfil: fotoProfil ?? this.fotoProfil,
        createdAt: createdAt ?? this.createdAt,
      );
}
