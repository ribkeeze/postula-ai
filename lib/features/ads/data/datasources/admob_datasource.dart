import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';

// Datasource for managing AdMob banner ads.
class AdmobDatasource {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Test Ad Unit ID for Android Banner
    } else {
      return 'ca-app-pub-3940256099942544/2934735716'; // Test Ad Unit ID for iOS Banner
    }
  }

  BannerAd createBannerAd({required BannerAdListener listener}) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: listener,
    );
  }
}

// Manager for AdMob interstitial ads.
class InterstitialAdManager {
  static InterstitialAd? _interstitialAd;
  static bool _showWhenReady = false;

  static bool get isAdLoaded => _interstitialAd != null;

  static String get _adUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test Ad Unit ID for Android Interstitial
    } else {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test Ad Unit ID for iOS Interstitial
    }
  }

  static void _attachCallbackAndShow(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        loadAd();
      },
    );
    ad.show().catchError((_) {
      ad.dispose();
      _interstitialAd = null;
      loadAd();
    });
  }

  // Loads an interstitial ad.
  static void loadAd() {
    debugPrint('[ADS] loadAd called');
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          debugPrint(
            '[ADS] Ad loaded successfully | showWhenReady=$_showWhenReady',
          );
          if (_showWhenReady) {
            _showWhenReady = false;
            _attachCallbackAndShow(ad);
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
          _showWhenReady = false;
          debugPrint('[ADS] Ad failed to load: ${error.message}');
        },
      ),
    );
  }

  // Shows the loaded interstitial ad. Eligibility checks are the caller's responsibility.
  // If ad is not yet loaded, sets _showWhenReady so it shows as soon as it loads.
  static Future<void> maybeShow() async {
    debugPrint('[ADS] maybeShow called | adLoaded=${_interstitialAd != null}');
    if (_interstitialAd == null) {
      _showWhenReady = true;
      debugPrint('[ADS] ad not ready — _showWhenReady set');
      return;
    }

    _showWhenReady = false;
    _attachCallbackAndShow(_interstitialAd!);
  }
}

// Manager for AdMob rewarded ads (shown before PDF download for free users).
class RewardedAdManager {
  static RewardedAd? _rewardedAd;
  static bool _isLoading = false;

  static bool get isAdLoaded => _rewardedAd != null;

  static String get _adUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Test rewarded Android
    } else {
      return 'ca-app-pub-3940256099942544/1712485313'; // Test rewarded iOS
    }
  }

  static void loadAd() {
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;
    debugPrint('[ADS] RewardedAd loadAd called');
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          debugPrint('[ADS] RewardedAd loaded');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoading = false;
          debugPrint('[ADS] RewardedAd failed to load: ${error.message}');
        },
      ),
    );
  }

  // Shows rewarded ad. onComplete(true) if reward earned, onComplete(false) otherwise.
  // If no ad loaded, calls onComplete(false) and starts loading for next time.
  static Future<void> show({
    required void Function(bool earned) onComplete,
  }) async {
    final ad = _rewardedAd;
    if (ad == null) {
      debugPrint('[ADS] RewardedAd not loaded — cannot show');
      loadAd();
      onComplete(false);
      return;
    }

    _rewardedAd = null;
    bool rewarded = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadAd();
        onComplete(rewarded);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadAd();
        debugPrint('[ADS] RewardedAd failed to show: ${error.message}');
        onComplete(false);
      },
    );

    await ad.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
        debugPrint('[ADS] RewardedAd reward earned: ${reward.type}');
      },
    );
  }
}
