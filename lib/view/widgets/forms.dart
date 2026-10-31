import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../model/kas_period_model.dart';
import '../../model/transaction_model.dart';
import '../../model/user_model.dart';
import 'common.dart';

const _kategoriPemasukan = ['Iuran', 'Donasi', 'Lainnya'];
const _kategoriPengeluaran = [
  'Fotokopi',
  'Konsumsi',
  'Kegiatan',
  'Administrasi',
  'Lainnya',
];

String? _wajib(String? v, String label) =>
    (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

String? _nominal(String? v) {
  final n = int.tryParse(v ?? '');
  return (n == null || n <= 0) ? 'Masukkan nominal lebih dari 0' : null;
}

final _hanyaAngka = <TextInputFormatter>[
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(10),
];

DateTime _hariIni() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

Future<void> _showSheet(BuildContext context, Widget child) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SingleChildScrollView(child: child),
      ),
    ),
  );
}

InputDecoration _dekor(String label, {String? prefix}) => InputDecoration(
      labelText: label,
      prefixText: prefix,
      border: const OutlineInputBorder(),
    );

// ---------------------------------------------------------------- Transaksi --

/// Form tambah (initial == null) atau ubah transaksi.
Future<void> showTransaksiSheet(
  BuildContext context, {
  TransactionModel? initial,
}) =>
    _showSheet(context, _TransaksiForm(initial: initial));

class _TransaksiForm extends StatefulWidget {
  const _TransaksiForm({this.initial});

  final TransactionModel? initial;

  @override
  State<_TransaksiForm> createState() => _TransaksiFormState();
}

class _TransaksiFormState extends State<_TransaksiForm> {
  final _formKey = GlobalKey<FormState>();
  late final _kategori = TextEditingController(text: widget.initial?.kategori);
  late final _nominalCtrl = TextEditingController(
    text: widget.initial?.nominal.toString(),
  );
  late final _keterangan =
      TextEditingController(text: widget.initial?.keterangan);
  late TransactionType _tipe =
      widget.initial?.tipe ?? TransactionType.pemasukan;
  late DateTime _tanggal = widget.initial == null
      ? _hariIni()
      : DateTime(
          widget.initial!.tglTransaksi.year,
          widget.initial!.tglTransaksi.month,
          widget.initial!.tglTransaksi.day,
        );

  @override
  void dispose() {
    _kategori.dispose();
    _nominalCtrl.dispose();
    _keterangan.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final dipilih = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: _hariIni(),
    );
    if (dipilih != null && mounted) setState(() => _tanggal = dipilih);
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    final kas = AppScope.of(context).kas;
    final messenger = ScaffoldMessenger.of(context);
    final initial = widget.initial;
    final nominal = int.parse(_nominalCtrl.text);

    final error = initial == null
        ? kas.tambahTransaksi(
            tipe: _tipe,
            kategori: _kategori.text,
            nominal: nominal,
            keterangan: _keterangan.text,
            tanggal: _tanggal,
          )
        : kas.ubahTransaksi(
            id: initial.id,
            tipe: _tipe,
            kategori: _kategori.text,
            nominal: nominal,
            keterangan: _keterangan.text,
            tanggal: _tanggal,
          );

    if (error != null) {
      snack(messenger, error, error: true);
      return; // sheet tetap terbuka agar data tidak hilang
    }
    Navigator.pop(context);
    snack(
      messenger,
      initial == null ? 'Transaksi disimpan.' : 'Perubahan disimpan.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    final saran = _tipe == TransactionType.pemasukan
        ? _kategoriPemasukan
        : _kategoriPengeluaran;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            editing ? 'Ubah Transaksi' : 'Transaksi Baru',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SegmentedButton<TransactionType>(
            segments: [
              for (final t in TransactionType.values)
                ButtonSegment(value: t, label: Text(t.label)),
            ],
            selected: {_tipe},
            onSelectionChanged: (s) => setState(() => _tipe = s.first),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _kategori,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dekor('Kategori'),
            validator: (v) => _wajib(v, 'Kategori'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final k in saran)
                ActionChip(
                  label: Text(k),
                  onPressed: () => setState(() => _kategori.text = k),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nominalCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: _hanyaAngka,
            decoration: _dekor('Nominal', prefix: 'Rp '),
            validator: _nominal,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _keterangan,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dekor('Keterangan (opsional)'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pilihTanggal,
            icon: const Icon(Icons.event_outlined),
            label: Text('Tanggal: ${tanggal(_tanggal)}'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _simpan,
            child: Text(editing ? 'Simpan Perubahan' : 'Simpan'),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------- Iuran --

Future<void> showIuranSheet(BuildContext context) =>
    _showSheet(context, const _IuranForm());

class _IuranForm extends StatefulWidget {
  const _IuranForm();

  @override
  State<_IuranForm> createState() => _IuranFormState();
}

class _IuranFormState extends State<_IuranForm> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _nominalCtrl = TextEditingController();
  final _jumlah = TextEditingController(text: '4');
  PeriodeIuran _periode = PeriodeIuran.sekali;
  late DateTime _tenggat = _hariIni().add(const Duration(days: 7));

  @override
  void dispose() {
    _nama.dispose();
    _nominalCtrl.dispose();
    _jumlah.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final hariIni = _hariIni();
    final dipilih = await showDatePicker(
      context: context,
      initialDate: _tenggat.isBefore(hariIni) ? hariIni : _tenggat,
      firstDate: hariIni,
      lastDate: hariIni.add(const Duration(days: 365 * 2)),
    );
    if (dipilih != null && mounted) setState(() => _tenggat = dipilih);
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    final kas = AppScope.of(context).kas;
    final messenger = ScaffoldMessenger.of(context);

    final error = kas.tambahIuran(
      nama: _nama.text,
      nominal: int.parse(_nominalCtrl.text),
      tenggat: _tenggat,
      periode: _periode,
      jumlah: int.tryParse(_jumlah.text) ?? 1,
    );
    if (error != null) {
      snack(messenger, error, error: true);
      return;
    }
    Navigator.pop(context);
    snack(messenger, 'Iuran dibuat.');
  }

  @override
  Widget build(BuildContext context) {
    final periodik = _periode != PeriodeIuran.sekali;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Iuran Baru', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nama,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dekor('Nama iuran'),
            validator: (v) => _wajib(v, 'Nama iuran'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nominalCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: _hanyaAngka,
            decoration: _dekor('Nominal per anggota', prefix: 'Rp '),
            validator: _nominal,
          ),
          const SizedBox(height: 12),
          SegmentedButton<PeriodeIuran>(
            segments: [
              for (final p in PeriodeIuran.values)
                ButtonSegment(value: p, label: Text(p.label)),
            ],
            selected: {_periode},
            onSelectionChanged: (s) => setState(() => _periode = s.first),
          ),
          if (periodik) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _jumlah,
              keyboardType: TextInputType.number,
              inputFormatters: _hanyaAngka,
              decoration: _dekor(
                _periode == PeriodeIuran.mingguan
                    ? 'Jumlah minggu'
                    : 'Jumlah bulan',
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n < 1 || n > 52) ? 'Isi 1 sampai 52' : null;
              },
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pilihTanggal,
            icon: const Icon(Icons.event_outlined),
            label: Text(
              periodik
                  ? 'Tenggat pertama: ${tanggal(_tenggat)}'
                  : 'Tenggat: ${tanggal(_tenggat)}',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _simpan, child: const Text('Buat Iuran')),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- Pembayaran --

Future<void> showPembayaranSheet(
  BuildContext context, {
  required KasPeriodModel iuran,
  required UserModel anggota,
}) =>
    _showSheet(context, _PembayaranForm(iuran: iuran, anggota: anggota));

class _PembayaranForm extends StatefulWidget {
  const _PembayaranForm({required this.iuran, required this.anggota});

  final KasPeriodModel iuran;
  final UserModel anggota;

  @override
  State<_PembayaranForm> createState() => _PembayaranFormState();
}

class _PembayaranFormState extends State<_PembayaranForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nominalCtrl = TextEditingController(
    text: AppScope.of(context)
        .kas
        .sisa(widget.iuran, widget.anggota.id)
        .toString(),
  );

  @override
  void dispose() {
    _nominalCtrl.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    final kas = AppScope.of(context).kas;
    final messenger = ScaffoldMessenger.of(context);
    final error = kas.catatPembayaran(
      iuranId: widget.iuran.id,
      anggotaId: widget.anggota.id,
      nominal: int.parse(_nominalCtrl.text),
    );
    if (error != null) {
      snack(messenger, error, error: true);
      return;
    }
    Navigator.pop(context);
    snack(messenger, 'Pembayaran ${widget.anggota.nama} dicatat.');
  }

  @override
  Widget build(BuildContext context) {
    final kas = AppScope.of(context).kas;
    final sisa = kas.sisa(widget.iuran, widget.anggota.id);
    final text = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Catat Pembayaran', style: text.titleLarge),
          const SizedBox(height: 8),
          Text(widget.anggota.nama, style: text.titleMedium),
          Text(
            '${widget.iuran.namaTagihan} • sisa ${rupiah(sisa)}',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nominalCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: _hanyaAngka,
            decoration: _dekor('Nominal dibayar', prefix: 'Rp '),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              if (n == null || n <= 0) return 'Masukkan nominal lebih dari 0';
              if (n > sisa) return 'Melebihi sisa tagihan (${rupiah(sisa)})';
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Isi lebih kecil dari sisa untuk pembayaran sebagian.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _simpan, child: const Text('Simpan')),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ Anggota --

Future<void> showAnggotaSheet(BuildContext context, {UserModel? initial}) =>
    _showSheet(context, _AnggotaForm(initial: initial));

class _AnggotaForm extends StatefulWidget {
  const _AnggotaForm({this.initial});

  final UserModel? initial;

  @override
  State<_AnggotaForm> createState() => _AnggotaFormState();
}

class _AnggotaFormState extends State<_AnggotaForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nim = TextEditingController(text: widget.initial?.nim);
  late final _nama = TextEditingController(text: widget.initial?.nama);

  @override
  void dispose() {
    _nim.dispose();
    _nama.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    final kas = AppScope.of(context).kas;
    final messenger = ScaffoldMessenger.of(context);
    final initial = widget.initial;
    final error = initial == null
        ? kas.tambahAnggota(nim: _nim.text, nama: _nama.text)
        : kas.ubahAnggota(id: initial.id, nim: _nim.text, nama: _nama.text);
    if (error != null) {
      snack(messenger, error, error: true);
      return;
    }
    Navigator.pop(context);
    snack(messenger, initial == null ? 'Anggota ditambahkan.' : 'Data disimpan.');
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            editing ? 'Ubah Anggota' : 'Anggota Baru',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nim,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: _hanyaAngka,
            decoration: _dekor('NIM'),
            validator: (v) => (v == null || v.trim().length < 3)
                ? 'NIM minimal 3 digit'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nama,
            textCapitalization: TextCapitalization.words,
            decoration: _dekor('Nama lengkap'),
            validator: (v) => _wajib(v, 'Nama'),
            onFieldSubmitted: (_) => _simpan(),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _simpan,
            child: Text(editing ? 'Simpan' : 'Tambah'),
          ),
        ],
      ),
    );
  }
}
