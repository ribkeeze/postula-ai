import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

// Web Client ID from Firebase Console → Authentication → Google → Web SDK configuration
const _webClientId =
    '714384703131-0ggnv7mro9htkk955sdkte2i249dm1o3.apps.googleusercontent.com';

const _revenueCatAndroidKey = 'test_nYUcYyzJdjlfVhLZbUBlnpdBViJ';
const _revenueCatIosKey = 'test_nYUcYyzJdjlfVhLZbUBlnpdBViJ';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kReleaseMode
        ? const AndroidPlayIntegrityProvider()
        : const AndroidDebugProvider(),
    providerApple: kReleaseMode
        ? const AppleDeviceCheckProvider()
        : const AppleDebugProvider(),
  );
  await GoogleSignIn.instance.initialize(serverClientId: _webClientId);

  await Purchases.configure(
    PurchasesConfiguration(
      Platform.isIOS ? _revenueCatIosKey : _revenueCatAndroidKey,
    ),
  );

  await MobileAds.instance.initialize();

  // Forzar orientación portrait — la app está diseñada para mobile vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: PostulaAIApp()));
}

class PostulaAIApp extends ConsumerWidget {
  const PostulaAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'PostulaAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      // Accesibilidad: permitir que el usuario escale texto sin romper layouts
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Máximo 1.3x de escalado — más que eso rompe algunos layouts
            // pero el diseño está hecho para tolerar hasta 1.3x
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(1.0, 1.3),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
