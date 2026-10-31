import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../core/format.dart';
import '../model/kas_period_model.dart';
import '../model/user_model.dart';
import '../viewmodel/kas_viewmodel.dart';
import 'widgets/common.dart';
import 'widgets/forms.dart';

/// Detail satu iuran.
///  * Anggota: status dan riwayat pembayaran miliknya.
///  * Bendahara: rekap seluruh anggota + catat pembayaran (penuh / sebagian).
///  * Pengawas: rekap seluruh anggota (read-only).
class HalamanDetailIuran extends StatelessWidget {
  const HalamanDetailIuran({super.key, required this.iuran});

  final KasPeriodModel iuran;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final user = scope.auth.currentUser;
    final kas = scope.kas;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Iuran')),
      body: user == null
          ? const SizedBox.shrink()
          : ListenableBuilder(
              listenable: kas,
              builder: (context, _) {
                final anggota = user.role == UserRole.anggota;
                return Column(
                  children: [
                    _Header(iuran: iuran, kas: kas, tampilkanProgress: !anggota),
                    Expanded(
                      child: anggota
                          ? _StatusSaya(iuran: iuran, kas: kas, user: user)
                          : _RekapAnggota(
                              iuran: iuran,
                              kas: kas,
                              bisaCatat: user.role == UserRole.admin,
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.iuran,
    required this.kas,
    required this.tampilkanProgress,
  });

  final KasPeriodModel iuran;
  final KasViewModel kas;
  final bool tampilkanProgress;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total = kas.anggota.length;
    final lunas = kas.jumlahLunas(iuran);
    final target = iuran.nominal * total;
    final terkumpul = kas.terkumpul(iuran.id);

    return Card.outlined(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              iuran.namaTagihan,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _Baris(Icons.payments_outlined, rupiah(iuran.nominal)),
            const SizedBox(height: 4),
            _Baris(
              Icons.event_outlined,
              'Tenggat ${tanggal(iuran.tglTenggat)}'
              '${iuran.lewatTenggat ? ' (lewat)' : ''}',
            ),
            if (tampilkanProgress) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: target == 0 ? 0 : terkumpul / target,
              ),
              const SizedBox(height: 6),
              Text(
                '$lunas dari $total mahasiswa lunas • '
                'terkumpul ${rupiah(terkumpul)} dari ${rupiah(target)}',
                style: text.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  const _Baris(this.icon, this.teks);

  final IconData icon;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 8),
        Expanded(child: Text(teks)),
      ],
    );
  }
}

class _StatusSaya extends StatelessWidget {
  const _StatusSaya({
    required this.iuran,
    required this.kas,
    required this.user,
  });

  final KasPeriodModel iuran;
  final KasViewModel kas;
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final status = kas.statusBayar(iuran, user.id);
    final riwayat = kas.pembayaran(iuran.id, user.id);
    final sisa = kas.sisa(iuran, user.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                bayarBadge(status, iuran),
                const SizedBox(height: 12),
                Text(
                  'Sudah dibayar ${rupiah(kas.dibayar(iuran.id, user.id))} '
                  'dari ${rupiah(iuran.nominal)}',
                  textAlign: TextAlign.center,
                  style: text.bodyLarge,
                ),
                if (sisa > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Sisa ${rupiah(sisa)}. Serahkan ke bendahara; '
                    'pembayaran dicatat oleh bendahara.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Riwayat pembayaran', style: text.titleMedium),
        const SizedBox(height: 8),
        if (riwayat.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Belum ada pembayaran untuk iuran ini.'),
          )
        else
          for (final tx in riwayat)
            Card.outlined(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(rupiah(tx.nominal)),
                subtitle: Text(tanggal(tx.tglTransaksi)),
              ),
            ),
      ],
    );
  }
}

class _RekapAnggota extends StatelessWidget {
  const _RekapAnggota({
    required this.iuran,
    required this.kas,
    required this.bisaCatat,
  });

  final KasPeriodModel iuran;
  final KasViewModel kas;
  final bool bisaCatat;

  @override
  Widget build(BuildContext context) {
    final list = kas.anggota;
    final text = Theme.of(context).textTheme;
    if (list.isEmpty) return const EmptyState('Belum ada anggota.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            bisaCatat
                ? 'Status pembayaran • ketuk nama untuk mencatat'
                : 'Status pembayaran',
            style: text.titleSmall,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final a = list[i];
              final status = kas.statusBayar(iuran, a.id);
              return Card.outlined(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: bisaCatat && status != StatusBayar.lunas
                      ? () => showPembayaranSheet(
                            context,
                            iuran: iuran,
                            anggota: a,
                          )
                      : null,
                  leading: CircleAvatar(child: Text(a.nama[0].toUpperCase())),
                  title: Text(a.nama),
                  subtitle: Text(
                    '${rupiah(kas.dibayar(iuran.id, a.id))} / '
                    '${rupiah(iuran.nominal)}',
                  ),
                  trailing: bayarBadge(status, iuran),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
