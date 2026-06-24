import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/profile/presentation/providers/profile_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../router/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _resolveAuth();
  }

  Future<void> _resolveAuth() async {
    final user = await ref.read(authStateProvider.future);
    if (!mounted) return;
    if (user == null) {
      context.go(AppRoutes.onboarding);
      return;
    }
    final repo = ref.read(profileRepositoryProvider);
    final result = await repo.isProfileComplete(user.uid);
    if (!mounted) return;
    final isComplete = result.fold((_) => false, (v) => v);
    context.go(isComplete ? AppRoutes.evaluate : AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                size: 48,
                color: Color(0xFF1A56DB),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'PostulaAI',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu asistente de búsqueda laboral',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
