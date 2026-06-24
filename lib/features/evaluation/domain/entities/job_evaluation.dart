import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_evaluation.freezed.dart';
part 'job_evaluation.g.dart';

/// Resultado de evaluar una oferta laboral con IA.
/// Equivalente al reporte de evaluación de career-ops.
@freezed
abstract class JobEvaluation with _$JobEvaluation {
  const factory JobEvaluation({
    required String id,
    required String userId,
    required String jobTitle, // Extraído por IA
    required String company, // Extraído por IA
    required String rawJobText, // El texto pegado por el usuario
    required double score, // 0.0 - 5.0 (equivalente al A-F de career-ops)
    required EvaluationRecommendation recommendation,
    required List<String>
    strengths, // Puntos fuertes del candidato para esta oferta
    required List<String> gaps, // Brechas o faltantes
    required String summary, // Resumen en 2-3 oraciones
    @Default([]) List<String> keywords, // Keywords de la oferta para el CV
    required DateTime createdAt,
  }) = _JobEvaluation;

  factory JobEvaluation.fromJson(Map<String, dynamic> json) =>
      _$JobEvaluationFromJson(json);
}

enum EvaluationRecommendation {
  @JsonValue('apply')
  apply, // Score >= 4.0 — aplicar
  @JsonValue('consider')
  consider, // Score 2.5-3.9 — considerar
  @JsonValue('skip')
  skip; // Score < 2.5 — no vale

  String get label {
    return switch (this) {
      EvaluationRecommendation.apply => '¡Aplicá!',
      EvaluationRecommendation.consider => 'Podés considerar',
      EvaluationRecommendation.skip => 'No recomendado',
    };
  }

  String get description {
    return switch (this) {
      EvaluationRecommendation.apply =>
        'Tu perfil encaja muy bien. Vale la pena aplicar.',
      EvaluationRecommendation.consider =>
        'Hay brechas pero son manejables. Podés aplicar si te interesa.',
      EvaluationRecommendation.skip =>
        'El fit es bajo. Hay mejores oportunidades para tu perfil.',
    };
  }
}

/// Estado de una postulación dentro del tracker.
enum ApplicationStatus {
  @JsonValue('interested')
  interested,
  @JsonValue('applied')
  applied,
  @JsonValue('interview')
  interview,
  @JsonValue('offer')
  offer,
  @JsonValue('rejected')
  rejected;

  String get label {
    return switch (this) {
      ApplicationStatus.interested => 'Interesado',
      ApplicationStatus.applied => 'Aplicado',
      ApplicationStatus.interview => 'Entrevista',
      ApplicationStatus.offer => 'Oferta',
      ApplicationStatus.rejected => 'No avanzó',
    };
  }
}
