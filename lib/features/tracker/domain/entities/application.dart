import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../evaluation/domain/entities/job_evaluation.dart';

part 'application.freezed.dart';
part 'application.g.dart';

class _TimestampConverter implements JsonConverter<DateTime, dynamic> {
  const _TimestampConverter();

  @override
  DateTime fromJson(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  dynamic toJson(DateTime dt) => dt.toIso8601String();
}

/// Una postulación en el tracker del usuario.
/// Se crea automáticamente cuando guarda una evaluación.
@freezed
abstract class Application with _$Application {
  const factory Application({
    required String id,
    required String userId,
    required String evaluationId,
    required String jobTitle,
    required String company,
    required double score,
    required ApplicationStatus status,
    String? notes,
    String? cvUrl,
    @_TimestampConverter() required DateTime createdAt,
    @_TimestampConverter() required DateTime updatedAt,
  }) = _Application;

  factory Application.fromJson(Map<String, dynamic> json) =>
      _$ApplicationFromJson(json);
}
