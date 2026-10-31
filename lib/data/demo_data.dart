import '../core/security.dart';
import '../model/kas_period_model.dart';
import '../model/transaction_model.dart';
import '../model/user_model.dart';

/// Data awal untuk demo. HAPUS / kosongkan sebelum dipakai sungguhan.
class DemoData {
  DemoData._();

  static const demoPassword = '123456';
  static const demoNims = {'220001', '220002', '220003', '220004', '220005'};

  static UserModel _akun(String id, String nim, String nama, UserRole role) {
    final salt = Security.newSalt();
    return UserModel(
      id: id,
      nim: nim,
      nama: nama,
      role: role,
      salt: salt,
      passwordHash: Security.hash(demoPassword, salt),
    );
  }

  static List<UserModel> users() => [
        _akun('U1', '220001', 'Budi', UserRole.admin),
        _akun('U2', '220002', 'Siti', UserRole.pengawas),
        _akun('U3', '220003', 'Andi', UserRole.anggota),
        _akun('U4', '220004', 'Muhamad Farel Nabil', UserRole.anggota),
        _akun('U5', '220005', 'Citra', UserRole.anggota),
      ];

  static List<KasPeriodModel> iuran() {
    final now = DateTime.now();
    DateTime hari(int offset) =>
        DateTime(now.year, now.month, now.day + offset);
    return [
      KasPeriodModel(
        id: 'TG00',
        namaTagihan: 'Iuran Kas Kelas (Bulan Lalu)',
        nominal: 20000,
        tglTenggat: hari(-10),
      ),
      KasPeriodModel(
        id: 'TG01',
        namaTagihan: 'Iuran Kas Kelas (Bulan Ini)',
        nominal: 20000,
        tglTenggat: hari(7),
      ),
      KasPeriodModel(
        id: 'TG02',
        namaTagihan: 'Dana Patungan Beli Spidol',
        nominal: 5000,
        tglTenggat: hari(3),
      ),
    ];
  }

  static List<TransactionModel> transaksi() {
    final now = DateTime.now();
    DateTime lalu(int hari) => now.subtract(Duration(days: hari));

    TransactionModel masuk(String id, int hari, String kategori, int nominal,
            String ket) =>
        TransactionModel(
          id: id,
          tipe: TransactionType.pemasukan,
          kategori: kategori,
          nominal: nominal,
          keterangan: ket,
          tglTransaksi: lalu(hari),
        );

    TransactionModel keluar(String id, int hari, String kategori, int nominal,
            String ket) =>
        TransactionModel(
          id: id,
          tipe: TransactionType.pengeluaran,
          kategori: kategori,
          nominal: nominal,
          keterangan: ket,
          tglTransaksi: lalu(hari),
        );

    TransactionModel bayar(String id, int hari, String iuranId,
            String iuranNama, String anggotaId, String nama, int nominal) =>
        TransactionModel(
          id: id,
          tipe: TransactionType.pemasukan,
          kategori: 'Iuran',
          nominal: nominal,
          keterangan: '$iuranNama • $nama',
          tglTransaksi: lalu(hari),
          iuranId: iuranId,
          anggotaId: anggotaId,
        );

    const bulanLalu = 'Iuran Kas Kelas (Bulan Lalu)';
    const bulanIni = 'Iuran Kas Kelas (Bulan Ini)';
    return [
      masuk('D1', 70, 'Iuran', 100000, 'Kas awal semester'),
      keluar('D2', 45, 'Konsumsi', 60000, 'Konsumsi rapat kelas'),
      masuk('D3', 30, 'Donasi', 120000, 'Donasi alumni'),
      keluar('D4', 20, 'Fotokopi', 25000, 'Fotokopi materi kuliah'),
      keluar('D5', 10, 'Kegiatan', 40000, 'Dekorasi acara kelas'),
      masuk('D6', 3, 'Iuran', 150000, 'Iuran Kas Minggu 1'),
      bayar('D7', 15, 'TG00', bulanLalu, 'U3', 'Andi', 20000),
      bayar('D8', 14, 'TG00', bulanLalu, 'U4', 'Muhamad Farel Nabil', 20000),
      bayar('D9', 12, 'TG00', bulanLalu, 'U5', 'Citra', 10000),
      bayar('D10', 1, 'TG01', bulanIni, 'U3', 'Andi', 20000),
      bayar('D11', 1, 'TG01', bulanIni, 'U4', 'Muhamad Farel Nabil', 10000),
    ];
  }
}
