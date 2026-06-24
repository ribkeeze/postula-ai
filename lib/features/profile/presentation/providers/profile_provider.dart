import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/profile_usecases.dart';

part 'profile_provider.g.dart';

@Riverpod(keepAlive: true)
ProfileRepositoryImpl profileRepository(Ref ref) {
  return ProfileRepositoryImpl(ProfileRemoteDatasourceImpl());
}

/// Perfil del usuario actual — se mantiene vivo toda la sesión.
@Riverpod(keepAlive: true)
Future<UserProfile?> userProfile(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final repo = ref.watch(profileRepositoryProvider);
  final result = await GetProfile(repo).call(user.uid);
  return result.fold((_) => null, (p) => p);
}

/// Notifier para editar y guardar el perfil.
@Riverpod(keepAlive: true)
class ProfileNotifier extends _$ProfileNotifier {
  @override
  AsyncValue<UserProfile?> build() {
    final profile = ref.watch(userProfileProvider);
    return profile.when(
      data: AsyncValue.data,
      loading: () => const AsyncValue.loading(),
      error: AsyncValue.error,
    );
  }

  Future<Either<Failure, void>> save(UserProfile profile) async {
    final repo = ref.read(profileRepositoryProvider);
    final result = await SaveProfile(repo).call(profile);
    if (result.isRight()) {
      ref.invalidate(userProfileProvider);
    }
    return result;
  }
}
