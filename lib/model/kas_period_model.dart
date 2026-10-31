enum PeriodeIuran {
  sekali('Sekali'),
  mingguan('Mingguan'),
  bulanan('Bulanan');

  const PeriodeIuran(this.label);
  final String label;
}

/// Satu tagihan iuran (mis. "Iuran Kas Oktober").
class KasPeriodModel {
  const KasPeriodModel({
    required this.id,
    required this.namaTagihan,
    required this.nominal,
    required this.tglTenggat,
  });

  final String id;
  final String namaTagihan;

  /// Rupiah utuh. Memakai int (bukan double) supaya tidak ada galat pembulatan.
  final int nominal;
  final DateTime tglTenggat;

  bool get lewatTenggat {
    final now = DateTime.now();
    final hariIni = DateTime(now.year, now.month, now.day);
    final tenggat =
        DateTime(tglTenggat.year, tglTenggat.month, tglTenggat.day);
    return hariIni.isAfter(tenggat);
  }

  factory KasPeriodModel.fromJson(Map<String, dynamic> json) => KasPeriodModel(
        id: json['id'] as String,
        namaTagihan: json['nama_tagihan'] as String,
        nominal: (json['nominal'] as num).toInt(),
        tglTenggat: DateTime.parse(json['tgl_tenggat'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama_tagihan': namaTagihan,
        'nominal': nominal,
        'tgl_tenggat': tglTenggat.toIso8601String(),
      };
}
