import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_portal.freezed.dart';
part 'job_portal.g.dart';

@freezed
abstract class JobPortal with _$JobPortal {
  const factory JobPortal({
    required String id,
    required String name,
    required String url,
    @Default(true) bool isActive,
    @Default(false) bool isDefault,
  }) = _JobPortal;

  factory JobPortal.fromJson(Map<String, dynamic> json) =>
      _$JobPortalFromJson(json);
}
