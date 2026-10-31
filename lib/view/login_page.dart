import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/demo_data.dart';
import 'registrasi_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nim = TextEditingController();
  final _sandi = TextEditingController();
  bool _lihat = false;
  String? _error;

  @override
  void dispose() {
    _nim.dispose();
    _sandi.dispose();
    super.dispose();
  }

  void _login() {
    final error = AppScope.of(context).auth.login(_nim.text, _sandi.text);
    // Jika berhasil, halaman ini otomatis diganti dashboard sesuai peran.
    if (error != null) setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final demo = auth.users
        .where((u) => u.punyaAkun && DemoData.demoNims.contains(u.nim))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: cs.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kas Kelas',
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Masuk dengan NIM dan kata sandi',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _nim,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    decoration: const InputDecoration(
                      labelText: 'NIM',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _sandi,
                    obscureText: !_lihat,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    decoration: InputDecoration(
                      labelText: 'Kata sandi',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      errorText: _error,
                      suffixIcon: IconButton(
                        tooltip: _lihat ? 'Sembunyikan' : 'Tampilkan',
                        icon: Icon(
                          _lihat ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _lihat = !_lihat),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _login,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('Masuk'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const RegistrasiPage(),
                      ),
                    ),
                    child: const Text('Belum punya akun? Registrasi'),
                  ),
                  if (demo.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Akun demo (sandi: ${DemoData.demoPassword})',
                      style: text.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final u in demo)
                          ActionChip(
                            label: Text('${u.nama} (${u.role.label})'),
                            onPressed: () => setState(() {
                              _nim.text = u.nim;
                              _sandi.text = DemoData.demoPassword;
                              _error = null;
                            }),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
