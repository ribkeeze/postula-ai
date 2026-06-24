import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/job_evaluation.dart';
import '../../domain/repositories/evaluation_repository.dart';
import '../datasources/evaluation_remote_datasource.dart';

class EvaluationRepositoryImpl
    implements EvaluationRepository {
  final EvaluationRemoteDatasource _datasource;
  EvaluationRepositoryImpl(this._datasource);

  //
  @override
  Future<Either<Failure, JobEvaluation>> evaluate(
      String jobText) async {
    try {
      final result = await _datasource.evaluate(jobText);
      return Right(result);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') return const Left(LimitExceededFailure());
      if (e.code == 'unauthenticated') return const Left(AuthFailure());
      if (e.code == 'not-found') return const Left(NotFoundFailure());
      return const Left(ServerFailure());
    } on Exception catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<JobEvaluation>>>
      getEvaluations() async {
    try {
      return Right(await _datasource.getEvaluations());
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, JobEvaluation>> getEvaluation(
      String id) async {
    try {
      return Right(await _datasource.getEvaluation(id));
    } catch (_) {
      return const Left(NotFoundFailure());
    }
  }
}
