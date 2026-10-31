enum UserRole {
  admin('Bendahara'),
  pengawas('Pengawas'),
  anggota('Anggota');

  const UserRole(this.label);
  final String label;
}

/// Satu orang di kelas. Anggota yang didaftarkan bendahara belum punya akun
/// (passwordHash null) sampai ia registrasi dengan NIM yang sama.
class UserModel {
  const UserModel({
    required this.id,
    required this.nim,
    required this.nama,
    required this.role,
    this.passwordHash,
    this.salt,
  });

  final String id;
  final String nim;
  final String nama;
  final UserRole role;
  final String? passwordHash;
  final String? salt;

  bool get punyaAkun => passwordHash != null && salt != null;

  UserModel copyWith({
    String? nim,
    String? nama,
    String? passwordHash,
    String? salt,
  }) =>
      UserModel(
        id: id,
        nim: nim ?? this.nim,
        nama: nama ?? this.nama,
        role: role,
        passwordHash: passwordHash ?? this.passwordHash,
        salt: salt ?? this.salt,
      );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        nim: json['nim'] as String,
        nama: json['nama'] as String,
        role: UserRole.values.byName(json['role'] as String),
        passwordHash: json['password_hash'] as String?,
        salt: json['salt'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nim': nim,
        'nama': nama,
        'role': role.name,
        'password_hash': passwordHash,
        'salt': salt,
      };
}
