import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// El perfil del usuario — equivalente a cv.md + profile.yml en career-ops.
///
/// Este objeto se construye durante el onboarding y se usa en TODAS las
/// llamadas a la IA como contexto base. Es el corazón de la app.
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String uid,
    required PersonalInfo personalInfo,
    @Default([]) List<WorkExperience> workExperience,
    @Default([]) List<Education> education,
    @Default([]) List<String> skills,
    @Default([]) List<Language> languages,
    @Default([]) List<Certification> certifications,
    @Default([]) List<Project> projects,
    String? linkedIn,
    String? summary,
    @Default(false) bool isComplete,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

@freezed
abstract class PersonalInfo with _$PersonalInfo {
  const factory PersonalInfo({
    required String fullName,
    required String email,
    String? phone,
    required String city,
    required String country,
    String? provincia,
    String? postalCode,
    String? linkedInUrl,
    String? githubUrl,
    String? portfolioUrl,
    double? expectedSalaryAmount,
    @Default('ARS') String expectedSalaryCurrency,
    @Default(true) bool salaryNegotiable,
    @Default([]) List<WorkModality> preferredModalities,
    int? maxCommuteKm,
    @Default(false) bool hasOwnVehicle,
    @Default([]) List<String> excludedIndustries,
    @Default([]) List<String> excludedCompanies,
  }) = _PersonalInfo;

  factory PersonalInfo.fromJson(Map<String, dynamic> json) =>
      _$PersonalInfoFromJson(json);
}

@freezed
abstract class WorkReference with _$WorkReference {
  const factory WorkReference({
    required String id,
    required String name,
    required String position,
    required String company,
    String? phone,
    String? email,
  }) = _WorkReference;

  factory WorkReference.fromJson(Map<String, dynamic> json) =>
      _$WorkReferenceFromJson(json);
}

@freezed
abstract class WorkExperience with _$WorkExperience {
  const factory WorkExperience({
    required String id,
    required String company,
    required String position,
    required String startDate, // "MM/YYYY"
    String? endDate, // null = trabajo actual
    @Default(false) bool isCurrent,
    String? description,
    @Default([]) List<String> achievements,
    @Default([]) List<WorkReference> references,
  }) = _WorkExperience;

  factory WorkExperience.fromJson(Map<String, dynamic> json) =>
      _$WorkExperienceFromJson(json);
}

@freezed
abstract class Education with _$Education {
  const factory Education({
    required String id,
    required String institution,
    required String degree,
    required String field,
    required String startYear,
    String? endYear, // null = en curso
    @Default(false) bool isOngoing,
  }) = _Education;

  factory Education.fromJson(Map<String, dynamic> json) =>
      _$EducationFromJson(json);
}

@freezed
abstract class Language with _$Language {
  const factory Language({
    required String name,
    required LanguageLevel level,
  }) = _Language;

  factory Language.fromJson(Map<String, dynamic> json) =>
      _$LanguageFromJson(json);
}

@freezed
abstract class Certification with _$Certification {
  const factory Certification({
    required String id,
    required String name,
    required String issuer,
    required int year,
    String? url,
  }) = _Certification;

  factory Certification.fromJson(Map<String, dynamic> json) =>
      _$CertificationFromJson(json);
}

@freezed
abstract class Project with _$Project {
  const factory Project({
    required String id,
    required String name,
    required String description,
    @Default([]) List<String> technologies,
    String? url,
    String? context,
    String? startDate, // "MM/YYYY"
    String? endDate,   // "MM/YYYY", null if ongoing
    @Default(false) bool isCurrent,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
}

enum WorkModality {
  @JsonValue('remoto') remote,
  @JsonValue('hibrido') hybrid,
  @JsonValue('presencial') onsite;

  String get label => switch (this) {
    WorkModality.remote => 'Remoto',
    WorkModality.hybrid => 'Híbrido',
    WorkModality.onsite => 'Presencial',
  };
}

enum LanguageLevel {
  @JsonValue('basico') basico,
  @JsonValue('intermedio') intermedio,
  @JsonValue('avanzado') avanzado,
  @JsonValue('nativo') nativo;

  String get label {
    return switch (this) {
      LanguageLevel.basico => 'Básico',
      LanguageLevel.intermedio => 'Intermedio',
      LanguageLevel.avanzado => 'Avanzado',
      LanguageLevel.nativo => 'Nativo',
    };
  }
}
