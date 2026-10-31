import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Hash kata sandi: SHA-256 dengan salt acak per akun (KNF-02).
/// Catatan: untuk produksi gunakan algoritma lambat (bcrypt/argon2) atau
/// layanan autentikasi seperti Firebase Authentication.
class Security {
  Security._();

  static String newSalt() {
    final random = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => random.nextInt(256)));
  }

  static String hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();
}
