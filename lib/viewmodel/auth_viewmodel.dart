// ignore_for_file: prefer_initializing_formals
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/security.dart';
import '../data/local_store.dart';
import '../model/user_model.dart';

/// Akun, sesi login, dan data anggota kelas.
/// Semua method perubahan mengembalikan `String?`: null = berhasil,
/// selain itu = pesan galat untuk ditampilkan.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required List<UserModel> users, LocalStore? store})
      : _users = [...users],
        _store = store {
    _rebuild();
  }

  static final _nimValid = RegExp(r'^\d{3,20}$');

  final List<UserModel> _users;
  final LocalStore? _store;
  UserModel? _current;
  List<UserModel> _anggota = const [];
  int _seq = 0;

  UserModel? get currentUser => _current;
  late final List<UserModel> users = UnmodifiableListView(_users);
  List<UserModel> get anggota => _anggota;

  /// Bendahara dan pengawas masing-masing hanya satu per kelas.
  List<UserRole> get peranTersedia => [
        for (final role in UserRole.values)
          if (role == UserRole.anggota || !_users.any((u) => u.role == role))
            role,
      ];

  UserModel? cariAnggota(String id) {
    for (final a in _anggota) {
      if (a.id == id) return a;
    }
    return null;
  }

  // ------------------------------------------------------------- Sesi ------

  String? login(String nim, String password) {
    if (nim.trim().isEmpty || password.isEmpty) {
      return 'NIM dan kata sandi wajib diisi.';
    }
    final user = _cariNim(nim.trim());
    final salt = user?.salt;
    if (user == null ||
        salt == null ||
        Security.hash(password, salt) != user.passwordHash) {
      return 'NIM atau kata sandi salah.';
    }
    _current = user;
    notifyListeners();
    return null;
  }

  /// Registrasi akun. Anggota yang sudah didaftarkan bendahara (NIM sama)
  /// cukup mengaktifkan akunnya.
  String? registrasi({
    required String nim,
    required String nama,
    required String password,
    required UserRole role,
  }) {
    final n = nim.trim();
    final nm = nama.trim();
    if (!_nimValid.hasMatch(n)) return 'NIM harus berupa angka 3–20 digit.';
    if (nm.isEmpty) return 'Nama wajib diisi.';
    if (password.length < 6) return 'Kata sandi minimal 6 karakter.';
    if (!peranTersedia.contains(role)) {
      return 'Peran ${role.label} sudah terisi.';
    }

    final salt = Security.newSalt();
    final hash = Security.hash(password, salt);
    final ada = _cariNim(n);
    final UserModel user;
    if (ada != null) {
      if (role != UserRole.anggota ||
          ada.role != UserRole.anggota ||
          ada.punyaAkun) {
        return 'NIM sudah terdaftar.';
      }
      user = ada.copyWith(passwordHash: hash, salt: salt);
      _users[_users.indexOf(ada)] = user;
    } else {
      user = UserModel(
        id: _id(),
        nim: n,
        nama: nm,
        role: role,
        passwordHash: hash,
        salt: salt,
      );
      _users.add(user);
    }
    _current = user;
    _commit();
    return null;
  }

  void logout() {
    if (_current == null) return;
    _current = null;
    notifyListeners();
  }

  // ---------------------------------------------------- Kelola anggota -----

  String? tambahAnggota({required String nim, required String nama}) {
    final error = _validasiAnggota(nim, nama);
    if (error != null) return error;
    if (_cariNim(nim.trim()) != null) return 'NIM sudah terdaftar.';
    _users.add(
      UserModel(
        id: _id(),
        nim: nim.trim(),
        nama: nama.trim(),
        role: UserRole.anggota,
      ),
    );
    _commit();
    return null;
  }

  String? ubahAnggota({
    required String id,
    required String nim,
    required String nama,
  }) {
    final error = _validasiAnggota(nim, nama);
    if (error != null) return error;
    final i = _users.indexWhere((u) => u.id == id && u.role == UserRole.anggota);
    if (i < 0) return 'Anggota tidak ditemukan.';
    final dipakai = _cariNim(nim.trim());
    if (dipakai != null && dipakai.id != id) return 'NIM sudah terdaftar.';
    _users[i] = _users[i].copyWith(nim: nim.trim(), nama: nama.trim());
    if (_current?.id == id) _current = _users[i];
    _commit();
    return null;
  }

  String? hapusAnggota(String id) {
    final i = _users.indexWhere((u) => u.id == id && u.role == UserRole.anggota);
    if (i < 0) return 'Anggota tidak ditemukan.';
    _users.removeAt(i);
    _commit();
    return null;
  }

  Future<void> simpan() async {
    final store = _store;
    if (store == null) return;
    try {
      await store.writeList(
        LocalStore.kUsers,
        _users.map((u) => u.toJson()).toList(),
      );
    } catch (_) {
      // Gagal menyimpan tidak boleh membuat aplikasi berhenti.
    }
  }

  // ----------------------------------------------------------- Internal ----

  UserModel? _cariNim(String nim) {
    for (final u in _users) {
      if (u.nim == nim) return u;
    }
    return null;
  }

  String _id() => 'U${DateTime.now().microsecondsSinceEpoch}${_seq++}';

  String? _validasiAnggota(String nim, String nama) {
    if (!_nimValid.hasMatch(nim.trim())) {
      return 'NIM harus berupa angka 3–20 digit.';
    }
    if (nama.trim().isEmpty) return 'Nama wajib diisi.';
    return null;
  }

  void _rebuild() {
    _anggota = List.unmodifiable(
      _users.where((u) => u.role == UserRole.anggota),
    );
  }

  void _commit() {
    _rebuild();
    notifyListeners();
    simpan();
  }
}
