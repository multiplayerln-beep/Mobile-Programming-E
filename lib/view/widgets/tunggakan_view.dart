import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import 'common.dart';

/// Rekap tunggakan per mahasiswa. Tunggakan = sisa tagihan pada iuran yang
/// sudah lewat tenggat. Hijau = tidak ada tunggakan, merah = menunggak.
class TunggakanView extends StatelessWidget {
  const TunggakanView({super.key});

  @override
  Widget build(BuildContext context) {
    final kas = AppScope.of(context).kas;
    return ListenableBuilder(
      listenable: kas,
      builder: (context, _) {
        final list = kas.daftarTunggakan;
        if (list.isEmpty) return const EmptyState('Belum ada anggota.');
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: list.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${kas.jumlahMenunggak} dari ${list.length} mahasiswa '
                  'menunggak',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              );
            }
            final t = list[i - 1];
            final lunas = t.total == 0;
            final warna = lunas ? Colors.green : Colors.red;
            return Card.outlined(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: warna.shade100,
                  foregroundColor: warna.shade800,
                  child: Icon(lunas ? Icons.check : Icons.warning_amber_rounded),
                ),
                title: Text(t.anggota.nama),
                subtitle: Text(
                  lunas
                      ? 'NIM ${t.anggota.nim} • tidak ada tunggakan'
                      : 'NIM ${t.anggota.nim} • ${t.jumlahIuran} iuran menunggak',
                ),
                trailing: Text(
                  lunas ? 'Lunas' : rupiah(t.total),
                  style: TextStyle(
                    color: warna.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
