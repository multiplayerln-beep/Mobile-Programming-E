import 'package:flutter/material.dart';

import 'widgets/dashboard_shell.dart';
import 'widgets/grafik_view.dart';
import 'widgets/lists.dart';
import 'widgets/riwayat_view.dart';
import 'widgets/tunggakan_view.dart';

/// Dashboard Pengawas: hanya melihat (read-only) seluruh data kas.
class PengawasDashboardPage extends StatelessWidget {
  const PengawasDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardShell(
      title: 'Pengawas',
      tabs: [
        Tab(text: 'Iuran'),
        Tab(text: 'Riwayat'),
        Tab(text: 'Tunggakan'),
        Tab(text: 'Grafik'),
      ],
      views: [
        IuranListView(
          emptyMessage: 'Belum ada iuran.',
          trailingBuilder: rekapTrailing,
        ),
        RiwayatView(),
        TunggakanView(),
        GrafikView(),
      ],
    );
  }
}
