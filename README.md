# Kas Kelas (Flutter) – Tahap 1

Ganti folder `lib/` di proyek Flutter-mu dengan folder ini. Tanpa dependensi
tambahan: `pubspec.yaml` cukup bawaan (butuh Flutter 3.22+ / Dart 3).

## Struktur (MVVM)
lib/
  main.dart, app.dart        entry point, tema, pemilihan halaman per peran
  core/                      format rupiah/tanggal, AppScope, pembuat laporan
  models/                    UserModel, IuranModel, TransaksiModel (+JSON)
  data/                      demo_data.dart (ganti dengan Firebase/SQLite nanti)
  viewmodels/                AuthViewModel (sesi), KasViewModel (semua logika kas)
  views/
    dashboard/               shell + dashboard Bendahara / Pengawas / Anggota
    iuran/ anggota/ transaksi/ grafik/ laporan/   satu folder per fitur
    widgets/                 komponen bersama (badge, form helper, kartu saldo)

## Pasang QR DANA bendahara
1. Timpa `assets/qr_dana.png` dengan screenshot/QR DANA bendahara (file sekarang hanya contoh, TIDAK bisa di-scan).
2. Ubah nama & nomor di `lib/core/pembayaran_config.dart`.
3. Daftarkan aset di `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/qr_dana.png
```

## Alur bayar & notifikasi
Anggota: Detail iuran > Bayar sekarang > scan QR > "Saya sudah bayar" > bendahara verifikasi > masuk saldo.
Notifikasi: ikon lonceng di AppBar (dalam aplikasi saja, tidak ke HP).

## Akun demo (login pakai NIM)
220001 Bendahara · 220002 Pengawas · 220003/220004/220005 Anggota
