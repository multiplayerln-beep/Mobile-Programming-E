import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../model/user_model.dart';
import '../../viewmodel/kas_viewmodel.dart';
import 'common.dart';
import 'forms.dart';

/// Kelola anggota kelas (khusus bendahara).
class AnggotaView extends StatelessWidget {
  const AnggotaView({super.key});

  Future<void> _hapus(
    BuildContext context,
    KasViewModel kas,
    UserModel a,
  ) async {
    final ok = await konfirmasi(
      context,
      judul: 'Hapus anggota?',
      pesan: '${a.nama} (${a.nim}) akan dihapus dari daftar kelas.',
      ya: 'Hapus',
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final error = kas.hapusAnggota(a.id);
    snack(messenger, error ?? 'Anggota dihapus.', error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final kas = AppScope.of(context).kas;
    return ListenableBuilder(
      listenable: kas,
      builder: (context, _) {
        final list = kas.anggota;
        if (list.isEmpty) {
          return const EmptyState('Belum ada anggota.\nTambah lewat tombol "Anggota".');
        }
        return ListView.builder(
          padding: kListPadding,
          itemCount: list.length,
          itemBuilder: (context, i) {
            final a = list[i];
            return Card.outlined(
              key: ValueKey(a.id),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(child: Text(a.nama[0].toUpperCase())),
                title: Text(a.nama),
                subtitle: Text(
                  'NIM ${a.nim} • ${a.punyaAkun ? 'akun aktif' : 'belum registrasi'}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'ubah') {
                      showAnggotaSheet(context, initial: a);
                    } else {
                      _hapus(context, kas, a);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'ubah', child: Text('Ubah')),
                    PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
