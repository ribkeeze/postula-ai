import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource _datasource;

  ProfileRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, UserProfile>> getProfile(String userId) async {
    try {
      final profile = await _datasource.getProfile(userId);
      if (profile == null) return const Left(NotFoundFailure());
      return Right(profile);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> saveProfile(UserProfile profile) async {
    try {
      await _datasource.saveProfile(profile);
      return const Right(null);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> isProfileComplete(String userId) async {
    try {
      final profile = await _datasource.getProfile(userId);
      return Right(profile?.isComplete ?? false);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
