// ignore_for_file: prefer_initializing_formals
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/format.dart';
import '../data/local_store.dart';
import '../model/kas_period_model.dart';
import '../model/transaction_model.dart';
import '../model/user_model.dart';
import 'auth_viewmodel.dart';

/// Status pembayaran seorang anggota untuk satu iuran.
enum StatusBayar {
  belumBayar('Belum bayar'),
  sebagian('Sebagian'),
  lunas('Lunas');

  const StatusBayar(this.label);
  final String label;
}

class BulanRingkasan {
  const BulanRingkasan(this.bulan, this.masuk, this.keluar);

  final DateTime bulan;
  final int masuk;
  final int keluar;

  String get label => namaBulanPendek(bulan.month);
}

class KategoriTotal {
  const KategoriTotal(this.kategori, this.total);

  final String kategori;
  final int total;
}

class Tunggakan {
  const Tunggakan({
    required this.anggota,
    required this.total,
    required this.jumlahIuran,
  });

  final UserModel anggota;
  final int total;
  final int jumlahIuran;
}

/// Seluruh logika kas. Semua method perubahan mengembalikan `String?`:
/// null = berhasil, selain itu = pesan galat untuk ditampilkan.
///
/// Aturan:
///  * Hanya bendahara yang mengubah data; pengawas dan anggota hanya melihat.
///  * Saldo (pemasukan - pengeluaran) tidak boleh negatif.
///  * Pembayaran iuran adalah transaksi pemasukan yang terhubung ke iuran dan
///    anggota; status lunas/sebagian dihitung dari total pembayarannya.
class KasViewModel extends ChangeNotifier {
  KasViewModel({
    required AuthViewModel auth,
    List<KasPeriodModel> iuran = const [],
    List<TransactionModel> transaksi = const [],
    LocalStore? store,
  })  : _auth = auth,
        _store = store,
        _iuran = [...iuran],
        _transaksi = [...transaksi] {
    _iuran.sort(_urutTenggat);
    _transaksi.sort(_terbaruDulu);
    _auth.addListener(_onAuth);
    _recompute();
  }

  final AuthViewModel _auth;
  final LocalStore? _store;
  final List<KasPeriodModel> _iuran;
  final List<TransactionModel> _transaksi; // terbaru di indeks 0

  // Hasil turunan: dihitung sekali setiap ada perubahan, bukan setiap build.
  int _totalPemasukan = 0;
  int _totalPengeluaran = 0;
  Map<String, int> _dibayar = const {};
  List<TransactionModel> _pengeluaran = const [];
  List<BulanRingkasan> _bulanan = const [];
  List<KategoriTotal> _perKategori = const [];
  List<String> _kategori = const [];
  List<Tunggakan> _tunggakan = const [];
  int _totalTunggakan = 0;
  int _jumlahMenunggak = 0;
  int _seq = 0;

  // ---------------------------------------------------------------- Data ---

  List<UserModel> get anggota => _auth.anggota;
  late final List<KasPeriodModel> iuran = UnmodifiableListView(_iuran);
  late final List<TransactionModel> transaksi =
      UnmodifiableListView(_transaksi);

  int get totalPemasukan => _totalPemasukan;
  int get totalPengeluaran => _totalPengeluaran;
  int get saldo => _totalPemasukan - _totalPengeluaran;

  List<TransactionModel> get pengeluaran => _pengeluaran;
  List<BulanRingkasan> get ringkasanBulanan => _bulanan;
  List<KategoriTotal> get pengeluaranPerKategori => _perKategori;
  List<String> get daftarKategori => _kategori;

  /// Tunggakan = sisa tagihan pada iuran yang sudah lewat tenggat.
  List<Tunggakan> get daftarTunggakan => _tunggakan;
  int get totalTunggakan => _totalTunggakan;
  int get jumlahMenunggak => _jumlahMenunggak;

  // ------------------------------------------------------------ Iuran ------

  int dibayar(String iuranId, String anggotaId) =>
      _dibayar[_kunci(iuranId, anggotaId)] ?? 0;

  int sisa(KasPeriodModel iuran, String anggotaId) =>
      math.max(0, iuran.nominal - dibayar(iuran.id, anggotaId));

  StatusBayar statusBayar(KasPeriodModel iuran, String anggotaId) {
    final d = dibayar(iuran.id, anggotaId);
    if (d >= iuran.nominal) return StatusBayar.lunas;
    if (d > 0) return StatusBayar.sebagian;
    return StatusBayar.belumBayar;
  }

  int jumlahLunas(KasPeriodModel iuran) => anggota
      .where((a) => statusBayar(iuran, a.id) == StatusBayar.lunas)
      .length;

  int terkumpul(String iuranId) =>
      anggota.fold(0, (sum, a) => sum + dibayar(iuranId, a.id));

  List<TransactionModel> pembayaran(String iuranId, String anggotaId) =>
      _transaksi
          .where((t) => t.iuranId == iuranId && t.anggotaId == anggotaId)
          .toList(growable: false);

  /// Membuat satu iuran, atau beberapa sekaligus bila periodik
  /// (mis. mingguan x 4 -> "Iuran - Minggu 1..4").
  String? tambahIuran({
    required String nama,
    required int nominal,
    required DateTime tenggat,
    PeriodeIuran periode = PeriodeIuran.sekali,
    int jumlah = 1,
  }) {
    final judul = nama.trim();
    if (judul.isEmpty) return 'Nama iuran wajib diisi.';
    if (nominal <= 0) return 'Nominal harus lebih dari 0.';
    final n = periode == PeriodeIuran.sekali ? 1 : jumlah;
    if (n < 1 || n > 52) return 'Jumlah periode harus antara 1 dan 52.';

    for (var k = 0; k < n; k++) {
      final tgl = switch (periode) {
        PeriodeIuran.sekali => tenggat,
        PeriodeIuran.mingguan =>
          DateTime(tenggat.year, tenggat.month, tenggat.day + 7 * k),
        PeriodeIuran.bulanan => _tambahBulan(tenggat, k),
      };
      final label = switch (periode) {
        PeriodeIuran.sekali => judul,
        PeriodeIuran.mingguan => '$judul - Minggu ${k + 1}',
        PeriodeIuran.bulanan => '$judul - Bulan ${k + 1}',
      };
      _iuran.add(
        KasPeriodModel(
          id: _id('TG'),
          namaTagihan: label,
          nominal: nominal,
          tglTenggat: tgl,
        ),
      );
    }
    _iuran.sort(_urutTenggat);
    _commit();
    return null;
  }

  String? hapusIuran(String id) {
    if (_transaksi.any((t) => t.iuranId == id)) {
      return 'Iuran ini sudah memiliki pembayaran dan tidak dapat dihapus.';
    }
    final i = _iuran.indexWhere((x) => x.id == id);
    if (i < 0) return 'Iuran tidak ditemukan.';
    _iuran.removeAt(i);
    _commit();
    return null;
  }

  /// Mencatat pembayaran (penuh atau sebagian) oleh bendahara.
  String? catatPembayaran({
    required String iuranId,
    required String anggotaId,
    required int nominal,
  }) {
    final iuran = _cariIuran(iuranId);
    if (iuran == null) return 'Iuran tidak ditemukan.';
    final anggota = _auth.cariAnggota(anggotaId);
    if (anggota == null) return 'Anggota tidak ditemukan.';
    if (nominal <= 0) return 'Nominal harus lebih dari 0.';
    final sisaTagihan = sisa(iuran, anggotaId);
    if (sisaTagihan == 0) return 'Iuran ini sudah lunas.';
    if (nominal > sisaTagihan) {
      return 'Nominal melebihi sisa tagihan (${rupiah(sisaTagihan)}).';
    }
    _transaksi.add(
      TransactionModel(
        id: _id('TX'),
        tipe: TransactionType.pemasukan,
        kategori: 'Iuran',
        nominal: nominal,
        keterangan: '${iuran.namaTagihan} • ${anggota.nama}',
        tglTransaksi: DateTime.now(),
        iuranId: iuranId,
        anggotaId: anggotaId,
      ),
    );
    _transaksi.sort(_terbaruDulu);
    _commit();
    return null;
  }

  // -------------------------------------------------------- Transaksi ------

  /// Pembayaran iuran tidak diubah nominalnya (agar tidak melebihi tagihan);
  /// bila salah, hapus lalu catat ulang.
  bool bisaDiubah(TransactionModel tx) => !tx.isPembayaranIuran;

  String? tambahTransaksi({
    required TransactionType tipe,
    required String kategori,
    required int nominal,
    String keterangan = '',
    DateTime? tanggal,
  }) {
    final error = _validasi(kategori, nominal);
    if (error != null) return error;
    final tx = TransactionModel(
      id: _id('TX'),
      tipe: tipe,
      kategori: kategori.trim(),
      nominal: nominal,
      keterangan: keterangan.trim(),
      tglTransaksi: _denganWaktu(tanggal),
    );
    final cek = _cekSaldo([..._transaksi, tx]);
    if (cek != null) return cek;
    _transaksi.add(tx);
    _transaksi.sort(_terbaruDulu);
    _commit();
    return null;
  }

  String? ubahTransaksi({
    required String id,
    required TransactionType tipe,
    required String kategori,
    required int nominal,
    String keterangan = '',
    DateTime? tanggal,
  }) {
    final i = _indeks(id);
    if (i < 0) return 'Transaksi tidak ditemukan.';
    if (!bisaDiubah(_transaksi[i])) {
      return 'Pembayaran iuran tidak dapat diubah. Hapus lalu catat ulang.';
    }
    final error = _validasi(kategori, nominal);
    if (error != null) return error;
    final baru = _transaksi[i].copyWith(
      tipe: tipe,
      kategori: kategori.trim(),
      nominal: nominal,
      keterangan: keterangan.trim(),
      tglTransaksi: tanggal == null ? null : _denganWaktu(tanggal),
    );
    final setelah = [..._transaksi]..[i] = baru;
    final cek = _cekSaldo(setelah);
    if (cek != null) return cek;
    _transaksi[i] = baru;
    _transaksi.sort(_terbaruDulu);
    _commit();
    return null;
  }

  String? hapusTransaksi(String id) {
    final i = _indeks(id);
    if (i < 0) return 'Transaksi tidak ditemukan.';
    final setelah = [..._transaksi]..removeAt(i);
    final cek = _cekSaldo(setelah);
    if (cek != null) return cek;
    _transaksi.removeAt(i);
    _commit();
    return null;
  }

  /// Pencarian & penyaringan riwayat. [sampai] ikut dihitung (inklusif).
  List<TransactionModel> filter({
    String query = '',
    TransactionType? tipe,
    String? kategori,
    DateTime? dari,
    DateTime? sampai,
  }) {
    final q = query.trim().toLowerCase();
    final awal = dari == null ? null : DateTime(dari.year, dari.month, dari.day);
    final akhir = sampai == null
        ? null
        : DateTime(sampai.year, sampai.month, sampai.day + 1);
    return _transaksi.where((t) {
      if (tipe != null && t.tipe != tipe) return false;
      if (kategori != null && t.kategori != kategori) return false;
      if (awal != null && t.tglTransaksi.isBefore(awal)) return false;
      if (akhir != null && !t.tglTransaksi.isBefore(akhir)) return false;
      if (q.isNotEmpty &&
          !'${t.kategori} ${t.keterangan}'.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  // -------------------------------------------------- Kelola anggota -------

  String? tambahAnggota({required String nim, required String nama}) =>
      _auth.tambahAnggota(nim: nim, nama: nama);

  String? ubahAnggota({
    required String id,
    required String nim,
    required String nama,
  }) =>
      _auth.ubahAnggota(id: id, nim: nim, nama: nama);

  String? hapusAnggota(String id) {
    if (_transaksi.any((t) => t.anggotaId == id)) {
      return 'Anggota memiliki riwayat pembayaran dan tidak dapat dihapus.';
    }
    return _auth.hapusAnggota(id);
  }

  Future<void> simpan() async {
    final store = _store;
    if (store == null) return;
    try {
      await store.writeList(
        LocalStore.kIuran,
        _iuran.map((e) => e.toJson()).toList(),
      );
      await store.writeList(
        LocalStore.kTransaksi,
        _transaksi.map((e) => e.toJson()).toList(),
      );
    } catch (_) {
      // Gagal menyimpan tidak boleh membuat aplikasi berhenti.
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuth);
    super.dispose();
  }

  // ----------------------------------------------------------- Internal ----

  static int _urutTenggat(KasPeriodModel a, KasPeriodModel b) =>
      a.tglTenggat.compareTo(b.tglTenggat);

  static int _terbaruDulu(TransactionModel a, TransactionModel b) =>
      b.tglTransaksi.compareTo(a.tglTransaksi);

  static DateTime _tambahBulan(DateTime d, int k) {
    final m0 = d.month - 1 + k;
    final tahun = d.year + m0 ~/ 12;
    final bulan = m0 % 12 + 1;
    final hariTerakhir = DateTime(tahun, bulan + 1, 0).day;
    return DateTime(tahun, bulan, math.min(d.day, hariTerakhir));
  }

  static DateTime _denganWaktu(DateTime? tanggal) {
    final now = DateTime.now();
    final t = tanggal ?? now;
    return DateTime(t.year, t.month, t.day, now.hour, now.minute, now.second);
  }

  String _kunci(String iuranId, String anggotaId) => '$iuranId|$anggotaId';

  String _id(String prefix) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch}${_seq++}';

  int _indeks(String id) => _transaksi.indexWhere((t) => t.id == id);

  KasPeriodModel? _cariIuran(String id) {
    for (final i in _iuran) {
      if (i.id == id) return i;
    }
    return null;
  }

  String? _validasi(String kategori, int nominal) {
    if (kategori.trim().isEmpty) return 'Kategori wajib diisi.';
    if (nominal <= 0) return 'Nominal harus lebih dari 0.';
    return null;
  }

  String? _cekSaldo(Iterable<TransactionModel> setelah) {
    final s = setelah.fold<int>(
      0,
      (sum, t) =>
          t.tipe == TransactionType.pemasukan ? sum + t.nominal : sum - t.nominal,
    );
    if (s < 0) {
      return 'Perubahan ini membuat saldo kas negatif (${rupiah(s)}).';
    }
    return null;
  }

  void _onAuth() {
    _recompute();
    notifyListeners();
  }

  void _commit() {
    _recompute();
    notifyListeners();
    simpan();
  }

  void _recompute() {
    var masuk = 0;
    var keluar = 0;
    final dibayar = <String, int>{};
    final pengeluaran = <TransactionModel>[];
    final perKategori = <String, int>{};
    final kategori = <String>{};
    final perBulan = <int, List<int>>{}; // tahun*12+bulan-1 -> [masuk, keluar]

    for (final tx in _transaksi) {
      kategori.add(tx.kategori);
      final bulan = perBulan.putIfAbsent(
        tx.tglTransaksi.year * 12 + tx.tglTransaksi.month - 1,
        () => [0, 0],
      );
      if (tx.tipe == TransactionType.pemasukan) {
        masuk += tx.nominal;
        bulan[0] += tx.nominal;
        final iuranId = tx.iuranId;
        final anggotaId = tx.anggotaId;
        if (iuranId != null && anggotaId != null) {
          dibayar.update(
            _kunci(iuranId, anggotaId),
            (v) => v + tx.nominal,
            ifAbsent: () => tx.nominal,
          );
        }
      } else {
        keluar += tx.nominal;
        bulan[1] += tx.nominal;
        pengeluaran.add(tx);
        perKategori.update(
          tx.kategori,
          (v) => v + tx.nominal,
          ifAbsent: () => tx.nominal,
        );
      }
    }

    final now = DateTime.now();
    final kunciSekarang = now.year * 12 + now.month - 1;
    final bulanan = <BulanRingkasan>[
      for (var k = kunciSekarang - 5; k <= kunciSekarang; k++)
        BulanRingkasan(
          DateTime(k ~/ 12, k % 12 + 1),
          perBulan[k]?[0] ?? 0,
          perBulan[k]?[1] ?? 0,
        ),
    ];

    final tunggakan = <Tunggakan>[];
    var totalTunggakan = 0;
    var menunggak = 0;
    for (final a in _auth.anggota) {
      var total = 0;
      var jumlah = 0;
      for (final i in _iuran) {
        if (!i.lewatTenggat) continue;
        final sisaTagihan = i.nominal - (dibayar[_kunci(i.id, a.id)] ?? 0);
        if (sisaTagihan > 0) {
          total += sisaTagihan;
          jumlah++;
        }
      }
      tunggakan.add(Tunggakan(anggota: a, total: total, jumlahIuran: jumlah));
      totalTunggakan += total;
      if (total > 0) menunggak++;
    }
    tunggakan.sort((a, b) => b.total.compareTo(a.total));

    _totalPemasukan = masuk;
    _totalPengeluaran = keluar;
    _dibayar = dibayar;
    _pengeluaran = List.unmodifiable(pengeluaran);
    _bulanan = List.unmodifiable(bulanan);
    _perKategori = List.unmodifiable(
      perKategori.entries.map((e) => KategoriTotal(e.key, e.value)).toList()
        ..sort((a, b) => b.total.compareTo(a.total)),
    );
    _kategori = List.unmodifiable(kategori.toList()..sort());
    _tunggakan = List.unmodifiable(tunggakan);
    _totalTunggakan = totalTunggakan;
    _jumlahMenunggak = menunggak;
  }
}
