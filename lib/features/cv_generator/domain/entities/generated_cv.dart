import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated_cv.freezed.dart';
part 'generated_cv.g.dart';

@freezed
abstract class GeneratedCv with _$GeneratedCv {
  const factory GeneratedCv({
    required String evaluationId,
    required String personalizedSummary,
    required List<CvWorkEntry> workExperience,
    required List<CvEducationEntry> education,
    required List<String> skillsHighlighted,
    required List<String> languages,
    required List<String> keywordsUsed,
    @Default([]) List<CvCertification> certifications,
    @Default([]) List<CvLink> links,
    @Default([]) List<CvReference> references,
    @Default([]) List<CvProject> projects,
    String? storageUrl,
  }) = _GeneratedCv;

  factory GeneratedCv.fromJson(Map<String, dynamic> json) =>
      _$GeneratedCvFromJson(json);
}

@freezed
abstract class CvWorkEntry with _$CvWorkEntry {
  const factory CvWorkEntry({
    required String company,
    required String position,
    required String period,
    required List<String> bullets,
  }) = _CvWorkEntry;

  factory CvWorkEntry.fromJson(Map<String, dynamic> json) =>
      _$CvWorkEntryFromJson(json);
}

@freezed
abstract class CvEducationEntry with _$CvEducationEntry {
  const factory CvEducationEntry({
    required String institution,
    required String degree,
    required String field,
    required String period,
    String? note,
  }) = _CvEducationEntry;

  factory CvEducationEntry.fromJson(Map<String, dynamic> json) =>
      _$CvEducationEntryFromJson(json);
}

@freezed
abstract class CvCertification with _$CvCertification {
  const factory CvCertification({
    required String name,
    required String issuer,
    required String year,
    String? url,
  }) = _CvCertification;

  factory CvCertification.fromJson(Map<String, dynamic> json) =>
      _$CvCertificationFromJson(json);
}

@freezed
abstract class CvLink with _$CvLink {
  const factory CvLink({
    required String label,
    required String url,
  }) = _CvLink;

  factory CvLink.fromJson(Map<String, dynamic> json) =>
      _$CvLinkFromJson(json);
}

@freezed
abstract class CvReference with _$CvReference {
  const factory CvReference({
    required String name,
    required String position,
    required String company,
    required String contact,
  }) = _CvReference;

  factory CvReference.fromJson(Map<String, dynamic> json) =>
      _$CvReferenceFromJson(json);
}

@freezed
abstract class CvProject with _$CvProject {
  const factory CvProject({
    required String name,
    String? context,
    String? period,
    @Default([]) List<String> technologies,
    String? url,
    @Default([]) List<String> bullets,
  }) = _CvProject;

  factory CvProject.fromJson(Map<String, dynamic> json) =>
      _$CvProjectFromJson(json);
}
