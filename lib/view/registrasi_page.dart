import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../model/user_model.dart';

class RegistrasiPage extends StatefulWidget {
  const RegistrasiPage({super.key});

  @override
  State<RegistrasiPage> createState() => _RegistrasiPageState();
}

class _RegistrasiPageState extends State<RegistrasiPage> {
  final _formKey = GlobalKey<FormState>();
  final _nim = TextEditingController();
  final _nama = TextEditingController();
  final _sandi = TextEditingController();
  final _ulangi = TextEditingController();
  UserRole _peran = UserRole.anggota;
  bool _lihat = false;
  String? _error;

  @override
  void dispose() {
    _nim.dispose();
    _nama.dispose();
    _sandi.dispose();
    _ulangi.dispose();
    super.dispose();
  }

  void _daftar() {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final error = AppScope.of(context).auth.registrasi(
          nim: _nim.text,
          nama: _nama.text,
          password: _sandi.text,
          role: _peran,
        );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    // Akun langsung masuk; halaman utama otomatis menampilkan dashboard.
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    final tersedia = auth.peranTersedia;
    final peran = tersedia.contains(_peran) ? _peran : UserRole.anggota;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrasi')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Daftar sebagai', style: text.labelLarge),
                    const SizedBox(height: 8),
                    SegmentedButton<UserRole>(
                      segments: [
                        for (final r in tersedia)
                          ButtonSegment(value: r, label: Text(r.label)),
                      ],
                      selected: {peran},
                      onSelectionChanged: (s) => setState(() {
                        _peran = s.first;
                        _error = null;
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      peran == UserRole.anggota
                          ? 'Jika NIM sudah didaftarkan bendahara, akunmu '
                              'akan diaktifkan.'
                          : 'Hanya satu akun ${peran.label} per kelas.',
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nim,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(20),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'NIM',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? 'NIM minimal 3 digit'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nama,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama lengkap',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sandi,
                      obscureText: !_lihat,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Kata sandi (min. 6 karakter)',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _lihat ? 'Sembunyikan' : 'Tampilkan',
                          icon: Icon(
                            _lihat ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _lihat = !_lihat),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Minimal 6 karakter'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ulangi,
                      obscureText: !_lihat,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _daftar(),
                      decoration: const InputDecoration(
                        labelText: 'Ulangi kata sandi',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v != _sandi.text ? 'Kata sandi tidak sama' : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _daftar,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('Daftar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
