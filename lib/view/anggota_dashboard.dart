import 'package:flutter/material.dart';

import '../app_scope.dart';
import 'widgets/common.dart';
import 'widgets/dashboard_shell.dart';
import 'widgets/lists.dart';

/// Dashboard Anggota: status iuran pribadi, riwayat pembayaran (di detail
/// iuran), saldo kas, dan rincian pengeluaran.
class AnggotaDashboardPage extends StatelessWidget {
  const AnggotaDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AppScope.of(context).auth.currentUser?.id ?? '';

    return DashboardShell(
      title: 'Kas Kelas',
      tampilkanTunggakan: false,
      tabs: const [Tab(text: 'Iuran Saya'), Tab(text: 'Pengeluaran Kas')],
      views: [
        IuranListView(
          emptyMessage: 'Belum ada iuran.',
          trailingBuilder: (context, kas, iuran) =>
              bayarBadge(kas.statusBayar(iuran, userId), iuran),
        ),
        TransactionListView(
          select: (kas) => kas.pengeluaran,
          emptyMessage: 'Belum ada pengeluaran kas.',
        ),
      ],
    );
  }
}
