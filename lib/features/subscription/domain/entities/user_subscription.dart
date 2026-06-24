import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_subscription.freezed.dart';
part 'user_subscription.g.dart';

/// Estado de la suscripción del usuario.
/// Guardado en Firestore: subscriptions/{userId}
@freezed
abstract class UserSubscription with _$UserSubscription {
  const factory UserSubscription({
    required String userId,
    required SubscriptionPlan plan,
    DateTime? expiresAt, // null = free (sin vencimiento)
    String? revenueCatId, // ID de RevenueCat para reconciliar
    required DateTime updatedAt,
  }) = _UserSubscription;

  const UserSubscription._();

  factory UserSubscription.fromJson(Map<String, dynamic> json) =>
      _$UserSubscriptionFromJson(json);

  /// Un usuario es premium si tiene plan premium Y no venció.
  bool get isPremium {
    if (plan != SubscriptionPlan.premium) return false;
    if (expiresAt == null) return false;
    return expiresAt!.isAfter(DateTime.now());
  }

  bool get isFree => !isPremium;

  /// Plan gratuito por defecto para usuarios nuevos.
  factory UserSubscription.free(String userId) => UserSubscription(
    userId: userId,
    plan: SubscriptionPlan.free,
    updatedAt: DateTime.now(),
  );
}

enum SubscriptionPlan {
  @JsonValue('free')
  free,
  @JsonValue('premium')
  premium,
}

/// Uso diario del usuario.
/// Guardado en Firestore: usage/{userId}/daily/{YYYY-MM-DD}
@freezed
abstract class DailyUsage with _$DailyUsage {
  const factory DailyUsage({
    required String date, // "2026-05-06"
    @Default(0) int evaluations,
    @Default(0) int cvGenerated,
    @Default(0) int coachSessions,
  }) = _DailyUsage;

  const DailyUsage._();

  factory DailyUsage.fromJson(Map<String, dynamic> json) =>
      _$DailyUsageFromJson(json);

  factory DailyUsage.empty(String date) => DailyUsage(date: date);

  bool canEvaluate(int limit) => evaluations < limit;
  bool canGenerateCv(int limit) => cvGenerated < limit;
  bool canCoach(int limit) => coachSessions < limit;
}
