class User {
  final String username;
  final String nama;
  final String role;
  final String accessToken;
  final bool isTemporaryPassword;
  final String? fotoProfil;

  User({
    required this.username,
    required this.nama,
    required this.role,
    required this.accessToken,
    this.isTemporaryPassword = false,
    this.fotoProfil,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] ?? '',
      nama: json['nama'] ?? json['nama_lengkap'] ?? '',
      role: json['role'] ?? '',
      accessToken: json['access_token'] ?? '',
      isTemporaryPassword: json['is_temporary_password'] ?? false,
      fotoProfil: json['foto_profil'],
    );
  }
}
