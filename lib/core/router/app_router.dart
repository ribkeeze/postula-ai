import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/coach/presentation/screens/coach_screen.dart';
import '../../features/cv_generator/presentation/screens/cv_preview_screen.dart';
import '../../features/evaluation/presentation/screens/evaluate_screen.dart';
import '../../features/evaluation/presentation/screens/evaluation_result_screen.dart';
import '../../features/job_search/presentation/screens/job_search_screen.dart';
import '../../features/legal/presentation/screens/privacy_policy_screen.dart';
import '../../features/legal/presentation/screens/terms_of_service_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/tracker/presentation/screens/tracker_screen.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/splash_screen.dart';

part 'app_router.g.dart';

abstract class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const evaluate = '/evaluate';
  static const tracker = '/tracker';
  static const profile = '/profile';
  static const jobSearch = '/job-search';
  static const privacy = '/privacy';
  static const terms = '/terms';
}

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue>(authStateProvider, (_, _) => notifyListeners());
    _ref.listen<AsyncValue>(userProfileProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync = _ref.read(authStateProvider);
    final loc = state.matchedLocation;
    final isOnSplash = loc == AppRoutes.splash;
    final isOnOnboarding = loc == AppRoutes.onboarding;
    final isPublic =
        isOnSplash ||
        isOnOnboarding ||
        loc == AppRoutes.privacy ||
        loc == AppRoutes.terms;
    final isProtected = !isPublic;

    return authAsync.when(
      // Mientras carga — quedarse en splash, o si ya está en otra ruta no mover
      loading: () => isOnSplash ? null : null,
      error: (_, _) => AppRoutes.onboarding,
      data: (user) {
        if (user == null) {
          // No autenticado — ir a onboarding si está en ruta protegida
          if (isProtected) return AppRoutes.onboarding;
          return null;
        }
        if (isOnSplash) return AppRoutes.evaluate;
        if (isOnOnboarding) {
          final isComplete =
              _ref.read(userProfileProvider).asData?.value?.isComplete ?? false;
          if (isComplete) return AppRoutes.evaluate;
        }
        return null;
      },
    );
  }
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (_, _) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (_, _) => const TermsOfServiceScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.evaluate,
            builder: (_, _) => const EvaluateScreen(),
            routes: [
              GoRoute(
                path: 'result',
                builder: (context, state) => EvaluationResultScreen(
                  evaluationId: state.uri.queryParameters['id'] ?? '',
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.tracker,
            builder: (_, _) => const TrackerScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, _) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, _) => const EditProfileScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.jobSearch,
            builder: (_, _) => const JobSearchScreen(),
          ),
          GoRoute(
            path: '/cv/:applicationId',
            builder: (context, state) => CvPreviewScreen(
              applicationId: state.pathParameters['applicationId']!,
            ),
          ),
          GoRoute(
            path: '/coach/:applicationId',
            builder: (context, state) => CoachScreen(
              applicationId: state.pathParameters['applicationId']!,
            ),
          ),
        ],
      ),
    ],
  );
}
