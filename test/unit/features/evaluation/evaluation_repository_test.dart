import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postula_ai/core/errors/failures.dart';
import 'package:postula_ai/features/evaluation/domain/entities/job_evaluation.dart';
import 'package:postula_ai/features/evaluation/domain/repositories/evaluation_repository.dart';

class MockEvaluationRepository extends Mock implements EvaluationRepository {}

void main() {
  late MockEvaluationRepository mockRepo;

  setUp(() {
    mockRepo = MockEvaluationRepository();
  });

  group('EvaluationRepository.evaluate', () {
    const testJobText = '''
      Buscamos Desarrollador Flutter con experiencia en Riverpod y Firebase.
      Requisitos: 2 años de experiencia, conocimiento de clean architecture.
      Beneficios: trabajo remoto, obra social, buen ambiente.
    ''';

    final testEvaluation = JobEvaluation(
      id: 'test-id',
      userId: 'user-1',
      jobTitle: 'Desarrollador Flutter',
      company: 'TechCorp',
      rawJobText: testJobText,
      score: 4.2,
      recommendation: EvaluationRecommendation.apply,
      strengths: ['Experiencia en Flutter', 'Conocimiento de Firebase'],
      gaps: ['Sin experiencia en proyectos enterprise'],
      summary: 'Buen match para el puesto.',
      keywords: ['Flutter', 'Riverpod', 'Firebase', 'Clean Architecture'],
      createdAt: DateTime(2026, 5, 6),
    );

    test('retorna JobEvaluation cuando la evaluación es exitosa', () async {
      when(
        () => mockRepo.evaluate(any()),
      ).thenAnswer((_) async => Right(testEvaluation));

      final result = await mockRepo.evaluate(testJobText);

      expect(result, isA<Right<Failure, JobEvaluation>>());
      result.fold((f) => fail('No debería haber falla'), (eval) {
        expect(eval.score, 4.2);
        expect(eval.recommendation, EvaluationRecommendation.apply);
        expect(eval.strengths, hasLength(2));
      });
    });

    test(
      'retorna LimitExceededFailure cuando el usuario alcanzó el límite',
      () async {
        when(
          () => mockRepo.evaluate(any()),
        ).thenAnswer((_) async => const Left(LimitExceededFailure()));

        final result = await mockRepo.evaluate(testJobText);

        expect(result, isA<Left<Failure, JobEvaluation>>());
        result.fold(
          (f) => expect(f, isA<LimitExceededFailure>()),
          (_) => fail('Debería haber falla'),
        );
      },
    );

    test('retorna ServerFailure cuando hay error del servidor', () async {
      when(
        () => mockRepo.evaluate(any()),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      final result = await mockRepo.evaluate(testJobText);

      expect(result.isLeft(), true);
    });
  });

  group('EvaluationRecommendation', () {
    test('apply tiene score >= 3.5', () {
      expect(EvaluationRecommendation.apply.label, '¡Aplicá!');
    });

    test('skip tiene descripción disuasoria', () {
      expect(EvaluationRecommendation.skip.description, contains('bajo'));
    });
  });
}
