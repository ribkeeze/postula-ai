import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/limits.dart';
import '../../domain/entities/user_subscription.dart';
import '../../../../shared/providers/auth_provider.dart';

part 'subscription_provider.g.dart';

const _premiumEntitlementId = 'premium';
const _monthlyProductId = 'postula_ai_premium_monthly';

/// Estado de la suscripción del usuario actual.
/// keepAlive: true porque se consulta constantemente en toda la app.
@Riverpod(keepAlive: true)
Stream<UserSubscription> subscription(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(UserSubscription.free(''));
  }

  return FirebaseFirestore.instance
      .collection('subscriptions')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists || doc.data() == null) {
          return UserSubscription.free(user.uid);
        }
        return UserSubscription.fromJson({...doc.data()!, 'userId': user.uid});
      });
}

/// Uso diario del usuario — se resetea cada día automáticamente
/// (Firestore guarda un doc por día: usage/{uid}/daily/{YYYY-MM-DD})
@riverpod
Stream<DailyUsage> dailyUsage(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(DailyUsage.empty(_todayKey()));
  }

  return FirebaseFirestore.instance
      .collection('usage')
      .doc(user.uid)
      .collection('daily')
      .doc(_todayKey())
      .snapshots()
      .map((doc) {
        if (!doc.exists || doc.data() == null) {
          return DailyUsage.empty(_todayKey());
        }
        return DailyUsage.fromJson(doc.data()!);
      });
}

/// Si el usuario puede hacer una acción según su plan y uso del día.
@riverpod
bool canEvaluate(Ref ref) {
  final sub = ref.watch(subscriptionProvider).asData?.value;
  if (sub?.isPremium == true) return true;

  final usage = ref.watch(dailyUsageProvider).asData?.value;
  return usage?.canEvaluate(AppLimits.freeEvaluationsPerDay) ?? true;
}

@riverpod
bool canGenerateCv(Ref ref) {
  final sub = ref.watch(subscriptionProvider).asData?.value;
  if (sub?.isPremium == true) return true;

  final usage = ref.watch(dailyUsageProvider).asData?.value;
  return usage?.canGenerateCv(AppLimits.freeCvPerDay) ?? true;
}

@riverpod
bool canCoach(Ref ref) {
  final sub = ref.watch(subscriptionProvider).asData?.value;
  if (sub?.isPremium == true) return true;

  final usage = ref.watch(dailyUsageProvider).asData?.value;
  return usage?.canCoach(AppLimits.freeCoachPerDay) ?? true;
}

/// Notifier para comprar/restaurar suscripción via RevenueCat.
@riverpod
class PurchaseNotifier extends _$PurchaseNotifier {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> purchasePremium() async {
    state = const AsyncValue.loading();
    try {
      final offerings = await Purchases.getOfferings();
      final monthly = offerings.current?.getPackage(_monthlyProductId);

      if (monthly == null) {
        state = AsyncValue.error('Producto no disponible', StackTrace.current);
        return false;
      }

      final purchaseResult =
          await Purchases.purchase(PurchaseParams.package(monthly));
      final isPremium = purchaseResult.customerInfo.entitlements.active
          .containsKey(_premiumEntitlementId);

      state = const AsyncValue.data(null);
      return isPremium;
    } on PurchasesErrorCode catch (e, st) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        state = const AsyncValue.data(null);
        return false;
      }
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    state = const AsyncValue.loading();
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isPremium = customerInfo.entitlements.active.containsKey(
        _premiumEntitlementId,
      );
      state = const AsyncValue.data(null);
      return isPremium;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

String _todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());
