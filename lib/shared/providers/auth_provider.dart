import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

/// Stream del estado de autenticación de Firebase.
/// keepAlive: true — siempre activo, toda la app depende de este provider.
@Riverpod(keepAlive: true)
Stream<User?> authState(Ref ref) {
  return FirebaseAuth.instance.authStateChanges();
}

/// Usuario actual (puede ser null si no está autenticado).
@Riverpod(keepAlive: true)
User? currentUser(Ref ref) {
  return ref.watch(authStateProvider).asData?.value;
}

/// Notifier para operaciones de autenticación.
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await FirebaseAuth.instance.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
