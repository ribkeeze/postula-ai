import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../subscription/presentation/providers/subscription_provider.dart';

part 'ads_provider.g.dart';

/// Returns true when the current user should see ads (i.e. is on the free plan).
@riverpod
bool shouldShowAds(Ref ref) {
  final sub = ref.watch(subscriptionProvider).asData?.value;
  return sub?.isPremium != true;
}
