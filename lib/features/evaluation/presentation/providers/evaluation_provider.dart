import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../data/datasources/evaluation_remote_datasource.dart';
import '../../data/repositories/evaluation_repository_impl.dart';
import '../../domain/entities/job_evaluation.dart';

part 'evaluation_provider.g.dart';

@riverpod
EvaluationRepositoryImpl evaluationRepository(Ref ref) {
  return EvaluationRepositoryImpl(
      EvaluationRemoteDatasourceImpl());
}

@Riverpod(keepAlive: true)
class EvaluationNotifier extends _$EvaluationNotifier {
  @override
  AsyncValue<JobEvaluation?> build() =>
      const AsyncValue.data(null);

  Future<Either<Failure, JobEvaluation>> evaluate(
      String jobText) async {
    state = const AsyncValue.loading();
    final repo = ref.read(evaluationRepositoryProvider);
    final result = await repo.evaluate(jobText);

    result.fold(
      (f) =>
          state = AsyncValue.error(f, StackTrace.current),
      (e) => state = AsyncValue.data(e),
    );

    return result;
  }
}

/// Carga una evaluación específica por ID (para la pantalla de resultado).
@riverpod
Future<JobEvaluation> evaluationById(Ref ref, String id) async {
  final inMemory = ref.watch(evaluationProvider).asData?.value;
  if (inMemory != null && inMemory.id == id) return inMemory;

  final repo = ref.read(evaluationRepositoryProvider);

  // First attempt
  var result = await repo.getEvaluation(id);
  if (result.isRight()) return result.getOrElse(() => throw Exception());

  // Retry once after 1 second
  await Future.delayed(const Duration(seconds: 1));
  result = await repo.getEvaluation(id);
  return result.fold(
    (f) => throw Exception(f.message),
    (e) => e,
  );
}
