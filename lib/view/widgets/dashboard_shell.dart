import 'package:flutter/material.dart';

import '../../app_scope.dart';
import 'common.dart';

/// Kerangka dashboard untuk semua peran: AppBar + kartu saldo + tab.
/// [fabs] opsional, satu per tab (null = tanpa tombol di tab itu).
class DashboardShell extends StatefulWidget {
  const DashboardShell({
    super.key,
    required this.title,
    required this.tabs,
    required this.views,
    this.fabs,
    this.tampilkanTunggakan = true,
  });

  final String title;
  final List<Tab> tabs;
  final List<Widget> views;
  final List<Widget?>? fabs;
  final bool tampilkanTunggakan;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  final ValueNotifier<int> _index = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    assert(widget.tabs.length == widget.views.length);
    _controller = TabController(length: widget.tabs.length, vsync: this)
      ..addListener(() => _index.value = _controller.index);
  }

  @override
  void dispose() {
    _controller.dispose();
    _index.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    final user = auth.currentUser;
    final fabs = widget.fabs;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            if (user != null)
              Text(
                '${user.nama} • ${user.role.label}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final ok = await konfirmasi(
                context,
                judul: 'Keluar?',
                pesan: 'Kamu akan kembali ke halaman login.',
                ya: 'Keluar',
              );
              if (ok) auth.logout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SaldoCard(tampilkanTunggakan: widget.tampilkanTunggakan),
          TabBar(
            controller: _controller,
            tabs: widget.tabs,
            isScrollable: widget.tabs.length > 3,
          ),
          Expanded(
            child: TabBarView(controller: _controller, children: widget.views),
          ),
        ],
      ),
      floatingActionButton: fabs == null
          ? null
          : ValueListenableBuilder<int>(
              valueListenable: _index,
              builder: (context, i, _) => fabs[i] ?? const SizedBox.shrink(),
            ),
    );
  }
}
