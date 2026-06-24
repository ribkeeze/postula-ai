import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/job_evaluation.dart';

abstract class EvaluationRepository {
  Future<Either<Failure, JobEvaluation>> evaluate(String jobText);
  Future<Either<Failure, List<JobEvaluation>>> getEvaluations();
  Future<Either<Failure, JobEvaluation>> getEvaluation(String id);
}
