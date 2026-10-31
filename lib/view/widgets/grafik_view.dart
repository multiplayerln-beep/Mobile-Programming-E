import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../viewmodel/kas_viewmodel.dart';

/// Visualisasi kas: pemasukan vs pengeluaran per bulan dan komposisi
/// pengeluaran per kategori. Digambar dengan CustomPaint (tanpa package).
class GrafikView extends StatelessWidget {
  const GrafikView({super.key});

  @override
  Widget build(BuildContext context) {
    final kas = AppScope.of(context).kas;
    return ListenableBuilder(
      listenable: kas,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _Kartu(
            judul: 'Pemasukan vs Pengeluaran',
            subjudul: '6 bulan terakhir',
            child: _BarSection(data: kas.ringkasanBulanan),
          ),
          const SizedBox(height: 12),
          _Kartu(
            judul: 'Komposisi Pengeluaran',
            subjudul: 'Berdasarkan kategori',
            child: _PieSection(data: kas.pengeluaranPerKategori),
          ),
        ],
      ),
    );
  }
}

class _Kartu extends StatelessWidget {
  const _Kartu({
    required this.judul,
    required this.subjudul,
    required this.child,
  });

  final String judul;
  final String subjudul;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(judul, style: text.titleMedium),
            Text(subjudul, style: text.bodySmall),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

final _warnaMasuk = Colors.green.shade600;
final _warnaKeluar = Colors.red.shade400;

class _Legenda extends StatelessWidget {
  const _Legenda(this.warna, this.label);

  final Color warna;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

// ---------------------------------------------------------------- Bar chart --

class _BarSection extends StatelessWidget {
  const _BarSection({required this.data});

  final List<BulanRingkasan> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maks = data.fold<int>(
      0,
      (m, d) => math.max(m, math.max(d.masuk, d.keluar)),
    );
    if (maks == 0) {
      return Text(
        'Belum ada transaksi pada 6 bulan terakhir.',
        style: TextStyle(color: cs.onSurfaceVariant),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          children: [
            _Legenda(_warnaMasuk, 'Pemasukan'),
            _Legenda(_warnaKeluar, 'Pengeluaran'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Skala maksimum ${rupiah(maks)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          width: double.infinity,
          child: CustomPaint(
            painter: _BarPainter(
              data: data,
              masuk: _warnaMasuk,
              keluar: _warnaKeluar,
              teks: cs.onSurfaceVariant,
              garis: cs.outlineVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.data,
    required this.masuk,
    required this.keluar,
    required this.teks,
    required this.garis,
  });

  final List<BulanRingkasan> data;
  final Color masuk;
  final Color keluar;
  final Color teks;
  final Color garis;

  @override
  void paint(Canvas canvas, Size size) {
    const bawah = 22.0;
    const atas = 8.0;
    final tinggi = size.height - bawah - atas;
    final dasar = atas + tinggi;
    final maks = data.fold<int>(
      0,
      (m, d) => math.max(m, math.max(d.masuk, d.keluar)),
    );
    if (maks == 0 || data.isEmpty) return;

    final skala = tinggi / maks;
    final lebarGrup = size.width / data.length;
    final lebarBatang = lebarGrup * 0.28;

    canvas.drawLine(
      Offset(0, dasar),
      Offset(size.width, dasar),
      Paint()
        ..color = garis
        ..strokeWidth = 1,
    );

    for (var i = 0; i < data.length; i++) {
      final tengah = lebarGrup * i + lebarGrup / 2;
      final d = data[i];
      _batang(canvas, tengah - lebarBatang - 1, dasar, lebarBatang,
          d.masuk * skala, masuk);
      _batang(canvas, tengah + 1, dasar, lebarBatang, d.keluar * skala, keluar);

      final tp = TextPainter(
        text: TextSpan(
          text: d.label,
          style: TextStyle(fontSize: 11, color: teks),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: lebarGrup);
      tp.paint(canvas, Offset(tengah - tp.width / 2, dasar + 4));
    }
  }

  void _batang(Canvas canvas, double x, double dasar, double lebar,
      double tinggi, Color warna) {
    if (tinggi <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(x, dasar - tinggi, lebar, tinggi),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      ),
      Paint()..color = warna,
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.data != data ||
      old.masuk != masuk ||
      old.keluar != keluar ||
      old.teks != teks ||
      old.garis != garis;
}

// ---------------------------------------------------------------- Pie chart --

const _palet = [
  Color(0xFF00897B),
  Color(0xFFF4511E),
  Color(0xFF3949AB),
  Color(0xFFD81B60),
  Color(0xFF8E24AA),
  Color(0xFF6D4C41),
  Color(0xFF7CB342),
];

class _PieSection extends StatelessWidget {
  const _PieSection({required this.data});

  final List<KategoriTotal> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final total = data.fold<int>(0, (s, e) => s + e.total);
    if (total == 0) {
      return Text(
        'Belum ada pengeluaran.',
        style: TextStyle(color: cs.onSurfaceVariant),
      );
    }

    // Maksimal 6 irisan; sisanya digabung menjadi "Lainnya".
    final tampil = data.length <= 6
        ? data
        : [
            ...data.take(5),
            KategoriTotal(
              'Lainnya',
              data.skip(5).fold<int>(0, (s, e) => s + e.total),
            ),
          ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: CustomPaint(
            painter: _PiePainter(tampil.map((e) => e.total).toList()),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < tampil.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 4, right: 8),
                        decoration: BoxDecoration(
                          color: _palet[i % _palet.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tampil[i].kategori,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium,
                            ),
                            Text(
                              '${(tampil[i].total * 100 / total).round()}% • '
                              '${rupiah(tampil[i].total)}',
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter(this.nilai);

  final List<int> nilai;

  @override
  void paint(Canvas canvas, Size size) {
    final total = nilai.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;
    final tebal = size.shortestSide * 0.28;
    final area = (Offset.zero & size).deflate(tebal / 2);
    var mulai = -math.pi / 2;
    for (var i = 0; i < nilai.length; i++) {
      final sapuan = 2 * math.pi * nilai[i] / total;
      canvas.drawArc(
        area,
        mulai,
        sapuan,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = tebal
          ..color = _palet[i % _palet.length],
      );
      mulai += sapuan;
    }
  }

  @override
  bool shouldRepaint(_PiePainter old) => !listEquals(old.nilai, nilai);
}
