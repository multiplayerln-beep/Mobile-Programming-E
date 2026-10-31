enum TransactionType {
  pemasukan('Pemasukan'),
  pengeluaran('Pengeluaran');

  const TransactionType(this.label);
  final String label;
}

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.tipe,
    required this.kategori,
    required this.nominal,
    required this.keterangan,
    required this.tglTransaksi,
    this.iuranId,
    this.anggotaId,
  });

  final String id;
  final TransactionType tipe;
  final String kategori;
  final int nominal;
  final String keterangan;
  final DateTime tglTransaksi;

  /// Terisi bila transaksi ini adalah pembayaran iuran seorang anggota.
  final String? iuranId;
  final String? anggotaId;

  bool get isPembayaranIuran => iuranId != null;

  TransactionModel copyWith({
    TransactionType? tipe,
    String? kategori,
    int? nominal,
    String? keterangan,
    DateTime? tglTransaksi,
  }) =>
      TransactionModel(
        id: id,
        tipe: tipe ?? this.tipe,
        kategori: kategori ?? this.kategori,
        nominal: nominal ?? this.nominal,
        keterangan: keterangan ?? this.keterangan,
        tglTransaksi: tglTransaksi ?? this.tglTransaksi,
        iuranId: iuranId,
        anggotaId: anggotaId,
      );

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        tipe: TransactionType.values.byName(json['tipe'] as String),
        kategori: json['kategori'] as String,
        nominal: (json['nominal'] as num).toInt(),
        keterangan: json['keterangan'] as String,
        tglTransaksi: DateTime.parse(json['tgl_transaksi'] as String),
        iuranId: json['iuran_id'] as String?,
        anggotaId: json['anggota_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipe': tipe.name,
        'kategori': kategori,
        'nominal': nominal,
        'keterangan': keterangan,
        'tgl_transaksi': tglTransaksi.toIso8601String(),
        'iuran_id': iuranId,
        'anggota_id': anggotaId,
      };
}
