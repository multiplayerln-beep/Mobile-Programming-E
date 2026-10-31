import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../model/kas_period_model.dart';
import '../../model/transaction_model.dart';
import '../../viewmodel/kas_viewmodel.dart';
import '../halaman_detail_iuran.dart';
import 'common.dart';

typedef TransactionSelector = List<TransactionModel> Function(KasViewModel kas);
typedef IuranTrailingBuilder = Widget? Function(
  BuildContext context,
  KasViewModel kas,
  KasPeriodModel iuran,
);

/// Daftar transaksi sederhana (dipakai anggota untuk melihat pengeluaran).
class TransactionListView extends StatelessWidget {
  const TransactionListView({
    super.key,
    required this.select,
    required this.emptyMessage,
  });

  final TransactionSelector select;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final kas = AppScope.of(context).kas;
    return ListenableBuilder(
      listenable: kas,
      builder: (context, _) {
        final list = select(kas);
        if (list.isEmpty) return EmptyState(emptyMessage);
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: list.length,
          itemBuilder: (context, i) =>
              TransactionTile(key: ValueKey(list[i].id), tx: list[i]),
        );
      },
    );
  }
}

/// Daftar program iuran; tap membuka halaman detail.
class IuranListView extends StatelessWidget {
  const IuranListView({
    super.key,
    required this.emptyMessage,
    this.trailingBuilder,
  });

  final String emptyMessage;
  final IuranTrailingBuilder? trailingBuilder;

  @override
  Widget build(BuildContext context) {
    final kas = AppScope.of(context).kas;
    return ListenableBuilder(
      listenable: kas,
      builder: (context, _) {
        final list = kas.iuran;
        if (list.isEmpty) return EmptyState(emptyMessage);
        return ListView.builder(
          padding: kListPadding,
          itemCount: list.length,
          itemBuilder: (context, i) {
            final iuran = list[i];
            return IuranTile(
              key: ValueKey(iuran.id),
              iuran: iuran,
              trailing: trailingBuilder?.call(context, kas, iuran),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => HalamanDetailIuran(iuran: iuran),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Trailing "2/4" untuk Bendahara & Pengawas.
Widget rekapTrailing(
  BuildContext context,
  KasViewModel kas,
  KasPeriodModel iuran,
) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '${kas.jumlahLunas(iuran)}/${kas.anggota.length}',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      const SizedBox(width: 4),
      const Icon(Icons.chevron_right),
    ],
  );
}
