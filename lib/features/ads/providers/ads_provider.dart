import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postula_ai/features/ads/data/datasources/admob_datasource.dart';
import 'package:postula_ai/features/ads/providers/interstitial_ad_counter_provider.dart';
import 'package:postula_ai/features/subscription/presentation/providers/subscription_provider.dart';

/// Provider to determine if ads should be shown to the user.
/// Returns true only for FREE users (Premium users should never see ads).
final shouldShowAdsProvider = Provider<bool>((ref) {
  final subscriptionAsync = ref.watch(subscriptionProvider);

  // Only show ads if subscription data is available and user is NOT premium
  return subscriptionAsync.maybeWhen(
    data: (subscription) => !subscription.isPremium,
    orElse: () => true, // Default to showing ads if data not yet loaded
  );
});

/// Provider for managing interstitial ad logic.
/// Handles checking eligibility and triggering ad display.
final interstitialAdServiceProvider = Provider<InterstitialAdService>((ref) {
  // Initialize ad loading when service is created
  InterstitialAdManager.loadAd();
  return InterstitialAdService(ref);
});

/// Service class for managing interstitial ad interactions.
/// Uses Provider ref internally for dependency injection.
class InterstitialAdService {
  final Ref _ref;

  InterstitialAdService(this._ref);

  /// Shows an interstitial ad if the user is eligible (free user).
  /// Call this AFTER the evaluation result screen is visible to the user.
  ///
  /// Behavior:
  /// - Premium users: no ad is ever shown
  /// - Free users: ad shown on every 2nd, 4th, 6th, etc. evaluation
  /// - Counter persists across app restarts via SharedPreferences
  Future<void> showInterstitialIfEligible() async {
    final shouldShowAds = _ref.read(shouldShowAdsProvider);

    // Await real persisted value — fixes count=0 bug from AsyncValue not yet loaded
    final currentCount = await _ref.read(interstitialAdCounterProvider.future);

    // Increment first, then check new value
    await _ref.read(interstitialAdCounterProvider.notifier).incrementCount();

    final newCount = currentCount + 1;
    debugPrint(
      '[ADS] checking: count=$newCount, isPremium=${!shouldShowAds}, adLoaded=${InterstitialAdManager.isAdLoaded}',
    );

    if (!shouldShowAds) return;

    final shouldShow = newCount % 2 == 0;
    debugPrint('[ADS] shouldShow=$shouldShow');

    if (shouldShow) {
      await InterstitialAdManager.maybeShow();
    }
  }
}
