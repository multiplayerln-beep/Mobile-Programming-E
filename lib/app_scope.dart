import 'package:flutter/widgets.dart';

import 'viewmodel/auth_viewmodel.dart';
import 'viewmodel/kas_viewmodel.dart';

/// Menyediakan ViewModel ke seluruh pohon widget tanpa package tambahan.
/// Objeknya tidak pernah berganti, jadi widget yang butuh pembaruan cukup
/// membungkus diri dengan ListenableBuilder pada ViewModel yang relevan.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.auth,
    required this.kas,
    required super.child,
  });

  final AuthViewModel auth;
  final KasViewModel kas;

  static AppScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope tidak ditemukan di atas widget ini.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
