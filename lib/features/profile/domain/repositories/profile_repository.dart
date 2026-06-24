import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserProfile>> getProfile(String userId);
  Future<Either<Failure, void>> saveProfile(UserProfile profile);
  Future<Either<Failure, bool>> isProfileComplete(String userId);
}
