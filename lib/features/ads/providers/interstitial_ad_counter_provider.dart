import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'interstitial_ad_counter_provider.g.dart';

const String _evaluationCountKey = 'evaluationCount';

/// Provider to manage the local evaluation counter persisted via SharedPreferences.
/// Automatically loads on first access and persists across app restarts.
@riverpod
class InterstitialAdCounter
    extends _$InterstitialAdCounter {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_evaluationCountKey) ?? 0;
  }

  /// Increments the counter and saves to SharedPreferences.
  Future<void> incrementCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await future;
    final newCount = current + 1;
    state = AsyncValue.data(newCount);
    await prefs.setInt(_evaluationCountKey, newCount);
    debugPrint('[ADS] counter incremented, new value: $newCount');
  }

  /// Resets the counter to 0.
  Future<void> resetCount() async {
    final prefs = await SharedPreferences.getInstance();
    state = const AsyncValue.data(0);
    await prefs.setInt(_evaluationCountKey, 0);
  }
}
