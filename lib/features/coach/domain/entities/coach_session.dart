import 'package:freezed_annotation/freezed_annotation.dart';

part 'coach_session.freezed.dart';
part 'coach_session.g.dart';

@freezed
abstract class CoachSession with _$CoachSession {
  const factory CoachSession({
    required String evaluationId,
    required List<String> interviewTips,
    required List<CoachQuestion> probableQuestions,
    required List<String> keyPointsToHighlight,
    required List<String> thingsToAvoid,
  }) = _CoachSession;

  factory CoachSession.fromJson(Map<String, dynamic> json) =>
      _$CoachSessionFromJson(json);
}

@freezed
abstract class CoachQuestion with _$CoachQuestion {
  const factory CoachQuestion({
    required String type,
    required String question,
    required String hint,
    required String suggestedApproach,
  }) = _CoachQuestion;

  factory CoachQuestion.fromJson(Map<String, dynamic> json) =>
      _$CoachQuestionFromJson(json);
}
