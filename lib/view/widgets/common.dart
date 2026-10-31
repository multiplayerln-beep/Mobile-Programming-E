import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../model/kas_period_model.dart';
import '../../model/transaction_model.dart';
import '../../viewmodel/kas_viewmodel.dart';

const kListPadding = EdgeInsets.fromLTRB(16, 8, 16, 96);

void snack(ScaffoldMessengerState messenger, String text,
    {bool error = false}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
}

Future<bool> konfirmasi(
  BuildContext context, {
  required String judul,
  required String pesan,
  String ya = 'Ya',
}) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(judul),
      content: Text(pesan),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ya),
        ),
      ],
    ),
  );
  return hasil ?? false;
}

// ------------------------------------------------------------------ Badge --

enum BadgeTone { success, warning, danger, neutral }

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, this.tone, {super.key});

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      BadgeTone.success => (Colors.green.shade100, Colors.green.shade900),
      BadgeTone.warning => (Colors.orange.shade100, Colors.orange.shade900),
      BadgeTone.danger => (Colors.red.shade100, Colors.red.shade900),
      BadgeTone.neutral => (cs.secondaryContainer, cs.onSecondaryContainer),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

/// Hijau = lunas, merah = menunggak (lewat tenggat), oranye = sebagian.
StatusBadge bayarBadge(StatusBayar status, KasPeriodModel iuran) {
  if (status == StatusBayar.lunas) {
    return const StatusBadge('Lunas', BadgeTone.success);
  }
  if (iuran.lewatTenggat) {
    return StatusBadge(
      status == StatusBayar.sebagian ? 'Menunggak (sebagian)' : 'Menunggak',
      BadgeTone.danger,
    );
  }
  return status == StatusBayar.sebagian
      ? const StatusBadge('Sebagian', BadgeTone.warning)
      : const StatusBadge('Belum bayar', BadgeTone.neutral);
}

// ------------------------------------------------------------- Empty state --

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: cs.outline),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- Saldo card --

class SaldoCard extends StatelessWidget {
  const SaldoCard({super.key, this.tampilkanTunggakan = true});

  final bool tampilkanTunggakan;

  @override
  Widget build(BuildContext context) {
    final kas = AppScope.of(context).kas;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: kas,
      builder: (context, _) => Card(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        elevation: 0,
        color: cs.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo kas',
                style: text.labelMedium?.copyWith(color: cs.onPrimaryContainer),
              ),
              const SizedBox(height: 4),
              Text(
                rupiah(kas.saldo),
                style: text.headlineMedium?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Ringkasan(
                      icon: Icons.south_west,
                      label: 'Pemasukan',
                      nilai: kas.totalPemasukan,
                    ),
                  ),
                  Expanded(
                    child: _Ringkasan(
                      icon: Icons.north_east,
                      label: 'Pengeluaran',
                      nilai: kas.totalPengeluaran,
                    ),
                  ),
                ],
              ),
              if (tampilkanTunggakan && kas.totalTunggakan > 0) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Colors.red.shade800,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tunggakan ${rupiah(kas.totalTunggakan)} • '
                        '${kas.jumlahMenunggak} mahasiswa',
                        style: text.labelMedium?.copyWith(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Ringkasan extends StatelessWidget {
  const _Ringkasan({
    required this.icon,
    required this.label,
    required this.nilai,
  });

  final IconData icon;
  final String label;
  final int nilai;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.onPrimaryContainer),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: text.labelSmall?.copyWith(color: cs.onPrimaryContainer),
              ),
              Text(
                rupiah(nilai),
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ Tiles --

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.tx, this.footer});

  final TransactionModel tx;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final masuk = tx.tipe == TransactionType.pemasukan;
    final warna = masuk ? Colors.green.shade700 : cs.error;
    final tanda = masuk ? '+' : '-';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor:
                    masuk ? Colors.green.shade50 : cs.errorContainer,
                foregroundColor: warna,
                child: Icon(masuk ? Icons.south_west : Icons.north_east),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.kategori,
                      style: text.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tx.keterangan.isNotEmpty)
                      Text(
                        tx.keterangan,
                        style: text.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    const SizedBox(height: 4),
                    Text(tanggal(tx.tglTransaksi), style: text.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$tanda${rupiah(tx.nominal)}',
                style: text.titleSmall?.copyWith(
                  color: warna,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: footer,
          ),
        const Divider(height: 1),
      ],
    );
  }
}

class IuranTile extends StatelessWidget {
  const IuranTile({
    super.key,
    required this.iuran,
    required this.onTap,
    this.trailing,
  });

  final KasPeriodModel iuran;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tenggat = 'Tenggat ${tanggal(iuran.tglTenggat)}'
        '${iuran.lewatTenggat ? ' (lewat)' : ''}';

    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.receipt_long_outlined, color: cs.primary),
        title: Text(
          iuran.namaTagihan,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${rupiah(iuran.nominal)} • $tenggat'),
        trailing: trailing ?? const Icon(Icons.chevron_right),
      ),
    );
  }
}
