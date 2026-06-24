import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class GetProfile {
  final ProfileRepository repository;
  GetProfile(this.repository);

  Future<Either<Failure, UserProfile>> call(String userId) =>
      repository.getProfile(userId);
}

class SaveProfile {
  final ProfileRepository repository;
  SaveProfile(this.repository);

  Future<Either<Failure, void>> call(UserProfile profile) =>
      repository.saveProfile(profile);
}

class IsProfileComplete {
  final ProfileRepository repository;
  IsProfileComplete(this.repository);

  Future<Either<Failure, bool>> call(String userId) =>
      repository.isProfileComplete(userId);
}
