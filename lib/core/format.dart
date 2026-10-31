/// Format angka rupiah tanpa package intl, contoh: 150000 -> "Rp 150.000".
String rupiah(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-Rp ' : 'Rp ');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String namaBulanPendek(int month) => _bulan[month - 1];

/// Contoh: 5 Nov 2026
String tanggal(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';
