import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan lokal sederhana (offline-first, KNF-07). Data disimpan sebagai
/// JSON di SharedPreferences. Cukup untuk data kelas yang kecil; bila data
/// membesar, ganti dengan SQLite/Drift tanpa mengubah ViewModel.
class LocalStore {
  LocalStore._(this._prefs);

  static const kUsers = 'users';
  static const kIuran = 'iuran';
  static const kTransaksi = 'transaksi';

  final SharedPreferences _prefs;

  static Future<LocalStore> open() async =>
      LocalStore._(await SharedPreferences.getInstance());

  /// True saat aplikasi pertama kali dijalankan (belum ada data tersimpan).
  bool get kosong => !_prefs.containsKey(kUsers);

  /// Null bila belum ada data atau datanya rusak.
  List<T>? read<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> value) =>
      _prefs.setString(key, jsonEncode(value));
}
