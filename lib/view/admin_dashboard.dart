import 'package:flutter/material.dart';

import 'widgets/anggota_view.dart';
import 'widgets/dashboard_shell.dart';
import 'widgets/forms.dart';
import 'widgets/grafik_view.dart';
import 'widgets/lists.dart';
import 'widgets/riwayat_view.dart';
import 'widgets/tunggakan_view.dart';

/// Dashboard Bendahara: kelola anggota & iuran, catat pembayaran dan mutasi.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Bendahara',
      tabs: const [
        Tab(text: 'Iuran'),
        Tab(text: 'Riwayat'),
        Tab(text: 'Tunggakan'),
        Tab(text: 'Grafik'),
        Tab(text: 'Anggota'),
      ],
      views: const [
        IuranListView(
          emptyMessage: 'Belum ada iuran.\nBuat lewat tombol "Iuran baru".',
          trailingBuilder: rekapTrailing,
        ),
        RiwayatView(editable: true),
        TunggakanView(),
        GrafikView(),
        AnggotaView(),
      ],
      fabs: [
        FloatingActionButton.extended(
          onPressed: () => showIuranSheet(context),
          icon: const Icon(Icons.add),
          label: const Text('Iuran baru'),
        ),
        FloatingActionButton.extended(
          onPressed: () => showTransaksiSheet(context),
          icon: const Icon(Icons.add),
          label: const Text('Transaksi'),
        ),
        null,
        null,
        FloatingActionButton.extended(
          onPressed: () => showAnggotaSheet(context),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Anggota'),
        ),
      ],
    );
  }
}
