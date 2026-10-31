import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../model/transaction_model.dart';
import '../../viewmodel/kas_viewmodel.dart';
import 'common.dart';
import 'forms.dart';

class RiwayatFilter {
  const RiwayatFilter({this.tipe, this.kategori, this.dari, this.sampai});

  final TransactionType? tipe;
  final String? kategori;
  final DateTime? dari;
  final DateTime? sampai;

  bool get aktif => tipe != null || kategori != null || dari != null;
}

/// Riwayat transaksi dengan pencarian dan filter (jenis, kategori, tanggal).
/// Bila [editable], bendahara dapat mengubah / menghapus transaksi.
class RiwayatView extends StatefulWidget {
  const RiwayatView({super.key, this.editable = false});

  final bool editable;

  @override
  State<RiwayatView> createState() => _RiwayatViewState();
}

class _RiwayatViewState extends State<RiwayatView>
    with AutomaticKeepAliveClientMixin {
  final _query = TextEditingController();
  RiwayatFilter _filter = const RiwayatFilter();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _bukaFilter(KasViewModel kas) async {
    final hasil = await showModalBottomSheet<RiwayatFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(awal: _filter, kategori: kas.daftarKategori),
    );
    if (hasil != null && mounted) setState(() => _filter = hasil);
  }

  Widget? _footer(BuildContext context, KasViewModel kas, TransactionModel tx) {
    if (!widget.editable) return null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (kas.bisaDiubah(tx))
          TextButton.icon(
            onPressed: () => showTransaksiSheet(context, initial: tx),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Ubah'),
          ),
        TextButton.icon(
          onPressed: () => _hapus(context, kas, tx),
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Hapus'),
        ),
      ],
    );
  }

  Future<void> _hapus(
    BuildContext context,
    KasViewModel kas,
    TransactionModel tx,
  ) async {
    final ok = await konfirmasi(
      context,
      judul: 'Hapus transaksi?',
      pesan: '${tx.kategori} • ${rupiah(tx.nominal)} akan dihapus.',
      ya: 'Hapus',
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final error = kas.hapusTransaksi(tx.id);
    snack(messenger, error ?? 'Transaksi dihapus.', error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final kas = AppScope.of(context).kas;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari kategori, keterangan, atau nama',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _query.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(_query.clear),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Filter',
                onPressed: () => _bukaFilter(kas),
                icon: Badge(
                  isLabelVisible: _filter.aktif,
                  child: const Icon(Icons.tune),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: kas,
            builder: (context, _) {
              final list = kas.filter(
                query: _query.text,
                tipe: _filter.tipe,
                kategori: _filter.kategori,
                dari: _filter.dari,
                sampai: _filter.sampai,
              );
              if (list.isEmpty) {
                return const EmptyState('Tidak ada transaksi yang cocok.');
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Text(
                      '${list.length} transaksi',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: list.length,
                      itemBuilder: (context, i) => TransactionTile(
                        key: ValueKey(list[i].id),
                        tx: list[i],
                        footer: _footer(context, kas, list[i]),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.awal, required this.kategori});

  final RiwayatFilter awal;
  final List<String> kategori;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late TransactionType? _tipe = widget.awal.tipe;
  late String? _kategori = widget.awal.kategori;
  late DateTime? _dari = widget.awal.dari;
  late DateTime? _sampai = widget.awal.sampai;

  Future<void> _pilihRentang() async {
    final now = DateTime.now();
    final hasil = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _dari == null || _sampai == null
          ? null
          : DateTimeRange(start: _dari!, end: _sampai!),
    );
    if (hasil != null && mounted) {
      setState(() {
        _dari = hasil.start;
        _sampai = hasil.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter Riwayat', style: text.titleLarge),
            const SizedBox(height: 16),
            Text('Jenis', style: text.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _tipe == null,
                  onSelected: (_) => setState(() => _tipe = null),
                ),
                for (final t in TransactionType.values)
                  ChoiceChip(
                    label: Text(t.label),
                    selected: _tipe == t,
                    onSelected: (_) => setState(() => _tipe = t),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Kategori', style: text.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _kategori == null,
                  onSelected: (_) => setState(() => _kategori = null),
                ),
                for (final k in widget.kategori)
                  ChoiceChip(
                    label: Text(k),
                    selected: _kategori == k,
                    onSelected: (_) => setState(() => _kategori = k),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Tanggal', style: text.labelLarge),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pilihRentang,
              icon: const Icon(Icons.date_range_outlined),
              label: Text(
                _dari == null || _sampai == null
                    ? 'Semua tanggal'
                    : '${tanggal(_dari!)} – ${tanggal(_sampai!)}',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, const RiwayatFilter()),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      RiwayatFilter(
                        tipe: _tipe,
                        kategori: _kategori,
                        dari: _dari,
                        sampai: _sampai,
                      ),
                    ),
                    child: const Text('Terapkan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
