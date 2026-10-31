import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'data/demo_data.dart';
import 'data/local_store.dart';
import 'model/kas_period_model.dart';
import 'model/transaction_model.dart';
import 'model/user_model.dart';
import 'view/admin_dashboard.dart';
import 'view/anggota_dashboard.dart';
import 'view/login_page.dart';
import 'view/pengawas_dashboard.dart';
import 'viewmodel/auth_viewmodel.dart';
import 'viewmodel/kas_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalStore.open();
  runApp(KasKelasApp(store: store));
}

class KasKelasApp extends StatefulWidget {
  const KasKelasApp({super.key, required this.store});

  final LocalStore store;

  @override
  State<KasKelasApp> createState() => _KasKelasAppState();
}

class _KasKelasAppState extends State<KasKelasApp> {
  late final AuthViewModel _auth;
  late final KasViewModel _kas;

  @override
  void initState() {
    super.initState();
    final store = widget.store;
    final pertamaKali = store.kosong;
    _auth = AuthViewModel(
      users: store.read(LocalStore.kUsers, UserModel.fromJson) ??
          DemoData.users(),
      store: store,
    );
    _kas = KasViewModel(
      auth: _auth,
      iuran: store.read(LocalStore.kIuran, KasPeriodModel.fromJson) ??
          DemoData.iuran(),
      transaksi:
          store.read(LocalStore.kTransaksi, TransactionModel.fromJson) ??
              DemoData.transaksi(),
      store: store,
    );
    if (pertamaKali) {
      _auth.simpan();
      _kas.simpan();
    }
  }

  @override
  void dispose() {
    _kas.dispose();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      auth: _auth,
      kas: _kas,
      child: MaterialApp(
        title: 'Kas Kelas',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        // Halaman ditentukan oleh sesi login; logout otomatis kembali ke login.
        home: ListenableBuilder(
          listenable: _auth,
          builder: (context, _) {
            final user = _auth.currentUser;
            if (user == null) return const LoginPage();
            return switch (user.role) {
              UserRole.admin => AdminDashboardPage(key: ValueKey(user.id)),
              UserRole.pengawas =>
                PengawasDashboardPage(key: ValueKey(user.id)),
              UserRole.anggota => AnggotaDashboardPage(key: ValueKey(user.id)),
            };
          },
        ),
      ),
    );
  }
}
